// ignore_for_file: unused_import, dead_code
//
// BACKUP FILE — This is an old version of auth_flow.dart kept for reference.
// The active implementation is in auth_flow.dart.
// This file is excluded from compilation by wrapping its class in a private
// scope that never conflicts with the real AuthFlow in auth_flow.dart.
//
// To avoid duplicate class errors this file intentionally contains no active
// Dart declarations. All code is commented out below.

/*
import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/auth/pan_card_verification.dart';
import 'package:nwt_app/screens/auth/phone_number.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/screens/onboarding/onboarding.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/auth/incomplete_onboarding_screen.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

/// BACKUP — Old AuthFlow implementation (pre-v1 API migration).
/// Do NOT use this class. Refer to auth_flow.dart for the active implementation.
class AuthFlowBackup {
  final AuthService _authService = AuthService();
  final UserController _userController = Get.find<UserController>();

  static const String _onboardingInProgressKey = 'onboarding_in_progress';

  Future<bool> _isOnboardingInProgress() async {
    await StorageService.init();
    final value = StorageService.read(_onboardingInProgressKey);
    return value == 'true';
  }

  Future<void> setOnboardingInProgress(bool inProgress) async {
    await StorageService.init();
    StorageService.write(_onboardingInProgressKey, inProgress.toString());
  }

  Future<void> clearOnboardingState() async {
    await StorageService.init();
    StorageService.remove(_onboardingInProgressKey);
  }

  bool _isOnboardingComplete(User user) {
    return user.isverified && user.ispanverified && user.ismfverified;
  }

  Future<void> handlePostOtpVerification() async {
    try {
      final userData = await _userController.fetchUserProfile(
        onLoading: (loading) {},
      );

      if (!userData.success) {
        await clearOnboardingState();
        _navigateToOnboarding();
        return;
      }

      if (_userController.userData != null) {
        final user = _userController.userData!;
        final isOnboardingComplete = _isOnboardingComplete(user);

        if (!isOnboardingComplete) {
          await setOnboardingInProgress(true);
        }

        if (isOnboardingComplete) {
          await clearOnboardingState();
          _navigateToStackedNavbar();
        } else {
          final wasOnboardingInProgress = await _isOnboardingInProgress();
          bool hasStartedVerification =
              user.isverified || user.ispanverified || user.ismfverified;

          if (wasOnboardingInProgress && hasStartedVerification) {
            final shouldContinue = await _showIncompleteOnboardingScreen();
            if (shouldContinue == true) {
              await _handleUserVerificationStatus(user);
            } else {
              await clearOnboardingState();
              _navigateToStackedNavbar();
            }
          } else {
            await _handleUserVerificationStatus(user);
          }
        }
      } else {
        await clearOnboardingState();
        _navigateToOnboarding();
      }
    } catch (e) {
      await clearOnboardingState();
      _navigateToOnboarding();
    }
  }

  Future<void> initialize() async {
    await StorageService.init();
    await SecureStorage.init();

    final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
    if (token == null) {
      _navigateToOnboarding();
      return;
    }

    bool isTokenValid = await _validateToken();
    if (!isTokenValid) {
      await _performLogout();
      return;
    }

    try {
      final userData = await _userController.fetchUserProfile(
        onLoading: (_) {},
      );

      if (userData.user != null) {
        final user = userData.user!;
        final isOnboardingComplete = _isOnboardingComplete(user);
        final wasOnboardingInProgress = await _isOnboardingInProgress();

        bool hasStartedVerification =
            user.isverified || user.ispanverified || user.ismfverified;

        if (!isOnboardingComplete &&
            wasOnboardingInProgress &&
            hasStartedVerification) {
          final shouldContinue = await _showIncompleteOnboardingScreen();
          if (!shouldContinue) {
            await _performLogout();
            return;
          }
        }

        if (!isOnboardingComplete) {
          await setOnboardingInProgress(true);
        } else {
          await clearOnboardingState();
        }

        await _handleUserVerificationStatus(user);
      } else {
        await clearOnboardingState();
        _navigateToOnboarding();
      }
    } catch (e) {
      await clearOnboardingState();
      _navigateToOnboarding();
    }
  }

  Future<void> _handleUserVerificationStatus(User user) async {
    if (!user.isverified && user.email != null) {
      _navigateToPhoneVerification();
      return;
    }

    if (!user.ispanverified) {
      _navigateToPanVerification();
      return;
    }

    await clearOnboardingState();
    _navigateToStackedNavbar();
  }

  void _navigateToOnboarding() {
    Get.offAll(
      () => const OnboardingScreen(),
      transition: Transition.rightToLeft,
    );
  }

  void _navigateToPhoneVerification() {
    Get.offAll(
      () => const PhoneNumberInputScreen(),
      transition: Transition.rightToLeft,
    );
  }

  void _navigateToPanVerification() {
    Get.offAll(
      () => const PanCardVerification(),
      transition: Transition.rightToLeft,
    );
  }

  void _navigateToStackedNavbar() {
    Get.offAll(
      () => StackedNavbar(selectedIdx: 0),
      transition: Transition.rightToLeft,
    );
  }

  Future<bool> _showIncompleteOnboardingScreen() async {
    try {
      final result = await Get.dialog<bool>(
        const IncompleteOnboardingScreen(),
        barrierDismissible: false,
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateToken() async {
    try {
      final response = await _authService.getUserProfile(
        onLoading: (_) {},
      );
      return response.success && response.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _performLogout() async {
    try {
      await SecureStorage.init();
      await SecureStorage.clearAll();
      _authService.logout();
      await clearOnboardingState();
      await Future.delayed(const Duration(milliseconds: 100));
      Get.deleteAll(force: true);
      _navigateToOnboarding();
    } catch (e) {
      _navigateToOnboarding();
    }
  }

  Future<void> logout() async {
    await _performLogout();
  }
}
*/
