import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/auth/pan_card_v2.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';

class UnlockPortfolioScreen extends StatelessWidget {
  const UnlockPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Log screen view
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.unlockPortfolioScreenViewed,
    );
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    // Title and Subtitle
                    AppText(
                      "Your Financial\nOverview",
                      variant: AppTextVariant.headline1,
                      weight: AppTextWeight.bold,
                      lineHeight: 1.2,
                    ),
                    SizedBox(height: 12.h),
                    AppText(
                      "See what Pivot Money can do for you",
                      variant: AppTextVariant.bodyLarge,
                      colorType: AppTextColorType.secondary,
                    ),
                    SizedBox(height: 32.h),

                    // Locked Preview Cards
                    _buildLockedCard(
                      title: "Net Worth",
                      previewChild: _buildNetWorthPreview(),
                      gradientColors: [
                        const Color(0xFF0A1F1A).withValues(alpha: 0.8),
                        const Color(0xFF040B09).withValues(alpha: 0.8),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildLockedCard(
                      title: "Asset Allocation",
                      previewChild: _buildAssetAllocationPreview(),
                      gradientColors: [
                        const Color(0xFF0E0E1F).withValues(alpha: 0.8),
                        const Color(0xFF04040B).withValues(alpha: 0.8),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // "What you'll get" Section
                    AppText(
                      "What you'll get",
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                    ),
                    SizedBox(height: 20.h),
                    _buildFeatureItem(
                      icon: Icons.auto_graph_rounded,
                      iconColor: const Color(0xFF00C7AC),
                      title: "Real-time Portfolio Updates",
                      subtitle: "Auto-synced daily",
                    ),
                    SizedBox(height: 16.h),
                    _buildFeatureItem(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: const Color(0xFF2E9DD8),
                      title: "Complete Asset View",
                      subtitle: "Banks, MF, Equity & more",
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding.w,
                vertical: 16.h,
              ),
              child: Column(
                children: [
                  AppButton(
                    text: "Unlock my portfolio",
                    variant: AppButtonVariant.primary,
                    isFullWidth: true,
                    leadingIcon: Icons.lock_outline_rounded,
                    onPressed: () {
                      AnalyticsService.to.logEvent(name: AnalyticsEvents.unlockPortfolioUnlockButtonClicked);
                      Get.to(
                        () => const PanCardV2(),
                        transition: Transition.rightToLeft,
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  // GestureDetector(
                  //   onTap: () async {
                  //     await StorageService.init();
                  //     StorageService.write(
                  //       StorageKeys.SKIP_TO_DASHBOARD_KEY,
                  //       true,
                  //     );
                  //     Get.offAll(
                  //       () => StackedNavbar(selectedIdx: 0),
                  //       transition: Transition.rightToLeft,
                  //     );
                  //   },
                  //   child: AppText(
                  //     "I'll do this later",
                  //     variant: AppTextVariant.bodyMedium,
                  //     colorType: AppTextColorType.secondary,
                  //     weight: AppTextWeight.medium,
                  //   ),
                  // ),
                  // SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding.w,
        vertical: 16.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              AnalyticsService.to.logEvent(name: AnalyticsEvents.unlockPortfolioBackClicked);
              Get.back();
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          // AppText(
          //   "Step 4 of 7",
          //   variant: AppTextVariant.bodySmall,
          //   colorType: AppTextColorType.secondary,
          //   weight: AppTextWeight.medium,
          // ),
        ],
      ),
    );
  }

  Widget _buildLockedCard({
    required String title,
    required Widget previewChild,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkButtonBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        title,
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                        weight: AppTextWeight.medium,
                      ),
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.darkTextSecondary,
                        size: 20.w,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: previewChild,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "₹12,34,567",
          variant: AppTextVariant.headline1,
          weight: AppTextWeight.bold,
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText(
                "+2.4%",
                variant: AppTextVariant.tiny,
                colorType: AppTextColorType.success,
                weight: AppTextWeight.bold,
              ),
            ),
            SizedBox(width: 8.w),
            AppText(
              "vs last month",
              variant: AppTextVariant.tiny,
              colorType: AppTextColorType.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssetAllocationPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 120.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAllocationItem("Mutual Funds", Colors.purple),
            _buildAllocationItem("Equity", Colors.blue),
            _buildAllocationItem("Cash", Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildAllocationItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        AppText(
          title,
          variant: AppTextVariant.tiny,
          colorType: AppTextColorType.secondary,
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkInputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.headline5,
                  weight: AppTextWeight.semiBold,
                ),
                SizedBox(height: 4.h),
                AppText(
                  subtitle,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
