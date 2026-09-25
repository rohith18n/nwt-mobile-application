import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';

class CashfreeSubscriptionService {
  /// Create a subscription on the backend
  /// Returns subscription_id and subscription_session_id
  static Future<Map<String, dynamic>> createSubscription({
    required String planId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    AppLogger.info('Creating Cashfree subscription', tag: 'CashfreeSubscription');
    
    try {
      final url = Uri.parse(ApiURLs.CASHFREE_CREATE_ORDER);
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'plan_id': planId,
          'amount': amount,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
        }),
      );

      AppLogger.info('Subscription creation response: ${response.statusCode}', tag: 'CashfreeSubscription');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          AppLogger.info('Subscription created successfully', tag: 'CashfreeSubscription');
          return responseData['data'];
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create subscription');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error creating subscription: $e', tag: 'CashfreeSubscription');
      rethrow;
    }
  }

  /// Verify subscription payment on the backend
  static Future<bool> verifySubscription({
    required String subscriptionId,
  }) async {
    AppLogger.info('Verifying subscription: $subscriptionId', tag: 'CashfreeSubscription');
    
    try {
      final url = Uri.parse('${ApiURLs.CASHFREE_CREATE_ORDER}/verify');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subscription_id': subscriptionId,
        }),
      );

      AppLogger.info('Subscription verification response: ${response.statusCode}', tag: 'CashfreeSubscription');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          AppLogger.info('Subscription verified successfully', tag: 'CashfreeSubscription');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Error verifying subscription: $e', tag: 'CashfreeSubscription');
      return false;
    }
  }
}
