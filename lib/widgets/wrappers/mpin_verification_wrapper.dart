import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/profile/verify_pin.dart';
import 'package:nwt_app/screens/splash.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/mpin_service.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';

class MPINVerificationWrapper extends StatefulWidget {
  final Widget child;

  const MPINVerificationWrapper({super.key, required this.child});

  @override
  State<MPINVerificationWrapper> createState() =>
      _MPINVerificationWrapperState();
}

class _MPINVerificationWrapperState extends State<MPINVerificationWrapper> {
  final _isVerified = false.obs;
  final _authService = AuthService();
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _checkPINStatus();
  }

  Future<void> _checkPINStatus() async {
    final hasPinSet = await MPINService.to.hasPIN();
    final hasToken =
        await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY) != null;

    if (!hasPinSet || !hasToken) {
      _isVerified.value = true;
      return;
    }

    // Validate token by making API call to check if user is still valid
    final isTokenValid = await _validateToken();

    if (!isTokenValid) {
      // Token is invalid, clear storage and navigate to splash screen
      await _clearStorageAndNavigateToSplash();
      return;
    }

    // Token is valid, proceed with PIN verification
    await _showVerificationDialog();
  }

  Future<bool> _validateToken() async {
    try {
      _isLoading.value = true;

      // Try to fetch user profile to validate token
      final response = await _authService.getUserProfile(
        onLoading: (loading) => _isLoading.value = loading,
      );

      // Check if response was successful and user data exists
      if (response.success && response.user != null) {
        AppLogger.info(
          'Token validation successful',
          tag: 'MPINVerificationWrapper',
        );
        return true;
      }

      AppLogger.error(
        'Token validation failed: ${response.message}',
        tag: 'MPINVerificationWrapper',
      );
      return false;
    } catch (e) {
      AppLogger.error(
        'Error validating token',
        error: e,
        tag: 'MPINVerificationWrapper',
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _clearStorageAndNavigateToSplash() async {
    try {
      // Clear all storage
      await SecureStorage.init();
      await SecureStorage.clearAll(); // Use clearAll() method to clear all secure storage

      // Clear auth data
      _authService.logout();

      // Make sure we're not in the middle of a GetX transition
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to splash screen
      Get.offAll(
        () => const SplashScreen(),
        transition: Transition.rightToLeft,
        predicate: (_) => false, // Clear all previous routes
      );
    } catch (e) {
      AppLogger.error(
        'Error during navigation after token validation failure',
        error: e,
        tag: 'MPINVerificationWrapper',
      );
    }
  }

  Future<void> _showVerificationDialog() async {
    final result = await Get.dialog<bool>(
      const VerifyPin(),
      barrierDismissible: false,
    );

    if (result == true) {
      _isVerified.value = true;
    } else {
      // If verification failed or was cancelled, try again
      await _showVerificationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _isVerified.value ? widget.child : const SizedBox.shrink(),
    );
  }
}
