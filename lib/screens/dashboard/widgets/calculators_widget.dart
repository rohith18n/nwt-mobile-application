import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/dashboard/types/calculators.dart';
import 'package:nwt_app/screens/dashboard/zerodha_webview.dart';

class CalculatorsSection extends StatelessWidget {
  final List<CalculatorItem> calculators;

  const CalculatorsSection({super.key, required this.calculators});

  @override
  Widget build(BuildContext context) {
    if (calculators.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                "Financial Calculators",
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              SizedBox(height: 4.h),
              AppText(
                "Plan your future with precision",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 220.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: calculators.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              return CalculatorCard(calculator: calculators[index]);
            },
          ),
        ),
      ],
    );
  }
}

class CalculatorCard extends StatelessWidget {
  final CalculatorItem calculator;

  const CalculatorCard({super.key, required this.calculator});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${calculator.name}. ${calculator.description}. Double tap to open.',
      button: true,
      child: GestureDetector(
        onTap: () {
          Get.to(
            () => ZerodhaWebView(url: calculator.url, title: calculator.name),
          );
        },
        child: ExcludeSemantics(
          child: Container(
            width: 260.w,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.darkButtonBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .trending_up, // Generic icon, we can map this later if needed
                    color: Colors.white,
                    size: 24.w,
                  ),
                ),
                const Spacer(),
                AppText(
                  calculator.name,
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
                SizedBox(height: 8.h),
                AppText(
                  calculator.description,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    AppText(
                      "Calculate now",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 16.w),
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
