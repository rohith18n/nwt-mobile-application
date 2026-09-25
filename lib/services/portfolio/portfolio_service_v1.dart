import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/portfolio/types/portfolio_v1.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MutualFundPortfolioServiceV1 {
  final NetworkAPIHelper _networkHelper = NetworkAPIHelper();

  /// Retrieve paginated mutual fund lumpsum orders
  Future<Map<String, dynamic>> getMutualFundOrders({int page = 1}) async {
    try {
      final int pageSize = 20;
      final url =
          "${ApiURLs.PORTFOLIO_MF_LIST}?page=$page&page_size=$pageSize";
      
      AppLogger.info(
        'GET $url',
        tag: 'orders_bse',
      );
      
      final response = await _networkHelper.get(url);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        AppLogger.info(
          'BSE Orders Response (Page $page):\n'
          'Status: ${response.statusCode}\n'
          'Count: ${data['count']}\n'
          'Has Next: ${data['next'] != null}\n'
          'Results Count: ${(data['results'] as List?)?.length ?? 0}',
          tag: 'orders_bse',
        );
        
        // Log full response in chunks to avoid truncation
        final responseBody = response.body;
        final chunkSize = 800; // Log in 800 character chunks
        for (int i = 0; i < responseBody.length; i += chunkSize) {
          final end = (i + chunkSize < responseBody.length) ? i + chunkSize : responseBody.length;
          final chunk = responseBody.substring(i, end);
          AppLogger.info(
            'Response Part ${(i ~/ chunkSize) + 1}: $chunk',
            tag: 'orders_bse',
          );
        }
        
        final results =
            (data['results'] as List? ?? [])
                .map((e) => PortfolioMFOrderV1.fromJson(e))
                .toList();
        return {
          'count': data['count'] ?? 0,
          'next': data['next'],
          'results': results,
        };
      }
      
      AppLogger.error(
        'BSE Orders failed: Status ${response?.statusCode}',
        tag: 'orders_bse',
      );
      
      return {'count': 0, 'results': <PortfolioMFOrderV1>[]};
    } catch (e) {
      AppLogger.error(
        'Error in getMutualFundOrders: $e',
        tag: 'orders_bse',
      );
      return {'count': 0, 'results': <PortfolioMFOrderV1>[]};
    }
  }

  /// Retrieve paginated SIP registrations
  Future<Map<String, dynamic>> getSips({int page = 1}) async {
    try {
      final int pageSize = 20;
      final url =
          "${ApiURLs.PORTFOLIO_SIP_LIST}?page=$page&page_size=$pageSize";
      
      AppLogger.info(
        'GET $url',
        tag: 'orders_bse',
      );
      
      final response = await _networkHelper.get(url);

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        AppLogger.info(
          'BSE SIPs Response (Page $page):\n'
          'Status: ${response.statusCode}\n'
          'Count: ${data['count']}\n'
          'Has Next: ${data['next'] != null}\n'
          'Results Count: ${(data['results'] as List?)?.length ?? 0}',
          tag: 'orders_bse',
        );
        
        // Log full response in chunks to avoid truncation
        final responseBody = response.body;
        final chunkSize = 800; // Log in 800 character chunks
        for (int i = 0; i < responseBody.length; i += chunkSize) {
          final end = (i + chunkSize < responseBody.length) ? i + chunkSize : responseBody.length;
          final chunk = responseBody.substring(i, end);
          AppLogger.info(
            'SIP Response Part ${(i ~/ chunkSize) + 1}: $chunk',
            tag: 'orders_bse',
          );
        }
        
        final results =
            (data['results'] as List? ?? [])
                .map((e) => PortfolioSIPRegistrationV1.fromJson(e))
                .toList();
        return {
          'count': data['count'] ?? 0,
          'next': data['next'],
          'results': results,
        };
      }
      
      AppLogger.error(
        'BSE SIPs failed: Status ${response?.statusCode}',
        tag: 'orders_bse',
      );
      
      return {'count': 0, 'results': <PortfolioSIPRegistrationV1>[]};
    } catch (e) {
      AppLogger.error(
        'Error in getSips: $e',
        tag: 'orders_bse',
      );
      return {'count': 0, 'results': <PortfolioSIPRegistrationV1>[]};
    }
  }

  /// Retrieve detailed SIP lifecycle
  Future<PortfolioSIPDetailV1?> getSipDetail(dynamic sipId) async {
    try {
      final url = ApiURLs.PORTFOLIO_SIP_DETAIL(sipId);
      final response = await _networkHelper.get(url);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PortfolioSIPDetailV1.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error in getSipDetail: $e', tag: 'MFPortfolioServiceV1');
      return null;
    }
  }

  /// Retrieve sellable holdings
  Future<List<SellablePortfolioItemV1>> getSellablePortfolio() async {
    try {
      final response = await _networkHelper.get(ApiURLs.PORTFOLIO_SELLABLE);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results =
            (data['results'] as List? ?? [])
                .map((e) => SellablePortfolioItemV1.fromJson(e))
                .toList();
        return results;
      }
      return [];
    } catch (e) {
      AppLogger.error(
        'Error in getSellablePortfolio: $e',
        tag: 'MFPortfolioServiceV1',
      );
      return [];
    }
  }

  /// Place a redemption order
  Future<Map<String, dynamic>> redeemOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _networkHelper.post(ApiURLs.ORDER_REDEEM, payload);
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to place redemption order'};
    } catch (e) {
      AppLogger.error('Error in redeemOrder: $e', tag: 'MFPortfolioServiceV1');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Retrieve payment link for an order (Using NEW V1 API)
  Future<String?> getPaymentLink(dynamic orderId) async {
    try {
      final id = int.tryParse(orderId.toString());
      if (id == null) throw Exception('Invalid order ID');

      // Use the NEW V1 Order Payment API (POST)
      // We default to NETBANKING for the redirect link
      final body = {'order_id': id, 'payment_mode': 'NETBANKING'};
      final response = await _networkHelper.post(ApiURLs.ORDER_PAYMENT, body);

      if (response != null) {
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          // New V1 response structure: data['data']['payment_url']
          return data['data']?['payment_url'];
        } else {
          // Capture specific error message from backend
          final errorMsg = data['message'] ?? 'Payment initiation failed';
          throw Exception(errorMsg);
        }
      }
      throw Exception('No response from server');
    } catch (e) {
      AppLogger.error(
        'Error in getPaymentLink: $e',
        tag: 'MFPortfolioServiceV1',
      );
      rethrow;
    }
  }

  /// Retrieve detailed MF order lifecycle
  Future<PortfolioMFOrderDetailV1?> getMutualFundOrderDetail(
    dynamic orderId,
  ) async {
    try {
      final url = ApiURLs.PORTFOLIO_MF_DETAIL(orderId);
      final response = await _networkHelper.get(url);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PortfolioMFOrderDetailV1.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Error in getMutualFundOrderDetail: $e',
        tag: 'MFPortfolioServiceV1',
      );
      return null;
    }
  }
}
