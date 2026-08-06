import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

enum AppOpenRefreshState {
  none,
  noConsent,
  alreadyFresh,
  started,
  inProgress,
  skippedQuota,
  failedRecently,
  completed,
  completedWithPartialFailures,
  failed,
}

class FinarkeinAppOpenRefreshController extends GetxController {
  static FinarkeinAppOpenRefreshController get to =>
      Get.find<FinarkeinAppOpenRefreshController>();

  final _api = NetworkAPIHelper();
  static const String _tag = 'AppOpenRefresh';

  final Rx<AppOpenRefreshState> currentState = AppOpenRefreshState.none.obs;
  final RxString operationId = ''.obs;
  final RxString statusUrl = ''.obs;
  final RxInt pollAfterSeconds = 2.obs;
  final RxBool hasCachedData = false.obs;
  final Rx<DateTime?> lastSuccessfulRefreshAt = Rx<DateTime?>(null);
  final RxList<dynamic> items = <dynamic>[].obs;

  VoidCallback? onRefreshComplete;

  String? getMessage() {
    switch (currentState.value) {
      case AppOpenRefreshState.skippedQuota:
        return 'Auto refresh skipped to preserve manual refresh quota';
      case AppOpenRefreshState.failedRecently:
        return 'Refresh failed recently. We will try again later.';
      case AppOpenRefreshState.completedWithPartialFailures:
        return 'Some institutions could not be refreshed';
      case AppOpenRefreshState.failed:
        return 'Refresh failed. Please try again later.';
      default:
        return null;
    }
  }

  bool _isPolling = false;
  bool _hasInitiated = false;

  /// Resets the initiation flag so the app-open refresh can be triggered again.
  void reset() {
    _hasInitiated = false;
  }

  /// Initiates the app-open refresh flow.
  Future<void> initiateAppOpenRefresh({bool force = false}) async {
    if (_hasInitiated && !force) {
      AppLogger.info(
        'App-open refresh already initiated this session, skipping.',
        tag: _tag,
      );
      return;
    }
    _hasInitiated = true;

    try {
      AppLogger.info('Initiating AA app-open refresh...', tag: _tag);
      final response = await _api.post(
        ApiURLs.AA_DATA_REFRESH_ON_OPEN,
        jsonEncode({}),
      );

      if (response == null ||
          (response.statusCode != 200 &&
              response.statusCode != 201 &&
              response.statusCode != 202)) {
        AppLogger.error(
          'Failed to initiate app-open refresh: ${response?.statusCode}',
          tag: _tag,
        );
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _updateFromResponse(body);

      if (currentState.value == AppOpenRefreshState.started ||
          currentState.value == AppOpenRefreshState.inProgress) {
        _startPolling();
      } else {
        // Any other state is terminal (alreadyFresh, skippedQuota, failedRecently, noConsent,
        // completed, completedWithPartialFailures, failed). Trigger the completion callback.
        onRefreshComplete?.call();
      }
    } catch (e, st) {
      AppLogger.error(
        'Error initiating app-open refresh',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _updateFromResponse(Map<String, dynamic> body) {
    final stateStr = body['state'] as String?;
    currentState.value = _mapState(stateStr);
    operationId.value = body['operationId']?.toString() ?? '';
    statusUrl.value = body['statusUrl']?.toString() ?? '';
    pollAfterSeconds.value = body['pollAfterSeconds'] as int? ?? 2;
    hasCachedData.value = body['hasCachedData'] as bool? ?? false;

    if (body['lastSuccessfulRefreshAt'] != null) {
      lastSuccessfulRefreshAt.value = DateTime.tryParse(
        body['lastSuccessfulRefreshAt'].toString(),
      );
    }

    if (body['items'] is List) {
      items.assignAll(body['items'] as List);
    }

    AppLogger.info('App-open refresh state: ${currentState.value}', tag: _tag);
  }

  AppOpenRefreshState _mapState(String? state) {
    switch (state?.toLowerCase()) {
      case 'no_consent':
        return AppOpenRefreshState.noConsent;
      case 'already_fresh':
        return AppOpenRefreshState.alreadyFresh;
      case 'started':
        return AppOpenRefreshState.started;
      case 'in_progress':
        return AppOpenRefreshState.inProgress;
      case 'skipped_quota':
        return AppOpenRefreshState.skippedQuota;
      case 'failed_recently':
        return AppOpenRefreshState.failedRecently;
      case 'completed':
        return AppOpenRefreshState.completed;
      case 'completed_with_partial_failures':
        return AppOpenRefreshState.completedWithPartialFailures;
      case 'failed':
        return AppOpenRefreshState.failed;
      default:
        return AppOpenRefreshState.none;
    }
  }

  Future<void> _startPolling() async {
    if (_isPolling) return;
    _isPolling = true;

    while (_isPolling) {
      await Future.delayed(Duration(seconds: pollAfterSeconds.value));

      try {
        final url = "https://testing.pivotmoney.app${statusUrl.value}";

        AppLogger.info('Polling AA app-open refresh status: $url', tag: _tag);
        final response = await _api.get(url);

        if (response == null ||
            (response.statusCode != 200 &&
                response.statusCode != 201 &&
                response.statusCode != 202)) {
          AppLogger.error('Polling failed: ${response?.statusCode}', tag: _tag);
          _isPolling = false;
          break;
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _updateFromResponse(body);

        if (currentState.value == AppOpenRefreshState.completed ||
            currentState.value ==
                AppOpenRefreshState.completedWithPartialFailures ||
            currentState.value == AppOpenRefreshState.failed) {
          AppLogger.info(
            'Polling finished with state: ${currentState.value}',
            tag: _tag,
          );
          _isPolling = false;
          onRefreshComplete?.call();
          break;
        }
      } catch (e, st) {
        AppLogger.error(
          'Error during polling',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
        _isPolling = false;
        break;
      }
    }
  }

  @override
  void onClose() {
    _isPolling = false;
    super.onClose();
  }
}
