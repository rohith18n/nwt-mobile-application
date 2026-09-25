import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/paper_trading/choose_investment_method.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class ChooseStrategyScreen extends StatefulWidget {
  const ChooseStrategyScreen({super.key});

  @override
  State<ChooseStrategyScreen> createState() => _ChooseStrategyScreenState();
}

class _ChooseStrategyScreenState extends State<ChooseStrategyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.chevron_left, color: Colors.white, size: 24.sp),
            ),
            AppText(
              "Choose Strategy",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Text
                AppText(
                  "SELECT 1 OR MORE STRATEGY",
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),

                SizedBox(height: 16.h),

                // VELOCITY MIDCAP Strategy Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.darkInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Strategy Title
                      AppText(
                        "VELOCITY MIDCAP",
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),

                      SizedBox(height: 8.h),

                      // Stocks count
                      AppText(
                        "10 Stocks • Nifty Midcap 150",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),

                      SizedBox(height: 12.h),

                      // Performance metrics
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "1Y RETURN*",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                  weight: AppTextWeight.medium,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "23.4%",
                                  variant: AppTextVariant.headline6,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.success,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "BENCHMARK",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                  weight: AppTextWeight.medium,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "18.0%",
                                  variant: AppTextVariant.headline6,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // Description
                      AppText(
                        "A meticulously curated, momentum-based equity strategy designed for long-term wealth creation. Focused on mid-cap growth stocks, it maintains a concentrated 10-stock, equally weighted portfolio using systematic rule driven approach combining Absolute and Relative Momentum principles.",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        lineHeight: 1.5,
                      ),

                      SizedBox(height: 12.h),

                      // Risk Label
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: AppText(
                          "HIGH RISK • HIGH RETURNS",
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          customColor: Colors.red,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Select Button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: "Select this strategy",
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.large,
                          onPressed: () {
                            Get.to(() => const ChooseInvestmentMethodScreen());
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // SURGE SMALLCAP Strategy Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.darkInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Strategy Title
                      AppText(
                        "SURGE SMALLCAP",
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),

                      SizedBox(height: 8.h),

                      // Stocks count
                      AppText(
                        "15 Stocks • Nifty Smallcap 250",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),

                      SizedBox(height: 12.h),

                      // Performance metrics
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "1Y RETURN*",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                  weight: AppTextWeight.medium,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "31.7%",
                                  variant: AppTextVariant.headline6,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.success,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "BENCHMARK",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                  weight: AppTextWeight.medium,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "20%",
                                  variant: AppTextVariant.headline6,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // Description
                      AppText(
                        "A high-powered smallcap momentum strategy crafted for ambitious investors. Tapping into Nifty Smallcap 250 index, it identifies early breakout performers and builds a focused 15-stock, equally weighted portfolio powered by systematic, rule based momentum approach.",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        lineHeight: 1.5,
                      ),

                      SizedBox(height: 12.h),

                      // Risk Label
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: AppText(
                          "VERY HIGH RISK • VERY HIGH RETURNS",
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          customColor: Colors.red,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Select Button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: "Select this strategy",
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.large,
                          onPressed: () {
                            Get.to(() => const ChooseInvestmentMethodScreen());
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Risk Warning
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A00),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF4A3300),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, color: Colors.amber, size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "RISK WARNING",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.bold,
                              customColor: Colors.amber,
                            ),
                            SizedBox(height: 8.h),
                            AppText(
                              "This is a virtual portfolio simulation. Past performance doesn't guarantee future results. All investments are subject to market risks. High volatility strategies may experience significant drawdowns.",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                              lineHeight: 1.4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
