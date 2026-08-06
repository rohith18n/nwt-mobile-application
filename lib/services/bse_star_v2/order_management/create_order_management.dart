import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/insights/types/bse_create_order.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/response_handler.dart';
import 'package:nwt_app/services/auth/auth.dart';

import '../../../screens/insights/types/bse_payment_redirect_link_responce.dart';

class CreateOrderService {
  static const String _tag = 'BseOnboardingService';
  Timer? _timer;

  /// Creates BSE create order response from JSON data
  static BseCreateOrderResponse _createOrderResponse(
    Map<String, dynamic> jsonData,
  ) {
    return BseCreateOrderResponse(
      statusCode: jsonData['statusCode'] ?? 200,
      message: jsonData['message'] ?? 'Request completed',
      data: jsonData['data'] != null ? Data.fromJson(jsonData['data']) : null,
    );
  }

  /// Creates fallback BSE create order response
  static BseCreateOrderResponse _createFallbackOrderResponse(
    int statusCode,
    String message,
    dynamic data,
  ) {
    return BseCreateOrderResponse(
      statusCode: statusCode,
      message: message,
      data: data != null ? Data.fromJson(data) : null,
    );
  }

  /// Creates new order for BSE
  static Future<BseCreateOrderResponse?> createOrder({
    required String schemeIsin,
    required int amount,
  }) async {
    try {
      AppLogger.info('Creating BSE order', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Map the order data
      final orderData = {"scheme_isin": schemeIsin, "amount": amount};

      AppLogger.info(
        'BSE order creation request body: ${json.encode(orderData)}',
        tag: _tag,
      );

      final response = await http.post(
        Uri.parse(ApiURLs.CREATE_ORDER),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-key': 'dev-key-12345',
        },
        body: json.encode(orderData),
      );

      AppLogger.info(
        'BSE order creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE order creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final orderResponse =
            ResponseHandler.handleResponse<BseCreateOrderResponse>(
              response,
              jsonData,
              responseFactory: _createOrderResponse,
              fallbackFactory: _createFallbackOrderResponse,
            );

        AppLogger.info(
          'BSE order created successfully: ${orderResponse.message}',
          tag: _tag,
        );
        return orderResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE order: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in createOrder: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Creates new sell order for BSE
  static Future<BseCreateOrderResponse?> sellOrder({
    required String schemeIsin,
    required int amount,
  }) async {
    try {
      AppLogger.info('Creating BSE sell order', tag: _tag);

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Map the order data
      final orderData = {"scheme_isin": schemeIsin, "amount": amount};

      AppLogger.info(
        'BSE sell order creation request body: ${json.encode(orderData)}',
        tag: _tag,
      );

      final response = await http.post(
        Uri.parse(ApiURLs.SELL_ORDER),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-key': 'dev-key-12345',
        },
        body: json.encode(orderData),
      );

      AppLogger.info(
        'BSE sell order creation API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info(
        'BSE sell order creation API body: ${response.body}',
        tag: _tag,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final orderResponse =
            ResponseHandler.handleResponse<BseCreateOrderResponse>(
              response,
              jsonData,
              responseFactory: _createOrderResponse,
              fallbackFactory: _createFallbackOrderResponse,
            );

        AppLogger.info(
          'BSE sell order created successfully: ${orderResponse.message}',
          tag: _tag,
        );
        return orderResponse;
      } else {
        AppLogger.error(
          'Failed to create BSE sell order: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception in sellOrder: $e',
        tag: _tag,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  void startPolling({
    required Future<String> Function() checkOrderStatus,
    required Function() onSuccess,
    required Function() onFailure,
  }) {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final status = await checkOrderStatus();

      if (status == "PAYMENT_SUCCESS") {
        timer.cancel();
        onSuccess();
      }

      if (status == "PAYMENT_FAILED") {
        timer.cancel();
        onFailure();
      }
    });
  }

  void stopPolling() {
    _timer?.cancel();
  }

  static Future<BsePaymentLinkResponse?> getPaymentLink(int orderId) async {
    try {
      // Construct the URL with the orderId
      final String url = ApiURLs.BSE_payment_redirect_link(orderId);

      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      // Use your existing headers (token, etc.)
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-key': 'dev-key-12345',
        },
      );

      if (response.statusCode == 200) {
        return BsePaymentLinkResponse.fromJson(jsonDecode(response.body));
      } else {
        print("Error fetching payment link: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception while fetching payment link: $e");
      return null;
    }
  }
}
