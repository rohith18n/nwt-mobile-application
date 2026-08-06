import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bank_management.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';

class BankManagementService {
  static const String _tag = 'BseOnboardingService';

  /// Creates BSE bank management response from JSON data
  static BseBankManagement _createBankResponse(Map<String, dynamic> jsonData) {
    return BseBankManagement(
      statusCode: jsonData['statusCode'] ?? 200,
      message: jsonData['message'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
    );
  }

  /// Creates fallback BSE bank management response
  static BseBankManagement _createFallbackBankResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseBankManagement(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new bank account for BSE onboarding
  static Future<BseBankManagement?> createBank({
    required String bankName,
    required String ifscCode,
    required String accountNumber,
    required String accountType,
    required String accountHolderName,
    String bankCountry = 'IND',
    bool setAsPrimary = true,
  }) async {
    try {
      AppLogger.info('Creating BSE bank account', tag: _tag);

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

      // Map the bank data
      // Map to v1 bank_details payload
      final bankData = {
        "bank_name": bankName,
        "ifsc_code": ifscCode,
        "account_number": accountNumber,
        "bank_type": accountType, // v1 expects 'bank_type'
        "account_holder_name": accountHolderName,
      };

      AppLogger.info(
        'BSE bank creation request body: ${json.encode(bankData)}',
        tag: 'BseOnboardingService',
      );

      final response = await http.post(
        Uri.parse(ApiURLs.PROFILE_BANK_DETAILS),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bankData),
      );

      AppLogger.info(
        'BSE bank creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info('BSE bank creation API body: ${response.body}', tag: _tag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final bankResponse = ResponseHandler.handleResponse<BseBankManagement>(
          response,
          jsonData,
          responseFactory: _createBankResponse,
          fallbackFactory: _createFallbackBankResponse,
        );

        AppLogger.info(
          'BSE bank account created successfully: ${bankResponse.message}',
          tag: _tag,
        );
        return bankResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE bank account: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          // If the API returns a standard error JSON
          String? errorMessage;
          if (jsonData.containsKey('detail')) {
            errorMessage = jsonData['detail'];
          } else if (jsonData.containsKey('message')) {
            errorMessage = jsonData['message'];
          }

          return ResponseHandler.handleResponse<BseBankManagement>(
            response,
            jsonData,
            responseFactory: _createBankResponse,
            fallbackFactory:
                (status, msg, data) => _createFallbackBankResponse(
                  status,
                  errorMessage ?? msg,
                  data,
                ),
          );
        } catch (_) {
          return ResponseHandler.createFallbackResponse<BseBankManagement>(
            statusCode: response.statusCode,
            message: 'Failed to create bank account',
            responseFactory: _createFallbackBankResponse,
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createBank: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Updates existing bank account for BSE onboarding
  static Future<BseBankManagement?> updateBank({
    required String bankName,
    required String ifscCode,
    required String accountNumber,
    required String accountType,
    required String accountHolderName,
    String bankCountry = 'IND',
    bool setAsPrimary = true,
  }) async {
    return createBank(
      bankName: bankName,
      ifscCode: ifscCode,
      accountNumber: accountNumber,
      accountType: accountType,
      accountHolderName: accountHolderName,
      bankCountry: bankCountry,
      setAsPrimary: setAsPrimary,
    );
  }

  /// Deletes a bank account for BSE onboarding
  static Future<bool> deleteBank(String bankId) async {
    try {
      AppLogger.info('Deleting BSE bank account: $bankId', tag: _tag);

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
        Uri.parse(ApiURLs.BSE_Star_DELETE_BANK(onboardingId, bankId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE bank deletion API response: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in deleteBank: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
