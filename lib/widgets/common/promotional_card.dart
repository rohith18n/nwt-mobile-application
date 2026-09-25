import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PromotionalCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onButtonTap;
  final String imagePath;
  final List<Color> gradientColors;
  final Alignment gradientCenter;
  final double gradientRadius;
  final bool useBackdropFilter;

  const PromotionalCard({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onButtonTap,
    required this.imagePath,
    required this.gradientColors,
    this.gradientCenter = Alignment.topCenter,
    this.gradientRadius = 1.4,
    this.useBackdropFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: gradientColors,
          center: gradientCenter,
          radius: gradientRadius,
        ),
      ),
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.headline5,
                  weight: AppTextWeight.bold,
                  lineHeight: 1.2,
                ),
                const SizedBox(height: 8),
                AppText(
                  description,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.semiBold,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onButtonTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.darkPrimary,
                    ),
                    child: AppText(
                      buttonText,
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: Image.asset(imagePath, fit: BoxFit.contain)),
        ],
      ),
    );

    if (useBackdropFilter) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: cardContent,
        ),
      );
    } else {
      return cardContent;
    }
  }
}
