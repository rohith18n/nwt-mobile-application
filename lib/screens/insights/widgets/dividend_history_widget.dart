import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class DividendItem {
  final String recordDate;
  final String dividend;

  const DividendItem({required this.recordDate, required this.dividend});
}

class DividendHistoryWidget extends StatelessWidget {
  final List<DividendItem> dividendItems;

  const DividendHistoryWidget({super.key, required this.dividendItems});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color valueColor =
        isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return CustomAccordion(
      title: 'Dividend History',
      initiallyExpanded: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppText(
                    'Record Date',
                    variant: AppTextVariant.bodyMedium,
                    customColor: textColor,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.secondary,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: AppText(
                    'Dividend(₹/Unit)',
                    variant: AppTextVariant.bodyMedium,
                    customColor: textColor,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.secondary,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ...dividendItems.map(
            (item) => _buildDividendRow(item: item, valueColor: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDividendRow({
    required DividendItem item,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              item.recordDate,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              customColor: valueColor,
            ),
          ),
          Expanded(
            flex: 2,
            child: AppText(
              item.dividend,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              customColor: valueColor,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
