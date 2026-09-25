import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class NotificationCard extends StatelessWidget {
  final String notificationTitle;
  final IconData icon;
  final String notificationMessage;
  final String date;
  final VoidCallback? onTap;

  const NotificationCard({
    Key? key,
    required this.notificationTitle,
    required this.icon,
    required this.notificationMessage,
    required this.date,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkButtonBorder,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppColors.darkTextMuted,
              ),
            ),

            Expanded(
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    notificationTitle,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                  ),
                  AppText(
                    notificationMessage,
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.regular,
                    colorType: AppTextColorType.primary,
                  ),
                  AppText(
                    date,
                    variant: AppTextVariant.tiny,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.secondary,
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
