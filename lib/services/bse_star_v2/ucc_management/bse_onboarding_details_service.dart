import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseOnboardingDetailsService {
  static const String _tag = 'BseOnboardingDetailsService';

  /// Creates BSE onboarding full response from JSON data
  static BseOnboardingResponse _createOnboardingResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseOnboardingResponse.fromJson(jsonData);
  }

  /// Creates fallback BSE onboarding full response
  static BseOnboardingResponse _createFallbackOnboardingResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseOnboardingResponse(
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Fetches the full BSE onboarding details
  static Future<BseOnboardingResponse?> getOnboardingDetails({
    required String onboardingId,
  }) async {
    // Suppressing this call during V1 migration to prevent 401 errors from atom backend.
    AppLogger.info('Skipping BSE onboarding details fetch on atom (V1 Migration)', tag: _tag);
    return null;

    /*
    try {
      AppLogger.info(
        'Fetching full BSE onboarding details for: $onboardingId',
        tag: _tag,
      );

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiURLs.BSE_Star_GET_BSE_ONBOARDING(onboardingId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE onboarding details API response: ${response.statusCode}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ResponseHandler.handleResponse<BseOnboardingResponse>(
          response,
          jsonData,
          responseFactory: _createOnboardingResponse,
          fallbackFactory: _createFallbackOnboardingResponse,
        );
      } else {
        AppLogger.error(
          'Failed to fetch BSE onboarding details: ${response.statusCode} - ${response.body}',
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
            message: 'Failed to fetch onboarding details',
            responseFactory: _createFallbackOnboardingResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getOnboardingDetails: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
    */
  }
}
