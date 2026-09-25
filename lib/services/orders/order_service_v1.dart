import 'dart:convert';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/screens/orders/types/order_v1.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/network_api_helper.dart';

class MutualFundOrderServiceV1 {
  final NetworkAPIHelper _networkHelper = NetworkAPIHelper();

  /// Retrieve linked UCC accounts for the user
  Future<UccAccountRespose> getAccounts() async {
    try {
      final response = await _networkHelper.get(ApiURLs.ORDER_ACCOUNTS);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UccAccountRespose.fromJson(data);
      }
      return UccAccountRespose(success: false, accounts: []);
    } catch (e) {
      AppLogger.error('Error in getAccounts: $e', tag: 'MFOrderServiceV1');
      return UccAccountRespose(success: false, accounts: []);
    }
  }

  /// Check for existing folios for a specific UCC and fund ISIN
  Future<FolioResponse> checkFolio({
    required String uccUuid,
    required String isin,
  }) async {
    try {
      final url = ApiURLs.ORDER_CHECK_FOLIO(uccUuid);
      final body = {'isin': isin};
      final response = await _networkHelper.post(url, body);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FolioResponse.fromJson(data);
      }
      return FolioResponse(success: false, folios: []);
    } catch (e) {
      AppLogger.error('Error in checkFolio: $e', tag: 'MFOrderServiceV1');
      return FolioResponse(success: false, folios: []);
    }
  }

  /// Create a lumpsum mutual fund order
  Future<OrderCreateResponse> createOrder({
    required String uccId,
    required String schemeCode,
    required double amount,
    String mode = 'Physical',
    bool isFresh = true,
    String? folioNumber,
  }) async {
    try {
      final body = {
        'ucc_id': uccId,
        'scheme_code': schemeCode,
        'amount': amount,
        'mode': mode,
        'is_fresh': isFresh,
        'folio_number': folioNumber,
      };

      // Log request payload
      AppLogger.info(
        '📤 CREATE ORDER REQUEST\n'
        'URL: ${ApiURLs.ORDER_CREATE}\n'
        'Payload: ${jsonEncode(body)}',
        tag: 'buy_order',
      );

      final response = await _networkHelper.post(ApiURLs.ORDER_CREATE, body);
      
      if (response != null) {
        final data = jsonDecode(response.body);
        
        // Log response
        AppLogger.info(
          '✅ CREATE ORDER RESPONSE\n'
          'Status Code: ${response.statusCode}\n'
          'Response: ${response.body}',
          tag: 'buy_order',
        );
        
        return OrderCreateResponse.fromJson(data);
      }
      
      AppLogger.error(
        '❌ CREATE ORDER FAILED - No response from server',
        tag: 'buy_order',
      );
      
      return OrderCreateResponse(
        success: false,
        message: 'No response from server',
      );
    } catch (e) {
      AppLogger.error(
        '❌ CREATE ORDER ERROR\n'
        'Error: $e',
        tag: 'buy_order',
      );
      return OrderCreateResponse(success: false, message: e.toString());
    }
  }

  /// Trigger payment for a created order
  Future<PaymentResponse> initiatePayment({
    required int orderId,
    required String paymentMode, // 'UPI' or 'NETBANKING'
    String? upiId,
  }) async {
    try {
      final body = {
        'order_id': orderId,
        'payment_mode': paymentMode,
        if (upiId != null) 'upi_id': upiId,
      };
      final response = await _networkHelper.post(ApiURLs.ORDER_PAYMENT, body);
      if (response != null) {
        final data = jsonDecode(response.body);
        return PaymentResponse.fromJson(data);
      }
      return PaymentResponse(
        success: false,
        message: 'No response from server',
      );
    } catch (e) {
      AppLogger.error('Error in initiatePayment: $e', tag: 'MFOrderServiceV1');
      return PaymentResponse(success: false, message: e.toString());
    }
  }

  /// Poll for payment and order execution status
  Future<PaymentStatusResponse> getPaymentStatus(dynamic orderId) async {
    try {
      final url = ApiURLs.ORDER_PAYMENT_STATUS(orderId);
      final response = await _networkHelper.get(url);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentStatusResponse.fromJson(data);
      }
      return PaymentStatusResponse(success: false);
    } catch (e) {
      AppLogger.error('Error in getPaymentStatus: $e', tag: 'MFOrderServiceV1');
      return PaymentStatusResponse(success: false);
    }
  }

  /// Create a redemption (sell) order
  Future<RedeemResponse> redeemOrder({
    int? purchaseOrderId,
    String? uccId,
    String? schemeCode,
    String? folioNumber,
    double? amount,
    double? units,
    bool allUnits = false,
  }) async {
    try {
      final body = {
        if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
        if (uccId != null) 'ucc_id': uccId,
        if (schemeCode != null) 'scheme_code': schemeCode,
        if (folioNumber != null) 'folio_number': folioNumber,
        if (amount != null) 'amount': amount,
        if (units != null) 'units': units,
        'all_units': allUnits,
      };
      final response = await _networkHelper.post(ApiURLs.ORDER_REDEEM, body);
      if (response != null) {
        final data = jsonDecode(response.body);
        return RedeemResponse.fromJson(data);
      }
      return RedeemResponse(success: false, message: 'No response from server');
    } catch (e) {
      AppLogger.error('Error in redeemOrder: $e', tag: 'MFOrderServiceV1');
      return RedeemResponse(success: false, message: e.toString());
    }
  }

  /// Create a new SIP
  Future<OrderCreateResponse> createSip({
    required String uccId,
    required String schemeCode,
    required double amount,
    String mode = 'Physical',
    String frequency = 'monthly',
    required int txnDate,
    required String startDate,
    required int installments,
    bool isFresh = true,
    String? folioNumber,
  }) async {
    try {
      final body = {
        'ucc_id': uccId,
        'scheme_code': schemeCode,
        'amount': amount,
        'mode': mode,
        'frequency': frequency,
        'txn_date': txnDate,
        'start_date': startDate,
        'installments': installments,
        'is_fresh': isFresh,
        'folio_number': folioNumber,
      };
      final response = await _networkHelper.post(ApiURLs.SIP_CREATE, body);
      if (response != null) {
        final data = jsonDecode(response.body);
        return OrderCreateResponse.fromJson(data);
      }
      return OrderCreateResponse(
        success: false,
        message: 'No response from server',
      );
    } catch (e) {
      AppLogger.error('Error in createSip: $e', tag: 'MFOrderServiceV1');
      return OrderCreateResponse(success: false, message: e.toString());
    }
  }

  /// Trigger payment for a created SIP (first installment)
  Future<PaymentResponse> initiateSipPayment({
    required int orderId,
    required String paymentMode,
    String? upiId,
  }) async {
    try {
      final body = {
        'order_id': orderId,
        'payment_mode': paymentMode,
        if (upiId != null) 'upi_id': upiId,
      };
      final response = await _networkHelper.post(ApiURLs.SIP_PAYMENT, body);
      if (response != null) {
        final data = jsonDecode(response.body);
        return PaymentResponse.fromJson(data);
      }
      return PaymentResponse(
        success: false,
        message: 'No response from server',
      );
    } catch (e) {
      AppLogger.error(
        'Error in initiateSipPayment: $e',
        tag: 'MFOrderServiceV1',
      );
      return PaymentResponse(success: false, message: e.toString());
    }
  }

  /// Check SIP payment status
  Future<PaymentStatusResponse> getSipPaymentStatus(dynamic orderId) async {
    try {
      final url = ApiURLs.SIP_PAYMENT_STATUS(orderId);
      final response = await _networkHelper.get(url);
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentStatusResponse.fromJson(data);
      }
      return PaymentStatusResponse(success: false);
    } catch (e) {
      AppLogger.error(
        'Error in getSipPaymentStatus: $e',
        tag: 'MFOrderServiceV1',
      );
      return PaymentStatusResponse(success: false);
    }
  }
}
