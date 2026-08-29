import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:intl/intl.dart';

class OrderActivityCard extends StatelessWidget {
  final String fundName;
  final String? fundIcon;
  final double payAmount;
  final DateTime date;
  final String orderId;
  final String status;
  final VoidCallback? onTap;

  const OrderActivityCard({
    super.key,
    required this.fundName,
    this.fundIcon,
    required this.payAmount,
    required this.date,
    required this.orderId,
    required this.status,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'buy pending':
      case 'pending':
        return AppColors.error;
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'processing':
        return AppColors.warning;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd, MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkButtonBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Fund Name and Status
            Row(
              children: [
                // Fund Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Fund Name
                Expanded(
                  child: AppText(
                    fundName,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.primary,
                    maxLines: 2,
                  ),
                ),

                const SizedBox(width: 12),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getStatusColor(), width: 1),
                  ),
                  child: AppText(
                    status,
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.medium,
                    customColor: _getStatusColor(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Details Row
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkInputBorder,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkButtonBorder, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pay Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Pay Amount',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          '₹${payAmount.toStringAsFixed(0)}',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ),
                  ),

                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Date',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          _formatDate(date),
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ),
                  ),

                  // Order ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Order ID',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.secondary,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          orderId,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
