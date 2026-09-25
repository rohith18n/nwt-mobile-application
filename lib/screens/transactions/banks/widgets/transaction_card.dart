import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/transactions/banks/details.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class BankTransactionCardWidget extends StatelessWidget {
  final Banktransation transaction;

  const BankTransactionCardWidget({super.key, required this.transaction});

  // Format date as "Today", "Yesterday", or the actual date
  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.type.toString().toLowerCase().contains('debit');
    final amount = CurrencyFormatter.formatRupeeWithCommas(transaction.amount);
    final formattedDate = _formatTransactionDate(
      transaction.transactiontimestamp,
    );

    // Extract merchant name from narration or use a default
    String merchantName =
        transaction.narration.isNotEmpty
            ? transaction.narration.split(' ').take(2).join(' ')
            : 'Transaction';

    if (merchantName.length > 20) {
      merchantName = '${merchantName.substring(0, 17)}...';
    }

    final semanticLabel =
        '$merchantName, $formattedDate, ${isDebit ? 'Debited' : 'Credited'} $amount';

    return Semantics(
      label: semanticLabel,
      button: true,
      hint: 'View transaction details',
      child: InkWell(
        onTap:
            () => Get.to(
              () => TransactionDetails(transaction: transaction),
              transition: Transition.rightToLeft,
            ),
        child: ExcludeSemantics(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.darkButtonBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkButtonBorder,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 20,
                          color: isDebit ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              merchantName,
                              variant: AppTextVariant.bodyLarge,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              formattedDate,
                              variant: AppTextVariant.bodySmall,
                              weight: AppTextWeight.regular,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      '${isDebit ? '-' : '+'}$amount',
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                      colorType:
                          isDebit
                              ? AppTextColorType.error
                              : AppTextColorType.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
