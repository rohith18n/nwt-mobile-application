import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/profile/verify_pin.dart';
import 'package:nwt_app/services/mpin_service.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';

class AppLifecycleManager extends GetxService with WidgetsBindingObserver {
  static AppLifecycleManager get to => Get.find<AppLifecycleManager>();

  final _isAppInBackground = false.obs;
  final _shouldLockOnResume = false.obs;
  final _isShowingPinDialog = false.obs;

  // Grace period for app lock (90 seconds)
  static const Duration _lockGracePeriod = Duration(seconds: 90);
  DateTime? _pausedAt;

  Future<AppLifecycleManager> init() async {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.info(
      'AppLifecycleManager initialized',
      tag: 'AppLifecycleManager',
    );
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.info(
      'App lifecycle state changed to: $state',
      tag: 'AppLifecycleManager',
    );

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning (e.g., during app switching)
        _handleAppInactive();
        break;
      case AppLifecycleState.paused:
        // App is in background
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        // App is detached from engine
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        _handleAppHidden();
        break;
    }
  }

  Future<void> _handleAppResumed() async {
    AppLogger.info('App resumed from background', tag: 'AppLifecycleManager');

    if (_shouldLockOnResume.value && !_isShowingPinDialog.value) {
      final now = DateTime.now();
      if (_pausedAt != null) {
        final timeInBackground = now.difference(_pausedAt!);
        AppLogger.info(
          'App was in background for ${timeInBackground.inSeconds} seconds',
          tag: 'AppLifecycleManager',
        );

        if (timeInBackground > _lockGracePeriod) {
          await _showPINVerificationIfNeeded();
        } else {
          AppLogger.info(
            'Within grace period, skipping PIN verification',
            tag: 'AppLifecycleManager',
          );
        }
      } else {
        // Fallback if _pausedAt was somehow not set
        await _showPINVerificationIfNeeded();
      }
      _shouldLockOnResume.value = false;
      _pausedAt = null;
    }

    _isAppInBackground.value = false;
  }

  void _handleAppInactive() {
    AppLogger.info('App became inactive', tag: 'AppLifecycleManager');
  }

  Future<void> _handleAppPaused() async {
    AppLogger.info(
      'App paused (sent to background)',
      tag: 'AppLifecycleManager',
    );
    _isAppInBackground.value = true;

    // Check if PIN is set and user is authenticated
    final hasPinSet = await MPINService.to.hasPIN();
    final hasToken =
        await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY) != null;

    if (hasPinSet && hasToken) {
      _shouldLockOnResume.value = true;
      _pausedAt = DateTime.now();
      AppLogger.info(
        'App will require PIN verification on resume if grace period (90s) is exceeded',
        tag: 'AppLifecycleManager',
      );
    }
  }

  void _handleAppDetached() {
    AppLogger.info('App detached', tag: 'AppLifecycleManager');
  }

  void _handleAppHidden() {
    AppLogger.info('App hidden', tag: 'AppLifecycleManager');
  }

  Future<void> _showPINVerificationIfNeeded() async {
    try {
      // Prevent multiple dialogs
      if (_isShowingPinDialog.value) {
        AppLogger.info(
          'PIN dialog already showing, skipping',
          tag: 'AppLifecycleManager',
        );
        return;
      }

      final hasPinSet = await MPINService.to.hasPIN();
      final hasToken =
          await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY) != null;

      if (!hasPinSet || !hasToken) {
        AppLogger.info(
          'No PIN or token, skipping verification',
          tag: 'AppLifecycleManager',
        );
        return;
      }

      _isShowingPinDialog.value = true;

      AppLogger.info(
        'Showing PIN verification after app resume',
        tag: 'AppLifecycleManager',
      );

      // Show PIN verification dialog
      final result = await Get.dialog<bool>(
        const VerifyPin(),
        barrierDismissible: false,
      );

      if (result == true) {
        AppLogger.info(
          'PIN verification successful',
          tag: 'AppLifecycleManager',
        );
      } else {
        // If verification failed, show again
        AppLogger.info(
          'PIN verification failed, showing again',
          tag: 'AppLifecycleManager',
        );
        _isShowingPinDialog.value = false;
        await _showPINVerificationIfNeeded();
        return;
      }
    } catch (e) {
      AppLogger.error(
        'Error showing PIN verification',
        error: e,
        tag: 'AppLifecycleManager',
      );
    } finally {
      _isShowingPinDialog.value = false;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
