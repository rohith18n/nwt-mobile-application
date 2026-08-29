import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class PaymentMethodWidget extends StatelessWidget {
  final String totalAmount;
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onNext;

  const PaymentMethodWidget({
    super.key,
    required this.totalAmount,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Order Summary',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 32),
          AppText(
            'Total Payable',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AppText(
              totalAmount,
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.white,
            ),
          ),
          const SizedBox(height: 32),
          AppText(
            'Select Payment Method',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodOption(
            'UPI',
            'Pay using UPI apps like GPay, PhonePe, Paytm',
            Icons.account_balance_wallet_outlined,
            'UPI',
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            'Net Banking',
            'Pay directly from your bank account',
            Icons.account_balance_outlined,
            'Net Banking',
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            'Debit Card',
            'Pay using your debit card',
            Icons.credit_card_outlined,
            'Debit Card',
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodOption(
            'Credit Card',
            'Pay using your credit card',
            Icons.credit_card,
            'Credit Card',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Continue',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: selectedPaymentMethod.isNotEmpty ? onNext : () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String title,
    String subtitle,
    IconData icon,
    String value,
  ) {
    final isSelected = selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () => onPaymentMethodChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    subtitle,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.gray,
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[600]!,
                  width: 2,
                ),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
