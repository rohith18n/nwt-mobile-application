import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

enum MFActionCardVariant { vibrant, dark }

class MFActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final MFActionCardVariant variant;
  final VoidCallback onTap;
  final bool isHighlighted;

  const MFActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.variant = MFActionCardVariant.dark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    isHighlighted
                        ? AppColors.darkPrimary.withOpacity(0.4)
                        : AppColors.darkButtonBorder,
                width: isHighlighted ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonBorder,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.darkPrimary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.darkPrimary, size: 24.w),
                ),
                SizedBox(width: 12.w),
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        title,
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        customColor: AppColors.darkPrimary,
                      ),
                      SizedBox(height: 2.h),
                      AppText(
                        subtitle,
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.medium,
                        customColor: AppColors.darkTextSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isHighlighted)
          Positioned(
            top: -10,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.darkPrimary,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.black, size: 12.sp),
                  SizedBox(width: 4.w),
                  Text(
                    "FAST & SECURE",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
