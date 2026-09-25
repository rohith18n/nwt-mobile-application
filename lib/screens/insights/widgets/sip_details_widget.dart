import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class SipDetailsWidget extends StatelessWidget {
  final String minimumSip;
  final String maximumSip;
  final String frequency;
  final double lockInPeriod;

  const SipDetailsWidget({
    super.key,
    required this.minimumSip,
    required this.maximumSip,
    required this.frequency,
    required this.lockInPeriod,
  });

  @override
  Widget build(BuildContext context) {

    return CustomAccordion(
      title: 'Your SIP Details',
      initiallyExpanded: true,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        childAspectRatio: 2.5,
        crossAxisSpacing: 5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGridItem(label: 'Minimum SIP ', value: minimumSip),

          _buildGridItem(label: 'Maximum SIP ', value: maximumSip),

          _buildGridItem(label: 'Frequency', value: frequency),

          _buildGridItem(
            label: 'Lock-in-Period',
            value: lockInPeriod.toString(),
          ),
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
