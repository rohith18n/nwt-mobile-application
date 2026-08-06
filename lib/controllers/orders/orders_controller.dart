import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/screens/advisory/types/order_history_model.dart';
import 'package:nwt_app/services/secure_storage.dart';

import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/services/bse_star/ucc_creation.dart';

import '../../utils/app_logger.dart';

class OrdersController extends GetxController {
  final List<String> filters = [
    'Pending',
    'Buy',
    'Sell',
    'SIP',
    'Switch',
    'SWP',
  ];

  var selectedFilter = 'Buy'.obs;
  var orders = <OrderHistoryModel>[].obs;
  var isLoading = true.obs;
  var isOnboardingStarted = false.obs;
  var isUccRegistered = false.obs;
  var error = RxnString();
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    checkOnboardingStatus();
  }

  Future<void> checkOnboardingStatus() async {
    final onboardingId = await SecureStorage.read('bse_onboarding_id');
    String? uccCode = await SecureStorage.read('UCC_CLIENT_CODE');

    isOnboardingStarted.value = onboardingId != null && onboardingId.isNotEmpty;
    bool isRegistered = uccCode != null && uccCode.isNotEmpty;

    // Fallback: If not found in local storage, check backend
    if (!isRegistered) {
      try {
        final uccStatusResponse =
            await BseUccCreationService().checkUccStatus();
        if (uccStatusResponse != null && uccStatusResponse.data != null) {
          final clientCode =
              uccStatusResponse.data?.investor?.clientCode ??
              uccStatusResponse.data?.uccStatusObject?.clientCode;

          if (clientCode != null && clientCode.isNotEmpty) {
            uccCode = clientCode;
            isRegistered = true;
            // Cache the result for future local checks
            await SecureStorage.write('UCC_CLIENT_CODE', clientCode);
            AppLogger.info(
              'UCC status verified from API: $clientCode',
              tag: 'OrdersController',
            );
          }
        }
      } catch (e) {
        AppLogger.error('Failed to verify UCC from API: $e');
      }
    }

    isUccRegistered.value = isRegistered;

    AppLogger.info(
      'Onboarding Status Check: started=$onboardingId, ucc=$uccCode, registered=$isRegistered',
    );
  }

  void _loadMockData() {
    final Map<String, dynamic> mockData = {
      "statusCode": 200,
      "message": "Successfully fetched orders list",
      "data": [
        {
          "id": 1001,
          "bse_order_id": 98765432,
          "user_id": "U_1771432045",
          "ucc": "MEMBER123",
          "status": "PENDING_EXECUTION",
          "bse_scheme": "AD3B-G",
          "amount": 5000,
          "type": "P",
          "is_units": false,
          "cur": "INR",
          "created_at": "2026-03-10T11:45:00.000Z",
          "fund_name": "Aditya Birla Sun Life Frontline Equity Fund",
          "fund_logo":
              "https://asset1.scripbox.com/assets/amc/icon/icici-prudential.png",
          "isin": "INF209K01157",
        },
        {
          "id": 1000,
          "bse_order_id": 98765431,
          "user_id": "U_1771432045",
          "ucc": "MEMBER123",
          "status": "DONE",
          "bse_scheme": "HDF012",
          "amount": 2000,
          "type": "P",
          "is_units": false,
          "cur": "INR",
          "created_at": "2026-03-05T09:30:00.000Z",
          "placed_at": "2026-03-05T10:00:00.000Z",
          "nav": 125.45,
          "nav_date": "2026-03-05",
          "units": 15.942,
          "fund_name": "HDFC Top 100 Fund",
          "fund_logo": "https://asset1.scripbox.com/assets/amc/icon/hdfc.png",
          "isin": "INF179K01BC7",
          "folio_number": "12345678/90",
        },
      ],
    };

    List<OrderHistoryModel> parsedOrders = [];
    if (mockData['data'] is List) {
      parsedOrders =
          (mockData['data'] as List)
              .map((item) => OrderHistoryModel.fromJson(item))
              .toList();
    } else if (mockData['data'] != null) {
      parsedOrders = [OrderHistoryModel.fromJson(mockData['data'])];
    }

    orders.value = parsedOrders;
    error.value = null;
  }

  Future<void> fetchOrders() async {
    if (_isFetching) return;
    _isFetching = true;

    isLoading.value = true;
    error.value = null;
    await checkOnboardingStatus();
    const String _tag = 'BSEOrderListing';
    try {
      final authService = AuthService();
      //final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMjAyLCJwaG9uZW51bWJlciI6Ijk1NjkwNTA1NDMiLCJndWlkIjoiVV8xNzcyMDQ5ODk2IiwiZW1haWwiOiJtYW5hc2h1a2xhMjFAZ21haWwuY29tIn0.sNHp5iL6TiKnHupr-rN7gTkodWBNvpifLGQvesnbNMw';
      final token = await authService.getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final orderData = {
        // "user_id": await SecureStorage.read("userid"),
      };

      final response = await http.post(
        Uri.parse('https://atom.pivotmoney.app/orders/api/v1/orders/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-key': 'dev-key-12345',
        },
        body: json.encode(orderData),
      );
      AppLogger.info(
        'BSE order Listing API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info('BSE order Listing API body: ${response.body}', tag: _tag);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        List<OrderHistoryModel> parsedOrders = [];
        if (jsonData['data'] is List) {
          parsedOrders =
              (jsonData['data'] as List)
                  .map((item) => OrderHistoryModel.fromJson(item))
                  .toList();
        } else if (jsonData['data'] != null) {
          parsedOrders = [OrderHistoryModel.fromJson(jsonData['data'])];
        }

        orders.value = parsedOrders;
        isLoading.value = false;
        _isFetching = false;
      } else {
        // Fallback to mock data on 404 or any other non-200 status
        print('API failed with ${response.statusCode}, loading mock data');
        // _loadMockData();
        error.value = null; // Clear error to allow UI to render mock data
        isLoading.value = false;
        _isFetching = false;
      }
    } catch (e) {
      // Fallback to mock data on error
      print('API exception $e, loading mock data');
      // _loadMockData();
      error.value = null; // Clear error to allow UI to render mock data
      isLoading.value = false;
      _isFetching = false;
    }
  }

  String formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    final doubleVal = double.tryParse(amount.toString());
    if (doubleVal == null) return 'N/A';

    return NumberFormat.currency(
      name: "INR",
      locale: 'en_IN',
      decimalDigits: 2,
      symbol: '₹',
    ).format(doubleVal);
  }

  String formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd, MMM yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String capitalize(String str) {
    if (str.isEmpty) return str;
    return '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}';
  }

  Future<bool> cancelOrder(dynamic orderId) async {
    const String _tag = 'CancelOrder';
    try {
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final body = {"remarks": "Cancellation with simplified body"};

      final response = await http.post(
        Uri.parse(ApiURLs.CANCEL_ORDER(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-key': 'dev-key-12345',
        },
        body: json.encode(body),
      );

      AppLogger.info(
        'Cancel Order API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info('Cancel Order API body: ${response.body}', tag: _tag);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchOrders(); // Refresh the list
        return true;
      } else {
        AppLogger.error(
          'Failed to cancel order: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception in cancelOrder: $e', tag: _tag);
      return false;
    }
  }

  Future<String?> getPaymentLink(dynamic orderId) async {
    const String _tag = 'GetPaymentLink';
    try {
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      // Ensure orderId is formatted correctly for the API path
      final id = int.tryParse(orderId.toString());
      if (id == null) {
        throw Exception('Invalid order ID format: $orderId');
      }

      final response = await http.get(
        Uri.parse(ApiURLs.BSE_payment_redirect_link(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-api-key': 'dev-key-12345',
        },
      );

      AppLogger.info(
        'Get Payment Link API response: ${response.statusCode}',
        tag: _tag,
      );
      AppLogger.info('Get Payment Link API body: ${response.body}', tag: _tag);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        // Adjust the key based on the actual API response structure
        // Assuming it returns {"data": {"payment_url": "..."}} or similar
        final paymentUrl =
            jsonData['data']?['redirect_link'] ??
            jsonData['data']?['payment_link'] ??
            jsonData['data']?['payment_url'] ??
            jsonData['redirect_link'] ??
            jsonData['payment_link'];

        return paymentUrl?.toString();
      } else {
        AppLogger.error(
          'Failed to get payment link: ${response.statusCode} - ${response.body}',
          tag: _tag,
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Exception in getPaymentLink: $e', tag: _tag);
      return null;
    }
  }
}
