import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/nominee_management.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';

class NomineeManagementService {
  static const String _tag = 'BseOnboardingService';

  /// Creates BSE nominee management response from JSON data
  static BseNomineeManagement _createNomineeResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseNomineeManagement(
      statusCode: jsonData['statusCode'] ?? jsonData['status_code'] ?? 200,
      message: jsonData['message'] ?? jsonData['error'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
      details: jsonData['details'],
    );
  }

  /// Creates fallback BSE nominee management response
  static BseNomineeManagement _createFallbackNomineeResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseNomineeManagement(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new nominees for BSE onboarding
  static Future<BseNomineeManagement?> createNominees(
    List<Map<String, dynamic>> nominees,
  ) async {
    try {
      AppLogger.info('Updating BSE nominees', tag: _tag);

      // Get onboarding ID from secure storage
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found in secure storage', tag: _tag);
        return null;
      }

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final body = {"nominees": nominees};

      AppLogger.info(
        'BSE nominee creation request body: ${json.encode(body)}',
        tag: 'BseOnboardingService',
      );

      final response = await http.post(
        Uri.parse(ApiURLs.BSE_Star_NOMINEES(onboardingId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      AppLogger.info(
        'BSE nominee creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE nominee creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 400 ||
          response.statusCode == 422) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final nomineeResponse =
            ResponseHandler.handleResponse<BseNomineeManagement>(
              response,
              jsonData,
              responseFactory: _createNomineeResponse,
              fallbackFactory: _createFallbackNomineeResponse,
            );

        // Ensure details are passed through for all response types
        if (nomineeResponse != null) {
          nomineeResponse.details = jsonData['details'];
        }

        if (response.statusCode == 400) {
          AppLogger.warning(
            'BSE nominee update returned 400: ${nomineeResponse.message}',
            tag: _tag,
          );
        } else {
          AppLogger.info(
            'BSE nominees updated successfully: ${nomineeResponse.message}',
            tag: _tag,
          );
        }
        return nomineeResponse;
      } else {
        AppLogger.error(
          'Failed to update BSE nominees: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createNominees: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Deletes a nominee for BSE onboarding
  static Future<bool> deleteNominee(String nomineeId) async {
    try {
      AppLogger.info('Deleting BSE nominee: $nomineeId', tag: _tag);

      // Get onboarding ID from secure storage
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found in secure storage', tag: _tag);
        return false;
      }

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return false;
      }

      final response = await http.delete(
        Uri.parse(ApiURLs.BSE_Star_DELETE_NOMINEE(onboardingId, nomineeId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE nominee deletion API response: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in deleteNominee: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
