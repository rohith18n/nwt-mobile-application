import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_address_management.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';

class AddressManagementService {
  static const String _tag = 'BseOnboardingService';

  /// Creates BSE address management response from JSON data
  static BseAddressManagement _createAddressResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseAddressManagement(
      statusCode: jsonData['statusCode'] ?? 200,
      message: jsonData['message'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
    );
  }

  /// Creates fallback BSE address management response
  static BseAddressManagement _createFallbackAddressResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseAddressManagement(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new address for BSE onboarding
  static Future<BseAddressManagement?> createAddress({
    required String line1,
    required String line2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    String addressType =
        "RESIDENTIAL", // Default to "RESIDENTIAL" for Residential or Business
  }) async {
    try {
      AppLogger.info('Creating BSE address', tag: _tag);

      // Get onboarding ID from secure storage
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found in secure storage', tag: _tag);
        return null;
      }

      // Get primary holder ID from secure storage
      final holderId = await SecureStorage.read('primary_holder_id');
      if (holderId == null) {
        AppLogger.error(
          'No primary holder ID found in secure storage',
          tag: _tag,
        );
        return null;
      }

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Map the address data
      final addressData = {
        "address_type": addressType,
        "line1": line1,
        "line2": line2,
        "city": city,
        "state": state,
        "country": country,
        "postal_code": postalCode,
      };

      AppLogger.info(
        'BSE address creation request body: ${json.encode(addressData)}',
        tag: 'BseOnboardingService',
      );

      final response = await http.post(
        Uri.parse(ApiURLs.BSE_Star_CREATE_ADDRESS(onboardingId, holderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(addressData),
      );

      AppLogger.info(
        'BSE address creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE address creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final addressResponse =
            ResponseHandler.handleResponse<BseAddressManagement>(
              response,
              jsonData,
              responseFactory: _createAddressResponse,
              fallbackFactory: _createFallbackAddressResponse,
            );

        AppLogger.info(
          'BSE address created successfully: ${addressResponse.message}',
          tag: _tag,
        );
        return addressResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE address: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ResponseHandler.handleResponse<BseAddressManagement>(
            response,
            jsonData,
            responseFactory: _createAddressResponse,
            fallbackFactory: _createFallbackAddressResponse,
          );
        } catch (_) {
          return ResponseHandler.createFallbackResponse<BseAddressManagement>(
            statusCode: response.statusCode,
            message: 'Failed to create address',
            responseFactory: _createFallbackAddressResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createAddress: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<BseAddressManagement?> updateAddress({
    required String line1,
    required String line2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    String addressType = "RESIDENTIAL",
  }) async {
    return createAddress(
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      addressType: addressType,
    );
  }

  /// Deletes an address for BSE onboarding
  static Future<bool> deleteAddress(String addressId) async {
    try {
      AppLogger.info('Deleting BSE address: $addressId', tag: _tag);

      // Get onboarding ID from secure storage
      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        AppLogger.error('No onboarding ID found in secure storage', tag: _tag);
        return false;
      }

      // Get holder ID from secure storage
      final holderId = await SecureStorage.read('primary_holder_id');
      if (holderId == null) {
        AppLogger.error(
          'No primary holder ID found in secure storage',
          tag: _tag,
        );
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
        Uri.parse(
          ApiURLs.BSE_Star_DELETE_ADDRESS(onboardingId, holderId, addressId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE address deletion API response: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in deleteAddress: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
