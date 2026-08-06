import 'dart:convert';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star/types/ucc_creation_response.dart';
import 'package:nwt_app/screens/bse_star/types/ucc_status_response.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class BseUccCreationService {
  /// Gets the UCC creation status from BSE Star API
  Future<UccResponse> getUccResponse({
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.GET_BSE_UCC_STATUS);
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Get BSE UCC Status Response: ${responseData.toString()}',
          tag: 'BseUccCreationService',
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return UccResponse.fromJson(responseData);
        } else {
          return UccResponse(
            message: responseData['message'] ?? 'Unknown error',
            data: null,
          );
        }
      }
      return UccResponse(
        message: 'Unknown error',
        data: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Get BSE UCC Status Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'BseUccCreationService',
      );
      return UccResponse(
        message: 'An unexpected error occurred',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }

  /// Checks detailed UCC status from BSE Star API (New)
  Future<UccStatusResponse?> checkUccStatus() async {
    try {
      final response = await NetworkAPIHelper().get(ApiURLs.BSE_UCC_STATUS_CHECK());

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Check BSE UCC Status Response: ${responseData.toString()}',
          tag: 'BseUccCreationService',
        );
        return UccStatusResponse.fromJson(responseData);
      } else if (response != null && response.statusCode == 404) {
        AppLogger.info(
          'UCC status endpoint not available (404) - endpoint may be disabled',
          tag: 'BseUccCreationService',
        );
        return null;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Check BSE UCC Status Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'BseUccCreationService',
      );
      return UccStatusResponse(
        status: 'error',
        messages: e.toString(),
      );
    }
  }

  /// Registers UCC data with BSE Star API
  Future<UccResponse> registerUcc({
    required Map<String, dynamic> uccData,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      AppLogger.info('UCC Data: ${jsonEncode(uccData)}', tag: 'BseUccCreationService');

      final response = await NetworkAPIHelper().post(
        ApiURLs.GET_BSE_UCC_REGISTER,
        jsonEncode(uccData),
      );

      AppLogger.info(
        'UCC Response: ${response?.body}',
        tag: 'BseUccCreationService',
      );
      
      if (response != null) {
        final responseData = jsonDecode(response.body);
        AppLogger.info(
          'Register BSE UCC Response: ${responseData.toString()}',
          tag: 'BseUccCreationService',
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return UccResponse.fromJson(responseData);
        } else {
          return UccResponse(
            message: responseData['message'] ?? 'Failed to register UCC',
            data: null,
          );
        }
      } else {
        return UccResponse(
          message: 'No response from server',
          data: null,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Register BSE UCC Error',
        error: e,
        stackTrace: stackTrace,
        tag: 'BseUccCreationService',
      );
      return UccResponse(
        message: 'Error: ${e.toString()}',
        data: null,
      );
    } finally {
      onLoading(false);
    }
  }

  /// Creates a new investment account (UCC) with nominees (v1)
  Future<Map<String, dynamic>?> createAccount({
    required String accounts, // 'si', 'as', 'both'
    String? secondaryUserId,
    Map<String, dynamic>? extendedProfile,
    Map<String, dynamic>? nomination,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        "accounts": accounts,
        if (secondaryUserId != null) "secondary_user_id": secondaryUserId,
        if (extendedProfile != null) "extended_profile": extendedProfile,
        if (nomination != null) "nomination": nomination,
      };

      final response = await NetworkAPIHelper().post(ApiURLs.ACCOUNT_CREATE, data);
      if (response != null) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      AppLogger.error('Create Account Error', error: e, tag: 'BseUccCreationService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  /// Creates a new investment account (UCC) without nominees (v1)
  Future<Map<String, dynamic>?> createAccountWithoutNominee({
    required String accounts,
    String? secondaryUserId,
    Map<String, dynamic>? extendedProfile,
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final data = {
        "accounts": accounts,
        if (secondaryUserId != null) "secondary_user_id": secondaryUserId,
        if (extendedProfile != null) "extended_profile": extendedProfile,
      };

      final response = await NetworkAPIHelper().post(ApiURLs.ACCOUNT_CREATE_WITHOUT_NOMINEE, data);
      if (response != null) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      AppLogger.error('Create Account Without Nominee Error', error: e, tag: 'BseUccCreationService');
      return null;
    } finally {
      onLoading(false);
    }
  }

  /// Verifies account creation or nominee opt-out via OTP (v1)
  Future<Map<String, dynamic>?> verifyAccountOtp({
    required String clientCode,
    required String otp,
    required String purpose, // 'bse' or 'nominee_opt_out'
    required Function(bool isLoading) onLoading,
  }) async {
    onLoading(true);
    try {
      final response = await NetworkAPIHelper().post(ApiURLs.ACCOUNT_OTP_VERIFY, {
        "client_code": clientCode,
        "otp": otp,
        "purpose": purpose,
      });
      if (response != null) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      AppLogger.error('Verify Account OTP Error', error: e, tag: 'BseUccCreationService');
      return null;
    } finally {
      onLoading(false);
    }
  }
}
