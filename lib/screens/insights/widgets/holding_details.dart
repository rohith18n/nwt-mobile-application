import 'package:flutter/material.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/delta_indicator.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class HoldingDetails extends StatelessWidget {
  final double investedAmount;
  final double currentAmount;
  final double gain;
  final double gainPercentage;
  final String investedSince;
  final String folioNo;
  final double quantity;
  final String lasttrxndate;


  const HoldingDetails({
    super.key,
    required this.investedAmount,
    required this.currentAmount,
    required this.gain,
    required this.gainPercentage,
    required this.investedSince,
    required this.folioNo,
    required this.quantity,
    required this.lasttrxndate,
  });


  @override
  Widget build(BuildContext context) {
    return CustomAccordion(
      title: 'Your Holding Details',
      initiallyExpanded: true,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        childAspectRatio: 2.5,
        crossAxisSpacing: 5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGridItem(
            label: 'Invested Amount ',
            value: CurrencyFormatter.formatRupeeWithCommas(
              investedAmount,
              decimals: 2,
            ),
          ),

          _buildGridItem(
            label: 'Current Amount ',
            value: CurrencyFormatter.formatRupeeWithCommas(
              currentAmount,
              decimals: 2,
            ),
          ),

          _buildGridItem(
            label: 'Gain',
            value: CurrencyFormatter.formatRupeeWithCommas(gain, decimals: 2),
            suffix: DeltaIndicator(
              deltaValue: gainPercentage,
              deltaType:
                  gainPercentage > 0 ? DeltaType.positive : DeltaType.negative,
            ),
          ),
          _buildGridItem(label: 'Last Transaction Date', value: lasttrxndate),
          _buildGridItem(label: 'Folio No', value: folioNo),
          _buildGridItem(label: 'Quantity', value: "$quantity units"),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required String label,
    required String value,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            AppText(
              label,
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
            ),
            if (suffix != null) ...[const SizedBox(width: 4), suffix],
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: AppText(
            value.isNotEmpty
                ? value[0].toUpperCase() + value.substring(1)
                : value,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
