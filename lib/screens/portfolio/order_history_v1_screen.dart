import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_controller_v1.dart';
import 'package:nwt_app/screens/orders/payment_processing_v1_screen.dart';
import 'package:nwt_app/screens/orders/types/order_v1.dart';
import 'package:nwt_app/screens/portfolio/types/portfolio_v1.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/orders/redeem_order_v1_screen.dart';

class OrderHistoryV1Screen extends StatefulWidget {
  const OrderHistoryV1Screen({super.key});

  @override
  State<OrderHistoryV1Screen> createState() => _OrderHistoryV1ScreenState();
}

class _OrderHistoryV1ScreenState extends State<OrderHistoryV1Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MutualFundPortfolioControllerV1 _controller = Get.put(
    MutualFundPortfolioControllerV1(),
  );
  final OrderV1Controller _orderV1Controller = Get.put(OrderV1Controller());
  final ScrollController _mfScrollController = ScrollController();
  final ScrollController _sipScrollController = ScrollController();
  final Set<dynamic> _paymentLoadingOrderIds = {};
  final Map<dynamic, String> _paymentErrors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Refresh data every time the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchMfOrders(refresh: true);
      _controller.fetchSips(refresh: true);
      _controller.fetchSellablePortfolio();
    });

    // Load accounts for payment selection (incase of продолжения оплаты)
    _orderV1Controller.fetchAccounts();

    _mfScrollController.addListener(() {
      if (_mfScrollController.position.pixels >=
          _mfScrollController.position.maxScrollExtent * 0.8) {
        _controller.fetchMfOrders();
      }
    });

    _sipScrollController.addListener(() {
      if (_sipScrollController.position.pixels >=
          _sipScrollController.position.maxScrollExtent * 0.8) {
        _controller.fetchSips();
      }
    });
  }

  Future<void> _handleCompletePayment(
    dynamic order, {
    bool isSip = false,
  }) async {
    // Check if a payment is already being processed
    if (_orderV1Controller.isPolling.value &&
        _orderV1Controller.activeOrderData.value != null) {
      Get.to(
        () => PaymentProcessingV1Screen(
          orderData: _orderV1Controller.activeOrderData.value!,
          isSip: _orderV1Controller.activeIsSip.value,
          isRedirected: true,
        ),
        transition: Transition.rightToLeft,
      );
      return;
    }

    final orderId = order.id;
    final String? amount = isSip ? order.amount : order.amount;
    final String bseOrderId =
        isSip ? (order.sxpId ?? '---') : (order.bseOrderId ?? '---');

    setState(() {
      _paymentLoadingOrderIds.add(orderId);
      _paymentErrors.remove(orderId); // Clear previous error
    });

    try {
      // Construct OrderData for the unified payment screen
      final orderData = OrderData(
        orderId: int.tryParse(orderId.toString()) ?? 0,
        bseOrderId: bseOrderId,
        amount: amount ?? '0.00',
        bankDetails: [], // Will be handled by the backend during initiation
        upiId: null, // User will enter/confirm in the next screen
      );

      if (mounted) {
        setState(() {
          _paymentLoadingOrderIds.remove(orderId);
        });
      }

      // Open the unified payment selection screen (UPI + Netbanking)
      await Get.to(
        () => PaymentProcessingV1Screen(orderData: orderData, isSip: isSip),
      );

      // Refresh data when returning to see updated status
      if (isSip) {
        _controller.fetchSips(refresh: true);
      } else {
        _controller.fetchMfOrders(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _paymentLoadingOrderIds.remove(orderId);
          _paymentErrors[orderId] = errorMsg;
        });

        // Set timer to clear error after 10 seconds
        Timer(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _paymentErrors.remove(orderId);
            });
          }
        });
      }
    }
  }

  Future<void> _handleSell(PortfolioMFOrderV1 order) async {
    Get.to(
      () => RedeemOrderV1Screen(
        fundName: order.schemeName,
        isin: order.isin ?? "",
        schemeCode: order.schemeCode!,
        nav: double.tryParse(order.allotmentPrice ?? '0') ?? 0,
        initialUcc: order.ucc,
        initialFolio: order.folioNumber,
        purchaseOrderId: order.id,
        availableAmount: double.tryParse(order.amount),
        availableUnits: double.tryParse(order.allotmentUnits ?? '10'),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mfScrollController.dispose();
    _sipScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: AppText(
          "Orders",
          variant: AppTextVariant.headline2,
          weight: AppTextWeight.bold,
          customColor: Colors.white,
        ),
        actions: const [
          WhatsAppSupportButton(size: 20, color: Colors.white),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkPrimary,
          labelColor: AppColors.darkPrimary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Mutual\nFunds"),
            Tab(text: "SIPs"),
            Tab(text: "Sellable\nHoldings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMfTab(), _buildSipTab(), _buildSellableTab()],
      ),
    );
  }

  Widget _buildMfTab() {
    return Obx(() {
      if (_controller.isMfLoading.value && _controller.mfOrders.isEmpty) {
        return _buildShimmerLoading();
      }

      final orders = _controller.filteredMfOrders;

      return Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child:
                orders.isEmpty
                    ? RefreshIndicator(
                      onRefresh: () => _controller.fetchMfOrders(refresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(
                              _controller.mfOrders.isEmpty
                                  ? "No mutual fund orders yet."
                                  : "No orders found matching the selected filter.",
                              icon:
                                  _controller.mfOrders.isEmpty
                                      ? Icons.history_toggle_off
                                      : Icons.filter_list_off,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () => _controller.fetchMfOrders(refresh: true),
                      child: ListView.separated(
                        controller: _mfScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(
                          AppSizing.scaffoldHorizontalPadding,
                        ),
                        itemCount:
                            orders.length +
                            (_controller.hasMoreMf.value ? 1 : 0),
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index >= orders.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.darkPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return _buildMfOrderCard(orders[index]);
                        },
                      ),
                    ),
          ),
        ],
      );
    });
  }

  Widget _buildSipTab() {
    return Obx(() {
      if (_controller.isSipLoading.value && _controller.sips.isEmpty) {
        return _buildShimmerLoading();
      }

      final filteredSips = _controller.filteredSips;

      return Column(
        children: [
          // _buildFilterHeader(),
          Expanded(
            child:
                (filteredSips.isEmpty || _controller.sipError.value != null)
                    ? RefreshIndicator(
                      onRefresh: () => _controller.fetchSips(refresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(
                              _controller.sipError.value ??
                                  (_controller.sips.isEmpty
                                      ? "No active SIPs found."
                                      : "No SIPs found matching the selected filter."),
                              icon:
                                  _controller.sipError.value != null
                                      ? Icons.error_outline
                                      : (_controller.sips.isEmpty
                                          ? Icons.history_toggle_off
                                          : Icons.filter_list_off),
                              onRetry:
                                  _controller.sipError.value != null
                                      ? () =>
                                          _controller.fetchSips(refresh: true)
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () => _controller.fetchSips(refresh: true),
                      child: ListView.separated(
                        controller: _sipScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(
                          AppSizing.scaffoldHorizontalPadding,
                        ),
                        itemCount:
                            filteredSips.length +
                            (_controller.hasMoreSip.value ? 1 : 0),
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index >= filteredSips.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.darkPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return _buildSipCard(filteredSips[index]);
                        },
                      ),
                    ),
          ),
        ],
      );
    });
  }

  Widget _buildSellableTab() {
    return Obx(() {
      if (_controller.isSellableLoading.value &&
          _controller.sellableItems.isEmpty) {
        return _buildShimmerLoading();
      }

      if (_controller.sellableItems.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => _controller.fetchSellablePortfolio(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildEmptyState("No sellable holdings found."),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _controller.fetchSellablePortfolio(),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
          itemCount: _controller.sellableItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildSellableCard(_controller.sellableItems[index]);
          },
        ),
      );
    });
  }

  Widget _buildSellableCard(SellablePortfolioItemV1 item) {
    return Semantics(
      label: 'Double tap to sell fund',
      onTapHint: 'Double tap to sell fund',
      child: InkWell(
        onTap: () {
          if (item.schemeCode == null) return;

          // Check if a payment is already being processed
          if (_orderV1Controller.isPolling.value &&
              _orderV1Controller.activeOrderData.value != null) {
            Get.to(
              () => PaymentProcessingV1Screen(
                orderData: _orderV1Controller.activeOrderData.value!,
                isSip: _orderV1Controller.activeIsSip.value,
                isRedirected: true,
              ),
              transition: Transition.rightToLeft,
            );
            return;
          }

          Get.to(
            () => RedeemOrderV1Screen(
              fundName: item.schemeName,
              isin: item.isin ?? "",
              schemeCode: item.schemeCode!,
              nav: item.nav,
              initialUcc: item.ucc,
              initialFolio: item.folioNumber,
              purchaseOrderId: item.id,
              availableAmount: double.tryParse(item.amount),
              availableUnits: double.tryParse(item.units ?? '0'),
            ),
          );
        },
        child: MergeSemantics(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Container(
                    //   width: 32,
                    //   height: 32,
                    //   decoration: const BoxDecoration(
                    //     color: Colors.greenAccent,
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: const Icon(
                    //     Icons.account_balance_wallet,
                    //     color: Colors.black,
                    //     size: 18,
                    //   ),
                    // ),
                    // const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            item.schemeName,
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.medium,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            "Folio: ${item.folioNumber}",
                            variant: AppTextVariant.bodySmall,
                            colorType: AppTextColorType.secondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.5),
                        ),
                      ),
                      child: AppText(
                        "SELL",
                        variant: AppTextVariant.caption,
                        weight: AppTextWeight.bold,
                        customColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoColumn(
                          "Available Units",
                          "${item.units ?? '---'}",
                        ),
                      ),
                      Expanded(
                        child: _buildInfoColumn("Value", "₹${item.amount}"),
                      ),
                      Expanded(
                        child: _buildInfoColumn(
                          "NAV",
                          item.nav != null ? "₹${item.nav}" : "---",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMfOrderCard(PortfolioMFOrderV1 order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkInputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppText(
                  order.schemeName,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(order.uiStatus),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        "Amount",
                        order.amount != "null" ? "₹${order.amount}" : "₹---",
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        "Date",
                        _formatDate(order.placedAt ?? order.createdAt),
                      ),
                    ),
                    if (order.bseOrderId != null &&
                        order.bseOrderId!.isNotEmpty)
                      Expanded(
                        child: _buildInfoColumn("Order ID", order.bseOrderId!),
                      ),
                  ],
                ),
                if ((order.folioNumber != null &&
                        order.folioNumber!.isNotEmpty) ||
                    (order.bseLifecycleStatus != null &&
                        order.bseLifecycleStatus!.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (order.folioNumber != null &&
                          order.folioNumber!.isNotEmpty)
                        Expanded(
                          child: _buildInfoColumn("Folio", order.folioNumber!),
                        ),
                      // if (order.bseLifecycleStatus != null &&
                      //     order.bseLifecycleStatus!.isNotEmpty)
                      //   Expanded(
                      //     child: _buildInfoColumn(
                      //       "BSE Status",
                      //       order.displayLifecycleStatus,
                      //     ),
                      //   ),
                    ],
                  ),
                ],
                // if (order.internalStatus != null &&
                //     order.internalStatus!.isNotEmpty) ...[
                //   const SizedBox(height: 12),
                //   Row(
                //     children: [
                //       Expanded(
                //         child: _buildInfoColumn(
                //           "Internal Status",
                //           order.displayInternalStatus,
                //         ),
                //       ),
                //     ],
                //   ),
                // ],
                if (order.allotmentDate != null ||
                    order.allotmentUnits != null ||
                    order.allotmentPrice != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (order.allotmentDate != null)
                        Expanded(
                          child: _buildInfoColumn(
                            "Allotted On",
                            _formatDate(order.allotmentDate!),
                          ),
                        ),
                      if (order.allotmentUnits != null)
                        Expanded(
                          child: _buildInfoColumn(
                            "Units",
                            order.allotmentUnits!,
                          ),
                        ),
                      if (order.allotmentPrice != null)
                        Expanded(
                          child: _buildInfoColumn(
                            "Alloted Price",
                            "₹${order.allotmentPrice!}",
                          ),
                        ),
                    ],
                  ),
                ],
                _buildStatusDescription(order),
              ],
            ),
          ),
          if (order.uiStatus == "PAYMENT_PENDING") ...[
            const SizedBox(height: 16),
            if (_paymentErrors.containsKey(order.id))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppText(
                  _paymentErrors[order.id]!,
                  variant: AppTextVariant.tiny,
                  customColor: AppColors.error,
                  textAlign: TextAlign.center,
                ),
              ),
            AppButton(
              text: "Continue Payment",
              isLoading: _paymentLoadingOrderIds.contains(order.id),
              onPressed: () => _handleCompletePayment(order),
              variant: AppButtonVariant.primary,
              size: AppButtonSize.small,
              isFullWidth: true,
            ),
          ],
          if (order.folioNumber != null &&
              order.folioNumber!.isNotEmpty &&
              order.uiStatus.toUpperCase() != "FAILED") ...[
            const SizedBox(height: 16),
            AppButton(
              text: "Sell Fund",
              onPressed: () => _handleSell(order),
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSipCard(PortfolioSIPRegistrationV1 sip) {
    return InkWell(
      onTap: () => _showSipDetails(sip),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkInputBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppText(
                    sip.schemeName,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(sip.status),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      "Instalment",
                      "₹${sip.amount ?? '---'}",
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      "Next Date",
                      _formatDate(sip.nextInstallmentDate, fallback: "N/A"),
                    ),
                  ),
                ],
              ),
            ),
            if (sip.status == "PAYMENT_PENDING") ...[
              const SizedBox(height: 16),
              if (_paymentErrors.containsKey(sip.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppText(
                    _paymentErrors[sip.id]!,
                    variant: AppTextVariant.tiny,
                    customColor: AppColors.error,
                    textAlign: TextAlign.center,
                  ),
                ),
              AppButton(
                text: "Continue Payment",
                isLoading: _paymentLoadingOrderIds.contains(sip.id),
                onPressed: () => _handleCompletePayment(sip, isSip: true),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.small,
                isFullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusUpper = status.toUpperCase();
    Color color;
    Color bgColor;

    if (['DONE', 'SUCCESS', 'ACTIVE', 'PAID'].contains(statusUpper)) {
      color = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.1);
    } else if (['FAILED', 'CANCELLED', 'REJECTED'].contains(statusUpper)) {
      color = AppColors.error;
      bgColor = AppColors.error.withOpacity(0.1);
    } else {
      color = AppColors.warning;
      bgColor = AppColors.warning.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: AppText(
        statusUpper == "PAYMENT_PENDING"
            ? "PAYMENT PENDING"
            : (statusUpper == "FAILED" ? "CANCELLED" : statusUpper),
        variant: AppTextVariant.tiny,
        customColor: color,
        weight: AppTextWeight.bold,
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.tiny,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 4),
        AppText(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          variant: AppTextVariant.bodySmall,
          weight: AppTextWeight.medium,
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Obx(() {
      final String? currentStatus =
          _tabController.index == 0
              ? _controller.activeMfStatus.value
              : _controller.activeSipStatus.value;

      return Container(
        padding: const EdgeInsets.only(right: 24, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Semantics(
                button: true,
                label:
                    'Filter by Status. Current selection: ${_getStatusDisplay(currentStatus)}',
                child: GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          _getStatusDisplay(currentStatus),
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.black,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(
    String message, {
    IconData icon = Icons.history_toggle_off,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            AppText(
              message,
              variant: AppTextVariant.bodyLarge,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: "Retry",
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final bool isMfTab = _tabController.index == 0;
    final bool isSipTab = _tabController.index == 1;

    if (!isMfTab && !isSipTab) {
      Get.snackbar(
        "Notice",
        "Filtering is only available for Orders and SIPs",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.darkCardBG,
        colorText: Colors.white,
      );
      return;
    }

    final String? currentStatus =
        isMfTab
            ? _controller.activeMfStatus.value
            : _controller.activeSipStatus.value;

    final List<String?> options = [
      null,
      'DONE',
      'PROCESSING',
      'PAYMENT_PENDING',
      'CANCELLED',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Filter by Status",
                    variant: AppTextVariant.headline6,
                    weight: AppTextWeight.semiBold,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    options.map((status) {
                      final bool isSelected = currentStatus == status;
                      return ChoiceChip(
                        label: AppText(
                          _getStatusDisplay(status),
                          variant: AppTextVariant.bodySmall,
                          customColor:
                              isSelected ? Colors.black : Colors.white70,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (isMfTab) {
                            _controller.setMfStatusFilter(status);
                          } else {
                            _controller.setSipStatusFilter(status);
                          }
                          Navigator.pop(context);
                        },
                        selectedColor: Colors.white,
                        backgroundColor: AppColors.darkCardBG,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? AppColors.darkCardBG
                                    : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _getStatusDisplay(String? status) {
    if (status == null) return "All";
    if (status.toUpperCase() == 'FAILED') return "Cancelled";
    return status.replaceAll('_', ' ').toLowerCase().capitalizeFirst ?? status;
  }

  String _formatDate(String? dateStr, {String fallback = "---"}) {
    if (dateStr == null || dateStr.isEmpty) return fallback;
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showSipDetails(PortfolioSIPRegistrationV1 sip) async {
    _controller.fetchSipDetail(sip.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              if (_controller.isDetailLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.darkPrimary,
                  ),
                );
              }

              final detail = _controller.selectedSipDetail.value;
              if (detail == null) {
                return const Center(child: AppText("Failed to load details"));
              }

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppText(
                      sip.schemeName,
                      variant: AppTextVariant.headline6,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: detail.installments.length,
                      separatorBuilder:
                          (context, index) =>
                              const Divider(color: AppColors.darkCardBG),
                      itemBuilder: (context, index) {
                        final inst = detail.installments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: AppText(
                            "Installment #${inst.number}",
                            variant: AppTextVariant.bodyMedium,
                          ),
                          subtitle: AppText(
                            _formatDate(inst.dueDate),
                            variant: AppTextVariant.bodySmall,
                            colorType: AppTextColorType.secondary,
                          ),
                          trailing: _buildStatusBadge(inst.uiStatus),
                        );
                      },
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  void _showMfOrderDetails(PortfolioMFOrderV1 order) async {
    _controller.fetchMfOrderDetail(order.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              if (_controller.isDetailLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.darkPrimary,
                  ),
                );
              }

              final detail = _controller.selectedMfOrderDetail.value;
              if (detail == null) {
                return const Center(child: AppText("Failed to load details"));
              }

              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: AppText(
                        order.schemeName,
                        variant: AppTextVariant.headline6,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(child: _buildStatusBadge(detail.uiStatus)),
                    const SizedBox(height: 32),
                    _buildDetailRow(
                      "Transaction ID",
                      detail.bseOrderId ?? "---",
                    ),
                    _buildDetailRow("Amount", "₹${detail.amount}"),
                    _buildDetailRow(
                      "Date",
                      _formatDate(order.placedAt ?? order.createdAt),
                    ),
                    _buildDetailRow(
                      "Folio Number",
                      detail.folioNumber ?? "---",
                    ),
                    const Divider(height: 48, color: AppColors.darkCardBG),
                    AppText(
                      "Allotment Details",
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      "Units Allotted",
                      detail.allotmentUnits ?? "---",
                    ),
                    _buildDetailRow(
                      "NAV/Price",
                      detail.allotmentPrice != null
                          ? "₹${detail.allotmentPrice}"
                          : "---",
                    ),
                    const Divider(height: 48, color: AppColors.darkCardBG),
                    AppText(
                      "Payment Details",
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      "Status",
                      detail.payment?.paymentStatus ?? "---",
                    ),
                    _buildDetailRow(
                      "Ref ID",
                      detail.payment?.bsePaymentRefId ?? "---",
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.secondary,
          ),
          AppText(
            value,
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.medium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDescription(PortfolioMFOrderV1 order) {
    if (order.uiStatus.toUpperCase() == 'PAYMENT_PENDING'
    //||order.uiStatus.toUpperCase() == 'CANCELLED'
    ) {
      return const SizedBox();
    }
    final status = order.bseLifecycleStatus?.toLowerCase();
    if (status == null) return const SizedBox();

    // A clean way to map backend statuses to UI text
    const Map<String, Map<String, String>> statusContent = {
      'payment_pending': {
        'title': 'Payment Processing',
        'desc': 'We’re waiting for your bank to confirm the payment.',
      },
      'match_pending': {
        'title': 'Awaiting Match',
        'desc':
            'Your order is at the exchange. We are looking for a match for your request.',
      },
      'matched': {
        'title': 'Order Matched',
        'desc':
            'A match has been found! We are now finalizing the transaction.',
      },
      // 'success': {
      //   'title': 'Success',
      //   'desc': 'The transaction has been completed successfully.',
      // },
      'received': {
        'title': 'Order received',
        'desc':
            'Your transaction has been successfully received by Stock Exchange and is being processed',
      },
      'queued_for_rta': {
        'title': 'Order queued for RTA',
        'desc': 'Your transaction is being processed and will be updated soon',
      },
      'error': {
        'title': 'Something went wrong',
        'desc': 'Something went wrong.',
      },
    };

    if (!statusContent.containsKey(status)) return const SizedBox();

    // Only show for non-payment_pending OR if it is payment_pending (user said don't remove button)
    // Actually, user said: "if the status is other than payment_pending, then show these descriptions instead of continue payment button"
    // "dont remove Continue payment button in case of payment pending status"
    // This implies for others, description replaces button. Since button is already only for PAYMENT_PENDING uiStatus,
    // adding description always (if in map) handles this.

    final content = statusContent[status]!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: AppText(
                  content['title']!,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.semiBold,
                  customColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(
            content['desc']!,
            variant: AppTextVariant.tiny,
            colorType: AppTextColorType.secondary,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
        vertical: 8,
      ),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: AppColors.darkCardBG,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // color: AppColors.darkInputBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header Shimmer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 20,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details Card Shimmer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildShimmerDetailColumn()),
                      Expanded(child: _buildShimmerDetailColumn()),
                      _buildShimmerDetailColumn(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerDetailColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 10,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
