import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/auth/pan_card_v2.dart';
import 'package:nwt_app/screens/auth/phone_number.dart';
import 'package:nwt_app/screens/auth/personalize_experience.dart';

import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/screens/onboarding/onboarding.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nwt_app/services/app_notification_permission/notification_permission.dart';

class AuthFlow {
  final AuthService _authService = AuthService();
  late final UserController _userController;

  AuthFlow() {
    // Initialize UserController - either get existing instance or create new one
    if (Get.isRegistered<UserController>()) {
      _userController = Get.find<UserController>();
    } else {
      _userController = Get.put(UserController());
    }
  }

  // Track onboarding state
  static const String _onboardingInProgressKey = 'onboarding_in_progress';

  /// Prevents re-entrant gating flows (e.g., double-taps on Dashboard CTAs).
  static bool _ensurePanAndPhoneInProgress = false;

  bool _hasAnyPhone(User user) {
    final primary = (user.phonenumber ?? '').trim();
    final secondary = (user.secondaryphonenumber ?? '').trim();
    return primary.isNotEmpty || secondary.isNotEmpty;
  }

  Future<User?> _fetchLatestUserOrNull() async {
    final userData = await _userController.fetchUserProfile(onLoading: (_) {});
    if (!userData.success) return null;
    return _userController.userData;
  }

  /// Ensures PAN is verified and phone number is available, then continues with [onReady].
  ///
  /// - If PAN is missing/unverified: opens PAN flow and waits for success (caller resumes only if completed).
  /// - If phone is missing: opens phone collection in collect-only mode and returns the captured number to [onReady].
  /// - Phone is NOT persisted here; downstream flows (Finarkein consent initiate / KYC initiate) must persist it
  ///   only after their respective initiate endpoints succeed.
  ///
  /// [capturedPhone] passed to [onReady] is non-null only when the user had no phone on profile and provided one.
  Future<void> ensurePanAndPhoneThen({
    required BuildContext context,
    required Future<void> Function(String? capturedPhone) onReady,
  }) async {
    if (_ensurePanAndPhoneInProgress) return;
    _ensurePanAndPhoneInProgress = true;
    try {
      // Always start from the latest profile.
      final userData = await _userController.fetchUserProfile(
        onLoading: (_) {},
      );
      if (!userData.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to fetch profile. Please try again.'),
            ),
          );
        }
        return;
      }

      var user = _userController.userData;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to fetch profile. Please try again.'),
            ),
          );
        }
        return;
      }

      // PAN gate: require verified PAN (and non-empty PAN number).
      final hasPan = (user.pannumber ?? '').trim().isNotEmpty;
      final isPanVerified = user.ispanverified == true;
      if (!hasPan || !isPanVerified) {
        final completedPan = await Get.to<bool>(
          () => const PanCardV2(nextStep: PanCardNextStep.returnToCaller),
          transition: Transition.rightToLeft,
        );
        if (completedPan != true) return;

        // Re-fetch after PAN completion.
        final refreshed = await _userController.fetchUserProfile(
          onLoading: (_) {},
        );
        if (refreshed.status != 200 && refreshed.status != 201) return;
        user = _userController.userData;
        if (user == null) return;
      }

      // Phone gate: require any phone on profile; if missing, collect (without persisting here).
      if (!_hasAnyPhone(user)) {
        final capturedPhone = await Get.to<String?>(
          () => const PhoneNumberInputScreen(
            mode: PhoneNumberInputMode.collectOnly,
          ),
          transition: Transition.rightToLeft,
        );
        final phone = (capturedPhone ?? '').trim();
        if (phone.isEmpty) return;

        // Do not persist here (must be tied to initiate success).
        // Unlock prerequisites are now being fulfilled; clear any prior skip-to-dashboard preference.
        try {
          await StorageService.init();
          StorageService.remove(StorageKeys.SKIP_TO_DASHBOARD_KEY);
        } catch (_) {}
        await onReady(phone);
        return;
      }

      // PAN+phone already satisfied; clear any prior skip-to-dashboard preference.
      try {
        await StorageService.init();
        StorageService.remove(StorageKeys.SKIP_TO_DASHBOARD_KEY);
      } catch (_) {}
      await onReady(null);
    } catch (e) {
      AppLogger.error(
        'Error in ensurePanAndPhoneThen',
        error: e,
        tag: 'AuthFlow',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      _ensurePanAndPhoneInProgress = false;
    }
  }

  /// Used by Splash (post-PIN) to route user based on v1 auth/status.
  Future<void> routeFromLatestProfile() async {
    try {
      await _routeByOnboardingStatus();
    } catch (e) {
      AppLogger.error(
        'Error in routeFromLatestProfile',
        error: e,
        tag: 'AuthFlow',
      );
      _navigateToOnboarding();
    }
  }

  /// Used after successful Email OTP verification. Fetches latest user profile and routes
  /// based on onboarding_flow_type + PAN + phone for the track_my_investments journey.
  ///
  /// Rules:
  /// - If (PAN available & PAN verified & phone available & flowType == track_my_investments) → Dashboard
  /// - Else if (flowType == track_my_investments & PAN available & PAN verified) → Phone number (Unlock Investments)
  /// - Else if (flowType == track_my_investments) → PAN screen
  /// - Else → Dashboard (UPDATED: Bypassing PersonalizeExperience)
  Future<void> routeAfterEmailOtpVerification(User? user) async {
    try {
      // Note: identifyUser is now called before this method in email_otp_verification.dart
      // to ensure CleverTap gets user data immediately after OTP verification.
      // We keep this check here for other entry points that might pass a user.
      if (user != null) {
        // Only identify if not already identified (avoid double calls)
        // The AnalyticsService will handle duplicates gracefully
        AnalyticsService.to.identifyUser(
          userId: user.id.toString(),
          phoneNumber: user.phonenumber ?? user.secondaryphonenumber ?? '',
          name: '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim(),
          email: user.email ?? '',
        );
      }

      // Route strictly via v1 onboarding status API
      await _routeByOnboardingStatus();
    } catch (e) {
      AppLogger.error(
        'Error in routeAfterEmailOtpVerification',
        error: e,
        tag: 'AuthFlow',
      );
      // Navigate to PersonalizeExperience on error
      Get.offAll(
        () => const PersonalizeExperience(),
        transition: Transition.rightToLeft,
      );
    }
  }

  Future<bool> _isOnboardingInProgress() async {
    await StorageService.init(); // Ensure storage is initialized
    final value = StorageService.read(_onboardingInProgressKey);
    AppLogger.info('Onboarding in progress check: $value', tag: 'AuthFlow');
    return value == 'true';
  }

  Future<void> setOnboardingInProgress(bool inProgress) async {
    await StorageService.init(); // Ensure storage is initialized
    StorageService.write(_onboardingInProgressKey, inProgress.toString());
    AppLogger.info(
      'Setting onboarding in progress: $inProgress',
      tag: 'AuthFlow',
    );
  }

  Future<void> clearOnboardingState() async {
    await StorageService.init(); // Ensure storage is initialized
    StorageService.remove(_onboardingInProgressKey);
    AppLogger.info('Cleared onboarding state', tag: 'AuthFlow');
  }

  bool _isOnboardingComplete(User user) {
    // Check if user is verified via phone OR email (Google Sign-In)
    bool isPhoneOrEmailVerified =
        user.isverified ||
        (user.email != null &&
            user.email!.isNotEmpty &&
            user.phonenumber == null);

    return isPhoneOrEmailVerified && user.ispanverified && user.ismfverified;
  }

  Future<void> handlePostOtpVerification() async {
    AppLogger.info(
      'handlePostOtpVerification → routing via auth/status',
      tag: 'AuthFlow',
    );
    try {
      await _routeByOnboardingStatus();
    } catch (e) {
      AppLogger.error(
        'Error in handlePostOtpVerification',
        error: e,
        tag: 'AuthFlow',
      );
      await clearOnboardingState();
      _navigateToOnboarding();
    }
  }

  Future<void> initialize() async {
    AppLogger.info(
      '🔄 INITIALIZE: AuthFlow.initialize() starting',
      tag: 'AuthFlow',
    );
    // Ensure storage is initialized before any operations
    await StorageService.init();
    await SecureStorage.init();

    final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
    AppLogger.info(
      'AuthFlow initialize - Token: ${token != null ? 'exists' : 'null'}',
      tag: 'AuthFlow',
    );

    if (token == null) {
      AppLogger.info(
        'No auth token, redirecting to onboarding',
        tag: 'AuthFlow',
      );
      _navigateToOnboarding();
      return;
    }

    // Validate token and route based on server-side status
    try {
      // Direct routing based strictly on onboarding_status API (V1 testing backend)
      // This avoids unauthorized side-effect calls to the atom backend during startup.
      await _routeByOnboardingStatus();
    } catch (e) {
      AppLogger.error('Error in AuthFlow.initialize: $e', tag: 'AuthFlow');
      _navigateToOnboarding();
    }
  }

  // ── Core routing method (called after every successful auth event) ────────
  //
  // Calls GET auth/status/ and navigates to the correct onboarding screen.
  // Status values per user.md / profile.md:
  //   pan     → PAN verification
  //   bank    → Bank details (profile/bank_details/)
  //   profile → Profile details (profile/details/ + details_update/)
  //   ucc     → BSE 7-step UCC journey
  //   order   → Fully onboarded → Dashboard
  Future<void> _routeByOnboardingStatus() async {
    AppLogger.info(
      '🚀 _routeByOnboardingStatus: calling auth/status/',
      tag: 'AuthFlow',
    );

    final statusResponse = await _authService.getOnboardingStatus();
    AppLogger.info(
      '📊 Onboarding status response: success=${statusResponse?.success}, statusCode=${statusResponse?.statusCode}',
      tag: 'AuthFlow',
    );

    if (statusResponse == null) {
      AppLogger.error('Failed to get onboarding status (null)', tag: 'AuthFlow');
      _navigateToOnboarding();
      return;
    }

    if (!statusResponse.success) {
      if (statusResponse.statusCode == 401 ||
          statusResponse.statusCode == 403) {
        AppLogger.warning(
          'Session invalid (${statusResponse.statusCode}), logging out',
          tag: 'AuthFlow',
        );
        await _performLogout();
      } else {
        AppLogger.error(
          'Failed to get onboarding status: ${statusResponse.statusCode}',
          tag: 'AuthFlow',
        );
        _navigateToOnboarding();
      }
      return;
    }

    final status = statusResponse.status;
    AppLogger.info('Onboarding status from API: "$status"', tag: 'AuthFlow');

    // Handle new users who haven't started onboarding
    if (status.isEmpty || status == 'personalize' || status == 'new') {
      AppLogger.info(
        '✅ New user (status: "$status") → Navigating to PersonalizeExperience',
        tag: 'AuthFlow',
      );
      Get.offAll(
        () => const PersonalizeExperience(),
        transition: Transition.rightToLeft,
      );
      return;
    }

    switch (status) {

      case 'pan':
        // POST /profile/pan_verify/ → on success status moves to "bank"
        // UPDATED: Bypassing PAN screen, going directly to dashboard
        AppLogger.info(
          '📍 Status "pan" → Dashboard (bypassing PAN verification)',
          tag: 'AuthFlow',
        );
        await clearOnboardingState();
        _navigateToStackedNavbar();
        // Get.offAll(() => const PanCardV2(), transition: Transition.rightToLeft); // COMMENTED: Bypassing PAN screen
        break;

      case 'bank':
        // POST /profile/bank_details/ → on success status moves to "profile"
        // Skip BSE journey, go directly to dashboard
        AppLogger.info(
          '📍 Status "bank" → Dashboard',
          tag: 'AuthFlow',
        );
        await clearOnboardingState();
        _navigateToStackedNavbar();
        break;

      case 'profile':
        // GET/POST /profile/details/ + /profile/details_update/?submit_profile=true
        // → on submit success status moves to "ucc"
        // Skip BSE journey, go directly to dashboard
        AppLogger.info(
          '📍 Status "profile" → Dashboard',
          tag: 'AuthFlow',
        );
        await clearOnboardingState();
        _navigateToStackedNavbar();
        break;

      case 'ucc':
        // BSE 7-step UCC onboarding journey
        // Skip BSE journey, go directly to dashboard
        AppLogger.info(
          '📍 Status "ucc" → Dashboard',
          tag: 'AuthFlow',
        );
        await clearOnboardingState();
        _navigateToStackedNavbar();
        break;

      case 'order':
        // All onboarding complete → Dashboard
        AppLogger.info(
          '📍 Status "order" → Dashboard (onboarding complete)',
          tag: 'AuthFlow',
        );
        await clearOnboardingState();
        _navigateToStackedNavbar();

        // Post-onboarding: Send FCM token to atom backend
        _sendFcmTokenAfterOnboarding();
        break;

      default:
        AppLogger.warning(
          'Unknown onboarding status: "$status" → Dashboard',
          tag: 'AuthFlow',
        );
        await clearOnboardingState();
        _navigateToStackedNavbar();
    }
  }

  /// Legacy alias kept so call-sites that pass a User still compile.
  /// Internally delegates to _routeByOnboardingStatus.
  Future<void> _handleUserVerificationStatus(User user) async {
    await _routeByOnboardingStatus();
  }

  void _navigateToOnboarding() {
    try {
      // Check if Get.key is initialized and has a valid context
      if (Get.key.currentContext != null && Get.key.currentState != null) {
        Get.offAll(
          () => const OnboardingScreen(),
          transition: Transition.rightToLeft,
        );
      } else {
        // If no valid context, use a delayed approach to allow context to be established
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            Get.offAll(
              () => const OnboardingScreen(),
              transition: Transition.rightToLeft,
            );
          } catch (e) {
            AppLogger.warning(
              'Could not navigate to onboarding screen after delay: $e',
              tag: 'AuthFlow',
            );
            // As a last resort, try with a longer delay and simpler navigation
            Future.delayed(const Duration(seconds: 1), () {
              try {
                Get.to(() => const OnboardingScreen());
              } catch (e) {
                AppLogger.error(
                  'All navigation attempts to onboarding screen failed: $e',
                  tag: 'AuthFlow',
                );
              }
            });
          }
        });
      }
    } catch (e) {
      AppLogger.warning(
        'Could not navigate to onboarding screen: $e',
        tag: 'AuthFlow',
      );
    }
  }

  void _navigateToPhoneVerification() {
    AppLogger.info(
      '🚨 REDIRECTING TO PHONE VERIFICATION - This should NOT happen for Google Sign-In!',
      tag: 'AuthFlow',
    );
    AppLogger.info('🚨 Stack trace:', tag: 'AuthFlow');
    AppLogger.info('🚨 ${StackTrace.current}', tag: 'AuthFlow');
    Get.offAll(
      () => const PhoneNumberInputScreen(),
      transition: Transition.rightToLeft,
    );
  }

  void _navigateToMutualFundVerification() {
    Get.offAll(
      () => const MutualFundHoldingsJourneyScreen(isInitialJourney: true),
      transition: Transition.rightToLeft,
    );
  }

  // void _navigateToUserProfile() {
  //   Get.offAll(
  //     () => const UserProfileScreen(),
  //     transition: Transition.rightToLeft,
  //   );
  // }

  void _navigateToStackedNavbar() {
    // Reset the unlinked-assets bottom sheet flag for this new session/login
    try {
      StorageService.write(StorageKeys.MF_BOTTOMSHEET_SHOWN_KEY, false);
    } catch (e) {
      AppLogger.warning(
        'Failed to reset bottom sheet flag: $e',
        tag: 'AuthFlow',
      );
    }
    Get.offAll(
      () => StackedNavbar(selectedIdx: 0),
      transition: Transition.rightToLeft,
    );
  }

  // Removed _showIncompleteOnboardingScreen method as it's no longer needed
  // Users are now directly redirected to the appropriate verification screen

  // Validate if the token is still valid by making an API call
  Future<bool> _validateToken() async {
    try {
      // Try to fetch user profile to validate token
      final response = await _authService.getUserProfile(
        onLoading: (_) {}, // Silently handle loading
      );

      // Check if response was successful and user data exists
      if (response.success && response.user != null) {
        AppLogger.info('Token validation successful', tag: 'AuthFlow');
        return true;
      }

      AppLogger.error(
        'Token validation failed: ${response.message}',
        tag: 'AuthFlow',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error validating token', error: e, tag: 'AuthFlow');
      return false;
    }
  }

  // Properly perform logout with cleanup
  Future<void> _performLogout() async {
    try {
      // Clear all secure storage
      await SecureStorage.init();
      await SecureStorage.clearAll();

      // Clear auth data
      _authService.logout();

      // Clear local skip-to-dashboard preference
      try {
        await StorageService.init();
        StorageService.remove(StorageKeys.SKIP_TO_DASHBOARD_KEY);
      } catch (_) {}

      // Clear onboarding state
      await clearOnboardingState();

      // Reset app opened count
      StorageService.write(StorageKeys.APP_OPENED_COUNT_KEY, 0);
      AppLogger.info(
        'App opened count reset to 0 during logout',
        tag: 'AuthFlow',
      );

      // Navigate to onboarding screen
      _navigateToOnboarding();
    } catch (e) {
      AppLogger.error('Error during logout process', error: e, tag: 'AuthFlow');
      // Still try to navigate to onboarding as a fallback
      _navigateToOnboarding();
    }
  }

  // Public logout method
  Future<void> logout() async {
    await _performLogout();
  }

  /// Sends FCM token to atom backend after onboarding is complete.
  /// This helps avoid 401 errors during the V1 onboarding journey.
  Future<void> _sendFcmTokenAfterOnboarding() async {
    try {
      final notificationService = NotificationPermissionService.to;
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        AppLogger.info(
          'Post-onboarding: Sending FCM token to atom',
          tag: 'AuthFlow',
        );
        await notificationService.sendFcmToken(fcmToken);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to send FCM token post-onboarding: $e',
        tag: 'AuthFlow',
      );
    }
  }

  // New method for direct navigation after PIN verification (without delays)
  Future<void> proceedAfterPINVerification() async {
    // Ensure storage is initialized before any operations
    await StorageService.init();
    await SecureStorage.init();

    final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
    AppLogger.info(
      'AuthFlow proceedAfterPINVerification - Token: ${token != null ? 'exists' : 'null'}',
      tag: 'AuthFlow',
    );

    if (token == null) {
      AppLogger.info(
        'No auth token, redirecting to onboarding',
        tag: 'AuthFlow',
      );
      _navigateToOnboarding();
      return;
    }

    // Validate token by making an API call
    bool isTokenValid = await _validateToken();
    if (!isTokenValid) {
      AppLogger.info(
        'Invalid or expired token, clearing data and redirecting to onboarding',
        tag: 'AuthFlow',
      );
      await _performLogout();
      return;
    }

    try {
      // Fetch user profile
      final userData = await _userController.fetchUserProfile(
        onLoading: (_) {}, // Silently handle loading
      );

      if (userData.user != null) {
        // Directly route via v1 onboarding status (no stale local checks)
        await _routeByOnboardingStatus();
      } else {
        await clearOnboardingState();
        _navigateToOnboarding();
      }
    } catch (e) {
      AppLogger.error(
        'Error in AuthFlow.proceedAfterPINVerification',
        error: e,
        tag: 'AuthFlow',
      );
      await clearOnboardingState();
      _navigateToOnboarding();
    }
  }
}
