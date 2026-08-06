import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nwt_app/notification/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/constants/theme.dart';
import 'package:nwt_app/controllers/realtime_controller.dart';
import 'package:nwt_app/controllers/theme_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/aa_data_fetch_controller.dart';
import 'package:nwt_app/controllers/mf_central/mf_central_status_controller.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_realtime_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_app_open_refresh_controller.dart';
import 'package:nwt_app/firebase_options.dart';
import 'package:nwt_app/screens/assets/investments/widgets/transaction.dart';
// import 'package:nwt_app/screens/auth/personalize_experience.dart'; // COMMENTED: Bypassing personalization, going directly to dashboard
import 'package:nwt_app/screens/bse_star/order_details.dart';
import 'package:nwt_app/screens/bse_star/start_journey.dart';
import 'package:nwt_app/screens/bse_star_v2/start_journey.dart';
import 'package:nwt_app/screens/buy_holdings/buy_holdings.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds_collections.dart';
import 'package:nwt_app/screens/onboarding/user_residental_status.dart';
import 'package:nwt_app/screens/sell_holdings/sell_holdings.dart';
import 'package:nwt_app/screens/splash.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/analytics/analytics_observer.dart';
import 'package:nwt_app/services/analytics/meta_app_events_service.dart';
import 'package:nwt_app/services/app_notification_permission/notification_permission.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/services/deep_linking/branch_service.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/app_lifecycle_manager.dart';
import 'package:nwt_app/services/mpin_service.dart';
import 'package:nwt_app/services/network/connectivity_service.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/services/search/search_history.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/services/update_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/network/network_sensitive.dart';
import 'package:nwt_app/screens/portfolio/order_history_v1_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saafe_aa_sdk/saafe_sdk.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/controllers/mutual_funds/mf_browse_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background handler is now managed in lib/notification/firebase_messaging.dart

void main() async {
  // Ensure Flutter is properly initialized first
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set debug flags before any service initialization
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;
  debugPaintLayerBordersEnabled = false;

  // Initialize Firebase first as it's a core dependency
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  await _initializeLocalNotifications();

  await FlutterBranchSdk.init(enableLogging: false, disableTracking: false);
  // FlutterBranchSdk.validateSDKIntegration();
  // Initialize Saafe SDK
  await SaafeSdk.initialize(useSandbox: false);

  // Configure Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Analytics Service
  await Get.putAsync(() => AnalyticsService().init());

  // Initialize storage service after Firebase but before Supabase
  // This helps avoid the shared_preferences channel error
  final storageInitialized = await StorageService.init();
  if (!storageInitialized) {
    AppLogger.warning(
      'Storage service failed to initialize. Some app features may be limited.',
      tag: 'Main',
    );
    // Continue app initialization even if storage fails
  }

  // Initialize Remote Config Service first
  await Get.putAsync(() => RemoteConfigService().init());

  // Initialize API URLs with remote config base URL
  ApiURLs.initialize();

  // Initialize Branch.io service for deep linking
  Get.put(BranchService()).init();

  // Initialize Supabase after RemoteConfig is ready
  await Supabase.initialize(
    url: RemoteConfigService.to.supabaseUrl.value,
    anonKey: RemoteConfigService.to.supabaseAnonKey.value,
    realtimeClientOptions: RealtimeClientOptions(
      eventsPerSecond: RemoteConfigService.to.supabaseEventsPerSecond.value,
    ),
  );

  // Note: Supabase realtime subscription for user data is now handled in UserController
  // This ensures we only subscribe to changes for the current logged-in user

  // Initialize Update Service - version check moved to dashboard screen
  Get.put(UpdateService());

  // Get package info for analytics
  final packageInfo = await PackageInfo.fromPlatform();

  final isFirstLaunch = StorageService.read('first_launch') == null;
  if (isFirstLaunch) {
    StorageService.write('first_launch', false);
  }

  final now = DateTime.now();
  final timeOfDay =
      now.hour < 12 ? 'morning' : (now.hour < 18 ? 'afternoon' : 'evening');

  await AnalyticsService.to.logEvent(
    name: 'app_open',
    parameters: {
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'is_first_launch': isFirstLaunch ? '1' : '0', // Convert boolean to string
      'time_of_day': timeOfDay,
      'day_of_week': now.weekday,
      'hour_of_day': now.hour,
    },
  );

  // Initialize Search History Service
  await Get.putAsync(() => SearchHistoryService().init());

  await Get.putAsync(() => ConnectivityService().init());
  await Get.putAsync(() => MPINService().init());
  await Get.putAsync(() => AppLifecycleManager().init());

  // Initialize Meta (Facebook) App Events for ad campaign optimization
  await MetaAppEventsService().initialize();
  Get.put(ThemeController());

  // Initialize RealtimeController before UserController
  Get.put(RealtimeController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(FinarkeinDataStore());
  await Get.putAsync(() => NotificationPermissionService().init());
  // await NotificationPermissionService.to.retryPendingTokens();
  FlutterNativeSplash.remove();
  // });
  // SecureStorage.remove(StorageKeys.AUTH_TOKEN_KEY);
  runApp(
    ScreenUtilInit(
      minTextAdapt: true,
      designSize: const Size(432.0, 960.0),
      child: const MainEntry(),
    ),
  );
}

// The setupRemoteConfig function has been replaced by the RemoteConfigService class

// Initialize local notifications plugin
Future<void> _initializeLocalNotifications() async {
  // Use FirebaseMessagingAPI for all messaging logic including APNS fix and logging
  final messagingAPI = FirebaseMessagingAPI();
  await messagingAPI.initNotifications();
  messagingAPI.setupTokenRefreshListener();
}

class MainEntry extends StatelessWidget {
  const MainEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    return GetMaterialApp(
      title: 'Pivot Money',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      navigatorObservers: [AnalyticsRouteObserver()],
      initialRoute: '/',
      getPages: [
        // GetPage(name: '/', page: () => const PaperTradingPortfolio()),
        GetPage(
          name: '/',
          page:
              () =>
                  const SplashScreen(), // UPDATED: Using SplashScreen which will route to dashboard via AuthFlow
          // page: () => PersonalizeExperience(), // COMMENTED: Bypassing personalization
          // page: () => const PanCardV2(),
          // page:   ()=> const BSEStartjourney()
        ),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Stack(children: [child!, const OfflineOverlayScreen()]),
        );
      },
      initialBinding: BindingsBuilder(() {
        _initializeControllers();
      }),
    );
  }

  void _initializeControllers() {
    try {
      // Initialize ThemeController first
      if (!Get.isRegistered<ThemeController>()) {
        Get.put<ThemeController>(ThemeController(), permanent: true);
      }

      // Initialize RealtimeController
      if (!Get.isRegistered<RealtimeController>()) {
        Get.put<RealtimeController>(RealtimeController(), permanent: true);
      }

      // Initialize UserController
      // Initialize AuthFlow
      if (!Get.isRegistered<AuthFlow>()) {
        final authFlow = AuthFlow();
        Get.put<AuthFlow>(authFlow, permanent: true);
        if (!Get.isRegistered<UserController>()) {
          Get.put<UserController>(UserController(), permanent: true);
        }
      }

      // Initialize AaDataFetchController
      if (!Get.isRegistered<AaDataFetchController>()) {
        Get.put<AaDataFetchController>(
          AaDataFetchController(),
          permanent: true,
        );
      }

      // Initialize FinarkeinAppOpenRefreshController
      if (!Get.isRegistered<FinarkeinAppOpenRefreshController>()) {
        Get.put<FinarkeinAppOpenRefreshController>(
          FinarkeinAppOpenRefreshController(),
          permanent: true,
        );
      }

      // Initialize MFBrowseController for shared filter options
      if (!Get.isRegistered<MFBrowseController>()) {
        Get.lazyPut<MFBrowseController>(
          () => MFBrowseController(),
          fenix: true,
        );
      }

      // Initialize MFCentralStatusController
      if (!Get.isRegistered<MFCentralStatusController>()) {
        Get.put<MFCentralStatusController>(
          MFCentralStatusController(),
          permanent: true,
        );
      }

      // Initialize PortfolioRealtimeController
      if (!Get.isRegistered<PortfolioRealtimeController>()) {
        Get.put<PortfolioRealtimeController>(
          PortfolioRealtimeController(),
          permanent: true,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error initializing controllers',
        error: e,
        tag: 'MainEntry',
      );
    }
  }
}
//flutter build ios --config-only --release