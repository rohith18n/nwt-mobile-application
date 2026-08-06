import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/holder_management.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';

class HolderManagementService {
  static const String _tag = 'BseOnboardingService';

  /// Creates BSE holder management response from JSON data
  static BseHolderManagement _createHolderResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseHolderManagement(
      statusCode: jsonData['statusCode'] ?? 200,
      message: jsonData['message'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
    );
  }

  /// Creates fallback BSE holder management response
  static BseHolderManagement _createFallbackHolderResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseHolderManagement(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new holder for BSE onboarding
  static Future<BseHolderManagement?> createHolder({
    required String firstName,
    String? middleName,
    required String lastName,
    required String pan,
    required String dob,
    required String gender,
    required String phone,
    required String email,
    required String pep,
    required String countryCode,
    required String taxStatus,
    required int holderRank,
    String? ckycNumber,
    String? communicationMode,
  }) async {
    try {
      AppLogger.info('Creating BSE holder', tag: _tag);

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

      final holderData = {
        "first_name": firstName.toUpperCase(),
        "middle_name": (middleName != null && middleName.isNotEmpty)
            ? middleName.toUpperCase()
            : null,
        "last_name": lastName.toUpperCase(),
        "pan": pan.toUpperCase(),
        "dob": dob,
        "gender": gender,
        "phone": "+$countryCode$phone",
        "email": email,
        "tax_status": taxStatus,
        "politically_exposed_person": pep,
        "communication_mode": "E", // Default to Electronic (Email)
        "holder_rank": holderRank,
      };

      AppLogger.info(
        'BSE holder creation request body: ${json.encode(holderData)}',
        tag: 'BseOnboardingService',
      );

      final response = await http.post(
        Uri.parse(ApiURLs.BSE_Star_CREATE_HOLDER(onboardingId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(holderData),
      );

      AppLogger.info(
        'BSE holder creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE holder creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final holderResponse =
            ResponseHandler.handleResponse<BseHolderManagement>(
              response,
              jsonData,
              responseFactory: _createHolderResponse,
              fallbackFactory: _createFallbackHolderResponse,
            );

        // Store primary holder ID in secure storage if data exists
        if (holderResponse.data?.id != null) {
          try {
            await SecureStorage.write(
              'primary_holder_id',
              holderResponse.data!.id!,
            );
            AppLogger.info(
              'Stored primary holder ID in secure storage: ${holderResponse.data!.id}',
              tag: _tag,
            );
          } catch (e) {
            AppLogger.error(
              'Failed to store primary holder ID in secure storage: $e',
              tag: _tag,
            );
          }
        }

        AppLogger.info(
          'BSE holder created successfully: ${holderResponse.message}',
          tag: _tag,
        );
        return holderResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE holder: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ResponseHandler.handleResponse<BseHolderManagement>(
            response,
            jsonData,
            responseFactory: _createHolderResponse,
            fallbackFactory: _createFallbackHolderResponse,
          );
        } catch (_) {
          return ResponseHandler.createFallbackResponse<BseHolderManagement>(
            statusCode: response.statusCode,
            message: 'Failed to create holder',
            responseFactory: _createFallbackHolderResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createHolder: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Updates an existing holder for BSE onboarding
  static Future<BseHolderManagement?> updateHolder({
    required String firstName,
    String? middleName,
    required String lastName,
    required String pan,
    required String dob,
    required String gender,
    required String phone,
    required String email,
    required String pep,
    required String countryCode,
    required String taxStatus,
    String? ckycNumber,
    String? communicationMode,
  }) async {
    try {
      AppLogger.info('Updating BSE holder information', tag: _tag);

      // Get onboarding ID from secure storage
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found in secure storage', tag: _tag);
        return null;
      }

      // Get holder ID from secure storage
      final holderId = await SecureStorage.read('primary_holder_id');
      if (holderId == null) {
        AppLogger.error('No primary holder ID found in secure storage', tag: _tag);
        return null;
      }

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Payload for update - Exclude holder_rank as it cannot be changed
      final holderData = {
        "first_name": firstName.toUpperCase(),
        "middle_name": (middleName != null && middleName.isNotEmpty)
            ? middleName.toUpperCase()
            : null,
        "last_name": lastName.toUpperCase(),
        "pan": pan.toUpperCase(),
        "dob": dob,
        "gender": gender,
        "phone": "+$countryCode$phone",
        "email": email,
        "tax_status": taxStatus,
        "politically_exposed_person": pep,
        if (ckycNumber != null) "ckyc_number": ckycNumber,
        if (communicationMode != null) "communication_mode": communicationMode,
      };

      AppLogger.info(
        'BSE holder update request body: ${json.encode(holderData)}',
        tag: 'BseOnboardingService',
      );

      final response = await http.put(
        Uri.parse(ApiURLs.BSE_Star_UPDATE_HOLDER(onboardingId, holderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(holderData),
      );

      AppLogger.info(
        'BSE holder update API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE holder update API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final holderResponse =
            ResponseHandler.handleResponse<BseHolderManagement>(
              response,
              jsonData,
              responseFactory: _createHolderResponse,
              fallbackFactory: _createFallbackHolderResponse,
            );

        AppLogger.info(
          'BSE holder updated successfully: ${holderResponse.message}',
          tag: _tag,
        );
        return holderResponse;
      } else {
        AppLogger.error(
          'Failed to update BSE holder: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ResponseHandler.handleResponse<BseHolderManagement>(
            response,
            jsonData,
            responseFactory: _createHolderResponse,
            fallbackFactory: _createFallbackHolderResponse,
          );
        } catch (_) {
          return ResponseHandler.createFallbackResponse<BseHolderManagement>(
            statusCode: response.statusCode,
            message: 'Failed to update holder information',
            responseFactory: _createFallbackHolderResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in updateHolder: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Deletes a holder for BSE onboarding
  static Future<bool> deleteHolder(String holderId) async {
    try {
      AppLogger.info('Deleting BSE holder: $holderId', tag: _tag);

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
        Uri.parse(ApiURLs.BSE_Star_DELETE_HOLDER(onboardingId, holderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE holder deletion API response: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in deleteHolder: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes personal details (FATCA) for BSE onboarding
  static Future<bool> deletePersonalDetails(String holderId) async {
    try {
      AppLogger.info(
        'Deleting BSE personal details for holder: $holderId',
        tag: _tag,
      );

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
        Uri.parse(ApiURLs.BSE_Star_FATCA(onboardingId, holderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE personal details deletion API response: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in deletePersonalDetails: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
