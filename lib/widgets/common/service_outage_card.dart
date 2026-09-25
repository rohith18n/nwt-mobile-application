import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class ServiceOutageCard extends StatelessWidget {
  const ServiceOutageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCardBG,
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              AppText(
                'SERVICE TEMPORARILY UNAVAILABLE',
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            'We are currently facing downtime with our mutual fund data provider. Fetching latest data is temporarily unavailable.',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 12),
          AppText(
            'Please try again later. Inconvenience caused is regretted.',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.white,
          ),
        ],
      ),
    );
  }
}
