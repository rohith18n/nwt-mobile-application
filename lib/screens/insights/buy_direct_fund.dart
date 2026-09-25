import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/bse_star_v2/order_management/create_order_management.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';
import 'package:nwt_app/widgets/common/payment_webView.dart';

class BuyDirectFundScreen extends StatefulWidget {
  final String fundName;
  final String isin;
  final double? nav;
  final String? fundLogo;
  final double? minAmount;

  const BuyDirectFundScreen({
    super.key,
    required this.fundName,
    required this.isin,
    this.nav,
    this.fundLogo,
    this.minAmount,
  });

  @override
  State<BuyDirectFundScreen> createState() => _BuyDirectFundScreenState();
}

class _BuyDirectFundScreenState extends State<BuyDirectFundScreen> {
  final TextEditingController _amountController = TextEditingController();
  final List<int> quickAmounts = [500, 1000, 5000, 10000, 25000, 50000];
  int? selectedQuickAmount;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.darkInputBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            AppText(
              "Buy Direct Fund",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(
              opacity: 0,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.chevron_left, size: 20),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Fund Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkInputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child:
                              widget.fundLogo != null &&
                                      widget.fundLogo!.isNotEmpty
                                  ? Image.network(
                                    widget.fundLogo!,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.account_balance,
                                              color: Color(0xFF195B8E),
                                              size: 20,
                                            ),
                                  )
                                  : const Icon(
                                    Icons.account_balance,
                                    color: Color(0xFF195B8E),
                                    size: 20,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              widget.fundName,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                            ),
                            if (widget.nav != null)
                              AppText(
                                'NAV: ₹${widget.nav!.toStringAsFixed(2)}',
                                variant: AppTextVariant.bodySmall,
                                colorType: AppTextColorType.secondary,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                AppText(
                  'Enter Investment Amount',
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.semiBold,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    filled: true,
                    fillColor: AppColors.darkInputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.darkInputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.darkInputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.darkPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedQuickAmount = null;
                    });
                  },
                ),

                if (widget.minAmount != null && (widget.minAmount! / 10) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: AppText(
                      'Min. Investment: ₹${(widget.minAmount! / 10).toStringAsFixed(0)}',
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.secondary,
                    ),
                  ),

                const SizedBox(height: 24),

                AppText(
                  'Quick Select',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.secondary,
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      quickAmounts.map((amount) {
                        final isSelected = selectedQuickAmount == amount;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedQuickAmount = amount;
                              _amountController.text = amount.toString();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.darkPrimary
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.darkPrimary
                                        : AppColors.darkButtonBorder,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: AppText(
                              '₹${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K' : amount.toString()}',
                              variant: AppTextVariant.bodySmall,
                              weight: AppTextWeight.medium,
                              customColor:
                                  isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Invest Now',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    onPressed: _handleInvest,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleInvest() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      AppSnackBar.showError(context, "Please enter an amount");
      return;
    }

    final amount = int.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      AppSnackBar.showError(context, "Please enter a valid amount");
      return;
    }

    if (widget.minAmount != null && amount < (widget.minAmount! / 10)) {
      AppSnackBar.showError(
        context,
        "Minimum investment for this scheme is ₹${(widget.minAmount! / 10).toStringAsFixed(0)}",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await CreateOrderService.createOrder(
        schemeIsin: widget.isin,
        amount: amount,
      );

      if (response != null) {
        final redirectLink = response.data?.redirectLink;

        if (redirectLink != null && redirectLink.isNotEmpty) {
          // Use redirect_link directly from createOrder response
          await Get.to(() => PaymentWebView(paymentUrl: redirectLink));
          if (mounted) Navigator.pop(context); // Close buy screen after payment
          return;
        }

        // Fallback: if redirectLink is not in response, try to fetch it via getPaymentLink
        final bseOrderId = response.data?.bseOrderId;
        if (bseOrderId != null) {
          final paymentLinkResponse = await CreateOrderService.getPaymentLink(
            int.parse(bseOrderId),
          );

          final fallbackRedirectLink = paymentLinkResponse?.data?.redirectLink;
          if (fallbackRedirectLink != null) {
            await Get.to(
              () => PaymentWebView(paymentUrl: fallbackRedirectLink),
            );
            if (mounted)
              Navigator.pop(context); // Close buy screen after payment
          } else {
            AppSnackBar.showError(context, "Failed to get payment link");
          }
        } else {
          AppSnackBar.showError(context, response.message);
        }
      } else {
        AppSnackBar.showError(context, "Failed to create order");
      }
    } catch (e) {
      AppSnackBar.showError(context, "An error occurred: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
