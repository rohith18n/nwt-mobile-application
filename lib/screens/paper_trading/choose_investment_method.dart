import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/paper_trading/portfolio.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';

class ChooseInvestmentMethodScreen extends StatefulWidget {
  const ChooseInvestmentMethodScreen({super.key});

  @override
  State<ChooseInvestmentMethodScreen> createState() =>
      _ChooseInvestmentMethodScreenState();
}

class _ChooseInvestmentMethodScreenState
    extends State<ChooseInvestmentMethodScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              "Choose Investment Method",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      backgroundColor: Colors.black,
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
                // LUMPSUM Method Card
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
                      // Method Title
                      AppText(
                        "LUMPSUM",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            "Initial Investment",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                          ),
                          Row(
                            children: [
                              AppText(
                                "₹ 10,00,000.00",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () {
                                    AnalyticsService.to.logEvent(
                                      name: AnalyticsEvents.paperTradingEditClicked,
                                      parameters: {'field': 'initial_investment', 'method': 'LUMPSUM'},
                                    );
                                  },
                                  child: Icon(Icons.edit, size: 16.sp, color: Colors.grey),
                                ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.darkInputBorder,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  AppText(
                                    "Velocity Midcap",
                                    variant: AppTextVariant.bodySmall,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    "23.4%",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.bold,
                                    colorType: AppTextColorType.success,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.darkInputBorder,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  AppText(
                                    "Surge Smallcap",
                                    variant: AppTextVariant.bodySmall,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    "31.7%",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.bold,
                                    colorType: AppTextColorType.success,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // Description
                      AppText(
                        "One-time initial investment at portfolio launch. Best for investors with available capital who want immediate full exposure to the strategy.",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        lineHeight: 1.5,
                      ),

                      SizedBox(height: 12.h),

                      // Select Button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: "Select this method",
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.large,
                          onPressed: () {
                            // Handle selection
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // LUMPSUM + SIP Method Card
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
                      // Method Title
                      AppText(
                        "LUMPSUM + SIP",
                        variant: AppTextVariant.headline5,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),

                      SizedBox(height: 8.h),

                      // Initial Investment
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            "Initial Investment",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                          ),
                          Row(
                            children: [
                              AppText(
                                "₹ 10,00,000.00",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () {
                                    AnalyticsService.to.logEvent(
                                      name: AnalyticsEvents.paperTradingEditClicked,
                                      parameters: {'field': 'initial_investment', 'method': 'LUMPSUM + SIP'},
                                    );
                                  },
                                  child: Icon(Icons.edit, size: 16.sp, color: Colors.grey),
                                ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // SIP Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            "SIP",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                          ),
                          Row(
                            children: [
                              AppText(
                                "₹ 1,00,000.00",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () {
                                    AnalyticsService.to.logEvent(
                                      name: AnalyticsEvents.paperTradingEditClicked,
                                      parameters: {'field': 'sip_amount', 'method': 'LUMPSUM + SIP'},
                                    );
                                  },
                                  child: Icon(Icons.edit, size: 16.sp, color: Colors.grey),
                                ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // Strategy Performance
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.darkInputBorder,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  AppText(
                                    "Velocity Midcap",
                                    variant: AppTextVariant.bodySmall,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    "25.4%",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.bold,
                                    colorType: AppTextColorType.success,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.darkInputBorder,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  AppText(
                                    "Surge Smallcap",
                                    variant: AppTextVariant.bodySmall,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  SizedBox(height: 4.h),
                                  AppText(
                                    "33.7%",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.bold,
                                    colorType: AppTextColorType.success,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // Description
                      AppText(
                        "Initial investment plus SIP on first business day of every month. Ideal for gradual wealth building with rupee-cost averaging benefits and regular exposure increases.",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        lineHeight: 1.5,
                      ),

                      SizedBox(height: 12.h),

                      // Select Button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: "Select this method",
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.large,
                          onPressed: () {
                            // Handle selection
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Bottom Info Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.darkInputBorder,
                      width: 1,
                    ),
                  ),
                  child: AppText(
                    "Both variants: Track real-time performance • Monthly rebalancing • Benchmark comparison • Risk-free simulation environment",
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.4,
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        width: double.infinity,
        child: AppButton(
          text: "Start Portfolio Simulator",
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          onPressed: () {
            Get.to(() => PaperTradingPortfolioScreen());
          },
        ),
      ),
    );
  }
}
