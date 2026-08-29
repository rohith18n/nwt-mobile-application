import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/theme.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/app_notification_permission/notification_permission.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/screens/auth/personalize_experience.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/pinput_peek.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:pinput/pinput.dart';

class PhoneOTPVerifyScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneOTPVerifyScreen({super.key, required this.phoneNumber});

  @override
  State<PhoneOTPVerifyScreen> createState() => _PhoneOTPVerifyScreenState();
}

class _PhoneOTPVerifyScreenState extends State<PhoneOTPVerifyScreen>
    with CodeAutoFill, TickerProviderStateMixin, PinPeekMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _timeLeft = 60;
  bool _canResendOTP = false;

  bool _isLocked = false;
  int _lockTimeRemaining = 0;
  Timer? _lockTimer;

  int _parseRemainingSeconds(String message) {
    // Try MM:SS format first
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(message);
    if (timeMatch != null) {
      final minutes = int.parse(timeMatch.group(1)!);
      final seconds = int.parse(timeMatch.group(2)!);
      return minutes * 60 + seconds;
    }

    // Try "X mins" or "X minutes"
    final minutesMatch = RegExp(
      r'(\d+)\s*(?:mins|minutes|min)',
    ).firstMatch(message);
    if (minutesMatch != null) {
      final minutes = int.parse(minutesMatch.group(1)!);
      return minutes * 60;
    }

    // Default to 5 minutes (300 seconds) if no pattern matches
    return 300;
  }

  void _startLockTimer(int seconds) {
    setState(() {
      _isLocked = true;
      _lockTimeRemaining = seconds;
      _errorMessage = null;
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

  String get _otpCode => _otpController.text;

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _showKeyboardAndFocus() {
    _otpFocusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _setupSmsListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.otpScreenViewed);
      AnalyticsService.to.logEvent(name: AnalyticsEvents.otpSentSuccess);
      AppLogger.info(
        '${AnalyticsEvents.otpScreenViewed} & ${AnalyticsEvents.otpSentSuccess}',
        tag: 'event',
      );
      if (mounted) _backButtonFocusNode.requestFocus();
    });
  }

  void _setupSmsListener() async {
    try {
      final appSignature = await SmsAutoFill().getAppSignature;
      AppLogger.info('App signature: $appSignature', tag: 'OTPVerifyScreen');
      listenForCode();
      SmsAutoFill().code.listen((code) {
        if (code.isNotEmpty) _autoFillOtp(code);
      });
    } catch (e) {
      AppLogger.error(
        'Error setting up SMS listener',
        error: e,
        tag: 'OTPVerifyScreen',
      );
    }
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      _otpController.text = code!;
      _verifyOTP();
    }
  }

  Future<void> _autoFillOtp(String otp) async {
    if (otp.isEmpty || !mounted) return;
    final otpDigits = otp.replaceAll(RegExp(r'[^0-9]'), '');
    if (otpDigits.isEmpty) return;
    setState(() {
      _otpController.text =
          otpDigits.length > 6 ? otpDigits.substring(0, 6) : otpDigits;
    });
    if (_otpController.text.length == 6) {
      _hideKeyboard();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _verifyOTP();
    }
  }

  @override
  void dispose() {
    disposePeekMixin();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _backButtonFocusNode.dispose();
    _resendTimer?.cancel();
    _lockTimer?.cancel();
    cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResendOTP = false;
      _timeLeft = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _canResendOTP = true;
          timer.cancel();
        }
      });
    });
  }

  void _setLoading(bool isLoading) {
    if (mounted) setState(() => _isLoading = isLoading);
  }

  void _setResending(bool isLoading) {
    if (mounted) setState(() => _isResending = isLoading);
  }

  Future<void> _verifyOTP() async {
    if (mounted) setState(() => _errorMessage = null);

    if (_otpCode.length != 6) {
      if (mounted) {
        setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      }
      return;
    }

    _setLoading(true);

    final response = await _authService.verifyOTP(
      phoneNumber: widget.phoneNumber,
      otp: _otpCode,
      onLoading: _setLoading,
    );

    if (response != null && response.success) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.otpVerifiedSuccess);

      // Identify user in CleverTap
      if (response.data?.user != null) {
        final user = response.data!.user!;
        String userEmail = user.email ?? '';

        // If email is empty, try to fetch from profile details
        if (userEmail.isEmpty) {
          try {
            final profileService = ProfileService();
            final profileDetails = await profileService.getProfileDetails();
            if (profileDetails?.data?.email != null &&
                profileDetails!.data!.email.isNotEmpty) {
              userEmail = profileDetails.data!.email;
              AppLogger.info(
                'Fetched email from profile details: $userEmail',
                tag: 'OTPVerify',
              );
            }
          } catch (e) {
            AppLogger.error(
              'Error fetching profile details for email: $e',
              tag: 'OTPVerify',
            );
          }
        }

        await AnalyticsService.to.identifyUser(
          userId: user.id,
          phoneNumber:
              user.phonenumber ??
              user.secondaryphonenumber ??
              widget.phoneNumber,
          name: '${user.firstname ?? ''} ${user.lastname ?? ''}'.trim(),
          email: userEmail,
        );
      }

      _setLoading(true);
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        String status = '';
        switch (settings.authorizationStatus) {
          case AuthorizationStatus.authorized:
            status = 'Authorized';
            break;
          case AuthorizationStatus.provisional:
            status = 'Provisional';
            break;
          case AuthorizationStatus.denied:
            status = 'Denied';
            break;
          default:
            status = 'Not Determined';
        }
        AppLogger.info(
          'Notification permission: $status',
          tag: 'OTPVerifyScreen',
        );

        // Token already saved by AuthService, navigate to personalize screen
        Get.offAll(
          () => const PersonalizeExperience(),
          transition: Transition.fadeIn,
        );
      } catch (e) {
        AppLogger.error(
          'Error during post-verification, still navigating to personalize screen',
          error: e,
          tag: 'OTPVerifyScreen',
        );
        Get.offAll(
          () => const PersonalizeExperience(),
          transition: Transition.fadeIn,
        );
      }
    } else {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.otpVerifiedFailed,
        parameters: {
          AnalyticsParams.errorMessage:
              response?.message ?? 'Failed to verify OTP',
        },
      );
      if (response != null &&
          response.message.toLowerCase().contains('too many failed attempts')) {
        final totalSeconds = _parseRemainingSeconds(response.message);
        _startLockTimer(totalSeconds);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                response?.message ?? 'Failed to verify OTP. Please try again.';
          });
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showKeyboardAndFocus();
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (mounted) setState(() => _errorMessage = null);
    if (!_canResendOTP || _isLoading || _isResending) return;

    AnalyticsService.to.logEvent(name: AnalyticsEvents.otpResendClicked);
    _setResending(true);

    final response = await _authService.generateOTP(
      phoneNumber: widget.phoneNumber,
      onLoading: _setResending,
    );

    if (response != null) {
      if (response.success) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.otpResendSuccess);
        _startResendTimer();
        if (mounted) {
          setState(() {
            _errorMessage = null;
            _otpController.clear();
          });
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _otpFocusNode.requestFocus();
        });
      } else {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.otpResendFailure,
          parameters: {AnalyticsParams.errorMessage: response.message},
        );
        if (mounted) setState(() => _errorMessage = response.message);
      }
    } else {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.otpResendFailure,
        parameters: {
          AnalyticsParams.errorMessage: 'Failed to connect to server',
        },
      );
      if (mounted)
        setState(
          () => _errorMessage = 'Failed to resend OTP. Please try again.',
        );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return _buildLockedUI();
    }
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
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
                      Semantics(
                        header: true,
                        child: AppText(
                          "Verify Mobile Number",
                          variant: AppTextVariant.headline1,
                          weight: AppTextWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      AppText(
                        "Enter the 6-digit code sent to\n${widget.phoneNumber}",
                        variant: AppTextVariant.bodyLarge,
                        colorType: AppTextColorType.secondary,
                      ),
                      SizedBox(height: 40.h),

                      // Phone Field (Read-only)
                      _buildPhoneInput(),

                      // OTP Field (Appears below)
                      SizedBox(height: 32.h),
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: _buildOTPInput(),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
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
                text: "Verify",
                isFullWidth: true,
                isLoading: _isLoading,
                onPressed: () {
                  if (_otpController.text.length == 6 &&
                      !_isLoading &&
                      !_isResending) {
                    AnalyticsService.to.logEvent(
                      name: AnalyticsEvents.otpEntered,
                    );
                    _verifyOTP();
                  }
                },
                isDisabled:
                    _otpController.text.length < 6 ||
                    _isLoading ||
                    _isResending,
              ),
            ),
          ],
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
          Focus(
            focusNode: _backButtonFocusNode,
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: Semantics(
                label: 'Back',
                button: true,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "Mobile Number",
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
        SizedBox(height: 12.h),
        Semantics(
          label: 'Mobile Number: ${widget.phoneNumber}',
          child: TextField(
            controller: TextEditingController(text: widget.phoneNumber),
            readOnly: true,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.phone_iphone_rounded,
                color: AppColors.darkTextGray,
                size: 20.w,
              ),
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      AnalyticsService.to.logEvent(
                        name: AnalyticsEvents.phoneNumberEditClicked,
                      );
                      Get.back();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: 20.w),
                      child: Semantics(
                        label: 'Edit phone number',
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
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 18.h,
              ),
              fillColor: AppColors.darkCardBG,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput() {
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
          color: _errorMessage != null ? Colors.red : Colors.transparent,
        ),
      ),
    );

    final focusedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration!.copyWith(
        border: Border.all(
          color: _errorMessage != null ? Colors.red : Colors.white,
          width: 1,
        ),
      ),
    );

    final submittedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration!.copyWith(
        border: Border.all(
          color:
              _errorMessage != null
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
        Semantics(
          label: 'Verification Code Field. Please enter 6-digit code.',
          child: Pinput.builder(
            separatorBuilder: (index) => SizedBox(width: 20.w),
            length: 6,
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: const TextInputType.numberWithOptions(
              signed: false,
              decimal: false,
            ),
            onChanged: (value) {
              onPinChanged(value);
              setState(() {
                _errorMessage = null;
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
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 8.h),
          AppText(
            _errorMessage!,
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
                  _isLoading || _isResending || !_canResendOTP
                      ? null
                      : () {
                        AnalyticsService.to.logEvent(
                          name: AnalyticsEvents.emailOtpResendClicked,
                        );
                        _resendOTP();
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
              text: _canResendOTP ? "Resend" : "Resend in ${_timeLeft}s",
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              customHeight: 20.h,
              customPadding: EdgeInsets.symmetric(horizontal: 12.w),
              onPressed:
                  _isLoading || _isResending || !_canResendOTP
                      ? null
                      : () {
                        AnalyticsService.to.logEvent(
                          name: AnalyticsEvents.emailOtpResendClicked,
                        );
                        _resendOTP();
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
                      Get.back();
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

                      // Phone number + Edit button
                      Row(
                        children: [
                          AppText(
                            widget.phoneNumber,
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.medium,
                            colorType: AppTextColorType.primary,
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {
                              Get.back();
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
                              text:
                                  "Too Many failed attempts. Try again\nafter ",
                            ),
                            TextSpan(
                              text: "$initialMinutes mins",
                              style: const TextStyle(
                                color: Color(
                                  0xFFFFC000,
                                ), // highlighted yellow/gold
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
                        padding: EdgeInsets.symmetric(
                          vertical: 36.h,
                          horizontal: 16.w,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF140508,
                          ), // extremely dark wine red
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
                                color: const Color(
                                  0xFFFF5277,
                                ), // Neon rose/pink time text
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
