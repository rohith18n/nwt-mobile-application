import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/services/orders/order_service_v1.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';
import 'package:collection/collection.dart';

class RedeemOrderV1Screen extends StatefulWidget {
  final String fundName;
  final String isin;
  final String schemeCode;
  final double? nav;
  final String? fundLogo;
  final String? initialUcc;
  final String? initialFolio;
  final dynamic purchaseOrderId;
  final double? availableAmount;
  final double? availableUnits;

  const RedeemOrderV1Screen({
    super.key,
    required this.fundName,
    required this.isin,
    required this.schemeCode,
    this.nav,
    this.fundLogo,
    this.initialUcc,
    this.initialFolio,
    this.purchaseOrderId,
    this.availableAmount,
    this.availableUnits,
  });

  @override
  State<RedeemOrderV1Screen> createState() => _RedeemOrderV1ScreenState();
}

enum _RedeemMode { amount, units, all }

class _RedeemOrderV1ScreenState extends State<RedeemOrderV1Screen> {
  final OrderV1Controller _orderController = Get.find<OrderV1Controller>();
  final MutualFundOrderServiceV1 _orderService = MutualFundOrderServiceV1();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();

  _RedeemMode _selectedMode = _RedeemMode.amount;
  String? _selectedFolio;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  Future<void> _initializeSelections() async {
    // If we have an initial UCC, find and select the corresponding account
    if (widget.initialUcc != null) {
      if (_orderController.accounts.isEmpty) {
        await _orderController.fetchAccounts();
      }
      final matchingAccount = _orderController.accounts.firstWhereOrNull(
        (a) => a.clientCode == widget.initialUcc,
      );
      if (matchingAccount != null) {
        _orderController.selectedAccount.value = matchingAccount;
      }
    }

    // Set initial folio if provided, and ensure it's in the available list so UI displays it
    if (widget.initialFolio != null) {
      _orderController.availableFolios.assignAll([widget.initialFolio!]);
      setState(() => _selectedFolio = widget.initialFolio);
    } else if (_orderController.availableFolios.isNotEmpty) {
      setState(() {
        _selectedFolio = _orderController.availableFolios.first;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    if (_orderController.selectedAccount.value == null) {
      AppSnackBar.showError(context, "Please select an investment account");
      return;
    }

    if (_selectedFolio == null) {
      AppSnackBar.showError(context, "No folio available for redemption");
      return;
    }

    final amountText = _amountController.text.trim();
    final unitsText = _unitsController.text.trim();

    if (_selectedMode == _RedeemMode.amount && amountText.isEmpty) {
      AppSnackBar.showError(context, "Please enter an amount to sell");
      return;
    }

    if (_selectedMode == _RedeemMode.units && unitsText.isEmpty) {
      AppSnackBar.showError(context, "Please enter units to sell");
      return;
    }

    final amount = double.tryParse(amountText);
    final units = double.tryParse(unitsText);

    // Validation: Prevent zero/negative values
    if (_selectedMode == _RedeemMode.amount && (amount == null || amount < 1)) {
      AppSnackBar.showError(context, "Please enter a valid amount");
      return;
    }
    if (_selectedMode == _RedeemMode.units && (units == null || units <= 0)) {
      AppSnackBar.showError(
        context,
        "Please enter a valid unit count greater than zero",
      );
      return;
    }

    // Validation: Prevent selling more than available
    if (_selectedMode == _RedeemMode.amount &&
        widget.availableAmount != null &&
        amount! > widget.availableAmount!) {
      AppSnackBar.showError(
        context,
        "Amount exceeds available balance (₹${widget.availableAmount})",
      );
      return;
    }

    if (_selectedMode == _RedeemMode.units &&
        widget.availableUnits != null &&
        units! > widget.availableUnits!) {
      AppSnackBar.showError(
        context,
        "Units exceed available balance (${widget.availableUnits})",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _orderService.redeemOrder(
        purchaseOrderId:
            widget.purchaseOrderId != null
                ? int.tryParse(widget.purchaseOrderId.toString())
                : null,
        uccId: _orderController.selectedAccount.value!.id,
        schemeCode: widget.schemeCode,
        folioNumber: _selectedFolio,
        amount: _selectedMode == _RedeemMode.amount ? amount : null,
        units: _selectedMode == _RedeemMode.units ? units : null,
        allUnits: _selectedMode == _RedeemMode.all,
      );

      if (response.success && response.data != null) {
        _showSuccessDialog(response.data!.amount);
      } else {
        AppSnackBar.showError(context, response.message);
      }
    } catch (e) {
      AppSnackBar.showError(context, "An error occurred: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.darkCardBG,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(height: 16),
                AppText(
                  "Redemption Placed",
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                ),
                const SizedBox(height: 8),
                AppText("Amount: ₹$amount"),
                const SizedBox(height: 24),
                AppButton(
                  text: "Done",
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Close Redeem screen
                  },
                  isFullWidth: true,
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFolio = _orderController.availableFolios.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Semantics(
          header: true,
          child: AppText(
            "Sell fund",
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
        child: Obx(() {
          final accounts = _orderController.accounts;
          final hasFolios =
              _orderController.availableFolios.isNotEmpty &&
              _orderController.availableFolios.value.toString() !=
                  '[New Folio]';
          if (accounts.isEmpty) {
            return Column(
              children: [
                _buildFundInfo(),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          "No linked investment accounts found. Please contact support.",
                          variant: AppTextVariant.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFundInfo(),
              const SizedBox(height: 32),
              if (!hasFolios) _buildNoFolioWarning(),
              if (hasFolios) ...[
                _buildFolioSelector(),
                const SizedBox(height: 24),
                _buildRedemptionOptions(),
                const SizedBox(height: 48),
                _buildActionButtons(),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFundInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // _buildFundLogo(),
          // const SizedBox(width: 12),
          Expanded(
            child: AppText(
              widget.fundName,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child:
            widget.fundLogo != null && widget.fundLogo!.isNotEmpty
                ? Image.network(widget.fundLogo!, fit: BoxFit.contain)
                : const Icon(
                  Icons.account_balance,
                  color: AppColors.darkPrimary,
                ),
      ),
    );
  }

  Widget _buildNoFolioWarning() {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                "No active folio found for this fund. You cannot sell this fund through this account.",
                customColor: AppColors.error,
                variant: AppTextVariant.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Sell from Folio",
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children:
              _orderController.availableFolios.map((f) {
                final isSelected = _selectedFolio == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedFolio = f),
                  selectedColor: AppColors.darkPrimary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  backgroundColor: AppColors.darkCardBG,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildRedemptionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "How much do you want to sell?",
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkInputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildModeOption(_RedeemMode.amount, "Amount"),
              _buildModeOption(_RedeemMode.units, "Units"),
              _buildModeOption(_RedeemMode.all, "Sell All"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedMode == _RedeemMode.amount) _buildAmountInput(),
        if (_selectedMode == _RedeemMode.units) _buildUnitsInput(),
        if (_selectedMode == _RedeemMode.all) _buildSellAllInfo(),
      ],
    );
  }

  Widget _buildModeOption(_RedeemMode mode, String label) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () => setState(() => _selectedMode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.darkPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AppText(
                label,
                variant: AppTextVariant.bodySmall,
                weight: isSelected ? AppTextWeight.bold : AppTextWeight.medium,
                customColor: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Enter Amount",
          variant: AppTextVariant.caption,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Enter Amount to sell',
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: "₹ ",
              prefixStyle: const TextStyle(color: Colors.white, fontSize: 20),
              filled: true,
              fillColor: AppColors.darkInputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: "0.00",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
        if (widget.availableAmount != null) ...[
          const SizedBox(height: 8),
          AppText(
            "Available: ₹${widget.availableAmount}",
            variant: AppTextVariant.caption,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildUnitsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Enter Units",
          variant: AppTextVariant.caption,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Enter Units to sell',
          child: TextField(
            controller: _unitsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.darkInputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: "0.000",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
        if (widget.availableUnits != null) ...[
          const SizedBox(height: 8),
          AppText(
            "Available Units: ${widget.availableUnits}",
            variant: AppTextVariant.caption,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildSellAllInfo() {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.darkPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                "You are choosing to liquidate your entire position in this fund.",
                variant: AppTextVariant.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Selling from Account",
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 12),
        Obx(() {
          final account = _orderController.selectedAccount.value;
          if (account == null) return const SizedBox.shrink();

          return Semantics(
            button: true,
            onTapHint: 'Double tap to change account',
            child: InkWell(
              onTap:
                  _orderController.accounts.length > 1
                      ? _showAccountPicker
                      : null,
              child: MergeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkInputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.darkPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              account.clientCode,
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                            ),
                            AppText(
                              account.holdingNature,
                              variant: AppTextVariant.caption,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ),
                      if (_orderController.accounts.length > 1)
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAccountPicker() {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                header: true,
                child: AppText(
                  "Select Account",
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _orderController.accounts.length,
                itemBuilder: (context, index) {
                  final acc = _orderController.accounts[index];
                  return ListTile(
                    onTap: () {
                      _orderController.selectedAccount.value = acc;
                      _orderController.checkFolios(widget.isin);
                      Get.back();
                    },
                    leading: const Icon(
                      Icons.account_balance,
                      color: AppColors.darkPrimary,
                    ),
                    title: AppText(
                      acc.clientCode,
                      variant: AppTextVariant.bodyMedium,
                    ),
                    subtitle: AppText(
                      acc.holdingNature,
                      variant: AppTextVariant.caption,
                    ),
                    trailing:
                        acc.id == _orderController.selectedAccount.value?.id
                            ? const Icon(
                              Icons.check_circle,
                              color: AppColors.darkPrimary,
                            )
                            : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildActionButtons() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: AppButton(
          text: 'Confirm Sell',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          onPressed:
              _orderController.selectedAccount.value == null
                  ? null
                  : () {
                    _handleRedeem();
                  },
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
