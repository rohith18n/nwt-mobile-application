import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class OrderSummaryWidget extends StatelessWidget {
  final String totalAmount;
  final String selectedBank;
  final String accountNumber;
  final String upiId;
  final VoidCallback onBankTap;
  final VoidCallback onPayNow;

  const OrderSummaryWidget({
    super.key,
    required this.totalAmount,
    required this.selectedBank,
    required this.accountNumber,
    required this.upiId,
    required this.onBankTap,
    required this.onPayNow,
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
            'Select Bank',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onBankTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        accountNumber,
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.medium,
                        colorType: AppTextColorType.white,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        selectedBank,
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.gray,
                      ),
                    ],
                  ),
                  Icon(
                    Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'Order will fail if UPI ID is not linked to this bank',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
          const SizedBox(height: 32),
          AppText(
            'Enter UPI ID',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '$selectedBank | $accountNumber',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.white,
                ),
                const SizedBox(height: 4),
                AppText(
                  upiId,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.gray,
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Pay Now',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: onPayNow,
            ),
          ),
        ],
      ),
    );
  }
}
