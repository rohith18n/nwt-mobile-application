import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

/// Trade API Service for UCC resolution, mandate management, and payment polling
class TradeApiService {
  final NetworkAPIHelper _api = NetworkAPIHelper();

  /// Resolve UCC for trading - checks if UCC exists and is ready
  /// POST /api/v2/trade/ucc/resolve/
  Future<Map<String, dynamic>?> tradeUccResolve({
    required String holdingNature, // "SI", "AS", "JO"
    required String nomination, // "skip", "provide", or holder_id
  }) async {
    try {
      final payload = {
        'holding_nature': holdingNature,
        'nomination': nomination,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_UCC_RESOLVE}\nPayload: ${jsonEncode(payload)}',
        tag: 'TradeApiService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_UCC_RESOLVE,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ UCC resolved\nResponse: ${response.body}',
          tag: 'TradeApiService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ UCC resolution failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'TradeApiService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in tradeUccResolve',
        error: e,
        tag: 'TradeApiService',
      );
      return null;
    }
  }

  /// Get payment poll configuration
  /// GET /api/v2/trade/payment/poll-config/
  Future<Map<String, dynamic>?> tradePaymentPollConfig() async {
    try {
      AppLogger.info(
        '📤 GET ${ApiURLs.TRADE_PAYMENT_POLL_CONFIG}',
        tag: 'TradeApiService',
      );

      final response = await _api.get(ApiURLs.TRADE_PAYMENT_POLL_CONFIG);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Poll config fetched\nResponse: ${response.body}',
          tag: 'TradeApiService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Failed to fetch poll config\nStatus: ${response?.statusCode}',
          tag: 'TradeApiService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in tradePaymentPollConfig',
        error: e,
        tag: 'TradeApiService',
      );
      return null;
    }
  }

  /// Check mandate status for SIP
  /// GET /api/v2/trade/mandate/status/?client_code={clientCode}
  Future<Map<String, dynamic>?> tradeMandateStatus({
    required String clientCode,
  }) async {
    try {
      final url = '${ApiURLs.TRADE_MANDATE_STATUS}?client_code=$clientCode';
      
      AppLogger.info(
        '📤 GET $url',
        tag: 'TradeApiService',
      );

      final response = await _api.get(url);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Mandate status fetched\nResponse: ${response.body}',
          tag: 'TradeApiService',
        );
        return data;
      } else {
        AppLogger.error(
          '❌ Failed to fetch mandate status\nStatus: ${response?.statusCode}',
          tag: 'TradeApiService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in tradeMandateStatus',
        error: e,
        tag: 'TradeApiService',
      );
      return null;
    }
  }

  /// Register a new mandate
  /// POST /api/v2/trade/mandate/register/
  Future<Map<String, dynamic>?> tradeMandateRegister({
    required String uccId,
    required double maxAmount,
    String frequency = 'monthly',
  }) async {
    try {
      final payload = {
        'ucc_id': uccId,
        'max_amount': maxAmount,
        'frequency': frequency,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_MANDATE_REGISTER}\nPayload: ${jsonEncode(payload)}',
        tag: 'TradeApiService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_MANDATE_REGISTER,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ Mandate registered\nResponse: ${response.body}',
          tag: 'TradeApiService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ Mandate registration failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'TradeApiService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in tradeMandateRegister',
        error: e,
        tag: 'TradeApiService',
      );
      return null;
    }
  }

  /// Poll mandate authorization status
  /// GET /api/v2/trade/mandate/poll/?mandate_id={mandateId}
  Future<Map<String, dynamic>?> tradeMandatePoll({
    required String mandateId,
  }) async {
    try {
      final url = '${ApiURLs.TRADE_MANDATE_POLL}?mandate_id=$mandateId';
      
      AppLogger.info(
        '📤 GET $url',
        tag: 'TradeApiService',
      );

      final response = await _api.get(url);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        AppLogger.error(
          '❌ Failed to poll mandate\nStatus: ${response?.statusCode}',
          tag: 'TradeApiService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in tradeMandatePoll',
        error: e,
        tag: 'TradeApiService',
      );
      return null;
    }
  }

  /// Create SIP with mandate
  /// POST /api/v2/trade/sip/create/
  Future<Map<String, dynamic>?> tradeSipCreate({
    required String mandateId,
    required String schemeCode,
    required double amount,
    required int txnDate,
    required String startDate,
    required int installments,
    bool isFresh = true,
    String? folioNumber,
  }) async {
    try {
      final payload = {
        'mandate_id': mandateId,
        'scheme_code': schemeCode,
        'amount': amount,
        'txn_date': txnDate,
        'start_date': startDate,
        'installments': installments,
        'is_fresh': isFresh,
        if (folioNumber != null) 'folio_number': folioNumber,
      };

      AppLogger.info(
        '📤 POST ${ApiURLs.TRADE_SIP_CREATE}\nPayload: ${jsonEncode(payload)}',
        tag: 'TradeApiService',
      );

      final response = await _api.post(
        ApiURLs.TRADE_SIP_CREATE,
        jsonEncode(payload),
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info(
          '✅ SIP created\nResponse: ${response.body}',
          tag: 'TradeApiService',
        );
        return data;
      } else {
        final errorData = response != null ? jsonDecode(response.body) : null;
        AppLogger.error(
          '❌ SIP creation failed\nStatus: ${response?.statusCode}\nResponse: ${response?.body}',
          tag: 'TradeApiService',
        );
        return errorData;
      }
    } catch (e) {
      AppLogger.error(
        '❌ Exception in tradeSipCreate',
        error: e,
        tag: 'TradeApiService',
      );
      return null;
    }
  }
}
