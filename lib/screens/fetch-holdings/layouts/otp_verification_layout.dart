import 'dart:async';
import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/otp_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:nwt_app/screens/fetch-holdings/types/mf_fetching.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/controllers/user_controller.dart';

class OtpVerificationLayout extends StatefulWidget {
  final bool isAnimating;
  final bool canResendOTP;
  final int timeLeft;
  final int activeFieldIndex;
  final List<bool> fieldFilled;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final List<Animation<double>> scaleAnimations;
  final String otpCode;
  final Function(String) onVerifyOTP;
  final VoidCallback onResendOTP;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final DecryptedCASDetails? casDetails;
  final String? errorMessage;

  const OtpVerificationLayout({
    super.key,
    required this.isAnimating,
    required this.canResendOTP,
    required this.timeLeft,
    required this.activeFieldIndex,
    required this.fieldFilled,
    required this.controllers,
    required this.focusNodes,
    required this.scaleAnimations,
    required this.otpCode,
    required this.onVerifyOTP,
    required this.onResendOTP,
    required this.onPrevious,
    required this.onNext,
    this.casDetails,
    this.errorMessage,
  });

  @override
  State<OtpVerificationLayout> createState() => _OtpVerificationLayoutState();
}

class _OtpVerificationLayoutState extends State<OtpVerificationLayout>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserController _userController = Get.find<UserController>();
  bool _isLoading = false;
  Timer? _verificationTimer;

  Timer? _resendTimer;
  int _timeLeft = 60;
  bool _canResendOTP = true;
  String? _previousErrorMessage;
  String _otpCode = '';

  // For OTPField widget
  final ValueNotifier<int> _otpKey = ValueNotifier<int>(0);

  Future<void> _launchUrl(String url) async {
    if (url == 'https://www.pivotmoney.app/termsconditions') {
      Get.to(() => const AppWebViewScreen(
        url: 'https://www.pivotmoney.app/termsconditions',
        title: 'Terms & Conditions',
      ));
      return;
    }
    if (url == 'https://www.pivotmoney.app/privacy-policy') {
      Get.to(() => const AppWebViewScreen(
        url: 'https://www.pivotmoney.app/privacy-policy',
        title: 'Privacy Policy',
      ));
      return;
    }
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _setPin(String pin) {
    setState(() {
      _otpCode = pin;
    });
    _verifyAndNavigate(pin);
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void didUpdateWidget(OtpVerificationLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    AppLogger.info(
      'Updating OTP verification layout with new data: ${json.encode(widget.errorMessage)}',
      tag: 'OtpVerificationLayout',
    );

    if (widget.errorMessage != null &&
        widget.errorMessage != _previousErrorMessage) {
      setState(() {
        _isLoading = false;
        _previousErrorMessage = widget.errorMessage;
      });

      _verificationTimer?.cancel();
    }

    if (oldWidget.errorMessage != null && widget.errorMessage == null) {
      _previousErrorMessage = null;
    }
  }

  void _startResendTimer() {
    if (mounted) {
      setState(() {
        _canResendOTP = false;
        _timeLeft = 60;
      });
    }
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _canResendOTP = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyAndNavigate(String otpCode) {
    if (_isLoading) return;
    if (otpCode.length == 6) {
      setState(() {
        _isLoading = true;
        _previousErrorMessage = null;
      });

      _verificationTimer?.cancel();

      _verificationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isLoading) {
          if (_previousErrorMessage == null) {
            widget.onNext();
          }
        }
      });
      widget.onVerifyOTP(otpCode);
    }
  }

  void _skipMFCVerification() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update user's skipmfc field to true
      final success = await _authService.updateUserField('skipmfc', true);

      if (success) {
        // Navigate to next screen
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error skipping MFC verification',
        error: e,
        tag: 'OtpVerificationLayout',
      );
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Exit Verification",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Are you sure you want to logout? Your mutual fund fetching progress will be lost.",
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Cancel",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            weight: AppTextWeight.semiBold,
                          ),
                        ),
                      ),

                      Container(
                        height: 52,
                        width: 1,
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                      ),

                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _authService.logout();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: AppText(
                            "Logout",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.error,
                            weight: AppTextWeight.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isAnimating
        ? FadeOutUp(
          duration: const Duration(milliseconds: 500),
          child: _buildContent(context),
        )
        : FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: _buildContent(context),
        );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Opacity(
          opacity: 0,
          child: const Icon(Icons.chevron_left, size: 32),
        ),
        centerTitle: true,
        title: AppText(
          "OTP Verification",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        actions: [
          TextButton(
            onPressed: () => _showExitConfirmationDialog(context),
            child: AppText(
              "Logout",
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.error,
              weight: AppTextWeight.semiBold,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.scaffoldHorizontalPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.45,
                                      child: Lottie.asset(
                                        'assets/lottie/lock.json',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      AppText(
                                        _userController.userData?.isNri == true
                                            ? "Enter 6 digit MF Central code \nsent to ${_userController.userData?.email}"
                                            : "Enter 6 digit MF Central code \nsent to ${_userController.userData?.phonenumber}",
                                        variant: AppTextVariant.headline4,
                                        lineHeight: 1.3,
                                        colorType: AppTextColorType.primary,
                                        weight: AppTextWeight.bold,
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                RepaintBoundary(
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: _otpKey,
                                    builder:
                                        (context, key, child) => OTPField(
                                          key: ValueKey(key),
                                          enableAutofill: true,
                                          onOTPFilled: (pin) {
                                            _setPin(pin);
                                          },
                                          length: 6,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    AppText(
                                      "Didn't get a code?",
                                      variant: AppTextVariant.bodyMedium,
                                      lineHeight: 1.3,
                                      colorType: AppTextColorType.muted,
                                      weight: AppTextWeight.bold,
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap:
                                          (_canResendOTP && !_isLoading)
                                              ? () {
                                                _startResendTimer();
                                                widget.onResendOTP();
                                              }
                                              : null,
                                      child: AppText(
                                        _canResendOTP
                                            ? "Resend Code"
                                            : "Resend in $_timeLeft s",
                                        variant: AppTextVariant.bodyMedium,
                                        lineHeight: 1.3,
                                        colorType:
                                            _canResendOTP
                                                ? AppTextColorType.primary
                                                : AppTextColorType.muted,
                                        weight: AppTextWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.errorMessage != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.darkCardBG
                                              : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkInputBorder
                                                : Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            AppText(
                                              "Having trouble with verification?",
                                              variant:
                                                  AppTextVariant.bodyMedium,
                                              weight: AppTextWeight.semiBold,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        AppText(
                                          "You can skip this step and continue using the app without MF Central verification.",
                                          variant: AppTextVariant.bodySmall,
                                          lineHeight: 1.4,
                                          colorType: AppTextColorType.secondary,
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap:
                                              _isLoading
                                                  ? null
                                                  : () =>
                                                      _skipMFCVerification(),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AppText(
                                                  "Skip Verification",
                                                  variant:
                                                      AppTextVariant.bodySmall,
                                                  weight:
                                                      AppTextWeight.semiBold,
                                                  colorType:
                                                      AppTextColorType.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  size: 16,
                                                ),
                                                if (_isLoading) ...[
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 24,
                                top: 16,
                              ),
                              child: Column(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontFamily: "Montserrat",
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              'By proceeding, you provide your consent for us to securely fetch your mutual fund data from MF Central to analyze your investments and help you make informed financial decisions. ',
                                        ),
                                        TextSpan(
                                          text: 'Terms and conditions',
                                          style: const TextStyle(
                                            color: AppColors.info,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer:
                                              TapGestureRecognizer()
                                                ..onTap =
                                                    () => _launchUrl(
                                                      'https://www.pivotmoney.app/termsconditions',
                                                    ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedErrorMessage(
                                    errorMessage: widget.errorMessage,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom + 16
                        : 16,
                left: AppSizing.scaffoldHorizontalPadding,
                right: AppSizing.scaffoldHorizontalPadding,
                top: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Proceed',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isDisabled: _isLoading,
                      onPressed: () {
                        if (!_isLoading && _otpCode.length == 6) {
                          _verifyAndNavigate(_otpCode);
                        }
                      },
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
