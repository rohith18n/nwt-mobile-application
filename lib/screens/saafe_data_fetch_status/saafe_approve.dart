import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class SaafeApprovedScreen extends StatelessWidget {
  const SaafeApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check mark animation at the top
              SizedBox(height: 40.h),
              Center(
                child: SizedBox(
                  height: 180.h,
                  width: 180.w,
                  child: Lottie.asset(
                    'assets/lottie/successful.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Status information section
              _buildInfoCard(
                icon: Icons.check_circle_rounded,
                iconColor: Color(0xFF4CAF50), // Green color for check mark
                iconBackgroundColor: Color(
                  0xFF1A1A1A,
                ), // Darker background for icon
                title: "status",
                titleColor: Color(0xFF5EAED6), // Blue color for status text
                description: "of the linking process once fetched",
                prefix: "Your home screen will display the ",
              ),

              SizedBox(height: 16.h),

              // Track and manage section
              _buildInfoCard(
                icon: Icons.bar_chart_rounded,
                iconColor: Color(0xFFFFB74D), // Amber color for icon
                iconBackgroundColor: Color(
                  0xFF1A1A1A,
                ), // Darker background for icon
                title: "track",
                titleColor: Color(0xFF5EAED6), // Blue color for track text
                description: "and manage your banks and investments",
                prefix: "After linking, ",
              ),

              SizedBox(height: 16.h),

              // Manage linked accounts section
              _buildInfoCard(
                icon: Icons.home_rounded,
                iconColor: Color.fromARGB(
                  255,
                  169,
                  157,
                  223,
                ), // Lavender color for house icon
                iconBackgroundColor: Color(
                  0xFF1A1A1A,
                ), // Darker background for icon
                title: "Manage",
                titleColor: Color(0xFF5EAED6), // Blue color for Manage text
                description: "all linked accounts directly from the",
                suffix: "home screen",
                suffixColor: Color(
                  0xFF5EAED6,
                ), // Blue color for home screen text
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: "Continue",
                  onPressed:
                      () => Get.offAll(() => StackedNavbar(selectedIdx: 0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    Color? iconBackgroundColor,
    required String title,
    Color? titleColor,
    required String description,
    String prefix = "",
    String suffix = "",
    Color? suffixColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Icon on the left
          Container(
            height: 40.h,
            width: 40.w,
            decoration: BoxDecoration(
              color:
                  iconBackgroundColor ??
                  Color(
                    0xFF1A1A1A,
                  ), // Use provided background color or default to dark
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 12.w),

          // Text content
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  if (prefix.isNotEmpty)
                    TextSpan(
                      text: prefix,
                      style: TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 14.sp,
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: titleColor ?? iconColor,
                      fontSize: 14.sp,
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: " $description",
                    style: TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 14.sp,
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: " $suffix",
                      style: TextStyle(
                        color: suffixColor ?? iconColor,
                        fontSize: 14.sp,
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
