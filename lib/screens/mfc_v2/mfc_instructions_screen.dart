import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/mf_central/mf_central_trigger.dart';

class MFCInstructionsScreen extends StatelessWidget {
  final String? panNumber;
  final String? phoneNumber;
  final VoidCallback? onComplete;

  const MFCInstructionsScreen({
    super.key,
    this.panNumber,
    this.phoneNumber,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "MFC",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              AppText(
                "You'll be redirected to MF Central for a quick verification step as below",
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.primary,
              ),

              SizedBox(height: 32.h),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1
                      _buildStep(
                        number: '1',
                        title: 'Verify OTP on MF Central',
                        titleSuffix: _buildMFCBadge(),
                        subtitle: 'Log on to the MF Central website using OTP',
                        hasLine: true,
                      ),
                      SizedBox(height: 16.h),

                      // Step 2
                      _buildStep(
                        number: '2',
                        title: 'Select Regular + Direct Investments',
                        subtitle:
                            'For complete Mutual Fund tracking coverage across all your folios.',
                        tag: 'Full Coverage',
                        tagColor: const Color(0xFF1A6B3C),
                        hasLine: true,
                      ),
                      SizedBox(height: 16.h),

                      // Step 3
                      _buildStep(
                        number: '3',
                        title: 'Select Transactions',
                        subtitle:
                            'For accurate Gains & Returns calculation in your portfolio.',
                        tag: 'Better Insights',
                        tagColor: const Color(0xFF1A4A7A),
                        hasLine: true,
                      ),
                      SizedBox(height: 16.h),

                      // Step 4
                      _buildStep(
                        number: '4',
                        title: 'Select all AMCs',
                        subtitle:
                            'For comprehensive portfolio tracking & review across all fund houses.',
                        tag: 'Complete Tracking',
                        tagColor: const Color(0xFF5A2D82),
                        hasLine: true,
                      ),
                      SizedBox(height: 16.h),

                      // Step 5
                      _buildStep(
                        number: '5',
                        title: 'Download and Share QR Code on Pivot Money',
                        hasLine: false,
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 16.h, top: 16.h),
                child: AppButton(
                  text: 'I Understand',
                  isFullWidth: true,
                  onPressed: () {
                    Get.to(
                      () => MFCentralTriggerScreen(
                        panNumber: panNumber ?? '',
                        phoneNumber: phoneNumber ?? '',
                        onComplete: onComplete,
                      ),
                      transition: Transition.fadeIn,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMFCBadge() {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF4B0082),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.orange, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            'mf central',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    Widget? titleSuffix,
    String? subtitle,
    String? tag,
    Color? tagColor,
    required bool hasLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: circle + vertical line
        Column(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkPrimary, width: 2),
              ),
              child: Center(
                child: AppText(
                  number,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
              ),
            ),
            if (hasLine)
              Container(
                width: 2,
                height: 68.h,
                color: AppColors.darkPrimary.withOpacity(0.25),
              ),
          ],
        ),

        SizedBox(width: 16.w),

        // Right: content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppText(
                        title,
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),
                    ),
                    if (titleSuffix != null) titleSuffix,
                  ],
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 6.h),
                  AppText(
                    subtitle,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                ],
                if (tag != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: (tagColor ?? AppColors.info).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: (tagColor ?? AppColors.info).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tagColor ?? AppColors.info,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
