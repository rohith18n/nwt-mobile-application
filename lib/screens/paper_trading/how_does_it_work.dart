import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/paper_trading/choose_strategy.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class HowDoesItWorkScreen extends StatefulWidget {
  const HowDoesItWorkScreen({super.key});

  @override
  State<HowDoesItWorkScreen> createState() => _HowDoesItWorkScreenState();
}

class _HowDoesItWorkScreenState extends State<HowDoesItWorkScreen> {
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
              "How does it work?",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 24.sp)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Momentum Strategies Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.darkCardBG,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.darkInputBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/imgs/dashboard/recommendation/paper_trading.png',
                                height: 20.sp,
                                width: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              AppText(
                                "MOMENTUM STRATEGIES",
                                variant: AppTextVariant.bodyLarge,
                                weight: AppTextWeight.bold,
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          AppText(
                            "We provide 2 expertly curated momentum-based strategies each month:",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            lineHeight: 1.4,
                          ),

                          SizedBox(height: 16.h),

                          // Mid-Cap Strategy
                          AppText(
                            "• Mid-Cap Strategy: 10 carefully selected stocks from Nifty Midcap 150",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            lineHeight: 1.4,
                          ),

                          SizedBox(height: 8.h),

                          // Small-Cap Strategy
                          AppText(
                            "• Small-Cap Strategy: 15 high-potential stocks from Nifty Smallcap 250",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            lineHeight: 1.4,
                          ),

                          SizedBox(height: 16.h),

                          AppText(
                            "Both strategies use systematic, rule driven approach combining Absolute and Relative Momentum principles for optimal performance.",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            lineHeight: 1.4,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Monthly Re-balancing Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.darkCardBG,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.darkInputBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/imgs/dashboard/recommendation/paper_trading.png',
                                height: 20.sp,
                                width: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              AppText(
                                "MONTHLY RE-BALANCING",
                                variant: AppTextVariant.bodyLarge,
                                weight: AppTextWeight.bold,
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          AppText(
                            "Portfolios are automatically re-balanced on the first business day of every month with fresh stock picks, ensuring you always have exposure to the strongest momentum performers in the market.",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            lineHeight: 1.4,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Continue Button
                  ],
                ),
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
          text: "Continue",
          variant: AppButtonVariant.primary,
          size: AppButtonSize.large,
          onPressed: () {
            Get.to(() => ChooseStrategyScreen());
          },
        ),
      ),
    );
  }
}
