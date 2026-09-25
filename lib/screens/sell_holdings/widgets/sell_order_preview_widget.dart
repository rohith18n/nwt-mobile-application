import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class SellOrderPreviewWidget extends StatelessWidget {
  final String fundName;
  final String amount;
  final String units;
  final String paymentStatus;
  final String paymentMode;
  final String bankName;
  final String triggerTime;
  final String navDate;
  final String folioNumber;
  final VoidCallback onNext;

  const SellOrderPreviewWidget({
    super.key,
    required this.fundName,
    required this.amount,
    required this.units,
    required this.paymentStatus,
    required this.paymentMode,
    required this.bankName,
    required this.triggerTime,
    required this.navDate,
    required this.folioNumber,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: AppText(
              'Order Preview',
              variant: AppTextVariant.headline5,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.white,
            ),
          ),
          const SizedBox(height: 24),
          // Fund Name Card
          MergeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppText(
                      fundName,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.white,
                    ),
                  ),
                  Semantics(
                    label: 'Status: Verified',
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Order Details
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDetailRow('Sell', amount),
                  const SizedBox(height: 16),
                  _buildDetailRow('Units', units),
                  const SizedBox(height: 16),
                  _buildDetailRow('Payment Status', paymentStatus),
                  const SizedBox(height: 16),
                  _buildDetailRow('Payment Mode', paymentMode),
                  const SizedBox(height: 16),
                  _buildDetailRow('Bank', bankName),
                  const SizedBox(height: 16),
                  _buildDetailRow('Trigger Time', triggerTime),
                  const SizedBox(height: 16),
                  _buildDetailRow('NAV Date', navDate),
                  const SizedBox(height: 16),
                  _buildDetailRow('Folio No.', folioNumber),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Continue',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppText(
              value,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.white,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
