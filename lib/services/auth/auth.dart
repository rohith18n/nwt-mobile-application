import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/assets/banks.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_refresh_controller.dart';
import 'package:nwt_app/controllers/dashboard/data_fetch_status_controller.dart';
import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
import 'package:nwt_app/controllers/realtime_controller.dart';
import 'package:nwt_app/controllers/search/global_search.dart';
import 'package:nwt_app/controllers/transactions/banks/transactions.dart';
import 'package:nwt_app/controllers/transactions/investments/transactions.dart';
import 'package:nwt_app/controllers/dashboard/blog_controller.dart';
import 'package:nwt_app/controllers/dashboard/calculator_controller.dart';
import 'package:nwt_app/controllers/amount_visibility_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/fip_status_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_app_open_refresh_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/onboarding/onboarding.dart';
import 'package:nwt_app/services/app_notification_permission/notification_permission.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/types/auth/otp.dart';
import 'package:nwt_app/types/auth/pan_consent.dart';
import 'package:nwt_app/types/auth/pan_verfication.dart';
import 'package:nwt_app/types/auth/user.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  Future<GenerateOtpResponse?> generateOTP({
    required String phoneNumber,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.AUTH_LOGIN, {
        "identifier": phoneNumber,
      });
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Generate OTP Response: ${responseData.toString()}',
          tag: 'AuthService',
        );

        return GenerateOtpResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      AppLogger.error('Generate OTP Error', error: e, tag: 'AuthService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  Future<GenerateOtpResponse?> sendEmailOtp({
    required String email,
    required Function(bool isLoading) onLoading,
  }) async {
    return generateOTP(phoneNumber: email, onLoading: onLoading);
  }

  Future<VerifyOtpResponse?> verifyEmailOtp({
    required String email,
    required String otp,
    required Function(bool isLoading) onLoading,
  }) async {
    return verifyOTP(phoneNumber: email, otp: otp, onLoading: onLoading);
  }

  Future<VerifyOtpResponse?> verifyOTP({
    required String phoneNumber,
    required String otp,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.AUTH_VERIFY, {
        "identifier": phoneNumber,
        "otp": otp,
      });

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Verify OTP Response: ${responseData.toString()}',
          tag: 'AuthService',
        );

        final verifyResponse = VerifyOtpResponse.fromJson(responseData);

        if (verifyResponse.success && verifyResponse.data != null) {
          AppLogger.info(
            '💾 Saving tokens after OTP verification - Access token length: ${verifyResponse.data!.access.length}',
            tag: 'AuthFlowService',
          );
          await SecureStorage.write(
            StorageKeys.AUTH_TOKEN_KEY,
            verifyResponse.data!.access,
          );
          await SecureStorage.write(
            StorageKeys.REFRESH_TOKEN_KEY,
            verifyResponse.data!.refresh,
          );

          // Verify token was saved
          final savedToken = await SecureStorage.read(
            StorageKeys.AUTH_TOKEN_KEY,
          );
          AppLogger.info(
            '✅ Token saved and verified - Token exists: ${savedToken != null}, Length: ${savedToken?.length ?? 0}',
            tag: 'AuthFlowService',
          );
        }
        return verifyResponse;
      }
      return null;
    } catch (e) {
      AppLogger.error('Verify OTP Error', error: e, tag: 'AuthService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  Future<VerifyOtpResponse?> googleAuth({
    required String token,
    String? email,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.GOOGLE_AUTH, {
        "token": token,
        "email": email,
      });

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info('Google Auth Response: $email', tag: 'AuthService');
        AppLogger.info(
          'Google Auth Response: ${responseData.toString()}',
          tag: 'AuthService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final googleAuthResponse = VerifyOtpResponse.fromJson(responseData);

          // Store both access and refresh tokens per v1 dual-token system
          if (googleAuthResponse.data?.access.isNotEmpty == true) {
            AppLogger.info(
              '💾 Saving tokens after Google auth - Access token length: ${googleAuthResponse.data!.access.length}',
              tag: 'AuthFlowService',
            );
            await SecureStorage.write(
              StorageKeys.AUTH_TOKEN_KEY,
              googleAuthResponse.data!.access,
            );
          }
          if (googleAuthResponse.data?.refresh.isNotEmpty == true) {
            await SecureStorage.write(
              StorageKeys.REFRESH_TOKEN_KEY,
              googleAuthResponse.data!.refresh,
            );
          }

          // Verify token was saved
          final savedToken = await SecureStorage.read(
            StorageKeys.AUTH_TOKEN_KEY,
          );
          AppLogger.info(
            '✅ Token saved and verified after Google auth - Token exists: ${savedToken != null}, Length: ${savedToken?.length ?? 0}',
            tag: 'AuthFlowService',
          );

          return googleAuthResponse;
        } else {
          return VerifyOtpResponse(
            success: false,
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Google Auth Error', error: e, tag: 'AuthService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  Future<String?> getAuthToken() async {
    return await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
  }

  Future<String?> getRefreshToken() async {
    return await SecureStorage.read(StorageKeys.REFRESH_TOKEN_KEY);
  }

  Future<bool> isLoggedIn() async {
    return await SecureStorage.hasKey(StorageKeys.AUTH_TOKEN_KEY);
  }

  Future<bool> refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await NetworkAPIHelper().post(ApiURLs.AUTH_REFRESH, {
        "refresh_token": refresh,
      }, requiresAuth: false);

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Robust parsing: handle both V1-style wrapped data and flat SimpleJWT responses
        String? newAccessToken;
        String? newRefreshToken;

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          newAccessToken = data['access'] as String?;
          newRefreshToken =
              data['refresh'] as String? ?? data['refresh_token'] as String?;
        }

        // Fallback to flat structure (Standard SimpleJWT)
        newAccessToken ??=
            responseData['access'] as String? ??
            responseData['access_token'] as String?;
        newRefreshToken ??=
            responseData['refresh'] as String? ??
            responseData['refresh_token'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await SecureStorage.write(StorageKeys.AUTH_TOKEN_KEY, newAccessToken);

          // Also update refresh token if a new one was provided (rotation)
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await SecureStorage.write(
              StorageKeys.REFRESH_TOKEN_KEY,
              newRefreshToken,
            );
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Refresh Token Error', error: e, tag: 'AuthService');
      return false;
    }
  }

  Future<OnboardingStatusResponse?> getOnboardingStatus() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.AUTH_STATUS);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          // Inject statusCode into the map so fromJson can read it
          responseData['statusCode'] = response.statusCode;
          return OnboardingStatusResponse.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Get Onboarding Status Error',
        error: e,
        tag: 'AuthService',
      );
      return null;
    }
  }

  Future<void> logoutWithAPI() async {
    AppLogger.info('Logging out user with API call', tag: 'AuthService');

    try {
      // Get FCM token if available
      final notificationService = NotificationPermissionService.to;
      final fcmToken = notificationService.getStoredToken();

      if (fcmToken != null) {
        AppLogger.info('Calling logout API with FCM token', tag: 'AuthService');

        // Call the logout API with FCM token
        final response = await NetworkAPIHelper().patch(ApiURLs.LOGOUT, {
          'fcm': fcmToken,
        });

        if (response != null) {
          final responseData = jsonDecode(response.body);
          AppLogger.info(
            'Logout API Response: ${responseData.toString()}',
            tag: 'AuthService',
          );
        }
      } else {
        AppLogger.info(
          'No FCM token available for logout API call',
          tag: 'AuthService',
        );
      }
    } catch (e) {
      AppLogger.error('Error calling logout API', error: e, tag: 'AuthService');
    }
  }

  Future<void> logout() async {
    AppLogger.info('Logging out user', tag: 'AuthService');
    await logoutWithAPI(); // Call logout API but don't await
    // Log that we're starting the logout process
    AppLogger.info(
      'Starting logout process - clearing all storage',
      tag: 'AuthService',
    );
    // Check and log auth token before clearing
    final authTokenBefore = await SecureStorage.read(
      StorageKeys.AUTH_TOKEN_KEY,
    );
    AppLogger.info(
      'Auth token before clearing: $authTokenBefore',
      tag: 'AuthService',
    );

    // Clear using SecureStorage wrapper
    await SecureStorage.clearAll();

    // Clear refresh token specifically
    await SecureStorage.remove(StorageKeys.REFRESH_TOKEN_KEY);

    // Check and log auth token after first clearing
    final authTokenAfter = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
    AppLogger.info(
      'Auth token after SecureStorage.clearAll(): $authTokenAfter',
      tag: 'AuthService',
    );

    // Clear directly using FlutterSecureStorage
    await FlutterSecureStorage().deleteAll();

    // Clear again using SecureStorage wrapper
    await SecureStorage.clearAll();

    // Log all remaining secure storage contents
    final allSecureStorageContents = await FlutterSecureStorage().readAll();
    AppLogger.info(
      'All secure storage contents after clearing: $allSecureStorageContents',
      tag: 'AuthService',
    );
    // Clear ALL regular storage data
    try {
      // First clear specific keys we know about
      StorageService.remove(StorageKeys.MF_BOTTOMSHEET_SHOWN_KEY);
      StorageService.remove(StorageKeys.PREVIOUS_MF_VERIFIED_KEY);
      StorageService.remove(StorageKeys.MF_SAVINGS_KEY);

      // Then clear everything else to be safe
      StorageService.clear();
      AppLogger.info('Cleared all regular storage data', tag: 'AuthService');
    } catch (e) {
      AppLogger.error(
        'Failed to clear regular storage: $e',
        tag: 'AuthService',
      );
    }

    // Clear FCM token after API call
    try {
      final notificationService = NotificationPermissionService.to;
      notificationService.clearTokens();
    } catch (e) {
      AppLogger.warning(
        'Could not clear notification tokens: $e',
        tag: 'AuthService',
      );
    }

    // Close any active realtime connections and clear user data
    try {
      final userController = Get.find<UserController>();
      userController
          .clearUserData(); // This already calls realtimeController.onClose()
    } catch (e) {
      AppLogger.warning('Could not clear user data: $e', tag: 'AuthService');
    }

    // Clear Dashboard refresh pending flags so next login doesn't trigger stale refresh
    try {
      if (Get.isRegistered<DashboardRefreshController>()) {
        final c = Get.find<DashboardRefreshController>();
        c.pendingLinkRefresh = false;
        c.pendingDelinkRefresh = false;
      }
    } catch (_) {}

    // Force clear all GetX controllers and services to reset all local states
    _clearAllGetXDependencies();

    // Verify storage is cleared by checking a few key values
    try {
      final hasAuthToken = await SecureStorage.hasKey(
        StorageKeys.AUTH_TOKEN_KEY,
      );
      final hasMFBottomsheet = StorageService.hasKey(
        StorageKeys.MF_BOTTOMSHEET_SHOWN_KEY,
      );

      AppLogger.info(
        'Storage verification after logout - Auth token exists: $hasAuthToken, MF Bottomsheet exists: $hasMFBottomsheet',
        tag: 'AuthService',
      );

      if (hasAuthToken) {
        AppLogger.warning(
          'Auth token still exists after logout!',
          tag: 'AuthService',
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Could not verify storage clearing: $e',
        tag: 'AuthService',
      );
    }

    AppLogger.info('User logged out successfully', tag: 'AuthService');
    Get.offAll(() => const OnboardingScreen());
  }

  /// Helper method to clear all GetX controllers, services and background services
  void _clearAllGetXDependencies() {
    AppLogger.info('Clearing all GetX dependencies', tag: 'AuthService');

    // First try to clear specific controllers that need special handling
    try {
      // Clear RealtimeController first as it has subscriptions
      if (Get.isRegistered<RealtimeController>()) {
        final realtimeController = Get.find<RealtimeController>();
        realtimeController.onClose();
        Get.delete<RealtimeController>(force: true);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to clear RealtimeController: $e',
        tag: 'AuthService',
      );
    }

    // List of controllers to force delete
    final controllerTypes = [
      UserController,
      BankController,
      InvestmentController,
      DashboardAssetController,
      GlobalSearchController,
      MFTopPerformersController,
      BankTransactionController,
      DataFetchStatusController,
      InvestmentTransactionController,
      BlogController,
      CalculatorController,
      AmountVisibilityController,
      RawAssetController,
      FipStatusController,
      FinarkeinDataController,
      DashboardRefreshController,
      FinarkeinAppOpenRefreshController,
      // Don't clear ThemeController as it's not related to user session
    ];

    // Force delete all registered controllers
    for (final controllerType in controllerTypes) {
      try {
        final typeName = controllerType.toString();
        if (Get.isRegistered(tag: typeName)) {
          Get.delete(tag: typeName, force: true);
          AppLogger.info('Deleted controller: $typeName', tag: 'AuthService');
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to delete controller: $e',
          tag: 'AuthService',
        );
      }
    }

    // Clear services
    try {
      // NotificationPermissionService is a singleton GetxService
      // We don't delete it but reset its state
      final notificationService = NotificationPermissionService.to;
      notificationService.clearTokens();
    } catch (e) {
      AppLogger.warning(
        'Failed to reset NotificationPermissionService: $e',
        tag: 'AuthService',
      );
    }

    // Clear any remaining controllers and services
    try {
      // This is a more aggressive approach - use with caution
      // It will reset all GetX bindings but keep the ones needed for navigation
      // Get.reset(clearRouteBindings: false);
      AppLogger.info('Reset GetX instance manager', tag: 'AuthService');
    } catch (e) {
      AppLogger.warning('Failed to reset GetX: $e', tag: 'AuthService');
    }
  }

  Future<UserDataResponse> getUserProfile({
    required Function(bool) onLoading,
  }) async {
    final notificationService = NotificationPermissionService.to;
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.PROFILE_DETAILS);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get User Profile Response: ${responseData.toString()}   ${response.statusCode}',
          tag: 'AuthService',
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final userDataResponse = UserDataResponse.fromJson(responseData);
          userDataResponse.statusCode = response.statusCode;
          return userDataResponse;
        } else {
          return UserDataResponse(
            success: false,
            message: responseData['message'] ?? 'Unknown error',
            statusCode: response.statusCode,
          );
        }
      }
      return UserDataResponse(
        success: false,
        message: 'Unknown error',
        statusCode: response?.statusCode,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get User Profile Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return UserDataResponse(success: false, message: e.toString());
    } finally {
      onLoading(false);
    }
  }

  Future<UserDataResponse> updateUserProfile({
    required String firstname,
    required String lastname,
    required String dob,
    String? profileImage,
    bool submitProfile = false,
    required Function(bool) onLoading,
  }) async {
    onLoading(true);
    try {
      final extendedProfile = {
        "primary_first_name": firstname,
        "primary_last_name": lastname,
      };

      final data = {
        "name": "$firstname $lastname",
        "dob": dob,
        "extended_profile": extendedProfile,
      };

      if (profileImage != null) {
        data["profileimage"] = profileImage;
      }

      if (submitProfile) {
        data["submit_profile"] = true;
      }

      final response = await NetworkAPIHelper().post(
        ApiURLs.PROFILE_DETAILS_UPDATE,
        data,
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Update User Profile Response: ${responseData.toString()}',
          tag: 'AuthService',
        );

        return UserDataResponse.fromJson(responseData);
      }
      return UserDataResponse(success: false, message: 'Unknown error');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update User Profile Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return UserDataResponse(success: false, message: e.toString());
    } finally {
      onLoading(false);
    }
  }

  /// Update primary phone for email-signup users (e.g. after Finarkein consent journey completes).
  /// Returns true if statusCode is 200.
  Future<bool> updatePhone({required String phonenumber}) async {
    try {
      final response = await NetworkAPIHelper().patch(
        ApiURLs.UPDATE_USER_PHONE,
        {'phonenumber': phonenumber},
      );
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update phone error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return false;
    }
  }

  /// Set onboarding flow type when user selects "What brings you here?".
  /// [flowType] must be one of: track_my_investments, explore_mutual_funds, complete_kyc, get_me_in.
  Future<bool> setOnboardingFlowType({required String flowType}) async {
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.ONBOARDING_FLOW, {
        'flow_type': flowType,
      });
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Set onboarding flow type error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return false;
    }
  }

  /// Update onboarding progress/status for a flow type.
  /// [status] must be one of: not_started, in_progress, completed.
  Future<bool> updateOnboardingProgress({
    required String flowType,
    required String status,
  }) async {
    try {
      final response = await NetworkAPIHelper().patch(
        ApiURLs.ONBOARDING_PROGRESS,
        {'flow_type': flowType, 'status': status},
      );
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update onboarding progress error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return false;
    }
  }

  Future<PanVerificationResponse> verifyPanCard({
    required String panNumber,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(
        ApiURLs.PAN_CARD_VERIFICATION,
        {"pannumber": panNumber, "version": 2},
      );

      if (response == null) {
        return PanVerificationResponse(
          status: 0,
          message: 'PAN verification failed.',
          data: null,
        );
      }

      final responseData = jsonDecode(response.body);
      AppLogger.info(
        'PAN Verification Response: ${responseData.toString()}',
        tag: 'Pan Verification Response',
      );

      final verificationResponse = PanVerificationResponse.fromJson(
        responseData,
      );

      if (verificationResponse.success) {
        await getUserProfile(onLoading: onLoading);
      }

      return verificationResponse;
    } catch (e, stackTrace) {
      AppLogger.error(
        'PAN Verification Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return PanVerificationResponse(
        status: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }

  Future<PanVerificationResponse> manualPANVerification({
    required String panNumber,
    required String firstName,
    required String lastName,
    required String dob,
    required String panPhoneNumber,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        "pannumber": panNumber,
        "firstname": firstName,
        "lastname": lastName,
        "dob": dob,
        "secondaryphonenumber": panPhoneNumber,
      };

      final response = await NetworkAPIHelper().put(
        ApiURLs.PAN_CARD_MANUAL_VERIFICATION,
        data,
      );

      AppLogger.info(
        'Manual PAN Verification Request: ${data.toString()}',
        tag: 'AuthService',
      );

      if (response == null) {
        return PanVerificationResponse(
          status: 0,
          message: 'PAN verification failed.',
          data: null,
        );
      }

      final responseData = jsonDecode(response.body);
      AppLogger.info(
        'Manual PAN Verification Response: ${responseData.toString()}',
        tag: 'AuthService',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final verificationResponse = PanVerificationResponse.fromJson(
          responseData,
        );

        if (verificationResponse.success) {
          await getUserProfile(onLoading: onLoading);
        }

        return verificationResponse;
      } else {
        return PanVerificationResponse(
          status: response.statusCode,
          message: responseData['message'] ?? 'PAN verification failed',
          data: null,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Manual PAN Verification Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return PanVerificationResponse(
        status: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }

  /// Fetch existing PAN profile details if available
  Future<Map<String, dynamic>?> getProfilePan({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.PROFILE_PAN);

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('GET Profile PAN Error', error: e, tag: 'AuthService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  /// Sends Name, PAN, and DOB to trigger Cashfree PAN 360 backend verification.
  Future<PanConsentResponse> verifyPanV1({
    required String pan,
    required String name,
    required String dob,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      // Check if token exists before making API call
      final token = await SecureStorage.read(StorageKeys.AUTH_TOKEN_KEY);
      AppLogger.info(
        'PAN Verification - Token exists: ${token != null}, Token length: ${token?.length ?? 0}',
        tag: 'AuthFlowService',
      );

      final requestBody = {"pan_number": pan, "name": name, "dob": dob};

      final response = await NetworkAPIHelper().post(
        ApiURLs.PROFILE_PAN_VERIFY,
        requestBody,
      );

      AppLogger.info(
        'PAN Consent Request: ${requestBody.toString()}',
        tag: 'PanConsentService',
      );

      if (response == null) {
        return PanConsentResponse(
          statusCode: 0,
          message: 'PAN consent confirmation failed.',
          data: null,
        );
      }

      final responseData = jsonDecode(response.body);
      AppLogger.info(
        'PAN Consent Response: ${responseData.toString()}',
        tag: 'PanConsentService',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final consentResponse = PanConsentResponse.fromJson(responseData);
        return consentResponse;
      } else {
        return PanConsentResponse(
          statusCode: response.statusCode,
          message: responseData['message'] ?? 'PAN consent confirmation failed',
          data: null,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'PAN Consent Confirmation Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'PanConsentService',
      );
      return PanConsentResponse(
        statusCode: 0,
        message: e.toString(),
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }

  Future<SetPinResponse> setPIN({
    required String pin,
    required String phonenumber,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.SET_PIN, {
        "securitypin": pin,
        "phonenumber": phonenumber,
      });

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Update Pin Response: ${responseData.toString()}',
          tag: 'AuthService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final userDataResponse = SetPinResponse.fromJson(responseData);
          return userDataResponse;
        } else {
          return SetPinResponse(
            statusCode: response.statusCode,
            message: responseData['message'] ?? 'Unknown error',
          );
        }
      }
      return SetPinResponse(statusCode: 0, message: 'Unknown error');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update Pin Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return SetPinResponse(statusCode: 0, message: e.toString());
    } finally {
      onLoading(false);
    }
  }

  Future<bool> updateUserField(String fieldName, dynamic value) async {
    try {
      // Get the current user ID
      final userController = Get.find<UserController>();
      final userId = userController.userData?.id;

      if (userId == null) {
        AppLogger.error(
          'Cannot update user field: User ID is null',
          tag: 'AuthService',
        );
        return false;
      }

      // Get Supabase client
      final supabase = Supabase.instance.client;

      // Update the user field in the users table
      await supabase.from('users').update({fieldName: value}).eq('id', userId);

      AppLogger.info(
        'Updated user field $fieldName to $value for user $userId',
        tag: 'AuthService',
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update User Field Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthService',
      );
      return false;
    }
  }
}
