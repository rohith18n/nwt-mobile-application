import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_app_open_refresh_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/connections/finarkein_journey_webview.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_refresh_controller.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/saafe_approve.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/dashboard/dashboard_bootstrap.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';

// --- Consent status poll result (single-check outcome) ---
sealed class _ConsentPollResult {}

class _ConsentNeedMore extends _ConsentPollResult {
  final int consecutiveErrors;
  _ConsentNeedMore(this.consecutiveErrors);
}

class _ConsentSuccess extends _ConsentPollResult {
  final Map<String, dynamic> data;
  _ConsentSuccess(this.data);
}

class _ConsentFailed extends _ConsentPollResult {
  final String message;
  _ConsentFailed(this.message);
}

class _ConsentAbandoned extends _ConsentPollResult {}

class _ConsentMaxErrors extends _ConsentPollResult {}

// --- Data result poll result (single-check outcome) ---
sealed class _DataResultPollResult {}

class _DataResultNeedMore extends _DataResultPollResult {}

class _DataResultSuccess extends _DataResultPollResult {
  final Map<String, dynamic> body;
  _DataResultSuccess(this.body);
}

/// Any error (non-2xx, null response, or body with error object); caller should stop (no retries).
class _DataResultError extends _DataResultPollResult {
  final int statusCode;
  _DataResultError(this.statusCode);
}

/// Finarkein AA flow: initiate consent -> open journey in WebView -> on close poll consent status -> on success call data result -> navigate to Approved/error.
class FinarkeinIntegrationService {
  static final FinarkeinIntegrationService _instance =
      FinarkeinIntegrationService._internal();
  factory FinarkeinIntegrationService() => _instance;
  FinarkeinIntegrationService._internal();

  static const String _tag = 'FinarkeinIntegrationService';
  final UserController _userController = Get.find<UserController>();
  final NetworkAPIHelper _api = NetworkAPIHelper();

  static const Duration _pollInterval = Duration(seconds: 4);

  /// Poll interval when journey is PENDING (no webview); user requested 5 seconds.
  static const Duration _pendingFlowPollInterval = Duration(seconds: 5);
  static const Duration _pollTimeout = Duration(minutes: 2);
  static const Duration _dataResultPollInterval = Duration(seconds: 4);
  static const Duration _dataResultPollTimeout = Duration(minutes: 2);
  static const int _maxConsecutiveErrors = 3;

  /// Pending requestId after initiating consent; cleared after status check or on error.
  static String? pendingRequestId;

  /// True while consent status is being polled after WebView close. Use to block duplicate "Link Now".
  static bool get isConsentStatusInProgress => pendingRequestId != null;

  /// App callback URL for Finarkein to redirect after consent. Backend must accept this.
  static const String redirectUrl =
      'https://dev.fnrk.in/o/networthtracker/thank-you';

  /// Initiates Finarkein consent, opens the journey URL in an in-app WebView. On WebView close, polls consent status then navigates.
  /// For email-signup users without a primary phone, [phoneNumber] must be provided (e.g. from phone screen shown after PAN success).
  /// After consent/initiate API returns success, primary phone is updated via PATCH userdetail/phone for email-only users.
  Future<void> initiateAndOpenRedirect({
    required BuildContext context,
    String? phoneNumber,
    bool hideBackButton = false,
  }) async {
    final user = _userController.userData;
    final phone =
        (phoneNumber ?? user?.phonenumber ?? user?.secondaryphonenumber ?? '')
            .trim();
    if (phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is required')),
        );
      }
      return;
    }

    final isEmailUserWithoutPhone =
        user != null &&
        (user.email ?? '').trim().isNotEmpty &&
        (user.phonenumber == null || (user.phonenumber ?? '').trim().isEmpty);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final body = <String, dynamic>{
        'mobileNumber': phone,
        'redirectUrl': redirectUrl,
        'provider': 'FINARKEIN',
      };
      if (user?.pannumber != null && (user!.pannumber ?? '').isNotEmpty) {
        body['pan'] = user.pannumber;
      }
      if (user?.email != null && (user!.email ?? '').isNotEmpty) {
        body['emailId'] = user.email;
      }

      AppLogger.info('Finarkein POST aa/consent/initiate request', tag: _tag);
      final response = await _api.post(
        ApiURLs.AA_CONSENT_INITIATE,
        jsonEncode(body),
        //{},
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      if (response == null || response.statusCode != 200) {
        AppLogger.error(
          'Finarkein initiate consent failed: ${response?.body}',
          tag: _tag,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start consent')),
        );
        return;
      }

      if (isEmailUserWithoutPhone) {
        final updated = await AuthService().updatePhone(phonenumber: phone);
        if (updated) {
          AppLogger.info(
            'Finarkein: updated primary phone for email user after consent/initiate success',
            tag: _tag,
          );
          await _userController.fetchUserProfile(onLoading: (_) {});
        } else {
          AppLogger.warning(
            'Finarkein: updatePhone failed after consent/initiate success (non-blocking)',
            tag: _tag,
          );
        }
        if (!context.mounted) return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      final requestId = data?['requestId'] as String?;
      final journeyUrl = data?['redirectUrl'] as String?;
      final rawJourneyStatus =
          data?['journeyStatus'] ?? data?['journey_status'] ?? data?['status'];
      final journeyStatus = rawJourneyStatus?.toString().toUpperCase();
      AppLogger.info(
        'Finarkein POST aa/consent/initiate success requestId=$requestId redirectUrl=${journeyUrl != null && journeyUrl.isNotEmpty ? "present" : "null"} journeyStatus=$journeyStatus',
        tag: _tag,
      );

      if (requestId == null || requestId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid response from server')),
        );
        return;
      }

      pendingRequestId = requestId;

      final bool isPendingNoWebView =
          (journeyUrl == null || journeyUrl.trim().isEmpty);

      if (isPendingNoWebView) {
        if (!context.mounted) return;
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
        return;
      }
      // At this point we have a valid journeyUrl (not PENDING flow)
      final url = journeyUrl.trim();
      if (url.isNotEmpty) {
        final completedWithRedirect = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder:
                (_) => FinarkeinJourneyWebView(
                  journeyUrl: url,
                  redirectUrlToDetect: redirectUrl,
                  hideBackButton: hideBackButton,
                  onRedirectDetected: () {
                    AppLogger.info(
                      'FinarkeinJourneyWebView - Redirect URL detected, auto-closing',
                      tag: _tag,
                    );
                  },
                ),
          ),
        );
        if (!context.mounted) return;
        if (completedWithRedirect != true) {
          pendingRequestId = null;
          AppLogger.info(
            'Finarkein journey closed by user (cancelled), not polling',
            tag: _tag,
          );
          return;
        }
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      }
    } catch (e, st) {
      AppLogger.error(
        'Finarkein initiate error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Called after the consent journey WebView closes. Polling GET aa/consent/status
  /// here allows the backend to move the consent from PENDING to ACTIVE (and set
  /// consentHandle) so revoke/delink can find and delete that same row.
  /// Runs in background with no blocking dialog; shows a snackbar so user can continue using the app.
  Future<void> _onJourneyWebViewClosed(
    BuildContext context,
    String requestId,
  ) async {
    if (!context.mounted) return;

    SnackbarHelper.showPersistentInfo(
      title: 'Linking in progress',
      message: "We're verifying your consent. You can continue using the app.",
      position: SnackPosition.TOP,
    );

    final stopwatch = Stopwatch()..start();

    try {
      await _pollConsentStatusRecursive(context, requestId, stopwatch, 0);
    } catch (e, st) {
      AppLogger.error(
        'Finarkein consent status polling error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      pendingRequestId = null;
      SnackbarHelper.safeCloseAll();
      SnackbarHelper.showError(
        title: 'Error',
        message: 'Error checking status: $e',
        position: SnackPosition.TOP,
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// Performs a single consent status check (GET aa/consent/status). Used by recursive poller; no loop.
  /// This call is what allows the backend to transition the consent from PENDING to ACTIVE.
  Future<_ConsentPollResult> _performOneConsentStatusCheck(
    String requestId,
    int consecutiveErrors,
  ) async {
    AppLogger.info(
      'Finarkein GET aa/consent/status requestId=$requestId',
      tag: _tag,
    );
    final response = await _api.get(ApiURLs.AA_CONSENT_STATUS(requestId));

    if (response == null || response.statusCode != 200) {
      AppLogger.info(
        'Finarkein GET aa/consent/status non-200 statusCode=${response?.statusCode} body=${response?.body}',
        tag: _tag,
      );
      final next = consecutiveErrors + 1;
      if (next >= _maxConsecutiveErrors) {
        return _ConsentMaxErrors();
      }
      return _ConsentNeedMore(next);
    }

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      return _ConsentNeedMore(consecutiveErrors);
    }

    final rawStatus =
        data?['journeyStatus'] ?? data?['journey_status'] ?? data?['status'];
    final journeyStatus = rawStatus?.toString().toUpperCase();
    AppLogger.info(
      'Finarkein GET aa/consent/status response journeyStatus=$journeyStatus',
      tag: _tag,
    );

    final isCompleted =
        journeyStatus == 'COMPLETED' ||
        journeyStatus == 'SUCCESS' ||
        journeyStatus == 'ACTIVE';
    if (isCompleted) {
      return _ConsentSuccess(data ?? <String, dynamic>{});
    }

    if (journeyStatus == 'FAILED') {
      return _ConsentFailed('Consent was not approved.');
    }
    if (journeyStatus == 'ABANDONED') {
      return _ConsentAbandoned();
    }

    return _ConsentNeedMore(0);
  }

  /// Recursive consent status poller. Schedules next check after delay; no while loop. Stops on context unmount or terminal result.
  Future<void> _pollConsentStatusRecursive(
    BuildContext context,
    String requestId,
    Stopwatch stopwatch,
    int consecutiveErrors,
  ) async {
    if (!context.mounted) return;
    if (stopwatch.elapsed >= _pollTimeout) {
      pendingRequestId = null;
      SnackbarHelper.safeCloseAll();
      SnackbarHelper.showInfo(
        title: 'Please try again later',
        message: 'Consent is still pending. Please try again later.',
        position: SnackPosition.TOP,
      );
      return;
    }

    final result = await _performOneConsentStatusCheck(
      requestId,
      consecutiveErrors,
    );

    if (!context.mounted) return;

    switch (result) {
      case _ConsentSuccess(:final data):
        pendingRequestId = null;
        SnackbarHelper.safeCloseAll();

        List<String> consentHandles = _extractConsentHandles(data);
        if (consentHandles.isEmpty) {
          consentHandles = await _fetchConsentHandlesFallback(requestId);
        }
        final store =
            Get.isRegistered<FinarkeinDataStore>()
                ? Get.find<FinarkeinDataStore>()
                : null;
        bool firstHandle = true;
        for (final handle in consentHandles) {
          try {
            final body = await _pollDataResultUntilReady(handle);
            if (body != null && store != null) {
              final dataMap = body['data'];
              final hasData =
                  dataMap is Map<String, dynamic> && dataMap.isNotEmpty;
              if (hasData) {
                store.setFromDataResult(
                  body,
                  merge: !firstHandle,
                  preserveExistingOnEmpty:
                      firstHandle &&
                      (store.lastBanks.isNotEmpty ||
                          store.lastStocks.isNotEmpty ||
                          store.lastMf.isNotEmpty ||
                          store.lastEtf.isNotEmpty ||
                          store.lastInsurance.isNotEmpty ||
                          store.lastNpsRows.isNotEmpty ||
                          store.lastPersonalAssets.isNotEmpty),
                );

                // Update RawAssetController immediately to ensure Dashboard reflects fresh journey data
                if (Get.isRegistered<RawAssetController>()) {
                  Get.find<RawAssetController>().setFromDataResult(
                    body,
                    merge: !firstHandle,
                  );
                }

                // Update FinarkeinDataController for networth and spends
                if (Get.isRegistered<FinarkeinDataController>()) {
                  Get.find<FinarkeinDataController>().setFromDataResult(
                    body,
                    merge: !firstHandle,
                  );
                }

                firstHandle = false;
              }
            }
          } catch (_) {
            // Non-blocking: still proceed and navigate
          }
        }

        // Notify Dashboard specifically that a link happened so it can prefer this fresh data
        if (Get.isRegistered<DashboardRefreshController>()) {
          Get.find<DashboardRefreshController>().notifyAfterLink();
        }

        // Mark Finarkein onboarding flow as completed once consents are active.
        await AuthService().updateOnboardingProgress(
          flowType: OnboardingFlowType.trackMyInvestments.apiValue,
          status: 'completed',
        );
        // Publish latest aa/consents to Dashboard immediately after link success.
        if (Get.isRegistered<FinarkeinConsentBootstrap>()) {
          unawaited(
            FinarkeinConsentBootstrap.to.refreshFromNetwork(forceRefresh: true),
          );
        }

        // Force an app-open refresh immediately after linking is successful
        if (Get.isRegistered<FinarkeinAppOpenRefreshController>()) {
          Get.find<FinarkeinAppOpenRefreshController>()
              .initiateAppOpenRefresh(force: true);
        }

        if (context.mounted) {
          Get.to(
            () => const SaafeApprovedScreen(),
            transition: Transition.rightToLeft,
          );
        }
        return;

      case _ConsentFailed(:final message):
        pendingRequestId = null;
        SnackbarHelper.safeCloseAll();
        SnackbarHelper.showError(
          title: 'Linking failed',
          message: message,
          position: SnackPosition.TOP,
        );
        return;

      case _ConsentAbandoned():
        pendingRequestId = null;
        SnackbarHelper.safeCloseAll();
        SnackbarHelper.showInfo(
          title: 'Consent abandoned',
          message: 'Consent was abandoned or timed out.',
          position: SnackPosition.TOP,
        );
        return;

      case _ConsentMaxErrors():
        pendingRequestId = null;
        SnackbarHelper.safeCloseAll();
        SnackbarHelper.showError(
          title: 'Error',
          message: 'Error checking consent status',
          position: SnackPosition.TOP,
        );
        return;

      case _ConsentNeedMore(:final consecutiveErrors):
        await Future.delayed(_pollInterval);
        if (!context.mounted) return;
        await _pollConsentStatusRecursive(
          context,
          requestId,
          stopwatch,
          consecutiveErrors,
        );
        return;
    }
  }

  /// Returns true if response body indicates an error (error object or status ERROR). Stops on any backend error instead of hardcoding 429.
  static bool _isDataResultErrorResponse(
    int statusCode,
    Map<String, dynamic>? body,
  ) {
    if (statusCode != 200 && statusCode != 201) return true;
    if (body == null) return false;
    if (body.containsKey('error')) return true;
    final status = (body['status'] as String?)?.toUpperCase();
    if (status == 'ERROR') return true;
    return false;
  }

  /// Performs a single GET aa/data/result check. Used by recursive poller; no loop.
  /// Returns _DataResultError on any error (null, non-2xx, or body with error object); caller stops immediately (no retries).
  Future<_DataResultPollResult> _performOneDataResultCheck(
    String handle,
  ) async {
    AppLogger.info(
      'Finarkein GET aa/data/result consentHandle=$handle',
      tag: _tag,
    );
    final response = await _api.get(ApiURLs.AA_DATA_RESULT(handle));
    AppLogger.info(
      'Finarkein GET aa/data/result response statusCode=${response?.statusCode}',
      tag: _tag,
    );

    if (response == null) {
      return _DataResultError(0);
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      return _DataResultError(response.statusCode);
    }
    if (response.body.isEmpty) {
      return _DataResultNeedMore();
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      return _DataResultNeedMore();
    }
    if (body == null) return _DataResultNeedMore();

    if (_isDataResultErrorResponse(response.statusCode, body)) {
      return _DataResultError(response.statusCode);
    }
    final status = (body['status'] as String?)?.toUpperCase();
    if (status == 'SUCCESS' || status == 'FAILED') {
      return _DataResultSuccess(body);
    }
    return _DataResultNeedMore();
  }

  /// Polls GET aa/data/result for [handle] until status is SUCCESS or FAILED, or timeout.
  /// Uses recursive scheduling (no while loop). Returns final response body or null.
  Future<Map<String, dynamic>?> _pollDataResultUntilReady(String handle) async {
    final stopwatch = Stopwatch()..start();
    return _pollDataResultRecursive(handle, stopwatch);
  }

  /// Recursive data result poller. Schedules next check after delay; no while loop.
  /// On any error (non-2xx or error object in body): stop immediately and return null (do not retry).
  Future<Map<String, dynamic>?> _pollDataResultRecursive(
    String handle,
    Stopwatch stopwatch,
  ) async {
    if (stopwatch.elapsed >= _dataResultPollTimeout) {
      AppLogger.info(
        'Finarkein GET aa/data/result timeout for handle=$handle',
        tag: _tag,
      );
      return null;
    }

    final result = await _performOneDataResultCheck(handle);

    switch (result) {
      case _DataResultSuccess(:final body):
        return body;
      case _DataResultError(:final statusCode):
        AppLogger.info(
          'Finarkein GET aa/data/result error statusCode=$statusCode, stopping poll (no retries)',
          tag: _tag,
        );
        return null;
      case _DataResultNeedMore():
        await Future.delayed(_dataResultPollInterval);
        return _pollDataResultRecursive(handle, stopwatch);
    }
  }

  /// When status API does not return consent handles, fetch from GET aa/consents and return handles for consents matching [requestId], or first active consent.
  Future<List<String>> _fetchConsentHandlesFallback(String requestId) async {
    try {
      final response = await _api.get(ApiURLs.AA_CONSENTS);
      if (response == null || response.statusCode != 200) return [];
      final body = jsonDecode(response.body);
      final List<dynamic> list;
      if (body is Map<String, dynamic> && body['consents'] is List) {
        list = body['consents'] as List;
      } else if (body is List) {
        list = body;
      } else {
        return [];
      }
      final handles = <String>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final handle =
            (e['consentHandle'] ?? e['consent_handle'])?.toString().trim();
        if (handle == null || handle.isEmpty) continue;
        final rid = (e['requestId'] ?? e['request_id'])?.toString();
        if (rid == requestId) handles.add(handle);
      }
      if (handles.isNotEmpty) return handles;
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final handle =
            (e['consentHandle'] ?? e['consent_handle'])?.toString().trim();
        if (handle != null && handle.isNotEmpty) return [handle];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Extracts consent handles from consent status response.
  /// Supports: state[] (each item has consentHandle), consentHandles (array), or consentHandle (single).
  static List<String> _extractConsentHandles(Map<String, dynamic>? data) {
    if (data == null) return [];
    // Primary: state array with consentHandle per item (actual status API response shape)
    final state = data['state'];
    if (state is List) {
      final fromState = <String>[];
      for (final item in state) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final handle =
            (map['consentHandle'] ?? map['consent_handle'])?.toString().trim();
        if (handle != null && handle.isNotEmpty) fromState.add(handle);
      }
      if (fromState.isNotEmpty) return fromState;
    }
    // Fallback: consentHandles array
    final handles = data['consentHandles'] ?? data['consent_handles'];
    if (handles is List) {
      return handles
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    // Fallback: single consentHandle
    final single = data['consentHandle'] ?? data['consent_handle'];
    if (single != null) {
      final s = single.toString().trim();
      if (s.isNotEmpty) return [s];
    }
    return [];
  }

  /// Call when user returns to the app (e.g. deep link or app-resume path). Checks consent status and navigates.
  Future<void> checkConsentStatusAndNavigate(BuildContext context) async {
    final requestId = pendingRequestId;
    if (requestId == null || requestId.isEmpty) return;

    await _onJourneyWebViewClosed(context, requestId);
  }

  /// Runs consent status polling then data/result polling without BuildContext (for Dashboard backend-driven flow).
  /// Returns outcome so caller can refresh and show snackbar. Does not navigate.
  Future<ConsentPollOutcome> pollConsentStatusAndDataResultInBackground(
    String requestId,
  ) async {
    final stopwatch = Stopwatch()..start();
    return _pollConsentStatusInBackgroundRecursiveOutcome(
      requestId,
      stopwatch,
      0,
    );
  }

  Future<ConsentPollOutcome> _pollConsentStatusInBackgroundRecursiveOutcome(
    String requestId,
    Stopwatch stopwatch,
    int consecutiveErrors,
  ) async {
    if (stopwatch.elapsed >= _pollTimeout) {
      pendingRequestId = null;
      return ConsentPollOutcome.timeout;
    }

    final result = await _performOneConsentStatusCheck(
      requestId,
      consecutiveErrors,
    );

    switch (result) {
      case _ConsentSuccess(:final data):
        pendingRequestId = null;
        List<String> consentHandles = _extractConsentHandles(data);
        if (consentHandles.isEmpty) {
          consentHandles = await _fetchConsentHandlesFallback(requestId);
        }
        final store =
            Get.isRegistered<FinarkeinDataStore>()
                ? Get.find<FinarkeinDataStore>()
                : null;
        for (final handle in consentHandles) {
          try {
            final body = await _pollDataResultUntilReady(handle);
            if (body != null && store != null) {
              final dataMap = body['data'];
              final hasData =
                  dataMap is Map<String, dynamic> && dataMap.isNotEmpty;
              if (hasData) {
                store.setFromDataResult(body, merge: true);
                if (Get.isRegistered<RawAssetController>()) {
                  Get.find<RawAssetController>().setFromDataResult(
                    body,
                    merge: true,
                  );
                }
                if (Get.isRegistered<FinarkeinDataController>()) {
                  Get.find<FinarkeinDataController>().setFromDataResult(
                    body,
                    merge: true,
                  );
                }
                if (Get.isRegistered<DashboardRefreshController>()) {
                  Get.find<DashboardRefreshController>().notifyAfterLink();
                }
              }
            }
          } catch (_) {}
        }
        return ConsentPollOutcome.success;

      case _ConsentFailed(:final message):
        pendingRequestId = null;
        AppLogger.info('Finarkein consent poll failed: $message', tag: _tag);
        return ConsentPollOutcome.failed;

      case _ConsentAbandoned():
        pendingRequestId = null;
        return ConsentPollOutcome.abandoned;

      case _ConsentMaxErrors():
        pendingRequestId = null;
        return ConsentPollOutcome.maxErrors;

      case _ConsentNeedMore(:final consecutiveErrors):
        await Future.delayed(_pendingFlowPollInterval);
        return _pollConsentStatusInBackgroundRecursiveOutcome(
          requestId,
          stopwatch,
          consecutiveErrors,
        );
    }
  }
}

/// Outcome of consent status + data/result polling (context-free, for Dashboard).
enum ConsentPollOutcome { success, failed, abandoned, timeout, maxErrors }
