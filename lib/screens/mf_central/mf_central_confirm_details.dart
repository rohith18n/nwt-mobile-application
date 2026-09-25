import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/mf_central/mf_central_trigger.dart';

class MFCentralConfirmDetailsScreen extends StatefulWidget {
  final String panNumber;
  final String phoneNumber;

  const MFCentralConfirmDetailsScreen({
    super.key,
    required this.panNumber,
    required this.phoneNumber,
  });

  @override
  State<MFCentralConfirmDetailsScreen> createState() => _MFCentralConfirmDetailsScreenState();
}

class _MFCentralConfirmDetailsScreenState extends State<MFCentralConfirmDetailsScreen> {
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _maskPan(String pan) {
    if (pan.length < 10) return pan;
    return '${pan.substring(0, 4)}****${pan.substring(pan.length - 2)}';
  }

  void _proceedToMFCentral() {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to MF Central trigger with confirmed details
    Get.off(
      () => MFCentralTriggerScreen(
        panNumber: widget.panNumber,
        phoneNumber: phone,
      ),
      transition: Transition.rightToLeft,
    );
  }

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
              "Confirm Details",
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      
                      // Info message
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                'Please verify your details before proceeding to MF Central',
                                variant: AppTextVariant.bodyMedium,
                                colorType: AppTextColorType.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // PAN Number Section
                      AppText(
                        'PAN Number',
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.secondary,
                        weight: AppTextWeight.medium,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkCardBG,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.darkButtonBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              color: AppColors.darkTextSecondary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AppText(
                                _maskPan(widget.panNumber),
                                variant: AppTextVariant.bodyLarge,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                            ),
                            Icon(
                              Icons.lock_outline,
                              color: AppColors.darkTextSecondary,
                              size: 18.sp,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Phone Number Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Phone Number',
                            variant: AppTextVariant.bodySmall,
                            colorType: AppTextColorType.secondary,
                            weight: AppTextWeight.medium,
                          ),
                          if (!_isEditing)
                            GestureDetector(
                              onTap: () {
                                setState(() => _isEditing = true);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppColors.info.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14.sp,
                                      color: AppColors.info,
                                    ),
                                    SizedBox(width: 4.w),
                                    AppText(
                                      'Edit',
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.link,
                                      weight: AppTextWeight.medium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      
                      if (_isEditing)
                        Column(
                          children: [
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.darkCardBG,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColors.darkButtonBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColors.darkButtonBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColors.info,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  color: AppColors.darkTextSecondary,
                                  size: 20.sp,
                                ),
                                counterText: '',
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _phoneController.text = widget.phoneNumber;
                                        _isEditing = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      side: BorderSide(color: AppColors.darkButtonBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    child: AppText(
                                      'Cancel',
                                      variant: AppTextVariant.bodyMedium,
                                      colorType: AppTextColorType.secondary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() => _isEditing = false);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.info,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    child: AppText(
                                      'Save',
                                      variant: AppTextVariant.bodyMedium,
                                      colorType: AppTextColorType.primary,
                                      weight: AppTextWeight.semiBold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkCardBG,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.darkButtonBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: AppColors.darkTextSecondary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: AppText(
                                  _phoneController.text,
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      SizedBox(height: 32.h),
                      
                      // Note
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.darkCardBG.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.darkButtonBorder.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.warning,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                AppText(
                                  'Important',
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            AppText(
                              'An OTP will be sent to this phone number to verify your identity with MF Central.',
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Continue button
              Padding(
                padding: EdgeInsets.only(bottom: 16.h, top: 16.h),
                child: AppButton(
                  text: 'Proceed to MF Central',
                  isFullWidth: true,
                  onPressed: _proceedToMFCentral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
