import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

class OtpBottomSheet extends StatefulWidget {
  final String phoneNumber;
  final Function(String otp) onVerify;
  final VoidCallback onResend;

  const OtpBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  bool _isVerifying = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleVerify() async {
    if (_otpController.text.length == 6) {
      setState(() {
        _isVerifying = true;
      });
      
      widget.onVerify(_otpController.text);
      
      // Note: The parent will handle closing the bottom sheet
      // We keep loading state until parent closes it
    }
  }

  void _handleResend() {
    widget.onResend();
    _startTimer();
    _otpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Title
              AppText(
                'Verify OTP',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
              ),
              
              SizedBox(height: 8.h),
              
              // Subtitle
              AppText(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
              ),
              
              SizedBox(height: 32.h),
              
              // OTP Input
              Pinput(
                controller: _otpController,
                focusNode: _otpFocusNode,
                length: 6,
                defaultPinTheme: PinTheme(
                  width: 48.w,
                  height: 56.h,
                  textStyle: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 1,
                    ),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 48.w,
                  height: 56.h,
                  textStyle: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.darkPrimary,
                      width: 2,
                    ),
                  ),
                ),
                submittedPinTheme: PinTheme(
                  width: 48.w,
                  height: 56.h,
                  textStyle: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.darkPrimary,
                      width: 1,
                    ),
                  ),
                ),
                onCompleted: (pin) => _handleVerify(),
              ),
              
              SizedBox(height: 24.h),
              
              // Resend OTP
              Center(
                child: AppButton(
                  customBorderRadius: 6.r,
                  text: _resendTimer > 0
                      ? "Resend in ${_resendTimer}s"
                      : "Resend",
                  onPressed: _resendTimer > 0 || _isVerifying ? null : _handleResend,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  customHeight: 20.h,
                  customPadding: EdgeInsets.symmetric(horizontal: 12.w),
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Verify Button
              AppButton(
                text: 'VERIFY',
                isFullWidth: true,
                isLoading: _isVerifying,
                onPressed: _otpController.text.length == 6 ? _handleVerify : null,
                isDisabled: _otpController.text.length != 6,
              ),
              
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
