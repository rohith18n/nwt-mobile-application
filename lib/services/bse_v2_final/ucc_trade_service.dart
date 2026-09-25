import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// UCC Trade Wizard Service
/// Handles all UCC creation and nomination APIs (Section 14 of frontend_investment_apis.md)
/// Reference: TestingFrontEnd/src/lib/mfTradeApi.js
class UccTradeService {
  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// Get payment polling configuration
  /// GET /api/v2/trade/payment-poll-config/
  Future<Map<String, dynamic>?> getPaymentPollConfig() async {
    try {
      AppLogger.info(
        '📤 GET ${ApiURLs.TRADE_PAYMENT_POLL_CONFIG}',
        tag: 'UccTradeService',
      );

      final response = await _api.get(ApiURLs.TRADE_PAYMENT_POLL_CONFIG);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Payment poll config fetched\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Failed to get poll config\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return response != null ? jsonDecode(response.body) : null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in getPaymentPollConfig',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Check if UCC exists for holder+nominee combination
  /// POST /api/v2/trade/ucc/resolve/
  Future<Map<String, dynamic>?> resolveUcc({
    required String holdingNature,
    String? secondaryHolderId,
    required String nomination,
    String? nomineeHolderId,
  }) async {
    try {
      final payload = {
        'holding_nature': holdingNature,
        if (secondaryHolderId != null) 'secondary_holder_id': secondaryHolderId,
        'nomination': nomination,
        if (nomineeHolderId != null) 'nominee_holder_id': nomineeHolderId,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_RESOLVE}\nPayload: ${jsonEncode(payload)}',
        tag: 'UccTradeService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_RESOLVE,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ UCC resolved\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ UCC resolve failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in resolveUcc',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Create UCC draft
  /// POST /api/v2/trade/ucc/draft/
  Future<Map<String, dynamic>?> createUccDraft({
    required String holdingNature,
    String? secondaryHolderId,
  }) async {
    try {
      final payload = {
        'holding_nature': holdingNature,
        if (secondaryHolderId != null) 'secondary_holder_id': secondaryHolderId,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_DRAFT}\nPayload: ${jsonEncode(payload)}',
        tag: 'UccTradeService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_DRAFT,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ UCC draft created\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ UCC draft creation failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in createUccDraft',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Set nomination for UCC
  /// POST /api/v2/trade/ucc/nomination/
  Future<Map<String, dynamic>?> setNomination({
    required String clientCode,
    required String choice,
    String? nomineeHolderId,
  }) async {
    try {
      final payload = {
        'client_code': clientCode,
        'choice': choice,
        if (nomineeHolderId != null) 'nominee_holder_id': nomineeHolderId,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_NOMINATION}\nPayload: ${jsonEncode(payload)}',
        tag: 'UccTradeService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_NOMINATION,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Nomination set\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Nomination failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in setNomination',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Verify opt-out OTP (when skipping nominee)
  /// POST /api/v2/trade/ucc/nominee-opt-out/verify/
  Future<Map<String, dynamic>?> verifyOptOutOtp({
    required String clientCode,
    required String otp,
  }) async {
    try {
      final payload = {
        'client_code': clientCode,
        'otp': otp,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_NOMINEE_OPTOUT_VERIFY}\nPayload: ${jsonEncode(payload)}',
        tag: 'UccTradeService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_NOMINEE_OPTOUT_VERIFY,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Opt-out OTP verified\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Opt-out OTP verification failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in verifyOptOutOtp',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Resend opt-out OTP
  /// POST /api/v2/trade/ucc/nominee-opt-out/resend/
  Future<Map<String, dynamic>?> resendOptOutOtp({
    required String clientCode,
  }) async {
    try {
      final payload = {
        'client_code': clientCode,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_NOMINEE_OPTOUT_RESEND}\nPayload: ${jsonEncode(payload)}',
        tag: 'UccTradeService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_NOMINEE_OPTOUT_RESEND,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Opt-out OTP resent\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Opt-out OTP resend failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in resendOptOutOtp',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Submit BSE AOF OTP (final verification)
  /// POST /api/v2/trade/ucc/bse/finish/
  Future<Map<String, dynamic>?> submitBseOtp({
    required String clientCode,
    required String otp,
  }) async {
    try {
      final payload = {
        'client_code': clientCode,
        'otp': otp,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_BSE_FINISH}\nPayload: ${jsonEncode(payload)}',
        tag: 'UccTradeService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_BSE_FINISH,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ BSE OTP verified\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ BSE OTP verification failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in submitBseOtp',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }

  /// Poll UCC status
  /// GET /api/v2/trade/ucc/status/?client_code=...
  Future<Map<String, dynamic>?> getUccStatus({
    required String clientCode,
  }) async {
    try {
      final url = ApiURLs.tradeUccStatus(clientCode);

      AppLogger.info(
        '📤 GET $url',
        tag: 'UccTradeService',
      );

      final response = await _api.get(url);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ UCC status fetched\nResponse: ${response.body}',
          tag: 'UccTradeService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ UCC status fetch failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'UccTradeService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in getUccStatus',
        error: e,
        tag: 'UccTradeService',
      );
      return null;
    }
  }
}
