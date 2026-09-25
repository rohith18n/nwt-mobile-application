import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/screens/orders/types/order_v1.dart';
import 'package:nwt_app/services/orders/order_service_v1.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/widgets/common/payment_webView.dart';

class PaymentProcessingV1Screen extends StatefulWidget {
  final OrderData orderData;
  final bool isSip;
  final bool isRedirected;

  const PaymentProcessingV1Screen({
    super.key,
    required this.orderData,
    this.isSip = false,
    this.isRedirected = false,
  });

  @override
  State<PaymentProcessingV1Screen> createState() =>
      _PaymentProcessingV1ScreenState();
}

class _PaymentProcessingV1ScreenState extends State<PaymentProcessingV1Screen> {
  final OrderV1Controller _orderController = Get.find<OrderV1Controller>();
  final MutualFundOrderServiceV1 _orderService = MutualFundOrderServiceV1();

  String? _selectedMode;
  bool _isInitiating = false;
  final TextEditingController _upiController = TextEditingController();
  Worker? _timeoutWorker;
  Timer? _successRedirectTimer;
  bool _successShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderData.upiId != null) {
      _upiController.text = widget.orderData.upiId!;
    }
    _upiController.addListener(_onUpiChanged);

    // Auto-back when timer hits 0
    _timeoutWorker = ever(_orderController.remainingSeconds, (int seconds) {
      if (seconds == 0 && _orderController.isPolling.value) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            "Payment verification timed out. Please try again.",
          );
          Get.back();
        }
      }
    });

    // Handle terminal state redirection — show success screen first, then redirect after 3s
    ever(_orderController.paymentStatus, (statusData) {
      if (statusData != null && !_successShown) {
        final status = statusData.orderStatus?.toUpperCase() ?? '';
        final paymentStatus = statusData.paymentStatus?.toUpperCase() ?? '';

        if (status == 'SUCCESS' || paymentStatus == 'SUCCESS') {
          _successShown = true;
          _successRedirectTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              Get.off(
                () => const StackedNavbar(selectedIdx: 1),
                transition: Transition.fadeIn,
              );
            }
          });
        }
      }
    });
  }


  void _onUpiChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _upiController.dispose();
    _timeoutWorker?.dispose();
    _successRedirectTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> _handlePaymentInitiation(String mode) async {
    setState(() {
      _selectedMode = mode;
      _isInitiating = true;
    });

    try {
      final response =
          widget.isSip
              ? await _orderService.initiateSipPayment(
                orderId: widget.orderData.orderId,
                paymentMode: mode,
                upiId: mode == 'UPI' ? _upiController.text.trim() : null,
              )
              : await _orderService.initiatePayment(
                orderId: widget.orderData.orderId,
                paymentMode: mode,
                upiId: mode == 'UPI' ? _upiController.text.trim() : null,
              );

      if (response.success && response.data != null) {
        if (mode == 'NETBANKING' && response.data!.paymentUrl != null) {
          Get.to(() => PaymentWebView(paymentUrl: response.data!.paymentUrl!));
          // For Netbanking, we still start polling to catch completion
          _orderController.startPaymentPolling(
            widget.orderData.orderId,
            isSip: widget.isSip,
            orderData: widget.orderData,
          );
        } else if (mode == 'UPI') {
          _orderController.startPaymentPolling(
            widget.orderData.orderId,
            isSip: widget.isSip,
            orderData: widget.orderData,
          );
        }
      } else {
        AppSnackBar.showError(context, response.message);
      }
    } catch (e) {
      AppSnackBar.showError(context, "Payment initiation failed: $e");
    } finally {
      setState(() => _isInitiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        title: Semantics(
          header: true,
          child: AppText(
            "Payment",
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          if (_orderController.isPolling.value) {
            return _buildPollingState();
          }
          return _buildPaymentOptionState();
        }),
      ),
    );
  }

  Widget _buildPaymentOptionState() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Total Amount",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      AppText(
                        "₹${widget.orderData.amount}",
                        variant: AppTextVariant.headline3,
                        weight: AppTextWeight.bold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Semantics(
                  label: "Select Any Payment Mode from the options below",
                  child: AppText(
                    "Select Payment Mode",
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModeCard(
                  "UPI",
                  "Pay via your default UPI app",
                  Icons.mobile_friendly_sharp,
                ),
                if (_selectedMode == 'UPI') ...[
                  const SizedBox(height: 12),
                  _buildUpiIdInput(),
                ],
                const SizedBox(height: 16),
                _buildModeCard(
                  "NETBANKING",
                  "Secure login via your bank",
                  Icons.account_balance,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (_orderController.paymentStatus.value?.paymentStatus == 'FAILED')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              liveRegion: true,
              label: "Error: Previous payment failed. Please try again.",
              child: AppText(
                "Previous payment failed. Please try again.",
                customColor: AppColors.error,
              ),
            ),
          ),
        _buildPayButton(),
      ],
    );
  }

  Widget _buildUpiIdInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "UPI ID",
          variant: AppTextVariant.caption,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: "UPI ID",
          child: TextField(
            controller: _upiController,
            decoration: InputDecoration(
              hintText: "example@upi",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: AppColors.darkInputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    final canPay =
        _selectedMode != null &&
        (_selectedMode != 'UPI' || _upiController.text.trim().isNotEmpty);
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: "Pay Now",
        onPressed:
            canPay
                ? () {
                  _handlePaymentInitiation(_selectedMode!);
                }
                : null,
        isLoading: _isInitiating,
        variant: AppButtonVariant.primary,
        size: AppButtonSize.large,
      ),
    );
  }

  Widget _buildModeCard(String mode, String subtitle, IconData icon) {
    final isSelected = _selectedMode == mode;
    return Semantics(
      selected: isSelected,
      label: "$mode, $subtitle",
      onTap: _isInitiating ? null : () => setState(() => _selectedMode = mode),
      excludeSemantics: true,
      child: InkWell(
        onTap:
            _isInitiating ? null : () => setState(() => _selectedMode = mode),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.darkPrimary
                      : AppColors.darkButtonBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.darkPrimary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      mode,
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.bold,
                    ),
                    AppText(
                      subtitle,
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.secondary,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.darkPrimary)
              else
                const Icon(Icons.circle_outlined, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollingState() {
    final statusData = _orderController.paymentStatus.value;
    final status = statusData?.orderStatus?.toUpperCase() ?? 'PAYMENT_PENDING';

    if (status == 'SUCCESS') {
      return _buildSuccessState();
    } else if (status == 'FAILED') {
      return _buildFailureState();
    } else {
      return _buildProcessingState(status);
    }
  }

  Widget _buildProcessingState(String status) {
    String title = "Payment request sent!";
    String message =
        "Please complete the payment in your ${_selectedMode ?? 'UPI'} app.";

    if (status == 'PROCESSING') {
      title =
          widget.isRedirected
              ? "An Order is already processing"
              : "Processing Order...";
      message =
          widget.isRedirected
              ? "You can only place one order at a time. Please wait for the current one to complete."
              : "We're confirming your order with the exchange. This may take a moment.";
    }

    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Processing payment',
              child: CircularProgressIndicator(color: AppColors.darkPrimary),
            ),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: AppText(
                title,
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppText(
                message,
                textAlign: TextAlign.center,
                colorType: AppTextColorType.secondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildCountdownTimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.darkPrimary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Obx(
            () => Semantics(
              label: 'Time remaining',
              value: _formatTime(_orderController.remainingSeconds.value),
              child: AppText(
                _formatTime(_orderController.remainingSeconds.value),
                variant: AppTextVariant.bodyMedium,
                customColor: AppColors.darkPrimary,
                weight: AppTextWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated success icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 56,
              ),
            ),
            const SizedBox(height: 28),
            AppText(
              "Investment Successful!",
              variant: AppTextVariant.headline5,
              weight: AppTextWeight.bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AppText(
              "Your order has been placed with the exchange.",
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Order details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildSuccessDetailRow(
                    'Amount Invested',
                    '₹${widget.orderData.amount}',
                    valueColor: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  _buildSuccessDetailRow(
                    'BSE Order ID',
                    widget.orderData.bseOrderId,
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  _buildSuccessDetailRow(
                    'Type',
                    widget.isSip ? 'SIP' : 'Lumpsum',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Auto-redirect indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                AppText(
                  'Redirecting to portfolio…',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _successRedirectTimer?.cancel();
                Get.off(
                  () => const StackedNavbar(selectedIdx: 1),
                  transition: Transition.fadeIn,
                );
              },
              child: AppText(
                'Go to Portfolio now',
                variant: AppTextVariant.bodySmall,
                customColor: AppColors.darkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
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
          weight: AppTextWeight.semiBold,
          customColor: valueColor,
        ),
      ],
    );
  }

  Widget _buildFailureState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'Failure icon',
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: AppText(
              "Payment Failed",
              variant: AppTextVariant.headline5,
              weight: AppTextWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const AppText(
            "We couldn't confirm your payment. Please try again.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          AppButton(
            text: "Try Again",
            onPressed: () {
              _orderController.stopPaymentPolling();
              // This will trigger a rebuild to _buildPaymentOptionState via Obx
            },
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
