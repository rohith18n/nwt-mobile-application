import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';

class InvestmentDetailsWidget extends StatelessWidget {
  final TextEditingController amountController;
  final String? selectedInvestmentType;
  final String? selectedAmount;
  final List<String> investmentTypes;
  final ValueChanged<String?> onInvestmentTypeChanged;
  final ValueChanged<String> onAmountSelected;
  final VoidCallback onNext;

  final double? minAmount;

  const InvestmentDetailsWidget({
    super.key,
    required this.amountController,
    this.selectedInvestmentType,
    this.selectedAmount,
    required this.investmentTypes,
    required this.onInvestmentTypeChanged,
    required this.onAmountSelected,
    required this.onNext,
    this.minAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Investment Details',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 24),
          DarkInputField(
            label: 'Amount*',
            controller: amountController,
            hintText: '₹ 500.00',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          if (minAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: AppText(
                'Min. amount: ₹${minAmount!.toStringAsFixed(0)}',
                variant: AppTextVariant.caption,
                colorType: AppTextColorType.secondary,
              ),
            ),
          const SizedBox(height: 16),
          // Scrollable amount selection chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryChip(
                  label: '₹ 1,000.00',
                  isSelected: selectedAmount == '1000',
                  onTap: () {
                    onAmountSelected('1000');
                    amountController.text = '1000';
                  },
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '₹ 5,000.00',
                  isSelected: selectedAmount == '5000',
                  onTap: () {
                    onAmountSelected('5000');
                    amountController.text = '5000';
                  },
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '₹ 10,000.00',
                  isSelected: selectedAmount == '10000',
                  onTap: () {
                    onAmountSelected('10000');
                    amountController.text = '10000';
                  },
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: '₹ 25,000.00',
                  isSelected: selectedAmount == '25000',
                  onTap: () {
                    onAmountSelected('25000');
                    amountController.text = '25000';
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppDropdown(
            value: selectedInvestmentType,
            items: investmentTypes,
            labelText: 'Investment Type',
            hintText: 'Select investment type',
            onChanged: onInvestmentTypeChanged,
            fillColor: Colors.transparent,
          ),
          const Spacer(),
          // Debug: Add test button for SIP screen
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Test SIP Screen',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.large,
              onPressed: () {
                print('Test SIP button pressed');
                // Force navigation to step 2 for testing
                onNext();
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Next',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
