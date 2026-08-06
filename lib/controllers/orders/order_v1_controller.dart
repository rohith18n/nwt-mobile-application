import 'dart:async';
import 'package:get/get.dart';
import 'package:nwt_app/screens/orders/types/order_v1.dart';
import 'package:nwt_app/services/orders/order_service_v1.dart';
import 'package:nwt_app/utils/app_logger.dart';

class OrderV1Controller extends GetxController {
  final MutualFundOrderServiceV1 _orderService = MutualFundOrderServiceV1();

  // Observable state
  var accounts = <UccAccount>[].obs;
  var isLoadingAccounts = false.obs;
  var selectedAccount = Rxn<UccAccount>();
  var availableFolios = <String>[].obs;
  var isLoadingFolios = false.obs;

  // Payment Polling State
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  var paymentStatus = Rxn<PaymentStatusData>();
  var isPolling = false.obs;
  var remainingSeconds = 300.obs;
  var activeOrderData = Rxn<OrderData>();
  var activeIsSip = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  /// Initial fetch of UCC accounts
  Future<void> fetchAccounts() async {
    if (isLoadingAccounts.value) return;

    isLoadingAccounts.value = true;
    try {
      final response = await _orderService.getAccounts();
      if (response.success) {
        accounts.assignAll(response.accounts);
        if (accounts.isNotEmpty && selectedAccount.value == null) {
          selectedAccount.value = accounts.first;
        }
      }
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  /// Check folios for the selected account and fund ISIN
  Future<void> checkFolios(String isin) async {
    if (selectedAccount.value == null) return;

    isLoadingFolios.value = true;
    availableFolios.clear();
    try {
      final response = await _orderService.checkFolio(
        uccUuid: selectedAccount.value!.id,
        isin: isin,
      );
      if (response.success) {
        availableFolios.assignAll(['New Folio', ...response.folios]);
      } else {
        availableFolios.assignAll(['New Folio']);
      }
    } finally {
      isLoadingFolios.value = false;
    }
  }

  /// Start polling payment status every 30 seconds
  void startPaymentPolling(
    int orderId, {
    bool isSip = false,
    OrderData? orderData,
  }) {
    stopPaymentPolling();
    isPolling.value = true;
    remainingSeconds.value = 300;
    activeOrderData.value = orderData;
    activeIsSip.value = isSip;

    // Initial fetch
    _fetchStatus(orderId, isSip: isSip);

    // Set up polling timer
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchStatus(orderId, isSip: isSip);
    });

    // Set up countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value = remainingSeconds.value - 1;
        AppLogger.info('Timer ticking: ${remainingSeconds.value}', tag: 'OrderV1Controller');
      } else {
        AppLogger.info('Timer finished', tag: 'OrderV1Controller');
        stopPaymentPolling();
      }
    });
  }

  Future<void> _fetchStatus(int orderId, {bool isSip = false}) async {
    AppLogger.info(
      'Polling ${isSip ? 'SIP' : 'order'} payment status for order $orderId',
      tag: 'OrderV1Controller',
    );
    final response = isSip 
      ? await _orderService.getSipPaymentStatus(orderId)
      : await _orderService.getPaymentStatus(orderId);
      
    if (response.success && response.data != null) {
      paymentStatus.value = response.data;

      // Stop polling if we reach terminal status
      final status = response.data!.orderStatus.toUpperCase();
      if (status == 'SUCCESS' || status == 'FAILED') {
        stopPaymentPolling();
      }
    }
  }

  void stopPaymentPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    isPolling.value = false;
    activeOrderData.value = null;
    activeIsSip.value = false;
  }

  @override
  void onClose() {
    stopPaymentPolling();
    super.onClose();
  }
}
