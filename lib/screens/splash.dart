import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/onboarding/onboarding.dart';
import 'package:nwt_app/screens/profile/verify_pin.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/mpin_service.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/jwt_decoder.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/screen_size.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:permission_handler/permission_handler.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final appLinks = AppLinks();
  final authFlow = AuthFlow();
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Handle deep links
    appLinks.uriLinkStream.listen((uri) {
      AppLogger.info('Deep link received: $uri', tag: 'SplashScreen');
      // Handle deep link if needed
    });

    // Start the splash flow after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.appLaunched);
      AppLogger.info(AnalyticsEvents.appLaunched, tag: 'event');
      AnalyticsService.to.logEvent(name: AnalyticsEvents.splashScreenViewed);
      AppLogger.info(AnalyticsEvents.splashScreenViewed, tag: 'event');
      _startSplashFlow();
    });
  }

  Future<void> _startSplashFlow() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // Small delay ensures the app is fully Active before showing the prompt
      await Future.delayed(const Duration(milliseconds: 1000));

      // Request App Tracking Transparency permission on iOS
      final status = await Permission.appTrackingTransparency.request();
      AppLogger.info(
        'App Tracking Transparency Status: $status',
        tag: 'SplashScreen',
      );

      // Remaining delay
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      // Show splash screen for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted || _hasNavigated) return;

    // Check PIN status and proceed accordingly
    await _checkPINAndProceed();
  }

  Future<void> _checkPINAndProceed() async {
    try {
      final hasPinSet = await MPINService.to.hasPIN();
      final hasToken =
          await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY) != null;

      AppLogger.info(
        'PIN status check - Has PIN: $hasPinSet, Has Token: $hasToken',
        tag: 'SplashScreen',
      );

      // If token exists and PIN is set, verify PIN first
      if (hasPinSet && hasToken) {
        AppLogger.info('Token and PIN found, showing PIN verification', tag: 'SplashScreen');
        await _showPINVerification();
        return;
      }

      // No PIN or No Token, hand over to AuthFlow for standard initialization and routing
      AppLogger.info(
        'Proceeding to AuthFlow initialization (Status-only)',
        tag: 'SplashScreen',
      );
      await _proceedToAuthFlowInitialization();
    } catch (e) {
      AppLogger.error('Error in splash verification flow', error: e, tag: 'SplashScreen');
      await _proceedToAuthFlowInitialization();
    }
  }



  Future<void> _clearStorageAndProceedToAuthFlowInitialization() async {
    try {
      await SecureStorage.init();
      await SecureStorage.clearAll();
      await authFlow.logout();
      await Future.delayed(const Duration(milliseconds: 100));
      await _proceedToAuthFlowInitialization();
    } catch (e) {
      AppLogger.error('Error clearing storage', error: e, tag: 'SplashScreen');
      await _proceedToAuthFlowInitialization();
    }
  }

  Future<void> _showPINVerification() async {
    if (!mounted || _hasNavigated) return;

    final result = await Get.dialog<bool>(
      const VerifyPin(),
      barrierDismissible: false,
    );

    if (result == true) {
      AppLogger.info(
        'PIN verification successful, routing based on user status',
        tag: 'SplashScreen',
      );
      await _routeAfterPinVerification();
    } else {
      // If verification failed, try again
      AppLogger.info('PIN verification failed, retrying', tag: 'SplashScreen');
      await _showPINVerification();
    }
  }

  Future<void> _routeAfterPinVerification() async {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    try {
      AppLogger.info(
        'Routing after PIN verification via AuthFlow status check',
        tag: 'SplashScreen',
      );

      // Route based on V1 auth/status API only
      await authFlow.routeFromLatestProfile();
    } catch (e) {
      AppLogger.error(
        'Error routing after PIN verification',
        error: e,
        tag: 'SplashScreen',
      );
      // Fallback to onboarding if direct navigation fails
      _hasNavigated = false;
      await _proceedToAuthFlowInitialization();
    }
  }

  Future<void> _proceedToAuthFlowInitialization() async {
    if (!mounted || _hasNavigated) return;

    try {
      // Initialize storage
      await StorageService.init();
      await SecureStorage.init();
      
      AppLogger.info('🚀 App initialization started', tag: 'SplashScreen');
      
      // Check for access token
      final accessToken = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
      
      if (accessToken == null) {
        AppLogger.info('No access token found, navigating to login', tag: 'SplashScreen');
        _navigateToLogin();
        return;
      }
      
      AppLogger.info('Access token found, checking validity', tag: 'SplashScreen');
      
      // Check if token is expired
      if (JwtDecoder.isExpired(accessToken)) {
        AppLogger.info('Token expired, attempting refresh', tag: 'SplashScreen');
        
        // Try to refresh
        final authService = AuthService();
        final refreshSuccess = await authService.refreshToken();
        
        if (refreshSuccess) {
          AppLogger.info('✅ Token refresh successful, navigating to dashboard', tag: 'SplashScreen');
          _navigateToDashboard();
        } else {
          AppLogger.warning(
            'Token refresh failed, clearing tokens and navigating to login',
            tag: 'SplashScreen',
          );
          await _clearTokensAndNavigateToLogin();
        }
      } else {
        AppLogger.info('Token valid, navigating to dashboard', tag: 'SplashScreen');
        _navigateToDashboard();
      }
      
    } catch (e) {
      AppLogger.error('Error during app initialization', error: e, tag: 'SplashScreen');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    if (_hasNavigated) return;
    
    _hasNavigated = true;
    AppLogger.info('Navigating to login screen', tag: 'SplashScreen');
    Get.offAll(() => const OnboardingScreen(), transition: Transition.fadeIn);
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    if (_hasNavigated) return;
    
    _hasNavigated = true;
    AppLogger.info('Navigating to dashboard', tag: 'SplashScreen');
    Get.offAll(() => StackedNavbar(selectedIdx: 0), transition: Transition.fadeIn);
  }

  Future<void> _clearTokensAndNavigateToLogin() async {
    await SecureStorage.clearAll();
    _navigateToLogin();
  }

  @override
  Widget build(BuildContext context) {
    double width = ScreenSizeUtils.screenWidth(context);
    double height = ScreenSizeUtils.screenHeight(context);
    AppLogger.info('Screen size: $width x $height', tag: 'SplashScreen');
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Opacity(
                  opacity: 0.0,
                  child: Image.asset('assets/splash/branding.png', height: 70),
                ),
                Column(
                  children: [
                    SvgPicture.asset('assets/app/pivot_money.svg', width: 100),
                    SizedBox(height: 10),
                    AppText(
                      "Pivot Money",
                      variant: AppTextVariant.headline2,
                      weight: AppTextWeight.bold,
                    ),
                    SizedBox(height: 15),
                    AppText(
                      "SEBI Registered Investment Advisor",
                      variant: AppTextVariant.headline6,
                      textAlign: TextAlign.center,
                      colorType: AppTextColorType.secondary,
                    ),
                  ],
                ),
                Image.asset('assets/splash/branding.png', height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
