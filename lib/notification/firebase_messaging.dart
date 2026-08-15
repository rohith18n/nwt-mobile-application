import 'package:firebase_core/firebase_core.dart';
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nwt_app/utils/logger.dart';

// Define this top-level function outside of any class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  AppLogger.info(
    'Handling a background message: ${message.messageId}',
    tag: 'FirebaseMessaging',
  );

  // Show local notification for background messages
  final notification = message.notification;
  if (notification != null) {
    final api = FirebaseMessagingAPI();
    api.localNotificationsApp(notification);
  }
}

class FirebaseMessagingAPI {
  late final FirebaseMessaging _firebaseMessaging;
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
        "high_importance_channel",
        "High Importance Notifications",
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  late DarwinNotificationDetails _iosNotificationDetails =
      const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.critical,
      );

  late final FlutterLocalNotificationsPlugin _localNotifications;

  FirebaseMessagingAPI();

  void localNotificationsApp(RemoteNotification? notification) {
    if (notification != null) {
      if (!_isLocalNotificationsInitialized()) {
        AppLogger.warning(
          'Local notifications not initialized',
          tag: 'FirebaseMessaging',
        );
        return;
      }

      _localNotifications.show(
        0,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
          ),
          iOS: _iosNotificationDetails,
        ),
      );
    }
  }

  bool _isLocalNotificationsInitialized() {
    try {
      var _ = _localNotifications.pendingNotificationRequests();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> initNotifications() async {
    try {
      // Register the background message handler first
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _localNotifications = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.info(
            'Notification clicked: ${response.payload}',
            tag: 'FirebaseMessaging',
          );
          // Handle notification click here
        },
      );

      await setupNotificationChannels();

      _firebaseMessaging = FirebaseMessaging.instance;

      // Configure how iOS notifications appear when the app is in foreground
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true, // Required to display a heads up notification
            badge: true,
            sound: true,
          );

      // Request permissions with more specific settings for iOS
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            criticalAlert: false,
          );

      AppLogger.info(
        'Permission status: ${settings.authorizationStatus}',
        tag: 'FirebaseMessaging',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Set up foreground message handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          AppLogger.info(
            'Received foreground message: ${message.messageId}',
            tag: 'FirebaseMessaging',
          );
          AppLogger.info(
            'Message Data: ${message.data}',
            tag: 'FirebaseMessaging',
          );

          RemoteNotification? notification = message.notification;

          // If notification is not null and contains title/body, show it
          if (notification != null &&
              notification.title != null &&
              notification.body != null) {
            localNotificationsApp(notification);
          }
        });

        // Set up notification tap handler when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          AppLogger.info(
            'Notification tapped in background state: ${message.messageId}',
            tag: 'FirebaseMessaging',
          );
          // Handle navigation or other actions when notification is tapped
        });

        // Check for initial message (app opened from terminated state)
        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) {
            AppLogger.info(
              'App opened from terminated state by notification: ${message.messageId}',
              tag: 'FirebaseMessaging',
            );
          }
        });

        // For iOS, wait a bit for APNs token to be available
        String? apnsToken;
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // Wait for APNs token first
          int attempts = 0;
          const maxAttempts = 10;

          AppLogger.info("Fetching APNs token...", tag: 'FirebaseMessaging');
          while (attempts < maxAttempts && apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            apnsToken = await _firebaseMessaging.getAPNSToken();
            AppLogger.info(
              "Attempt ${attempts + 1}: APNs Token: ${apnsToken != null ? 'Found' : 'Not found'}",
              tag: 'FirebaseMessaging',
            );
            attempts++;
          }

          if (apnsToken != null) {
            AppLogger.info("APNs Token: $apnsToken", tag: 'FirebaseMessaging');
            // Update CleverTap with the APNs token for iOS
            AppLogger.info(
              "Sending APNs token to CleverTap: $apnsToken",
              tag: 'FirebaseMessaging',
            );
            CleverTapPlugin.setPushToken(apnsToken);
          } else {
            AppLogger.warning(
              "APNs Token not available after $maxAttempts attempts",
              tag: 'FirebaseMessaging',
            );
            return null;
          }
        }

        // Now get FCM token
        final fcmToken = await _firebaseMessaging.getToken();

        if (fcmToken != null) {
          AppLogger.info("FCM Token: $fcmToken", tag: 'FirebaseMessaging');
          // Update CleverTap with the FCM token only for NON-iOS platforms
          // On iOS, we use the APNs token already set above
          if (defaultTargetPlatform != TargetPlatform.iOS) {
            CleverTapPlugin.setPushToken(fcmToken);
          }
          return fcmToken;
        } else {
          AppLogger.warning("FCM Token is null", tag: 'FirebaseMessaging');
          return null;
        }
      } else {
        AppLogger.warning(
          'Notification permission denied',
          tag: 'FirebaseMessaging',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        "Error initializing notifications: $e",
        tag: 'FirebaseMessaging',
      );
      return null;
    }
  }

  // Add this method to listen for token refresh
  void setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh
        .listen((fcmToken) {
          AppLogger.info(
            "FCM Token refreshed: $fcmToken",
            tag: 'FirebaseMessaging',
          );
          // Send the token to your server here
        })
        .onError((err) {
          AppLogger.error(
            "Error on token refresh: $err",
            tag: 'FirebaseMessaging',
          );
        });
  }

  // Debug method to check iOS setup
  Future<void> debugiOSSetup() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Check if running on simulator
      var isSimulator = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      AppLogger.info(
        "Running on iOS simulator: $isSimulator",
        tag: 'FirebaseMessaging',
      );

      // Check APNs token availability
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      AppLogger.info(
        "APNs Token available: ${apnsToken != null}",
        tag: 'FirebaseMessaging',
      );

      // Check permission status
      NotificationSettings settings =
          await _firebaseMessaging.getNotificationSettings();
      AppLogger.info(
        "Notification permission: ${settings.authorizationStatus}",
        tag: 'FirebaseMessaging',
      );

      // Check if Firebase is properly initialized
      try {
        var app = Firebase.app();
        AppLogger.info(
          "Firebase app initialized: ${app.name}",
          tag: 'FirebaseMessaging',
        );
      } catch (e) {
        AppLogger.error(
          "Firebase not initialized: $e",
          tag: 'FirebaseMessaging',
        );
      }
    }
  }

  Future<void> setupNotificationChannels() async {
    if (!_isLocalNotificationsInitialized()) {
      AppLogger.warning(
        'Local notifications not initialized for channel setup',
        tag: 'FirebaseMessaging',
      );
      return;
    }

    _iosNotificationDetails = const DarwinNotificationDetails();

    final platform =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await platform?.createNotificationChannel(_androidChannel);
  }
}
