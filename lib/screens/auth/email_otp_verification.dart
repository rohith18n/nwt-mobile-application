import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nwt_app/screens/auth/personalize_experience.dart';
import 'package:nwt_app/widgets/common/pinput_peek.dart';
import 'package:pinput/pinput.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';

class EmailOTPVerification extends StatefulWidget {
  const EmailOTPVerification({super.key});

  @override
  State<EmailOTPVerification> createState() => _EmailOTPVerificationState();
}

class _EmailOTPVerificationState extends State<EmailOTPVerification>
    with PinPeekMixin {
  final TextEditingController _emailController = TextEditingController();
  // Single controller for the entire OTP — Pinput manages internally
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _headerFocusNode = FocusNode();

  bool _showOTPFields = false;
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  int _resendSeconds = 0;
  String? _emailErrorMessage;
  String? _otpErrorMessage;

  bool _isLocked = false;
  int _lockTimeRemaining = 0;
  Timer? _lockTimer;

  int _parseRemainingSeconds(String message) {
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(message);
    if (timeMatch != null) {
      final minutes = int.parse(timeMatch.group(1)!);
      final seconds = int.parse(timeMatch.group(2)!);
      return minutes * 60 + seconds;
    }
    final minutesMatch = RegExp(r'(\d+)\s*(?:mins|minutes|min)').firstMatch(message);
    if (minutesMatch != null) {
      final minutes = int.parse(minutesMatch.group(1)!);
      return minutes * 60;
    }
    return 300;
  }

  void _startLockTimer(int seconds) {
    setState(() {
      _isLocked = true;
      _lockTimeRemaining = seconds;
      _otpErrorMessage = null;
    });
    _otpController.clear();
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockTimeRemaining > 0) {
        setState(() {
          _lockTimeRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _resendSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logEvent(name: AnalyticsEvents.emailOtpScreenViewed);

    // Set focus on header for initial context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _headerFocusNode.requestFocus();
    });
  }

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    disposePeekMixin();
    _emailController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _headerFocusNode.dispose();
    _timer?.cancel();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _handleContinue() async {
    if (_resendSeconds > 0) return;
    if (_emailController.text.isEmpty) {
      return;
    }

    if (!_emailController.text.contains('@')) {
      setState(() {
        _emailErrorMessage = "Invalid email format";
      });
      return;
    }

    setState(() {
      _emailErrorMessage = null;
    });

    final email = _emailController.text.trim();
    final domain = email.contains('@') ? email.split('@').last : 'unknown';

    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.emailOtpContinueClicked,
      parameters: {AnalyticsParams.emailDomain: domain},
    );

    final response = await _authService.sendEmailOtp(
      email: email,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            if (_showOTPFields) {
              _isResending = isLoading;
            } else {
              _isLoading = isLoading;
            }
          });
        }
      },
    );

    if (!mounted) return;

    if (response != null && response.success) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.emailOtpSendSuccess);
      setState(() {
        _showOTPFields = true;
        _otpController.clear();
      });
      _startTimer();

      // Autofocus OTP field after it animates in
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _otpFocusNode.requestFocus();
      });
    } else {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.emailOtpSendFailed,
        parameters: {
          AnalyticsParams.errorMessage:
              response?.message ?? "Failed to send OTP",
          AnalyticsParams.errorType: 'send_failed',
        },
      );
      setState(() {
        _emailErrorMessage = response?.message ?? "Failed to send OTP";
      });
    }
  }

  void _verifyOTP() async {
    final otp = _otpController.text;
    if (otp.length < 6) return;

    setState(() {
      _otpErrorMessage = null;
    });

    final response = await _authService.verifyEmailOtp(
      email: _emailController.text.trim(),
      otp: otp,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
          });
        }
      },
    );

    if (!mounted) return;

    if (response != null && response.success) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.emailOtpVerifySuccess);

      // Identify user in CleverTap
      if (response.data?.user != null) {
        final user = response.data!.user!;
        await AnalyticsService.to.identifyUser(
          userId: user.id,
          phoneNumber: user.phonenumber ?? user.secondaryphonenumber ?? '',
          name: '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim(),
          email: user.email ?? _emailController.text.trim(),
        );
      }

      // Navigate directly to PersonalizeExperience (matching mobile OTP flow)
      Get.offAll(
        () => const PersonalizeExperience(),
        transition: Transition.fadeIn,
      );
    } else {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.emailOtpVerifyFailed,
        parameters: {
          AnalyticsParams.errorMessage:
              response?.message ?? "Failed to verify OTP",
          AnalyticsParams.errorType: 'verify_failed',
        },
      );
      if (response != null && response.message.toLowerCase().contains('too many failed attempts')) {
        final totalSeconds = _parseRemainingSeconds(response.message);
        _startLockTimer(totalSeconds);
      } else {
        setState(() {
          _otpErrorMessage = response?.message ?? "Failed to verify OTP";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return _buildLockedUI();
    }
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Semantics(
          explicitChildNodes: true,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding.w,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        Focus(
                          focusNode: _headerFocusNode,
                          child: Semantics(
                            header: true,
                            child: AppText(
                              "Sign in with email",
                              variant: AppTextVariant.headline1,
                              weight: AppTextWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          _showOTPFields
                              ? "Enter the 6-digit code sent to\n${_emailController.text}"
                              : "We'll send you a verification code to get\nstarted",
                          variant: AppTextVariant.bodyLarge,
                          colorType: AppTextColorType.secondary,
                        ),
                        SizedBox(height: 40.h),

                        // Email Field (Always visible)
                        _buildEmailInput(),

                        // OTP Field (Appears below)
                        if (_showOTPFields) ...[
                          SizedBox(height: 32.h),
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            child: _buildOTPInput(),
                          ),
                        ],
                        SizedBox(
                          height:
                              _showOTPFields
                                  ? MediaQuery.of(context).size.height * 0.3
                                  : 20.h,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      16,
                  left: AppSizing.scaffoldHorizontalPadding.w,
                  right: AppSizing.scaffoldHorizontalPadding.w,
                  top: 10,
                ),
                child: AppButton(
                  text:
                      _showOTPFields
                          ? "Verify"
                          : (_resendSeconds > 0
                              ? "Continue in ${_resendSeconds}s"
                              : "Continue"),
                  isFullWidth: true,
                  isLoading: _isLoading,
                  onPressed:
                      _showOTPFields
                          ? _verifyOTP
                          : (_resendSeconds > 0 || _isResending
                              ? null
                              : _handleContinue),
                  isDisabled:
                      _showOTPFields
                          ? _otpController.text.length < 6 ||
                              _isLoading ||
                              _isResending
                          : (_emailController.text.isEmpty ||
                              _isLoading ||
                              _isResending),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              if (_showOTPFields) {
                setState(() {
                  _showOTPFields = false;
                });
              } else {
                Get.back();
              }
            },
            child: Semantics(
              label: 'Back',
              button: true,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Email Address",
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _emailController,
          readOnly: _showOTPFields,
          onChanged: (val) {
            setState(() {
              _emailErrorMessage = null;
            });
          },
          style: TextStyle(
            color:
                _showOTPFields ? Colors.white.withOpacity(0.5) : Colors.white,
            fontSize: 16.sp,
          ),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "your.email@example.com",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.darkTextGray,
              size: 20.w,
            ),
            suffixIcon:
                _showOTPFields
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            AnalyticsService.to.logEvent(
                              name: AnalyticsEvents.emailOtpEditEmailClicked,
                            );
                            setState(() => _showOTPFields = false);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 20.w),
                            child: Semantics(
                              label: 'Edit email address',
                              button: true,
                              child: AppText(
                                "Edit",
                                variant: AppTextVariant.bodySmall,
                                customColor: Colors.white,
                                weight: AppTextWeight.semiBold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 18.h,
            ),
            fillColor: AppColors.darkCardBG,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    _emailErrorMessage != null
                        ? Colors.red
                        : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    _emailErrorMessage != null
                        ? Colors.red
                        : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _emailErrorMessage != null ? Colors.red : Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_emailErrorMessage != null) ...[
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: AppText(
              _emailErrorMessage!,
              variant: AppTextVariant.bodySmall,
              customColor: Colors.red,
            ),
          ),
        ],
        if (!_showOTPFields && _emailErrorMessage == null) ...[
          SizedBox(height: 12.h),
          AppText(
            "We'll use this to secure your account and send updates",
            variant: AppTextVariant.tiny,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildOTPInput() {
    // Design tokens matching the original custom implementation:
    //  • box: 48w × 56h, rounded 12, fill = AppColors.darkCardBG
    //  • border: transparent (default), white 1px (focused)
    //  • text: white, 20sp, bold, centered
    final defaultPin = PinTheme(
      width: 48.w,
      height: 56.h,
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpErrorMessage != null ? Colors.red : Colors.transparent,
        ),
      ),
    );

    final focusedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration!.copyWith(
        border: Border.all(
          color: _otpErrorMessage != null ? Colors.red : Colors.white,
          width: 1,
        ),
      ),
    );

    final submittedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration!.copyWith(
        border: Border.all(
          color:
              _otpErrorMessage != null
                  ? Colors.red
                  : Colors.white.withOpacity(0.3),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Enter Verification Code",
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        Pinput.builder(
          separatorBuilder: (index) => SizedBox(width: 20.w),
          length: 6,
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          scrollPadding: EdgeInsets.only(bottom: 150.h),
          onChanged: (value) {
            onPinChanged(value);
            setState(() {
              _otpErrorMessage = null;
            });
          },
          onCompleted: (_) => _verifyOTP(),
          builder: (context, state) {
            final theme = switch (state.type) {
              PinItemStateType.focused => focusedPin,
              PinItemStateType.submitted => submittedPin,
              _ => defaultPin,
            };

            final bool isPeeking =
                state.value.isNotEmpty && state.index == peekIndex;
            final display =
                state.value.isEmpty
                    ? ''
                    : isPeeking
                    ? state.value
                    : obscuringCharacter;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: theme.width ?? 48.w,
              height: theme.height ?? 56.h,
              decoration: theme.decoration,
              alignment: Alignment.center,
              child:
                  display.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                        display,
                        style: theme.textStyle ?? defaultPin.textStyle,
                      ),
            );
          },
        ),
        if (_otpErrorMessage != null) ...[
          SizedBox(height: 8.h),
          AppText(
            _otpErrorMessage!,
            variant: AppTextVariant.bodySmall,
            customColor: Colors.red,
          ),
        ],
        SizedBox(height: 32.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap:
                  _resendSeconds > 0 || _isLoading || _isResending
                      ? null
                      : () {
                        AnalyticsService.to.logEvent(
                          name: AnalyticsEvents.emailOtpResendClicked,
                        );
                        _handleContinue();
                      },
              child: AppText(
                "Didn't receive code? ",
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.secondary,
                weight: AppTextWeight.medium,
              ),
            ),
            SizedBox(width: 8.w),
            AppButton(
              customBorderRadius: 6.r,
              text:
                  _resendSeconds > 0
                      ? "Resend in ${_resendSeconds}s"
                      : "Resend",
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              customHeight: 20.h,
              customPadding: EdgeInsets.symmetric(horizontal: 12.w),
              onPressed:
                  _resendSeconds > 0 || _isLoading || _isResending
                      ? null
                      : () {
                        AnalyticsService.to.logEvent(
                          name: AnalyticsEvents.emailOtpResendClicked,
                        );
                        _handleContinue();
                      },
            ),
            if (_isResending) ...[
              SizedBox(width: 12.w),
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLockedUI() {
    final int initialMinutes = (_lockTimeRemaining / 60).ceil();
    final bool isCountdownFinished = _lockTimeRemaining == 0;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top back button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding.w,
                vertical: 16.h,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLocked = false;
                        _showOTPFields = false;
                      });
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24.h),
                      Semantics(
                        header: true,
                        child: const AppText(
                          "Account Temporarily\nLocked",
                          variant: AppTextVariant.headline1,
                          weight: AppTextWeight.bold,
                          lineHeight: 1.2,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      // Email Address + Edit button
                      Row(
                        children: [
                          AppText(
                            _emailController.text,
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.medium,
                            colorType: AppTextColorType.primary,
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLocked = false;
                                _showOTPFields = false;
                              });
                            },
                            child: const AppText(
                              "Edit",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              customColor: Color(0xFF2E9DD8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      
                      // Description line with highlighted remaining time
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                              text: "Too Many failed attempts. Try again\nafter ",
                            ),
                            TextSpan(
                              text: "$initialMinutes mins",
                              style: const TextStyle(
                                color: Color(0xFFFFC000), // highlighted yellow/gold
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 48.h),
                      
                      // Burgundy red countdown container card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140508), // extremely dark wine red
                          border: Border.all(
                            color: const Color(0xFF4A0E17), // dark red border
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDuration(_lockTimeRemaining),
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: const Color(0xFFFF5277), // Neon rose/pink time text
                                fontSize: 54.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            const AppText(
                              "Time Remaining",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              customColor: Colors.white, // slate-grey subtitle
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Try Again Button
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: AppSizing.scaffoldHorizontalPadding.w,
                right: AppSizing.scaffoldHorizontalPadding.w,
                top: 10,
              ),
              child: AppButton(
                text: "Try Again",
                isFullWidth: true,
                isDisabled: !isCountdownFinished,
                onPressed: () {
                  setState(() {
                    _isLocked = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
