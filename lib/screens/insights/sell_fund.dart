import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/bse_star_v2/order_management/create_order_management.dart';

class SellFundScreen extends StatefulWidget {
  final String fundName;
  final String isin;
  final String folio;
  final double totalUnits;
  final double currentAmount;
  final double nav;
  final String? fundLogo;

  const SellFundScreen({
    super.key,
    required this.fundName,
    required this.isin,
    required this.folio,
    required this.totalUnits,
    required this.currentAmount,
    required this.nav,
    this.fundLogo,
  });

  @override
  State<SellFundScreen> createState() => _SellFundScreenState();
}

class _SellFundScreenState extends State<SellFundScreen> {
  bool _sellAllUnits = false;
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unitsController.addListener(_onUnitsChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _onUnitsChanged() {
    final text = _unitsController.text;
    if (text.isEmpty) {
      _amountController.text = '';
      return;
    }
    final units = double.tryParse(text) ?? 0;
    if (units > 0) {
      final amount = units * widget.nav;
      _amountController.text = "₹ ${amount.toStringAsFixed(2)}";
    } else {
      _amountController.text = '';
    }
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
            Semantics(
              button: true,
              label: 'Back',
              onTap: () => Navigator.pop(context),
              child: GestureDetector(
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
            ),
            Semantics(
              header: true,
              child: AppText(
                "Sell Funds",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
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
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Redeem From Section
                      Semantics(
                        header: true,
                        child: AppText(
                          'Redeem From',
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MergeSemantics(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkInputBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ExcludeSemantics(
                                    child: Container(
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
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText(
                                      widget.fundName,
                                      variant: AppTextVariant.bodyMedium,
                                      weight: AppTextWeight.medium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCardBG,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.folio.isNotEmpty)
                                      AppText(
                                        'Folio No.: ${widget.folio}',
                                        variant: AppTextVariant.bodyMedium,
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        AppText(
                                          'Value: ₹${widget.currentAmount.toStringAsFixed(2)}',
                                          variant: AppTextVariant.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        AppText(
                                          'Units: ${widget.totalUnits.toStringAsFixed(2)}',
                                          variant: AppTextVariant.bodyMedium,
                                        ),
                                        AppText(
                                          'NAV: ₹${widget.nav.toStringAsFixed(4)}',
                                          variant: AppTextVariant.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Withdraw Details Section
                      Semantics(
                        header: true,
                        child: AppText(
                          'Withdraw Details',
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkInputBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  AppText(
                                    'Amount',
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  Semantics(
                                    label: 'Withdrawal Amount (calculated based on units)',
                                    child: TextField(
                                      controller: _amountController,
                                      readOnly: true,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Amount',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkInputBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  AppText(
                                    'Units',
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  Semantics(
                                    label: 'Withdrawal Units',
                                    child: TextField(
                                      controller: _unitsController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Units',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Sell All Units
                      Semantics(
                        selected: _sellAllUnits,
                        label: 'Sell All Units',
                        button: true,
                        onTap: () {
                          setState(() {
                            _sellAllUnits = !_sellAllUnits;
                            if (_sellAllUnits) {
                              _amountController.text =
                                  "₹ ${widget.currentAmount.toStringAsFixed(2)}";
                              _unitsController.text = widget.totalUnits
                                  .toStringAsFixed(3);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.darkButtonBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                'Sell All Units',
                                variant: AppTextVariant.bodyMedium,
                              ),
                              ExcludeSemantics(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _sellAllUnits,
                                    onChanged: (value) {
                                      setState(() {
                                        _sellAllUnits = value ?? false;
                                        if (_sellAllUnits) {
                                          _amountController.text =
                                              "₹ ${widget.currentAmount.toStringAsFixed(2)}";
                                          _unitsController.text = widget.totalUnits
                                              .toStringAsFixed(3);
                                        }
                                      });
                                    },
                                    activeColor: Colors.white,
                                    checkColor: Colors.black,
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Message
                      Semantics(
                        container: true,
                        label: 'Important Information',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkInputBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppText(
                                  'Sell orders once placed cannot be cancelled.',
                                  variant: AppTextVariant.bodyMedium,
                                  colorType: AppTextColorType.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedErrorMessage(
                    errorMessage:
                        widget.totalUnits <= 0
                            ? 'You have no units available to sell for this fund.'
                            : _errorMessage,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Continue',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isDisabled: widget.totalUnits <= 0,
                      onPressed: () async {
                        final amountStr =
                            _amountController.text.replaceAll('₹', '').trim();
                        final amount = double.tryParse(amountStr) ?? 0;

                        if (amount <= 0) {
                          setState(() {
                            _errorMessage = 'Please enter a valid amount';
                          });
                          return;
                        }

                        if (amount > widget.currentAmount) {
                          setState(() {
                            _errorMessage = 'Amount exceeds available balance';
                          });
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });

                        try {
                          final response = await CreateOrderService.sellOrder(
                            schemeIsin: widget.isin,
                            amount: amount.toInt(),
                          );

                          if (response != null && response.statusCode == 200) {
                            Get.snackbar(
                              'Success',
                              'Sell order placed successfully',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _errorMessage =
                                  response?.message ??
                                  'Failed to place sell order';
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'An error occurred: $e';
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
