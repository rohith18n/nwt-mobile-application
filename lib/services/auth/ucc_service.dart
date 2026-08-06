import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/network_api_helper.dart';
import 'package:nwt_app/utils/logger.dart';

/// Response model for UCC account creation
class UCCAccountResponse {
  final bool success;
  final String message;
  final UCCAccountData? data;

  UCCAccountResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UCCAccountResponse.fromJson(Map<String, dynamic> json) {
    return UCCAccountResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UCCAccountData.fromJson(json['data']) : null,
    );
  }
}

class UCCAccountData {
  final List<UCCAccount> accounts;

  UCCAccountData({required this.accounts});

  factory UCCAccountData.fromJson(Map<String, dynamic> json) {
    final accountsList = json['accounts'] as List? ?? [];
    return UCCAccountData(
      accounts: accountsList
          .map((account) => UCCAccount.fromJson(account as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UCCAccount {
  final String holdingNature;
  final String clientCode;

  UCCAccount({
    required this.holdingNature,
    required this.clientCode,
  });

  factory UCCAccount.fromJson(Map<String, dynamic> json) {
    return UCCAccount(
      holdingNature: json['holding_nature'] ?? '',
      clientCode: json['client_code'] ?? '',
    );
  }
}

/// Response model for OTP verification
class UCCOTPResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  UCCOTPResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UCCOTPResponse.fromJson(Map<String, dynamic> json) {
    return UCCOTPResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Service for UCC (Uniform Client Code) account creation and management
class UCCService {
  /// Create UCC account with nominees
  /// 
  /// [accounts] - Account type: "si", "as", or "both"
  /// [nomination] - Nomination data with choice and nominees list
  /// [secondaryUserId] - Legacy parameter for secondary user ID
  /// [secondaryHolder] - Secondary holder data (required for "as" or "both" accounts)
  Future<UCCAccountResponse?> createAccount({
    required String accounts,
    required Map<String, dynamic> nomination,
    String? secondaryUserId,
    Map<String, dynamic>? secondaryHolder,
  }) async {
    try {
      AppLogger.info(
        'Creating UCC account with nominees: $accounts',
        tag: 'UCCService',
      );

      final body = <String, dynamic>{
        'accounts': accounts,
        'nomination': nomination,
      };

      if (secondaryHolder != null) {
        body['secondary_holder'] = secondaryHolder;
      } else if (secondaryUserId != null) {
        body['secondary_user_id'] = secondaryUserId;
      }

      AppLogger.info(
        'UCC creation payload: ${jsonEncode(body)}',
        tag: 'UCCService',
      );

      // Log exact payload being sent to API
      AppLogger.info(
        '📤 EXACT PAYLOAD BEING SENT TO CREATE ACCOUNT API:',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Endpoint: ${ApiURLs.ACCOUNT_CREATE}',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Payload:\n${const JsonEncoder.withIndent('  ').convert(body)}',
        tag: 'bse_journey_final',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.ACCOUNT_CREATE,
        body,
      );

      if (response != null) {
        final jsonResponse = jsonDecode(response.body);
        
        AppLogger.info(
          'UCC creation response: ${jsonEncode(jsonResponse)}',
          tag: 'UCCService',
        );

        return UCCAccountResponse.fromJson(jsonResponse);
      }

      return null;
    } catch (e) {
      AppLogger.error(
        'Error creating UCC account',
        error: e,
        tag: 'UCCService',
      );
      return null;
    }
  }

  /// Create UCC account without nominees (opt-out)
  /// 
  /// [accounts] - Account type: "si", "as", or "both"
  /// [secondaryUserId] - Legacy parameter for secondary user ID
  /// [secondaryHolder] - Secondary holder data (required for "as" or "both" accounts)
  Future<UCCAccountResponse?> createAccountWithoutNominee({
    required String accounts,
    String? secondaryUserId,
    Map<String, dynamic>? secondaryHolder,
  }) async {
    try {
      AppLogger.info(
        'Creating UCC account without nominees: $accounts',
        tag: 'UCCService',
      );

      final body = <String, dynamic>{
        'accounts': accounts,
      };

      if (secondaryHolder != null) {
        body['secondary_holder'] = secondaryHolder;
      } else if (secondaryUserId != null) {
        body['secondary_user_id'] = secondaryUserId;
      }

      AppLogger.info(
        'UCC creation (no nominee) payload: ${jsonEncode(body)}',
        tag: 'UCCService',
      );

      // Log exact payload being sent to API
      AppLogger.info(
        '📤 EXACT PAYLOAD BEING SENT TO CREATE ACCOUNT WITHOUT NOMINEE API:',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Endpoint: ${ApiURLs.ACCOUNT_CREATE_WITHOUT_NOMINEE}',
        tag: 'bse_journey_final',
      );
      AppLogger.info(
        'Payload:\n${const JsonEncoder.withIndent('  ').convert(body)}',
        tag: 'bse_journey_final',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.ACCOUNT_CREATE_WITHOUT_NOMINEE,
        body,
      );

      if (response != null) {
        final jsonResponse = jsonDecode(response.body);
        
        AppLogger.info(
          'UCC creation (no nominee) response: ${jsonEncode(jsonResponse)}',
          tag: 'UCCService',
        );

        return UCCAccountResponse.fromJson(jsonResponse);
      }

      return null;
    } catch (e) {
      AppLogger.error(
        'Error creating UCC account without nominee',
        error: e,
        tag: 'UCCService',
      );
      return null;
    }
  }

  /// Verify OTP for UCC account
  /// 
  /// [clientCode] - Client code from account creation response
  /// [otp] - OTP code from email
  /// [purpose] - "nominee_opt_out", "opt_out", "nominee_optout", "bse", "bse_submit", or "exchange"
  Future<UCCOTPResponse?> verifyOTP({
    required String clientCode,
    required String otp,
    required String purpose,
  }) async {
    try {
      AppLogger.info(
        'Verifying OTP for client_code: $clientCode, purpose: $purpose',
        tag: 'UCCService',
      );

      final body = {
        'client_code': clientCode,
        'otp': otp,
        'purpose': purpose,
      };

      AppLogger.info(
        'OTP verification payload: ${jsonEncode(body)}',
        tag: 'UCCService',
      );

      final response = await NetworkAPIHelper().post(
        ApiURLs.ACCOUNT_OTP_VERIFY,
        body,
      );

      if (response != null) {
        final jsonResponse = jsonDecode(response.body);
        
        AppLogger.info(
          'OTP verification response: ${jsonEncode(jsonResponse)}',
          tag: 'UCCService',
        );

        return UCCOTPResponse.fromJson(jsonResponse);
      }

      return null;
    } catch (e) {
      AppLogger.error(
        'Error verifying OTP',
        error: e,
        tag: 'UCCService',
      );
      return null;
    }
  }
}
