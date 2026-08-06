import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/odm_conversion_utils.dart';

/// A service to handle Firebase or CleverTap Analytics tracking throughout the app
class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find<AnalyticsService>();

  late final FirebaseAnalytics _analytics;
  FirebaseAnalytics get analytics => _analytics;

  late AppsflyerSdk _appsflyerSdk;
  AppsflyerSdk get appsflyerSdk => _appsflyerSdk;

  /// Initialize the analytics service
  Future<AnalyticsService> init() async {
    _analytics = FirebaseAnalytics.instance;
    await _analytics.setAnalyticsCollectionEnabled(true);

    // AppsFlyer Initialization
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: 'oQKzEyKhkEQKd7cKAVg7qA',
      appId:
          '6746093850', // Required for iOS only. For Android this is ignored.
      showDebug: true,
      timeToWaitForATTUserAuthorization: 50,
    );
    _appsflyerSdk = AppsflyerSdk(options);

    _appsflyerSdk
        .initSdk(
          registerConversionDataCallback: true,
          registerOnAppOpenAttributionCallback: true,
          registerOnDeepLinkingCallback: true,
        )
        .then((result) {
          AppLogger.info("AppsFlyer init result: $result", tag: 'Analytics');
        });

    // CleverTap is auto-initialized via native Android/iOS setup,
    // but enabling debug level here can act as a check or set up additional config if needed.
    CleverTapPlugin.setDebugLevel(3);
    
    // Log CleverTap ID for testing push notifications
    CleverTapPlugin.getCleverTapID().then((id) {
      AppLogger.info("CleverTap ID: $id", tag: 'Analytics');
    });

    // Create the notification channel for CleverTap to match Firebase config
    await CleverTapPlugin.createNotificationChannel(
      "high_importance_channel",
      "High Importance Notifications",
      "High Importance Notifications for user updates",
      5, // Importance.max
      true, // Show badge
    );
    return this;
  }

  /// Log a custom event to CleverTap only
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    print('=== CLEVERTAP EVENT ===');
    print('Event name: $name');
    print('Parameters: $parameters');
    print('=====================');
    
    AppLogger.debug('CleverTap: Recording event: $name with params: $parameters', tag: 'CleverTap');
    
    // CleverTap - expects Map<String, dynamic>
    try {
      if (parameters != null) {
        CleverTapPlugin.recordEvent(name, parameters);
        AppLogger.info('CleverTap: Event recorded successfully: $name', tag: 'CleverTap');
      } else {
        CleverTapPlugin.recordEvent(name, {});
        AppLogger.info('CleverTap: Event recorded successfully (no params): $name', tag: 'CleverTap');
      }
    } catch (e) {
      AppLogger.error('CleverTap: Error recording event $name: $e', tag: 'CleverTap');
    }
  }

  /// Log when a screen is viewed to CleverTap only
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    print('=== CLEVERTAP SCREEN VIEW ===');
    print('Screen name: $screenName');
    print('Screen class: $screenClass');
    print('===========================');
    
    AppLogger.debug('CleverTap: Recording screen view: $screenName', tag: 'CleverTap');
    
    // CleverTap
    try {
      CleverTapPlugin.recordScreenView(screenName);
      AppLogger.info('CleverTap: Screen view recorded successfully: $screenName', tag: 'CleverTap');
    } catch (e) {
      AppLogger.error('CleverTap: Error recording screen view $screenName: $e', tag: 'CleverTap');
    }
  }

  /// Log when a user logs in
  Future<void> logLogin({String? method}) async {
    // Firebase
    await _analytics.logLogin(loginMethod: method ?? 'phone');

    // CleverTap
    // onUserLogin is used to identify the user.
    // We typically pass Identity, Email, Phone etc. here.
    // For now we just log a "Login" event or if we have user details we should pass them.
    // As this method only takes 'method', we might just record an event or skip onUserLogin unless we have user attributes.
    // However, the user asked to merge flows. Let's record the event at least.
    try {
      CleverTapPlugin.recordEvent("Login", {'method': method ?? 'phone'});
    } catch (e) {
      AppLogger.error('Error logging login to CleverTap: $e', tag: 'Analytics');
    }

    // AppsFlyer
    try {
      _appsflyerSdk.logEvent("login", {'method': method ?? 'phone'});
    } catch (e) {
      AppLogger.error('Error logging login to AppsFlyer: $e', tag: 'Analytics');
    }
  }

  /// Log when a user signs up
  Future<void> logSignUp({String? method}) async {
    // Firebase
    await _analytics.logSignUp(signUpMethod: method ?? 'phone');

    // CleverTap
    try {
      CleverTapPlugin.recordEvent("SignUp", {'method': method ?? 'phone'});
    } catch (e) {
      AppLogger.error('Error logging sign up to CleverTap: $e', tag: 'Analytics');
    }

    // AppsFlyer
    try {
      _appsflyerSdk.logEvent("signup", {'method': method ?? 'phone'});
    } catch (e) {
      AppLogger.error('Error logging sign up to AppsFlyer: $e', tag: 'Analytics');
    }
  }

  /// Set a user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    // Firebase
    await _analytics.setUserProperty(name: name, value: value);

    // CleverTap call strictly for user profile updates
    if (value != null) {
      try {
        // This maps a single property to a profile update
        CleverTapPlugin.profileSet({name: value});
      } catch (e) {
        AppLogger.error('Error setting user property in CleverTap: $e', tag: 'Analytics');
      }
    }
  }

  /// Set the user ID for analytics
  Future<void> setUserId(String? userId) async {
    // Firebase
    await _analytics.setUserId(id: userId);

    // CleverTap
    // CleverTap identifies users via onUserLogin usually with an 'Identity' field.
    if (userId != null) {
      try {
        // onUserLogin is the standard way to "Identify" a user in CleverTap
        CleverTapPlugin.onUserLogin({'Identity': userId});
      } catch (e) {
        AppLogger.error('Error setting user ID in CleverTap: $e', tag: 'Analytics');
      }
    }

    // AppsFlyer
    if (userId != null) {
      try {
        _appsflyerSdk.setCustomerUserId(userId);
      } catch (e) {
        AppLogger.error('Error setting user ID in AppsFlyer: $e', tag: 'Analytics');
      }
    }
  }

  /// Identify user for CleverTap and Firebase
  Future<void> identifyUser({
    required String userId,
    String? phoneNumber,
    String? name,
    String? email,
  }) async {
    print('=== CLEVERTAP DEBUG: identifyUser called ===');
    print('userId: $userId');
    print('email: $email');
    print('phone: $phoneNumber');
    print('=====================================');
    
    AppLogger.debug('CleverTap identifyUser called with userId: $userId, email: $email, phone: $phoneNumber', tag: 'CleverTap');

    // CleverTap
    // Construct profile map as per documentation
    final Map<String, dynamic> profile = {
      'Identity': 'U_$userId', // Primary identifier
      'Name': name ?? '',
      'MSG-email': true, // Enable email notifications since we're collecting email
      'MSG-push': true, // Enable push notifications
      'MSG-sms': phoneNumber != null ? true : false, // Enable SMS only if phone provided
      'MSG-whatsapp': phoneNumber != null ? true : false, // Enable WhatsApp only if phone provided
    };

    // Add email as primary identifier if provided
    if (email != null && email.isNotEmpty) {
      profile['Email'] = email;
      AppLogger.debug('CleverTap: Adding email to profile: $email', tag: 'CleverTap');
    }
      
    // Add phone as secondary identifier if provided
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      profile['Phone'] = phoneNumber;
      AppLogger.debug('CleverTap: Adding phone to profile: $phoneNumber', tag: 'CleverTap');
    }

    print('=== CLEVERTAP PROFILE ===');
    print('Profile data: $profile');
    print('========================');

    try {
      AppLogger.info('CleverTap: Calling onUserLogin with profile: $profile', tag: 'CleverTap');
      CleverTapPlugin.onUserLogin(profile);
      AppLogger.info('CleverTap: User identification successful', tag: 'CleverTap');
    } catch (e) {
      AppLogger.error('CleverTap: Error in onUserLogin: $e', tag: 'CleverTap');
    }
  }

  /// Initiates Firebase On-Device Conversion Measurement (ODM) for iOS Google Ads.
  /// Normalizes per Google rules, then SHA256 (32 raw bytes) and passes to Flutter
  /// Firebase plugin hashed API. Phone (E.164) preferred, then email. No-op on non-iOS.
  Future<void> initiateOnDeviceConversionMeasurement({
    String? email,
    String? phone,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final normalizedPhone = normalizePhoneToE164ForOdm(phone);
      if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        final hashedBase64 = sha256Base64ForOdm(normalizedPhone);
        if (hashedBase64 != null) {
          await _analytics
              .initiateOnDeviceConversionMeasurementWithHashedPhoneNumber(
                hashedBase64,
              );
        }
        return;
      }

      final normalizedEmail = normalizeEmailForOdm(email);
      if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
        final hashedBase64 = sha256Base64ForOdm(normalizedEmail);
        if (hashedBase64 != null) {
          await _analytics
              .initiateOnDeviceConversionMeasurementWithHashedEmailAddress(
                hashedBase64,
              );
        }
      }
    } catch (e) {
      AppLogger.error('Error initiating on-device conversion measurement: $e', tag: 'Analytics');
    }
  }
}
