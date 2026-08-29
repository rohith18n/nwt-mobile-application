import 'package:flutter/material.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
import 'package:nwt_app/screens/dashboard/widgets/mf_top_performers_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class MFTopPerformersSection extends StatelessWidget {
  final MFTopPerformersController mfTopPerformersController;

  const MFTopPerformersSection({
    super.key,
    required this.mfTopPerformersController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                "Top Performing Mutual Funds",
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              TextButton(
                onPressed: () {},
                child: const AppText(
                  "See All",
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.link,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MFTopPerformersWidget(controller: mfTopPerformersController, dashboard: true, assetclass: "",),
        const SizedBox(height: 16),
      ],
    );
  }
}
