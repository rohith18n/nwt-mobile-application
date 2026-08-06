import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';

class BseOnboardingService {
  static const String _tag = 'BseOnboardingService';

  /// Creates BSE onboarding response from JSON data
  static BseOnboardingResponse _createOnboardingResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseOnboardingResponse(
      statusCode: jsonData['statusCode'] ?? 200,
      message: jsonData['message'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
    );
  }

  /// Creates fallback BSE onboarding response
  static BseOnboardingResponse _createFallbackOnboardingResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseOnboardingResponse(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new BSE onboarding record
  static Future<BseOnboardingResponse?> createOnboarding() async {
    // Suppressing this call during V1 migration to prevent 401 errors from atom backend.
    // The onboarding flow is currently driven by the testing backend.
    AppLogger.info(
      'Skipping BSE onboarding creation on atom (V1 Migration)',
      tag: _tag,
    );
    return null;

    /* 
    try {
      AppLogger.info('Creating BSE onboarding record', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final onboardingData = {"source_channel": "APP"};

      final response = await http.post(
        Uri.parse(ApiURLs.BSE_Star_ONBOARDING),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(onboardingData),
      );

      AppLogger.info(
        'BSE onboarding creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE onboarding creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final onboardingResponse =
            ResponseHandler.handleResponse<BseOnboardingResponse>(
              response,
              jsonData,
              responseFactory: _createOnboardingResponse,
              fallbackFactory: _createFallbackOnboardingResponse,
            );

        // Store onboarding ID in secure storage if data exists
        if (onboardingResponse.data?.id != null) {
          try {
            await SecureStorage.write(
              'bse_onboarding_id',
              onboardingResponse.data!.id,
            );
            AppLogger.info(
              'Stored BSE onboarding ID in secure storage: ${onboardingResponse.data!.id}',
              tag: _tag,
            );
          } catch (e) {
            AppLogger.error(
              'Failed to store onboarding ID in secure storage: $e',
              tag: _tag,
            );
          }
        }

        AppLogger.info(
          'BSE onboarding created successfully: ${onboardingResponse.message}',
          tag: _tag,
        );
        return onboardingResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE onboarding: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ResponseHandler.handleResponse<BseOnboardingResponse>(
            response,
            jsonData,
            responseFactory: _createOnboardingResponse,
            fallbackFactory: _createFallbackOnboardingResponse,
          );
        } catch (_) {
          return ResponseHandler.createFallbackResponse<BseOnboardingResponse>(
            statusCode: response.statusCode,
            message: 'Failed to create onboarding record',
            responseFactory: _createFallbackOnboardingResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createOnboarding: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
    */
  }

  /// Deletes the complete onboarding journey
  static Future<bool> deleteOnboarding(String onboardingId) async {
    try {
      AppLogger.info(
        'Deleting BSE onboarding journey: $onboardingId',
        tag: _tag,
      );

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return false;
      }

      final response = await http.delete(
        Uri.parse(ApiURLs.BSE_Star_DELETE_ONBOARDING(onboardingId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE onboarding deletion API response: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in deleteOnboarding: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
