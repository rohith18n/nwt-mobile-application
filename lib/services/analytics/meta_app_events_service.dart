import 'dart:io';

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for Meta (Facebook) App Events
/// Used for tracking app installs and optimizing Meta ad campaigns
class MetaAppEventsService {
  static final MetaAppEventsService _instance = MetaAppEventsService._internal();
  factory MetaAppEventsService() => _instance;
  MetaAppEventsService._internal();

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();
  bool _isInitialized = false;

  /// Initialize Meta App Events
  /// Call this in main.dart before app launch
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get Remote Config values for logging (verification only)
      final remoteConfig = RemoteConfigService.to;
      final appId = remoteConfig.metaAppId.value;

      AppLogger.info(
        'Meta SDK initializing - AppId: $appId',
        tag: 'MetaAppEvents',
      );

      // Request iOS 14.5+ ATT permission for tracking
      await _requestTrackingPermission();

      // Log app activation event - REQUIRED for Meta ad optimization
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_activate_app',
        parameters: {
          'app_version': '1.7.5',
        },
      );

      AppLogger.info(
        'Meta SDK connected successfully - fb_mobile_activate_app event logged',
        tag: 'MetaAppEvents',
      );

      _isInitialized = true;
    } catch (e) {
      AppLogger.error(
        'Meta SDK initialization failed: $e',
        tag: 'MetaAppEvents',
      );
    }
  }

  /// Request iOS App Tracking Transparency permission (iOS 14.5+)
  /// This is REQUIRED for Meta to track users on iOS 14.5+
  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS) return;

    try {
      final status = await Permission.appTrackingTransparency.status;
      AppLogger.info(
        'ATT permission status: $status',
        tag: 'MetaAppEvents',
      );

      if (status.isDenied || status.isRestricted) {
        final result = await Permission.appTrackingTransparency.request();
        AppLogger.info(
          'ATT permission requested, result: $result',
          tag: 'MetaAppEvents',
        );

        // Log the permission result to Meta for analysis
        await _facebookAppEvents.logEvent(
          name: 'att_permission_result',
          parameters: {
            'granted': result.isGranted,
            'status': result.toString(),
          },
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error requesting ATT permission: $e',
        tag: 'MetaAppEvents',
      );
    }
  }

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _facebookAppEvents.logEvent(
        name: name,
        parameters: parameters,
        valueToSum: valueToSum,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[MetaAppEvents] Error logging event $name: $e');
      }
    }
  }

  /// Log completed registration
  Future<void> logCompletedRegistration({String? registrationMethod}) async {
    await logEvent(
      name: 'fb_mobile_complete_registration',
      parameters: {
        if (registrationMethod != null) 'fb_registration_method': registrationMethod,
      },
    );
  }

  /// Log purchase
  Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[MetaAppEvents] Error logging purchase: $e');
      }
    }
  }

  /// Set user data for better ad targeting
  Future<void> setUserData({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      await _facebookAppEvents.setUserData(
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[MetaAppEvents] Error setting user data: $e');
      }
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    try {
      await _facebookAppEvents.clearUserData();
    } catch (e) {
      if (kDebugMode) {
        print('[MetaAppEvents] Error clearing user data: $e');
      }
    }
  }
}
