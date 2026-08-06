import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/types/app_notificationpermission/notification_permission.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class NotificationPermissionService extends GetxService {
  static NotificationPermissionService get to =>
      Get.find<NotificationPermissionService>();

  // Singleton instance
  static final NotificationPermissionService _instance =
      NotificationPermissionService._internal();

  // Factory constructor to return the same instance
  factory NotificationPermissionService() => _instance;

  // Private constructor
  NotificationPermissionService._internal();
  // Maximum number of retry attempts
  static const int _maxRetries = 3;

  // Storage keys
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenSentKey = 'fcm_token_sent';

  /// Save FCM token to local storage for future retries
  Future<void> saveFcmToken(String fcmToken) async {
    StorageService.write(_fcmTokenKey, fcmToken);
    StorageService.write(_fcmTokenSentKey, false);
    AppLogger.info(
      'FCM token saved for future retries',
      tag: 'NotificationPermissionService',
    );
  }

  /// Check if there's a pending FCM token that needs to be sent
  bool hasPendingToken() {
    final token = StorageService.read(_fcmTokenKey);
    final sent = StorageService.read(_fcmTokenSentKey);
    return token != null && (sent == null || sent == false);
  }

  /// Get the stored FCM token
  String? getStoredToken() {
    return StorageService.read(_fcmTokenKey);
  }

  /// Mark FCM token as successfully sent
  Future<void> markTokenAsSent() async {
    StorageService.write(_fcmTokenSentKey, true);
    AppLogger.info(
      'FCM token marked as sent',
      tag: 'NotificationPermissionService',
    );
  }

  /// Send FCM token to backend after permission is granted
  /// Returns true if successful, false otherwise
  /// Will retry up to 3 times if the request fails
  Future<bool> sendFcmToken(String fcmToken) async {
    // Save token for future retries if needed
    await saveFcmToken(fcmToken);

    int retryCount = 0;

    // Create a completer to handle async completion
    Completer<bool> completer = Completer<bool>();

    // Function to attempt sending the token
    Future<void> attemptSend() async {
      try {
        final response = await NetworkAPIHelper().patch(
          ApiURLs.GET_NOTIFICATION_PERMISSION,
          {'fcm': fcmToken},
        );

        if (response != null) {
          final responseData = jsonDecode(response.body);
          AppLogger.info(
            'Send FCM Token Response: ${responseData.toString()}',
            tag: 'NotificationPermissionService',
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final fcmResponse = FcmTokenResponse.fromJson(responseData);
            if (fcmResponse.status == 200 || fcmResponse.status == 201) {
              // Mark token as successfully sent
              await markTokenAsSent();

              if (!completer.isCompleted) {
                completer.complete(true);
              }
              return;
            }
          }
        }

        // If we reach here, the request failed
        retryCount++;
        if (retryCount < _maxRetries) {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: 2 * retryCount));
          attemptSend(); // Retry
        } else {
          // Max retries reached
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      } catch (e) {
        AppLogger.error(
          'Send FCM Token Error',
          error: e,
          tag: 'NotificationPermissionService',
        );
        retryCount++;
        if (retryCount < _maxRetries) {
          // Wait before retrying
          await Future.delayed(Duration(seconds: 2 * retryCount));
          attemptSend(); // Retry
        } else {
          // Max retries reached
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      }
    }

    // Start the first attempt in the background
    attemptSend();

    // Return the completer's future, but don't await it
    // This allows the caller to continue execution while retries happen in background
    return completer.future;
  }

  /// Initialize the service
  Future<NotificationPermissionService> init() async {
    AppLogger.info(
      'Initializing NotificationPermissionService',
      tag: 'NotificationPermissionService',
    );
    return this;
  }

  /// Check for pending FCM token and attempt to send it
  /// This should be called when the app starts
  Future<void> retryPendingTokens() async {
    if (hasPendingToken()) {
      final token = getStoredToken();
      if (token != null) {
        AppLogger.info(
          'Found pending FCM token, attempting to send',
          tag: 'NotificationPermissionService',
        );
        await sendFcmToken(token);
      }
    }
  }

  /// Clear all FCM tokens from storage
  /// This should be called during logout
  void clearTokens() {
    StorageService.remove(_fcmTokenKey);
    StorageService.remove(_fcmTokenSentKey);
    AppLogger.info(
      'FCM tokens cleared from storage',
      tag: 'NotificationPermissionService',
    );
  }
}
