import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/fetch-holdings/types/mf_fetching.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MFOnboardingService {
  // Static variables to store retry information
  static String? _retryPhoneNumber;
  static String? _retryStage;
  
  // Method to set retry information
  static void setRetryInfo({String? phoneNumber, String? stage}) {
    _retryPhoneNumber = phoneNumber;
    _retryStage = stage;
    AppLogger.info(
      'MF Retry info set - Phone: $phoneNumber, Stage: $stage',
      tag: 'MFOnboardingService',
    );
  }
  
  // Method to clear retry information
  static void clearRetryInfo() {
    _retryPhoneNumber = null;
    _retryStage = null;
    AppLogger.info('MF Retry info cleared', tag: 'MFOnboardingService');
  }
  
  // Method to check if retry information exists
  static bool hasRetryInfo() {
    return _retryPhoneNumber != null || _retryStage != null;
  }

  Future<MfCentralOtpResponse> sendOTP({
    String? phoneNumber,
    String? panNumber,
    String? stage,
    bool forcePrimary = false, // Force primary stage for fresh starts
    required Function(bool isLoading) onLoading,
    required Function(String message, int statusCode, String? stage, String? panNumber) onError,
  }) async {
    onLoading(true);

    try {
      // Build request body with phone number, PAN, and stage if provided
      // Use stored retry info if no parameters are provided, unless forcePrimary is true
      final Map<String, dynamic> requestBody = {};
      
      final effectivePhoneNumber = phoneNumber ?? (forcePrimary ? null : _retryPhoneNumber);
      final effectiveStage = forcePrimary ? "primary" : (stage ?? _retryStage);
      
      if (effectivePhoneNumber != null && effectivePhoneNumber.isNotEmpty) {
        requestBody['phone_number'] = effectivePhoneNumber;
      }
      // if (panNumber != null && panNumber.isNotEmpty) {
      //   requestBody['panNumber'] = panNumber;
      // }
      if (effectiveStage != null && effectiveStage.isNotEmpty) {
        requestBody['phone_type'] = effectiveStage;
      } else if (forcePrimary || (effectiveStage == null && effectivePhoneNumber == null)) {
        // Always pass primary if forcePrimary is true or if no stage/phone info available
        requestBody['phone_type'] = "primary";
      }
      
      AppLogger.info(
        'MF OTP Request Body: ${requestBody.toString()}',
        tag: 'MFOnboardingServiceOTPRequestBody',
      );
      
      final response = await NetworkAPIHelper().post(
        ApiURLs.MF_HOLDINGS_TOKEN,
        requestBody,
      );
      AppLogger.info(
        'MF OTP Responses: ${response?.body.toString()}',
        tag: 'MFOnboardingService',
      );
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'MF OTP Response: ${responseData.toString()}',
          tag: 'MFOnboardingService',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return MfCentralOtpResponse.fromJson(responseData);
        } else {
          final message = responseData['message'] ?? 'Failed to send OTP';
          final error = responseData['error'] as String?;
          final stage = responseData['stage'] as String?;
          final panNumber = responseData['pannumber'] as String?;
          
          // Combine message and error field content
          String combinedErrorMessage = message;
          if (error != null && error.isNotEmpty && error != message) {
            combinedErrorMessage = '$message ($error)';
          }
          
          onError(combinedErrorMessage, response.statusCode, stage, panNumber);
          return MfCentralOtpResponse(
            status: response.statusCode,
            message: combinedErrorMessage,
          );
        }
      }

      const errorMessage = 'Network error occurred';
      onError(errorMessage, 500, null, null);
      return MfCentralOtpResponse(status: 0, message: errorMessage);
    } catch (e, stackTrace) {
      AppLogger.error(
        'MF OTP Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'MFOnboardingService',
      );
      const errorMessage = 'An unexpected error occurred';
      onError(errorMessage, 500, null, null);
      return MfCentralOtpResponse(status: 0, message: errorMessage);
    } finally {
      onLoading(false);
    }
  }

  Future<MfCentralVerifyOtpResponse?> verifyOTP({
    required String token,
    required DecryptedCASDetails casDetails,
    required String otp,
    required Function(bool isLoading) onLoading,
    required Function(String message, int statusCode) onError,
  }) async {
    onLoading(true);

    try {
      final body = {
        "reqId": casDetails.reqId,
        "otpRef": casDetails.otpRef,
        "userSubjectReference": "",
        "clientRefNo": casDetails.clientRefNo,
        "enteredOtp": otp,
        "token": token,
      };

      AppLogger.info('Verifying MF OTP: $body', tag: 'MFOnboardingService');

      final response = await NetworkAPIHelper().post(
        ApiURLs.MF_HOLDINGS_VERIFY,
        body,
      );
      print(response.toString());
      AppLogger.info(
        'MF OTP Verification Response: ${response?.statusCode.toString()}',
        tag: 'MFOnboardingService1112',
      );

      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'MF OTP Verification Response: ${responseData.toString()}',
          tag: 'MFOnboardingService',
        );

        return MfCentralVerifyOtpResponse.fromJson(responseData);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'MF OTP Verification Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'MFOnboardingService',
      );
      onError('An unexpected error occurred', 500);
      return MfCentralVerifyOtpResponse(
        status: 0,
        message: 'An unexpected error occurred',
      );
    } finally {
      onLoading(false);
    }
    return null;
  }
}
