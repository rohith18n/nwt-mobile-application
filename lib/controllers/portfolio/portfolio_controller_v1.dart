import 'package:get/get.dart';
import 'package:nwt_app/screens/portfolio/types/portfolio_v1.dart';
import 'package:nwt_app/services/portfolio/portfolio_service_v1.dart';
import 'package:nwt_app/utils/app_logger.dart';

class MutualFundPortfolioControllerV1 extends GetxController {
  final MutualFundPortfolioServiceV1 _service = MutualFundPortfolioServiceV1();

  // MF Orders List State
  final RxList<PortfolioMFOrderV1> mfOrders = <PortfolioMFOrderV1>[].obs;
  final RxBool isMfLoading = false.obs;
  final RxBool isMfLoadingMore = false.obs;
  final RxInt mfPage = 1.obs;
  final RxBool hasMoreMf = true.obs;
  final RxnString mfError = RxnString();
  final RxnString activeMfStatus = RxnString();

  // SIP List State
  final RxList<PortfolioSIPRegistrationV1> sips =
      <PortfolioSIPRegistrationV1>[].obs;
  final RxBool isSipLoading = false.obs;
  final RxBool isSipLoadingMore = false.obs;
  final RxInt sipPage = 1.obs;
  final RxBool hasMoreSip = true.obs;
  final RxnString sipError = RxnString();
  final RxnString activeSipStatus = RxnString();

  // Detail States
  final Rxn<PortfolioSIPDetailV1> selectedSipDetail =
      Rxn<PortfolioSIPDetailV1>();
  final Rxn<PortfolioMFOrderDetailV1> selectedMfOrderDetail =
      Rxn<PortfolioMFOrderDetailV1>();
  final RxBool isDetailLoading = false.obs;

  // Sellable State
  final RxList<SellablePortfolioItemV1> sellableItems =
      <SellablePortfolioItemV1>[].obs;
  final RxBool isSellableLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMfOrders(refresh: true);
    fetchSips(refresh: true);
  }

  /// Fetch MF Orders (Lumpsum)
  Future<void> fetchMfOrders({bool refresh = false}) async {
    if (refresh) {
      mfPage.value = 1;
      hasMoreMf.value = true;
      isMfLoading.value = true;
    } else {
      if (!hasMoreMf.value || isMfLoadingMore.value) return;
      isMfLoadingMore.value = true;
    }

    mfError.value = null;

    try {
      final response = await _service.getMutualFundOrders(page: mfPage.value);
      final List<PortfolioMFOrderV1> results = response['results'];

      if (refresh) {
        mfOrders.assignAll(results);
      } else {
        mfOrders.addAll(results);
      }

      hasMoreMf.value = response['next'] != null;
      if (hasMoreMf.value) {
        mfPage.value++;
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching MF orders: $e',
        tag: 'MFPortfolioController',
      );
      mfError.value = "Failed to load orders";
    } finally {
      isMfLoading.value = false;
      isMfLoadingMore.value = false;

      // Smart auto-fetch: if filter is active and we have few results, try next page
      if (activeMfStatus.value != null &&
          filteredMfOrders.length < 10 &&
          hasMoreMf.value) {
        fetchMfOrders();
      }
    }
  }

  /// Fetch SIP Registrations
  Future<void> fetchSips({bool refresh = false}) async {
    if (refresh) {
      sipPage.value = 1;
      hasMoreSip.value = true;
      isSipLoading.value = true;
    } else {
      if (!hasMoreSip.value || isSipLoadingMore.value) return;
      isSipLoadingMore.value = true;
    }

    sipError.value = null;

    try {
      AppLogger.info(
        'Fetching SIPs - Page: ${sipPage.value}',
        tag: 'MFPortfolioController',
      );
      final response = await _service.getSips(page: sipPage.value);
      final List<PortfolioSIPRegistrationV1> results = response['results'];
      AppLogger.info(
        'Fetched ${results.length} SIPs',
        tag: 'MFPortfolioController',
      );

      if (refresh) {
        sips.assignAll(results);
      } else {
        sips.addAll(results);
      }

      hasMoreSip.value = response['next'] != null;
      AppLogger.info(
        'Has more SIPs: ${hasMoreSip.value}',
        tag: 'MFPortfolioController',
      );
      if (hasMoreSip.value) {
        sipPage.value++;
      }
    } catch (e) {
      AppLogger.error('Error fetching SIPs: $e', tag: 'MFPortfolioController');
      sipError.value = "Failed to load SIPs";
    } finally {
      isSipLoading.value = false;
      isSipLoadingMore.value = false;

      // Smart auto-fetch: if filter is active and we have few results, try next page
      if (activeSipStatus.value != null &&
          filteredSips.length < 10 &&
          hasMoreSip.value) {
        fetchSips();
      }
    }
  }

  /// Get filtered MF orders
  List<PortfolioMFOrderV1> get filteredMfOrders {
    if (activeMfStatus.value == null) return mfOrders;
    final activeStatus = activeMfStatus.value!.toUpperCase();
    return mfOrders
        .where((o) {
          final orderStatus = o.uiStatus.toUpperCase();
          if (activeStatus == 'CANCELLED') {
            return orderStatus == 'FAILED' || orderStatus == 'CANCELLED';
          }
          return orderStatus == activeStatus;
        })
        .toList();
  }

  /// Get filtered SIPs
  List<PortfolioSIPRegistrationV1> get filteredSips {
    if (activeSipStatus.value == null) return sips;
    final activeStatus = activeSipStatus.value!.toUpperCase();
    return sips
        .where((s) {
          final sipStatus = s.status.toUpperCase();
          if (activeStatus == 'CANCELLED') {
            return sipStatus == 'FAILED' || sipStatus == 'CANCELLED';
          }
          return sipStatus == activeStatus;
        })
        .toList();
  }

  /// Set Status Filter for MF Orders
  void setMfStatusFilter(String? status) {
    if (activeMfStatus.value == status) return;
    activeMfStatus.value = status;
    // If we select a filter and the resulting list is short, trigger a fetch
    if (status != null && filteredMfOrders.length < 10 && hasMoreMf.value) {
      fetchMfOrders();
    }
  }

  /// Set Status Filter for SIPs
  void setSipStatusFilter(String? status) {
    if (activeSipStatus.value == status) return;
    activeSipStatus.value = status;
    // If we select a filter and the resulting list is short, trigger a fetch
    if (status != null && filteredSips.length < 10 && hasMoreSip.value) {
      fetchSips();
    }
  }

  /// Fetch SIP Details
  Future<void> fetchSipDetail(dynamic sipId) async {
    isDetailLoading.value = true;
    selectedSipDetail.value = null;
    try {
      final detail = await _service.getSipDetail(sipId);
      selectedSipDetail.value = detail;
    } catch (e) {
      AppLogger.error(
        'Error fetching SIP detail: $e',
        tag: 'MFPortfolioController',
      );
    } finally {
      isDetailLoading.value = false;
    }
  }

  /// Fetch MF Order Details
  Future<void> fetchMfOrderDetail(dynamic orderId) async {
    isDetailLoading.value = true;
    selectedMfOrderDetail.value = null;
    try {
      final detail = await _service.getMutualFundOrderDetail(orderId);
      selectedMfOrderDetail.value = detail;
    } catch (e) {
      AppLogger.error(
        'Error fetching MF detail: $e',
        tag: 'MFPortfolioController',
      );
    } finally {
      isDetailLoading.value = false;
    }
  }

  /// Get payment link for continuation
  Future<String?> getPaymentLink(dynamic orderId) async {
    try {
      return await _service.getPaymentLink(orderId);
    } catch (e) {
      AppLogger.error(
        'Controller error in getPaymentLink: $e',
        tag: 'MFPortfolioController',
      );
      rethrow;
    }
  }

  /// Fetch Sellable Portfolio
  Future<void> fetchSellablePortfolio() async {
    isSellableLoading.value = true;
    try {
      final items = await _service.getSellablePortfolio();
      sellableItems.assignAll(items);
    } catch (e) {
      AppLogger.error(
        'Error fetching sellable portfolio: $e',
        tag: 'MFPortfolioController',
      );
    } finally {
      isSellableLoading.value = false;
    }
  }

  /// Redeem Order
  Future<Map<String, dynamic>> redeemOrder(Map<String, dynamic> payload) async {
    return await _service.redeemOrder(payload);
  }
}
