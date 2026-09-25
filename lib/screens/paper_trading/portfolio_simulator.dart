import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/paper_trading/how_does_it_work.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class PaperTradingPortfolio extends StatefulWidget {
  const PaperTradingPortfolio({super.key});

  @override
  State<PaperTradingPortfolio> createState() => _PaperTradingPortfolioState();
}

class _PaperTradingPortfolioState extends State<PaperTradingPortfolio> {
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
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Portfolio Simulator",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
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
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
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
                      // Chart Icon
                      Center(
                        child: Image.asset(
                          'assets/imgs/dashboard/recommendation/paper_trading.png',
                          height: 80.h,
                          width: 80.w,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Title
                      AppText(
                        "WHAT IS A PORTFOLIO SIMULATOR?",
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.bold,
                        textAlign: TextAlign.start,
                      ),

                      SizedBox(height: 12.h),

                      // Subtitle
                      AppText(
                        "Practice with real market data, zero financial risk",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.medium,
                        colorType: AppTextColorType.secondary,
                      ),

                      SizedBox(height: 12.h),

                      // Description
                      AppText(
                        "A virtual trading portfolio simulator lets you invest and track real stocks with virtual money. Experience actual market movements, learn investment strategies, and build confidence before investing real capital.",
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        lineHeight: 1.5,
                      ),

                      SizedBox(height: 20.h),

                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: "Get Started",
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.large,
                          onPressed: () {
                            Get.to(() => const HowDoesItWorkScreen());
                          },
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
