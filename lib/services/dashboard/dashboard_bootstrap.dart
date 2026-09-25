import 'dart:async';

import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/aa_consent.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:get/get.dart';

/// Finarkein-only dashboard bootstrap helpers.
///
/// Purpose: decide whether the user has ANY Finarkein AA consents before
/// triggering slow dashboard endpoints, to avoid late UI switching.
class DashboardBootstrapService {
  static const Duration defaultTimeout = Duration(seconds: 3);
  static const Duration defaultCacheMaxAge = Duration(days: 7);

  /// Read last-known consent existence from local storage.
  /// Returns null when not available or not parseable.
  static FinarkeinConsentCache? readLastKnownConsentCache({
    required String userguid,
  }) {
    try {
      final raw = StorageService.read(StorageKeys.AA_HAS_ANY_CONSENT(userguid));
      final updatedAtRaw =
          StorageService.read(StorageKeys.AA_HAS_ANY_CONSENT_UPDATED_AT(userguid));

      final bool? hasAnyConsent =
          raw is bool ? raw : (raw is String ? raw.toLowerCase() == 'true' : null);

      DateTime? updatedAt;
      if (updatedAtRaw is String && updatedAtRaw.trim().isNotEmpty) {
        updatedAt = DateTime.tryParse(updatedAtRaw.trim());
      }

      if (hasAnyConsent == null) return null;
      return FinarkeinConsentCache(hasAnyConsent: hasAnyConsent, updatedAt: updatedAt);
    } catch (_) {
      return null;
    }
  }

  static bool isCacheFresh(
    FinarkeinConsentCache cache, {
    Duration maxAge = defaultCacheMaxAge,
  }) {
    final updatedAt = cache.updatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) <= maxAge;
  }

  /// Fetches `aa/consents` and returns a minimal summary.
  ///
  /// - Returns null on failure/timeout (callers should fall back to legacy behavior).
  /// - Persists last-known `hasAnyConsent` for observability and potential future optimizations.
  static Future<FinarkeinConsentSummary?> fetchFinarkeinConsentSummary({
    Duration timeout = defaultTimeout,
    bool forceRefresh = true,
  }) async {
    final startedAt = DateTime.now();
    try {
      final state = await FinarkeinConsentsService()
          .getConsentsWithPendingState(forceRefresh: forceRefresh)
          .timeout(timeout);

      // Safety: do not treat cached/failed responses as authoritative for consent existence.
      // Otherwise transient network issues can incorrectly persist "no consents" and flip the dashboard to unlinked.
      if (!state.networkOk) {
        AppLogger.error(
          'Dashboard bootstrap: aa/consents not confirmed from network (status=${state.httpStatusCode}), skipping consent state update',
          tag: 'DashboardBootstrap',
        );
        return null;
      }

      final consents = state.consents;
      final hasAnyConsent = consents.isNotEmpty;

      _persistLastKnown(hasAnyConsent);

      AppLogger.info(
        'Dashboard bootstrap: aa/consents ok hasAnyConsent=$hasAnyConsent count=${consents.length} in ${DateTime.now().difference(startedAt).inMilliseconds}ms',
        tag: 'DashboardBootstrap',
      );

      return FinarkeinConsentSummary(
        hasAnyConsent: hasAnyConsent,
        consents: consents,
        pendingConsentRequestId: state.pendingConsentRequestId,
        pendingRevokeRequestId: state.pendingRevokeRequestId,
        consentedFiTypes: state.consentedFiTypes,
        fetchedAt: DateTime.now(),
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'Dashboard bootstrap: aa/consents timeout after ${timeout.inMilliseconds}ms',
        error: e,
        stackTrace: st,
        tag: 'DashboardBootstrap',
      );
      return null;
    } catch (e, st) {
      AppLogger.error(
        'Dashboard bootstrap: aa/consents failed',
        error: e,
        stackTrace: st,
        tag: 'DashboardBootstrap',
      );
      return null;
    }
  }

  static void _persistLastKnown(bool hasAnyConsent) {
    try {
      if (!Get.isRegistered<UserController>()) return;
      final userguid = Get.find<UserController>().userData?.guid;
      if (userguid == null || userguid.trim().isEmpty) return;

      StorageService.write(StorageKeys.AA_HAS_ANY_CONSENT(userguid), hasAnyConsent);
      StorageService.write(
        StorageKeys.AA_HAS_ANY_CONSENT_UPDATED_AT(userguid),
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // best-effort; never block dashboard
    }
  }
}

class FinarkeinConsentSummary {
  final bool hasAnyConsent;
  final List<AaConsent> consents;
  final String? pendingConsentRequestId;
  final String? pendingRevokeRequestId;
  final List<String>? consentedFiTypes;
  final DateTime fetchedAt;

  const FinarkeinConsentSummary({
    required this.hasAnyConsent,
    required this.consents,
    required this.pendingConsentRequestId,
    required this.pendingRevokeRequestId,
    required this.consentedFiTypes,
    required this.fetchedAt,
  });
}

class FinarkeinConsentCache {
  final bool hasAnyConsent;
  final DateTime? updatedAt;

  const FinarkeinConsentCache({required this.hasAnyConsent, required this.updatedAt});
}

/// Reactive Finarkein consent state for the Dashboard.
///
/// Single source of truth:
/// - Hydrates from local storage for fast cold start.
/// - Refreshes from network (`aa/consents`) and publishes updates to listeners immediately.
class FinarkeinConsentBootstrap extends GetxService {
  static FinarkeinConsentBootstrap get to => Get.find<FinarkeinConsentBootstrap>();

  final Rxn<FinarkeinConsentSummary> summaryRx = Rxn<FinarkeinConsentSummary>();
  final RxBool hasAnyConsentRx = false.obs;
  final RxList<String> consentedFiTypesRx = <String>[].obs;

  String? _userguid;

  String? get userguid => _userguid;

  void hydrateFromStorage({required String userguid}) {
    _userguid = userguid.trim();
    final cache = DashboardBootstrapService.readLastKnownConsentCache(
      userguid: _userguid!,
    );
    if (cache == null) return;
    hasAnyConsentRx.value = cache.hasAnyConsent;
    // We don't persist FI types yet; leave as-is.
  }

  /// Refreshes consents from network and publishes to reactive fields.
  /// Returns the fetched summary or null on failure.
  Future<FinarkeinConsentSummary?> refreshFromNetwork({
    Duration timeout = DashboardBootstrapService.defaultTimeout,
    bool forceRefresh = true,
  }) async {
    final summary = await DashboardBootstrapService.fetchFinarkeinConsentSummary(
      timeout: timeout,
      forceRefresh: forceRefresh,
    );
    if (summary == null) return null;

    summaryRx.value = summary;
    hasAnyConsentRx.value = summary.hasAnyConsent;
    consentedFiTypesRx.assignAll(summary.consentedFiTypes ?? const <String>[]);

    return summary;
  }
}

