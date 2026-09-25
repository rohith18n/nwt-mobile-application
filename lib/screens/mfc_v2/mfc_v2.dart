import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_instructions_screen.dart';
import 'package:nwt_app/controllers/user_controller.dart';

class MFCv2Screen extends StatelessWidget {
  const MFCv2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();
    final phoneNumber = userController.userData?.phonenumber ?? 
                       userController.userData?.secondaryphonenumber ?? 
                       '';
    
    // Mask phone number for display
    String maskedPhone = '';
    if (phoneNumber.isNotEmpty && phoneNumber.length >= 10) {
      final lastDigits = phoneNumber.substring(phoneNumber.length - 3);
      maskedPhone = '+91 ******$lastDigits';
    }

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
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration placeholder - you can replace with actual asset
                    Container(
                      height: 200.h,
                      width: 200.w,
                      decoration: BoxDecoration(
                        color: AppColors.darkCardBG.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 100.sp,
                        color: AppColors.info.withOpacity(0.6),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Title
                    AppText(
                      "Let's get started by fetching your\nMutual Funds",
                      variant: AppTextVariant.headline2,
                      weight: AppTextWeight.semiBold,
                      textAlign: TextAlign.center,
                      colorType: AppTextColorType.primary,
                    ),
                    
                    SizedBox(height: 60.h),
                    
                    // OTP info text
                    if (maskedPhone.isNotEmpty)
                      AppText(
                        'An OTP will be sent to $maskedPhone to fetch your holdings via MF Central',
                        variant: AppTextVariant.bodyMedium,
                        textAlign: TextAlign.center,
                        colorType: AppTextColorType.secondary,
                      ),
                  ],
                ),
              ),
              
              // Continue button
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: AppButton(
                  text: 'Continue',
                  isFullWidth: true,
                  onPressed: () {
                    Get.to(
                      () => const MFCInstructionsScreen(),
                      transition: Transition.rightToLeft,
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
}
