import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/orders/orders_controller.dart';
import 'package:nwt_app/screens/advisory/types/order_history_model.dart';
import 'package:nwt_app/screens/bse_star_v2/start_journey.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/screens/insights/insights.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/pulse_animation.dart';
import 'package:nwt_app/widgets/common/payment_webView.dart';
import 'package:nwt_app/screens/orders/redeem_order_v1_screen.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrdersController controller;
  final Set<dynamic> _cancellingOrderIds = {}; // Track orders being cancelled
  final Set<dynamic> _paymentLoadingOrderIds =
      {}; // Track orders where payment is being initiated

  @override
  void initState() {
    super.initState();
    controller = Get.find<OrdersController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(0, 132, 81, 81),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.transparent,
                  size: 20,
                ),
              ),
            ),
            AppText(
              "Orders",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.transparent,
                  size: 20,
                ),
              ),
            ),
            //  const WhatsAppSupportButton(size: 20, color: Colors.white),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.fetchOrders();
              },
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? _buildShimmerLoading()
                        : controller.error.value != null
                        ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            alignment: Alignment.center,
                            child: AppText(
                              controller.error.value!,
                              variant: AppTextVariant.bodyMedium,
                              colorType: AppTextColorType.error,
                            ),
                          ),
                        )
                        : controller.orders.isEmpty
                        ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            alignment: Alignment.center,
                            child: _buildEmptyState(),
                          ),
                        )
                        : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.scaffoldHorizontalPadding,
                            vertical: 8,
                          ),
                          itemCount: controller.orders.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final order = controller.orders[index];

                            final isSuccess = order.isSuccess;
                            final isFailed = order.isFailed;
                            final statusText = order.displayStatus;
                            final fundName = order.displayFundName;
                            final fundLogo = order.fundLogo;
                            final navText = order.displayNav;
                            final unitsText = order.displayUnits;
                            final orderIdText = order.displayOrderId;

                            return InkWell(
                              onTap: () {
                                if (order.isin != null) {
                                  Get.to(
                                    () => InsightsScreen(isincode: order.isin!),
                                    transition: Transition.rightToLeft,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.darkInputBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    // Fund Icon, Name and Status
                                    MergeSemantics(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (fundLogo != null &&
                                              fundLogo.isNotEmpty)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipOval(
                                                child: Image.network(
                                                  fundLogo,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return const Icon(
                                                      Icons.error,
                                                      size: 20,
                                                    );
                                                  },
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: const BoxDecoration(
                                                color: Colors.blueAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  fundName,
                                                  variant:
                                                      AppTextVariant.bodyMedium,
                                                  weight: AppTextWeight.medium,
                                                  maxLines: 2,
                                                ),
                                                const SizedBox(height: 4),
                                                AppText(
                                                  order.isRedemption
                                                      ? 'Redemption'
                                                      : 'Purchase',
                                                  variant:
                                                      AppTextVariant.bodySmall,
                                                  colorType:
                                                      AppTextColorType
                                                          .secondary,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSuccess
                                                      ? const Color(
                                                        0xFF133b2b,
                                                      ) // Dark green
                                                      : isFailed
                                                      ? const Color(
                                                        0xFF4b1b1b,
                                                      ) // Dark red
                                                      : const Color(
                                                        0xFF3b3013,
                                                      ), // Dark yellow/orange for pending
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: AppText(
                                              statusText,
                                              variant: AppTextVariant.bodySmall,
                                              colorType:
                                                  isSuccess
                                                      ? AppTextColorType.success
                                                      : isFailed
                                                      ? AppTextColorType.error
                                                      : AppTextColorType
                                                          .warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Transaction Details Dark Card
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkCardBG,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Table(
                                            columnWidths: const {
                                              0: FlexColumnWidth(),
                                              1: FlexColumnWidth(),
                                              2: IntrinsicColumnWidth(),
                                            },
                                            children: [
                                              TableRow(
                                                children: [
                                                  _buildDetailColumn(
                                                    'Amount',
                                                    controller.formatCurrency(
                                                      order.amount,
                                                    ),
                                                  ),
                                                  _buildDetailColumn(
                                                    'NAV',
                                                    navText,
                                                  ),
                                                  _buildDetailColumn(
                                                    'Units',
                                                    unitsText,
                                                    alignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                  ),
                                                ],
                                              ),
                                              const TableRow(
                                                children: [
                                                  SizedBox(height: 16),
                                                  SizedBox(height: 16),
                                                  SizedBox(height: 16),
                                                ],
                                              ),
                                              TableRow(
                                                children: [
                                                  _buildDetailColumn(
                                                    'Date',
                                                    controller.formatDate(
                                                      order.createdAt,
                                                    ),
                                                  ),
                                                  _buildDetailColumn(
                                                    'Order ID',
                                                    orderIdText,
                                                  ),
                                                  if (order.folioNumber !=
                                                          null &&
                                                      order
                                                          .folioNumber!
                                                          .isNotEmpty)
                                                    _buildDetailColumn(
                                                      'Folio',
                                                      order.displayFolioNumber,
                                                      alignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                    )
                                                  else
                                                    const SizedBox(),
                                                ],
                                              ),
                                              if ((order.bseLifecycleStatus !=
                                                          null &&
                                                      order
                                                          .bseLifecycleStatus!
                                                          .isNotEmpty) ||
                                                  (order.internalStatus !=
                                                          null &&
                                                      order
                                                          .internalStatus!
                                                          .isNotEmpty)) ...[
                                                const TableRow(
                                                  children: [
                                                    SizedBox(height: 16),
                                                    SizedBox(height: 16),
                                                    SizedBox(height: 16),
                                                  ],
                                                ),
                                                TableRow(
                                                  children: [
                                                    if (order.bseLifecycleStatus !=
                                                            null &&
                                                        order
                                                            .bseLifecycleStatus!
                                                            .isNotEmpty)
                                                      _buildDetailColumn(
                                                        'Current Stage',
                                                        order
                                                            .displayLifecycleStatus,
                                                      )
                                                    else
                                                      const SizedBox(),
                                                    if (order.internalStatus !=
                                                            null &&
                                                        order
                                                            .internalStatus!
                                                            .isNotEmpty)
                                                      _buildDetailColumn(
                                                        'Internal Status',
                                                        order
                                                            .displayInternalStatus,
                                                      )
                                                    else
                                                      const SizedBox(),
                                                    const SizedBox(),
                                                  ],
                                                ),
                                              ],
                                              if (order.allotmentDate != null ||
                                                  order.allotmentUnits !=
                                                      null ||
                                                  order.allotmentPrice !=
                                                      null) ...[
                                                const TableRow(
                                                  children: [
                                                    SizedBox(height: 16),
                                                    SizedBox(height: 16),
                                                    SizedBox(height: 16),
                                                  ],
                                                ),
                                                TableRow(
                                                  children: [
                                                    if (order.allotmentDate !=
                                                        null)
                                                      _buildDetailColumn(
                                                        'Allotted On',
                                                        order
                                                            .displayAllotmentDate,
                                                      )
                                                    else
                                                      const SizedBox(),
                                                    if (order.allotmentUnits !=
                                                        null)
                                                      _buildDetailColumn(
                                                        'Units Allotted',
                                                        order
                                                            .displayAllotmentUnits,
                                                      )
                                                    else
                                                      const SizedBox(),
                                                    if (order.allotmentPrice !=
                                                        null)
                                                      _buildDetailColumn(
                                                        'Allotment Price',
                                                        order
                                                            .displayAllotmentPrice,
                                                        alignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                      )
                                                    else
                                                      const SizedBox(),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (order.isProcessing)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.darkCardBG
                                                .withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.warning
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const PulseAnimation(
                                                child: Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 16,
                                                  color: AppColors.warning,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: AppText(
                                                  order.isRedemption
                                                      ? "Redemption request received! Funds will be credited to your bank account within 3-5 business days."
                                                      : "Order submitted! Your units will be allotted in your folio within 3-5 business days.",
                                                  variant:
                                                      AppTextVariant.bodySmall,
                                                  colorType:
                                                      AppTextColorType.warning,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (order.status.toLowerCase() ==
                                            'pending_execution' ||
                                        order.status.toLowerCase() ==
                                            'payment_pending' ||
                                        order.status.toLowerCase() == 'pending')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Row(
                                          children: [
                                            if (order.isPaymentPending) ...[
                                              Expanded(
                                                child: AppButton(
                                                  customBorderRadius: 12.r,
                                                  text: 'Complete Payment',
                                                  variant:
                                                      AppButtonVariant.primary,
                                                  size: AppButtonSize.small,
                                                  customHeight: 48.h,
                                                  isFullWidth: true,
                                                  isLoading:
                                                      _paymentLoadingOrderIds
                                                          .contains(order.id),
                                                  onPressed:
                                                      () =>
                                                          _handleCompletePayment(
                                                            order,
                                                          ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: SizedBox(
                                                height:
                                                    48.h, // Slightly reduced height for small buttons
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed:
                                                      _cancellingOrderIds
                                                              .contains(
                                                                order.id,
                                                              )
                                                          ? null
                                                          : () =>
                                                              _showCancelDialog(
                                                                context,
                                                                order,
                                                              ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.error,
                                                    side: const BorderSide(
                                                      color: AppColors.error,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal: 4,
                                                        ),
                                                  ),
                                                  child:
                                                      _cancellingOrderIds
                                                              .contains(
                                                                order.id,
                                                              )
                                                          ? const SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color:
                                                                      AppColors
                                                                          .error,
                                                                ),
                                                          )
                                                          : const FittedBox(
                                                            fit:
                                                                BoxFit
                                                                    .scaleDown,
                                                            child: AppText(
                                                              'Cancel Order',
                                                              variant:
                                                                  AppTextVariant
                                                                      .bodySmall,
                                                              customColor:
                                                                  AppColors
                                                                      .error,
                                                              weight:
                                                                  AppTextWeight
                                                                      .semiBold,
                                                            ),
                                                          ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (order.folioNumber != null &&
                                        order.folioNumber!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: AppButton(
                                          customBorderRadius: 12.r,
                                          text: 'Sell Fund',
                                          variant: AppButtonVariant.secondary,
                                          size: AppButtonSize.small,
                                          customHeight: 48.h,
                                          isFullWidth: true,
                                          onPressed: () => _handleSell(order),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, OrderHistoryModel order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.darkInputBackground,
            title: AppText(
              "Cancel Order",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            content: AppText(
              "Are you sure you want to cancel this order for ${order.displayFundName}?",
              variant: AppTextVariant.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText(
                  "No",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  _handleCancel(order);
                },
                child: AppText(
                  "Yes, Cancel",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.error,
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleCancel(OrderHistoryModel order) async {
    setState(() {
      _cancellingOrderIds.add(order.id);
    });

    final success = await controller.cancelOrder(order.id);

    if (mounted) {
      setState(() {
        _cancellingOrderIds.remove(order.id);
      });

      if (success) {
        // Get.snackbar(
        //   "Order Cancelled",
        //   "Order for ${order.displayFundName} has been cancelled successfully.",
        //   backgroundColor: Colors.green.withOpacity(0.2),
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        //   duration: const Duration(seconds: 4),
        // );
      } else {
        Get.snackbar(
          "Cancellation Failed",
          "Could not cancel order for ${order.displayFundName}. Please try again.",
          backgroundColor: Colors.red.withOpacity(0.4),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    final bool onboardingStarted = controller.isOnboardingStarted.value;
    final bool uccRegistered = controller.isUccRegistered.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Illustration placeholder
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkInputBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          if (!uccRegistered) ...[
            AppText(
              onboardingStarted
                  ? "Complete Your Investment Profile"
                  : "Start Your Investment Journey",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppText(
              onboardingStarted
                  ? "You're just a few steps away from completing your profile. Finish it to start investing."
                  : "Complete your profile to start investing in mutual funds and managing your portfolio.",
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              onPressed:
                  () => Get.to(
                    () => const BSEStartjourney(),
                    transition: Transition.rightToLeft,
                  ),
              text:
                  onboardingStarted
                      ? "Continue Onboarding"
                      : "Complete Profile",
              //  isFullWidth: true,
            ),
          ] else ...[
            AppText(
              "No recent orders",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppText(
              "Your orders will appear here once you start investing.",
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCompletePayment(OrderHistoryModel order) async {
    setState(() {
      _paymentLoadingOrderIds.add(order.id);
    });

    try {
      final paymentUrl = await controller.getPaymentLink(order.id);

      if (mounted) {
        setState(() {
          _paymentLoadingOrderIds.remove(order.id);
        });
      }

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        final result = await Get.to<String>(
          () => PaymentWebView(paymentUrl: paymentUrl),
        );

        if (result == 'SUCCESS') {
          Get.snackbar(
            'Success',
            'Payment completed successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          controller.fetchOrders(); // Refresh orders
        } else if (result == 'FAILED') {
          Get.snackbar(
            'Payment Failed',
            'Your payment could not be completed. Please try again.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to generate payment link. Please try again later.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentLoadingOrderIds.remove(order.id);
        });
      }
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleSell(OrderHistoryModel order) async {
    final uccCode = await SecureStorage.read('UCC_CLIENT_CODE');

    Get.to(
      () => RedeemOrderV1Screen(
        fundName: order.displayFundName,
        isin: order.isin ?? '',
        schemeCode: order.bseScheme ?? order.scheme ?? '',
        nav: order.nav != null ? double.tryParse(order.nav.toString()) : null,
        fundLogo: order.fundLogo,
        initialFolio: order.folioNumber,
        purchaseOrderId: order.id,
        initialUcc: uccCode,
      ),
      transition: Transition.rightToLeft,
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildShimmerDetailColumn()),
                          Expanded(child: _buildShimmerDetailColumn()),
                          _buildShimmerDetailColumn(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildShimmerDetailColumn()),
                          Expanded(child: _buildShimmerDetailColumn()),
                          const Spacer(),
                        ],
                      ),
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

  Widget _buildDetailColumn(
    String title,
    String value, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          AppText(
            title,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
          const SizedBox(height: 4),
          AppText(
            value,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
          ),
        ],
      ),
    );
  }
}
