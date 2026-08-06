import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_fatca_management.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';

class FatcaManagementService {
  static const String _tag = 'BseOnboardingService';

  /// Creates BSE FATCA management response from JSON data
  static BseFatcaManagement _createFatcaResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseFatcaManagement(
      statusCode: jsonData['statusCode'] ?? 200,
      message: jsonData['message'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
    );
  }

  /// Creates fallback BSE FATCA management response
  static BseFatcaManagement _createFallbackFatcaResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseFatcaManagement(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new FATCA details for BSE onboarding
  static Future<BseFatcaManagement?> createFatcaDetails({
    required String fatherName,
    required String motherName,
    required String occupationCode,
    required String annualIncome,
    required String sourceOfWealth,
    required String maritalStatus,
    required String nationality,
    required String placeOfBirth,
    required String countryOfBirth,
    required String taxResidence,
    String? tin,
  }) async {
    try {
      AppLogger.info('Updating BSE personal details', tag: _tag);

      // Get onboarding ID from secure storage
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found in secure storage', tag: _tag);
        return null;
      }

      // Get holder ID from secure storage
      final holderId = await SecureStorage.read('primary_holder_id');
      if (holderId == null) {
        AppLogger.error('No holder ID found in secure storage', tag: _tag);
        return null;
      }

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Map the FATCA data - Only including fields requested by user
      final fatcaData = {
        "father_name": fatherName,
        "mother_name": motherName,
        "occupation_code": occupationCode,
        "annual_income": annualIncome,
        "source_of_wealth": sourceOfWealth,
        "marital_status": maritalStatus,
        "nationality": nationality,
        "place_of_birth": placeOfBirth,
        "country_of_birth": countryOfBirth,
        "tax_residence": taxResidence,
        "tin": tin,
      };

      AppLogger.info(
        'BSE FATCA creation request body: ${json.encode(fatcaData)}',
        tag: 'BseOnboardingService',
      );

      final response = await http.post(
        Uri.parse(ApiURLs.BSE_Star_FATCA(onboardingId, holderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(fatcaData),
      );

      AppLogger.info(
        'BSE FATCA creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE FATCA creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final fatcaResponse =
            ResponseHandler.handleResponse<BseFatcaManagement>(
              response,
              jsonData,
              responseFactory: _createFatcaResponse,
              fallbackFactory: _createFallbackFatcaResponse,
            );

        AppLogger.info(
          'BSE FATCA created successfully: ${fatcaResponse.message}',
          tag: _tag,
        );
        return fatcaResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE FATCA: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ResponseHandler.handleResponse<BseFatcaManagement>(
            response,
            jsonData,
            responseFactory: _createFatcaResponse,
            fallbackFactory: _createFallbackFatcaResponse,
          );
        } catch (_) {
          return ResponseHandler.createFallbackResponse<BseFatcaManagement>(
            statusCode: response.statusCode,
            message: 'Failed to add Personal details',
            responseFactory: _createFallbackFatcaResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createFatcaDetails: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Updates existing Personal details for BSE onboarding
  static Future<BseFatcaManagement?> updatePersonalDetails({
    required String fatherName,
    required String motherName,
    required String occupationCode,
    required String annualIncome,
    required String sourceOfWealth,
    required String maritalStatus,
    required String nationality,
    required String placeOfBirth,
    required String countryOfBirth,
    required String taxResidence,
    String? tin,
  }) async {
    return createFatcaDetails(
      fatherName: fatherName,
      motherName: motherName,
      occupationCode: occupationCode,
      annualIncome: annualIncome,
      sourceOfWealth: sourceOfWealth,
      maritalStatus: maritalStatus,
      nationality: nationality,
      placeOfBirth: placeOfBirth,
      countryOfBirth: countryOfBirth,
      taxResidence: taxResidence,
      tin: tin,
    );
  }
}
