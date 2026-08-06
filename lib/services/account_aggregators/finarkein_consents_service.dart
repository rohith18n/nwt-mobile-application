import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/aa_consent.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// For Finarkein users: GET aa/consents and derive adhoc remaining; POST aa/data/fetch for manual refresh.
/// aa/consents is only invoked on app launch (first use) or after data/fetch completes; not on every screen change.
/// Manual trigger sequence: 1) POST data/fetch 2) Poll GET aa/consent/status until done 3) GET aa/data/result once 4) Refresh consents.
class FinarkeinConsentsService {
  FinarkeinConsentsService._();
  static final FinarkeinConsentsService _instance =
      FinarkeinConsentsService._();
  factory FinarkeinConsentsService() => _instance;

  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// Cached consents from GET aa/consents. Only refreshed at launch (first getConsents) or after data/fetch (forceRefresh).
  List<AaConsent>? _cachedConsents;

  /// Set by ConsentRevokeScreen when revoke webview closes with redirect, so Dashboard can start revoke polling before getConsentsWithPendingState may return it.
  static String? pendingRevokeRequestIdFromUi;

  /// True while revoke status polling is running. Use to disable "Delink account" in Data Protection and revoke sheet.
  static bool isRevokeInProgress = false;

  /// Circuit breaker: do not call data/result API until this time. Set on any error (non-2xx or error object in body).
  static DateTime? _dataResultCircuitOpenUntil;
  static const Duration _dataResultCircuitCooldown = Duration(minutes: 5);

  /// Minimum delay between consecutive data/result calls in getDataResultsForConsents to avoid burst.
  static const Duration _minDelayBetweenResultCalls = Duration(
    milliseconds: 400,
  );

  /// Poll interval and timeout for consent/status after triggering data/fetch (before calling data/result).
  static const Duration _consentStatusPollInterval = Duration(seconds: 4);
  static const Duration _consentStatusPollTimeout = Duration(minutes: 2);

  /// Poll interval and timeout for consent revoke status (after revoke WebView or when no redirectUrl).
  static const Duration _revokeStatusPollInterval = Duration(seconds: 4);
  static const Duration _revokeStatusPollTimeout = Duration(minutes: 2);

  /// Returns true if data/result calls are currently blocked (circuit open).
  static bool get isDataResultCircuitOpen =>
      _dataResultCircuitOpenUntil != null &&
      DateTime.now().isBefore(_dataResultCircuitOpenUntil!);

  /// Resets the circuit so data/result can be called again. Call on explicit user refresh.
  static void resetDataResultCircuit() {
    _dataResultCircuitOpenUntil = null;
    AppLogger.info(
      'Finarkein data/result circuit reset',
      tag: 'FinarkeinConsentsService',
    );
  }

  /// Clears in-memory consents and pending state cache. Next getConsents() will call the API.
  /// Call when revoke is initiated so UI does not show stale consents.
  void clearConsentsCache() {
    _cachedConsents = null;
    _cachedPendingState = null;
    AppLogger.info(
      'Finarkein consents cache cleared',
      tag: 'FinarkeinConsentsService',
    );
  }

  static void _openDataResultCircuit() {
    _dataResultCircuitOpenUntil = DateTime.now().add(
      _dataResultCircuitCooldown,
    );
    AppLogger.info(
      'Finarkein data/result circuit opened until $_dataResultCircuitOpenUntil (cooldown ${_dataResultCircuitCooldown.inMinutes} min)',
      tag: 'FinarkeinConsentsService',
    );
  }

  /// Cached pending state from last GET aa/consents (when backend returns object with pending ids).
  ConsentsWithPendingState? _cachedPendingState;

  /// Last consented FI types from GET aa/consents. Null when not yet fetched or legacy response.
  List<String>? get consentedFiTypes => _cachedPendingState?.consentedFiTypes;

  /// Fetches active consents. GET aa/consents is only called on app launch (first use, cache null) or when [forceRefresh] is true.
  /// When returning to dashboard or changing screens, cached consents are returned so aa/consents is not invoked.
  /// Supports both legacy array response and new object shape { consents, pendingConsentRequestId?, pendingRevokeRequestId? }.
  Future<List<AaConsent>> getConsents({bool forceRefresh = false}) async {
    final state = await getConsentsWithPendingState(forceRefresh: forceRefresh);
    return state.consents;
  }

  /// Fetches consents and pending operation requestIds (for Dashboard to run consent/revoke status polling).
  /// Backend returns { consents, pendingConsentRequestId?, pendingRevokeRequestId? }; legacy array is also supported.
  Future<ConsentsWithPendingState> getConsentsWithPendingState({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedPendingState != null) {
      return _cachedPendingState!;
    }
    try {
      AppLogger.info(
        'Finarkein GET aa/consents request (forceRefresh=$forceRefresh)',
        tag: 'FinarkeinConsentsService',
      );
      final response = await _api.get(ApiURLs.AA_CONSENTS);
      if (response == null || response.statusCode != 200) {
        AppLogger.info(
          'Finarkein GET aa/consents failed: ${response?.body}',
          tag: 'FinarkeinConsentsService',
        );
        final cached = _cachedPendingState;
        return ConsentsWithPendingState(
          consents: cached?.consents ?? _cachedConsents ?? const <AaConsent>[],
          consentedFiTypes: cached?.consentedFiTypes,
          pendingConsentRequestId: cached?.pendingConsentRequestId,
          pendingRevokeRequestId: cached?.pendingRevokeRequestId,
          networkOk: false,
          httpStatusCode: response?.statusCode,
        );
      }
      final body = jsonDecode(response.body);
      List<AaConsent> list;
      String? pendingConsentRequestId;
      String? pendingRevokeRequestId;
      List<String>? consentedFiTypes;

      if (body is Map<String, dynamic>) {
        final consentsRaw = body['consents'];
        if (consentsRaw is List) {
          list =
              consentsRaw
                  .map(
                    (e) =>
                        AaConsent.fromJson(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList();
        } else {
          list = _cachedConsents ?? [];
        }
        final pcr = body['pendingConsentRequestId'];
        final prr = body['pendingRevokeRequestId'];
        pendingConsentRequestId = pcr != null ? pcr.toString().trim() : null;
        if (pendingConsentRequestId != null &&
            pendingConsentRequestId.isEmpty) {
          pendingConsentRequestId = null;
        }
        pendingRevokeRequestId = prr != null ? prr.toString().trim() : null;
        if (pendingRevokeRequestId != null && pendingRevokeRequestId.isEmpty) {
          pendingRevokeRequestId = null;
        }
        final cft = body['consentedFiTypes'];
        if (cft is List) {
          consentedFiTypes =
              cft
                  .map((e) => e?.toString().trim())
                  .where((s) => s != null && s.isNotEmpty)
                  .cast<String>()
                  .toList();
        }
      } else if (body is List) {
        list =
            body
                .map(
                  (e) =>
                      AaConsent.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList();
      } else {
        list = _cachedConsents ?? [];
      }

      _cachedConsents = list;
      _cachedPendingState = ConsentsWithPendingState(
        consents: list,
        consentedFiTypes: consentedFiTypes,
        pendingConsentRequestId: pendingConsentRequestId,
        pendingRevokeRequestId: pendingRevokeRequestId,
        networkOk: true,
        httpStatusCode: response.statusCode,
      );
      AppLogger.info(
        'Finarkein GET aa/consents success count=${list.length} pendingConsent=$pendingConsentRequestId pendingRevoke=$pendingRevokeRequestId',
        tag: 'FinarkeinConsentsService',
      );
      return _cachedPendingState!;
    } catch (e, st) {
      AppLogger.error(
        'Finarkein getConsents error',
        error: e,
        stackTrace: st,
        tag: 'FinarkeinConsentsService',
      );
      final cached = _cachedPendingState;
      return ConsentsWithPendingState(
        consents: cached?.consents ?? _cachedConsents ?? const <AaConsent>[],
        consentedFiTypes: cached?.consentedFiTypes,
        pendingConsentRequestId: cached?.pendingConsentRequestId,
        pendingRevokeRequestId: cached?.pendingRevokeRequestId,
        networkOk: false,
      );
    }
  }

  /// Derives adhoc remaining from consents: max(0, max(remaining) per consent).
  /// Only considers ACTIVE consents.
  double getAdhocRemainingFromConsents(List<AaConsent> consents) {
    if (consents.isEmpty) return 0.0;
    int maxRemaining = 0;
    for (final c in consents) {
      if (c.isActive && c.remaining > maxRemaining) {
        maxRemaining = c.remaining;
      }
    }
    return maxRemaining.toDouble();
  }

  /// Returns the id to use for GET aa/data/result: first consent's consentHandle, else first consent's requestId.
  /// Prefer consentHandle so the result API returns actual FI data; using only requestId can return empty data.
  static String? getDataResultIdFromConsents(List<AaConsent> consents) {
    if (consents.isEmpty) return null;
    for (final c in consents) {
      final handle = c.consentHandle?.trim();
      if (handle != null && handle.isNotEmpty) return handle;
    }
    for (final c in consents) {
      final rid = c.requestId?.trim();
      if (rid != null && rid.isNotEmpty) return rid;
    }
    return null;
  }

  /// Returns all ids to use for GET aa/data/result: for each consent, consentHandle if present else requestId. Non-empty only, capped at [maxCount].
  /// Prefer consentHandle so the result API returns actual FI data.
  static List<String> getDataResultIdsFromConsents(
    List<AaConsent> consents, {
    int maxCount = 20,
  }) {
    final ids = <String>[];
    final seen = <String>{};
    for (final c in consents) {
      if (ids.length >= maxCount) break;
      final handle = c.consentHandle?.trim();
      final id =
          (handle != null && handle.isNotEmpty) ? handle : c.requestId?.trim();
      if (id != null && id.isNotEmpty && seen.add(id)) ids.add(id);
    }
    return ids;
  }

  /// Fetches data result for each consent id (up to [maxConsents]). Returns list of successful result bodies.
  /// If circuit is open (429 or prior failure), returns [] without calling the API. Calls are sequential with a small delay to avoid burst/429.
  Future<List<Map<String, dynamic>>> getDataResultsForConsents({
    int maxConsents = 20,
  }) async {
    if (isDataResultCircuitOpen) {
      AppLogger.info(
        'Finarkein getDataResultsForConsents: circuit open, skipping data/result calls',
        tag: 'FinarkeinConsentsService',
      );
      return [];
    }
    final consents = await getConsents();
    final ids = getDataResultIdsFromConsents(consents, maxCount: maxConsents);
    if (ids.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i++) {
      if (isDataResultCircuitOpen) break;
      if (i > 0) await Future.delayed(_minDelayBetweenResultCalls);
      final result = await getDataResult(ids[i]);
      if (result != null) {
        results.add(result);
      } else {
        AppLogger.info(
          'Finarkein getDataResultsForConsents: skipped null result for id=${ids[i]} (circuit may be open), continuing with remaining consents',
          tag: 'FinarkeinConsentsService',
        );
        // Continue to next consent instead of breaking, so we can get partial data.
      }
    }
    return results;
  }

  /// Fetches consents, resolves id (requestId else consentHandle), then GET aa/data/result(id). Returns parsed body or null.
  Future<Map<String, dynamic>?> getDataResultForFirstConsent() async {
    final consents = await getConsents();
    final id = getDataResultIdFromConsents(consents);
    if (id == null || id.isEmpty) return null;
    return getDataResult(id);
  }

  static bool _isSuccessStatusCode(int statusCode) =>
      statusCode == 200 || statusCode == 201;

  /// Returns true if we should open a circuit breaker for this response code.
  /// We only do this for transient / burst-prone failures (rate limits, 5xx, null response),
  /// not for per-consent 4xx (which should not block other consent handles).
  static bool _shouldOpenCircuitForStatus(int statusCode) =>
      statusCode == 429 || statusCode >= 500;

  static bool _bodyIndicatesError(Map<String, dynamic>? body) {
    if (body == null) return false;
    if (body.containsKey('error')) return true;
    final status = (body['status'] as String?)?.toUpperCase();
    if (status == 'ERROR') return true;
    return false;
  }

  /// Fetches financial data result for a consent. GET aa/data/result/:id (id may be requestId or consentHandle). Returns parsed body or null.
  ///
  /// Important: For multi-consent users, **do not** block fetching other handles if one handle fails.
  /// We only open the circuit on transient errors (429/5xx/null response). Per-handle 4xx are ignored.
  Future<Map<String, dynamic>?> getDataResult(String id) async {
    if (id.isEmpty) return null;
    if (isDataResultCircuitOpen) return null;
    try {
      AppLogger.info(
        'Finarkein GET aa/data/result id=$id',
        tag: 'FinarkeinConsentsService',
      );
      final response = await _api.get(ApiURLs.AA_DATA_RESULT(id));
      if (response == null) {
        AppLogger.info(
          'Finarkein GET aa/data/result null response, opening circuit',
          tag: 'FinarkeinConsentsService',
        );
        _openDataResultCircuit();
        return null;
      }
      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        body = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        body = null;
      }
      if (!_isSuccessStatusCode(response.statusCode)) {
        AppLogger.info(
          'Finarkein GET aa/data/result non-2xx statusCode=${response.statusCode} body=${response.body}',
          tag: 'FinarkeinConsentsService',
        );
        if (_shouldOpenCircuitForStatus(response.statusCode)) {
          _openDataResultCircuit();
        }
        return null;
      }
      if (_bodyIndicatesError(body)) {
        AppLogger.info(
          'Finarkein GET aa/data/result body indicates error (id=$id), not opening circuit so other handles can proceed. body=${response.body}',
          tag: 'FinarkeinConsentsService',
        );
        return null;
      }
      AppLogger.info(
        'Finarkein GET aa/data/result success statusCode=${response.statusCode}',
        tag: 'FinarkeinConsentsService',
      );
      return body;
    } catch (e, st) {
      AppLogger.error(
        'Finarkein getDataResult error',
        error: e,
        stackTrace: st,
        tag: 'FinarkeinConsentsService',
      );
      _openDataResultCircuit();
      return null;
    }
  }

  /// Fetches consents and returns the derived adhoc remaining for UI.
  Future<double> fetchAdhocRemaining({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final list = await getConsents();
      return getAdhocRemainingFromConsents(list);
    } finally {
      onLoading(false);
    }
  }

  /// Returns true if consent/status response indicates a terminal journeyStatus (completed or failed).
  static bool _isConsentStatusTerminal(String? journeyStatus) {
    if (journeyStatus == null || journeyStatus.isEmpty) return false;
    final s = journeyStatus.toUpperCase();
    return s == 'COMPLETED' ||
        s == 'SUCCESS' ||
        s == 'ACTIVE' ||
        s == 'FAILED' ||
        s == 'ABANDONED';
  }

  /// After POST data/fetch, polls GET aa/consent/status(requestId) until journeyStatus is terminal (COMPLETED/SUCCESS/ACTIVE/FAILED/ABANDONED).
  /// Only after this is done should we call data/result.
  Future<void> _pollConsentStatusUntilTerminal(String requestId) async {
    final deadline = DateTime.now().add(_consentStatusPollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      AppLogger.info(
        'Finarkein GET aa/consent/status requestId=$requestId',
        tag: 'FinarkeinConsentsService',
      );
      final response = await _api.get(ApiURLs.AA_CONSENT_STATUS(requestId));
      if (response == null || response.statusCode != 200) {
        AppLogger.info(
          'Finarkein GET aa/consent/status non-200 statusCode=${response?.statusCode}',
          tag: 'FinarkeinConsentsService',
        );
        if (response?.statusCode == 401) {
          AppLogger.error(
            'Finarkein consent/status unauthorized (401), stopping poll',
            tag: 'FinarkeinConsentsService',
          );
          return;
        }
        await Future.delayed(_consentStatusPollInterval);
        continue;
      }
      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        await Future.delayed(_consentStatusPollInterval);
        continue;
      }
      final rawStatus =
          data?['journeyStatus'] ?? data?['journey_status'] ?? data?['status'];
      final journeyStatus = rawStatus?.toString().trim();
      if (_isConsentStatusTerminal(journeyStatus)) {
        AppLogger.info(
          'Finarkein consent/status terminal: $journeyStatus',
          tag: 'FinarkeinConsentsService',
        );
        return;
      }
      AppLogger.info(
        'Finarkein consent/status IN_PROGRESS, polling again in ${_consentStatusPollInterval.inSeconds}s',
        tag: 'FinarkeinConsentsService',
      );
      await Future.delayed(_consentStatusPollInterval);
    }
  }

  /// Triggers manual refresh: 1) POST aa/data/fetch 2) Poll GET aa/consent/status until done 3) GET aa/data/result once 4) Refresh aa/consents once.
  /// Returns new adhoc remaining after fetch, or null on failure.
  Future<double?> triggerDataFetch({
    required String consentHandle,
    required String requestId,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      AppLogger.info(
        'Finarkein POST aa/data/fetch request consentHandle=$consentHandle',
        tag: 'FinarkeinConsentsService',
      );
      final body = jsonEncode({'consentHandle': consentHandle});
      final response = await _api.post(ApiURLs.AA_DATA_FETCH, body);

      if (response == null) {
        throw Exception('Network error: No response from server');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        AppLogger.info(
          'Finarkein POST aa/data/fetch failed: ${response.body}',
          tag: 'FinarkeinConsentsService',
        );
        // Try to parse error message from body
        String errorMsg = 'Data fetch failed';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('message')) {
            errorMsg = decoded['message'];
          }
        } catch (_) {}

        throw Exception(errorMsg);
      }

      AppLogger.info(
        'Finarkein POST aa/data/fetch success, polling consent/status until terminal',
        tag: 'FinarkeinConsentsService',
      );
      await _pollConsentStatusUntilTerminal(requestId);
      AppLogger.info(
        'Finarkein consent/status done, invoking data/result once',
        tag: 'FinarkeinConsentsService',
      );
      await getDataResult(consentHandle);
      final list = await getConsents(forceRefresh: true);
      return getAdhocRemainingFromConsents(list);
    } catch (e, st) {
      AppLogger.error(
        'Finarkein triggerDataFetch error',
        error: e,
        stackTrace: st,
        tag: 'FinarkeinConsentsService',
      );
      // Re-throw so UI can handle it (revert optimistic update and show error)
      rethrow;
    } finally {
      onLoading(false);
    }
  }

  /// Result of POST aa/consent/revoke. UI uses [requestId] for polling and [redirectUrl] for WebView when non-empty.
  static RevokeResult parseRevokeResponse(http.Response? response) {
    if (response == null ||
        (response.statusCode != 200 && response.statusCode != 201)) {
      return RevokeResult.failure();
    }
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) return RevokeResult.failure();
      final requestId = map['requestId'] as String?;
      if (requestId == null || requestId.toString().trim().isEmpty) {
        return RevokeResult.failure();
      }
      final redirectUrl = map['redirectUrl'] as String?;
      return RevokeResult(
        requestId: requestId.trim(),
        redirectUrl:
            redirectUrl != null && redirectUrl.toString().trim().isNotEmpty
                ? redirectUrl.toString().trim()
                : null,
      );
    } catch (_) {
      return RevokeResult.failure();
    }
  }

  /// Calls POST aa/consent/revoke with [consentHandles] and [mobileNumber]. Returns [RevokeResult] with requestId and optional redirectUrl.
  Future<RevokeResult> revokeConsent(
    List<String> consentHandles,
    String mobileNumber,
  ) async {
    if (consentHandles.isEmpty) return RevokeResult.failure();
    try {
      final body = jsonEncode({
        'consentHandles': consentHandles,
        'mobileNumber': mobileNumber,
      });
      final response = await _api.post(ApiURLs.AA_CONSENT_REVOKE, body);
      return parseRevokeResponse(response);
    } catch (e, st) {
      AppLogger.error(
        'Finarkein revokeConsent error',
        error: e,
        stackTrace: st,
        tag: 'FinarkeinConsentsService',
      );
      return RevokeResult.failure();
    }
  }

  /// Result of a single GET aa/consent/revoke/status/:requestId call.
  static RevokeStatusResult parseRevokeStatusResponse(http.Response? response) {
    if (response == null) return RevokeStatusResult.error();
    if (response.statusCode != 200) return RevokeStatusResult.error();
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) return RevokeStatusResult.error();
      final data = map['data'] as Map<String, dynamic>?;
      if (data == null) return RevokeStatusResult.error();
      final journeyStatus =
          (data['journeyStatus'] as String?)?.toString().trim().toUpperCase();
      final revokedConsentHandles = data['revokedConsentHandles'];
      final terminal = journeyStatus == 'SUCCESS' || journeyStatus == 'FAILED';
      final success = journeyStatus == 'SUCCESS';
      return RevokeStatusResult(
        terminal: terminal,
        success: success,
        journeyStatus: journeyStatus,
        revokedConsentHandles:
            revokedConsentHandles is List
                ? List<String>.from(
                  revokedConsentHandles.map((e) => e.toString()),
                )
                : null,
      );
    } catch (_) {
      return RevokeStatusResult.error();
    }
  }

  /// Single GET aa/consent/revoke/status/:requestId. Use with polling until [RevokeStatusResult.terminal] is true.
  Future<RevokeStatusResult> checkConsentRevokeStatus(String requestId) async {
    if (requestId.trim().isEmpty) return RevokeStatusResult.error();
    try {
      final url = ApiURLs.AA_CONSENT_REVOKE_STATUS(requestId.trim());
      final response = await _api.get(url);
      return parseRevokeStatusResponse(response);
    } catch (e, st) {
      AppLogger.error(
        'Finarkein checkConsentRevokeStatus error',
        error: e,
        stackTrace: st,
        tag: 'FinarkeinConsentsService',
      );
      return RevokeStatusResult.error();
    }
  }

  /// Poll [checkConsentRevokeStatus] until terminal (SUCCESS/FAILED) or [_revokeStatusPollTimeout]. Returns last result.
  Future<RevokeStatusResult> pollRevokeStatusUntilTerminal(
    String requestId,
  ) async {
    final deadline = DateTime.now().add(_revokeStatusPollTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await checkConsentRevokeStatus(requestId);
      if (result.terminal) return result;
      await Future<void>.delayed(_revokeStatusPollInterval);
    }
    return RevokeStatusResult.error(); // timeout
  }
}

/// Response shape from GET aa/consents when backend returns consents + pending operation ids.
class ConsentsWithPendingState {
  const ConsentsWithPendingState({
    required this.consents,
    this.consentedFiTypes,
    this.pendingConsentRequestId,
    this.pendingRevokeRequestId,
    this.networkOk = false,
    this.httpStatusCode,
  });
  final List<AaConsent> consents;

  /// FI types user has consented to (e.g. deposit, mf, equities). Used for per-asset islinked.
  final List<String>? consentedFiTypes;
  final String? pendingConsentRequestId;
  final String? pendingRevokeRequestId;

  /// True only when the most recent `getConsentsWithPendingState()` call successfully fetched from the network (HTTP 200).
  /// When false, [consents] may be served from cache and should not be used to flip "linked/unlinked" UI.
  final bool networkOk;
  final int? httpStatusCode;
}

/// Result of POST aa/consent/revoke: requestId and optional redirectUrl for WebView.
class RevokeResult {
  const RevokeResult({required this.requestId, this.redirectUrl});
  final String requestId;
  final String? redirectUrl;
  bool get isSuccess => requestId.isNotEmpty;
  static RevokeResult failure() => const RevokeResult(requestId: '');
}

/// Result of GET aa/consent/revoke/status/:requestId.
class RevokeStatusResult {
  const RevokeStatusResult({
    required this.terminal,
    required this.success,
    this.journeyStatus,
    this.revokedConsentHandles,
  });
  final bool terminal;
  final bool success;
  final String? journeyStatus;
  final List<String>? revokedConsentHandles;
  static RevokeStatusResult error() =>
      const RevokeStatusResult(terminal: false, success: false);
}
