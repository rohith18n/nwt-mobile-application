import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/bse_star/types/order_details.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseOrderDetailsService {
  static const String _tag = 'BseOrderDetailsService';

  /// Fetches order details by order ID
  static Future<Data?> getOrderDetails(String orderId) async {
    try {
      AppLogger.info('Fetching BSE order details for ID: $orderId', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Construct the full URL with order ID
      final url = '${ApiURLs.GET_BSE_ORDER_DETAILS}/$orderId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE order details API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE order details API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final orderResponse = BseOrderDetailsResponse.fromJson(jsonData);
        
        if (orderResponse.data != null) {
          AppLogger.info(
            'Retrieved order details for order ID: $orderId',
            tag: _tag,
          );
          return orderResponse.data;
        }
      } else {
        AppLogger.error(
          'Failed to fetch order details: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getOrderDetails: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Fetches all orders (list of orders)
  static Future<List<Data>?> getAllOrders() async {
    try {
      AppLogger.info('Fetching all BSE orders', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final response = await http.get(
        Uri.parse(ApiURLs.GET_BSE_ORDER_DETAILS),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info(
        'BSE all orders API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE all orders API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // Check if response contains a list of orders
        if (jsonData['data'] is List) {
          final List<Data> orders = (jsonData['data'] as List)
              .map((item) => Data.fromJson(item))
              .toList();
          
          AppLogger.info(
            'Retrieved ${orders.length} orders',
            tag: _tag,
          );
          return orders;
        } else if (jsonData['data'] != null) {
          // Single order response
          final orderResponse = BseOrderDetailsResponse.fromJson(jsonData);
          if (orderResponse.data != null) {
            return [orderResponse.data!];
          }
        }
      } else {
        AppLogger.error(
          'Failed to fetch all orders: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in getAllOrders: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
