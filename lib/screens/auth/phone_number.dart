import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/screens/auth/otp_verify.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

class PhoneNumberInputScreen extends StatefulWidget {
  /// Backward compatible flag for existing call sites.
  /// When true, the CTA starts Account Aggregator linking (instead of sending OTP).
  final bool unlockInvestmentsMode;

  /// Explicit mode for this screen.
  /// - [otpVerification]: send OTP and verify phone
  /// - [unlockInvestments]: start AA linking (Finarkein/Saafe)
  /// - [collectOnly]: collect a 10-digit phone and return it to caller (no OTP, no AA)
  final PhoneNumberInputMode? mode;

  const PhoneNumberInputScreen({
    super.key,
    this.unlockInvestmentsMode = false,
    this.mode,
  });

  @override
  State<PhoneNumberInputScreen> createState() => _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState extends State<PhoneNumberInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendSeconds = 0;
  Timer? _timer;
  // _agreed is only used in unlockInvestments / collectOnly modes
  // (in otpVerification mode the user already accepted T&C on OnboardingScreen)
  bool _agreed = true;

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

  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
  ];

  late String _selectedCountryCode;
  late String _selectedCountryFlag;
  bool _isAutoDetected = false;

  Future<void> _launchUrl(String url) async {
    if (url == 'https://www.pivotmoney.app/termsconditions') {
      Get.to(
        () => const AppWebViewScreen(
          url: 'https://www.pivotmoney.app/termsconditions',
          title: 'Terms & Conditions',
        ),
      );
      return;
    }
    if (url == 'https://www.pivotmoney.app/privacy-policy') {
      Get.to(
        () => const AppWebViewScreen(
          url: 'https://www.pivotmoney.app/privacy-policy',
          title: 'Privacy Policy',
        ),
      );
      return;
    }
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _getHintPhoneNumber() async {
    final phoneNumber = await SmsAutoFill().hint;
    AppLogger.info(
      "Phone number hint: $phoneNumber",
      tag: 'PhoneNumberInputScreen',
    );
    if (phoneNumber != null) {
      try {
        // Remove all non-digit characters
        String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

        // Take only the last 10 digits if the number is longer
        if (digitsOnly.length > 10) {
          digitsOnly = digitsOnly.substring(digitsOnly.length - 10);
        }

        // Validate it's exactly 10 digits
        if (digitsOnly.length == 10 && int.tryParse(digitsOnly) != null) {
          setState(() {
            _phoneController.text = digitsOnly;
            // Set cursor to end when auto-filling
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _phoneController.text.length),
            );
          });
        } else {
          AppLogger.error(
            "Invalid phone number format: $digitsOnly",
            tag: 'PhoneNumberInputScreen',
          );
        }
      } catch (e) {
        AppLogger.error(
          "Error processing phone number: $e",
          tag: 'PhoneNumberInputScreen',
        );
      }
    }
  }

  void _onPhoneNumberChanged(String limitedText) {
    // Log phone number entered event
    if (limitedText.isNotEmpty) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.phoneNumberEntered);
    }
    // Auto-detection logic for Indian numbers
    if (limitedText.length == 1 && !_isAutoDetected) {
      final firstDigit = int.tryParse(limitedText);
      if (firstDigit != null && firstDigit >= 6 && firstDigit <= 9) {
        setState(() {
          _selectedCountryCode = '+91';
          _selectedCountryFlag = '🇮🇳';
          _isAutoDetected = true;
        });
        return;
      }
    } else if (limitedText.isEmpty) {
      _isAutoDetected = false;
    }
    setState(() {
      _errorMessage = null;
    });
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "Select Country",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: AppText(
                        country['name']!,
                        variant: AppTextVariant.bodyMedium,
                      ),
                      trailing: AppText(
                        country['code']!,
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = country['code']!;
                          _selectedCountryFlag = country['flag']!;
                          _isAutoDetected =
                              true; // Mark as manually/auto selected
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _validatePhoneNumber() {
    if (_selectedCountryCode == '+91' && _phoneController.text.length != 10) {
      setState(() {
        _errorMessage = "Please enter a valid 10-digit phone number";
      });
      return false;
    } else if (_selectedCountryCode != '+91' &&
        (_phoneController.text.length < 7 ||
            _phoneController.text.length > 15)) {
      setState(() {
        _errorMessage = "Please enter a valid phone number";
      });
      return false;
    }
    return true;
  }

  Future<void> _generateOTP() async {
    // Unfocus any text field first to ensure keyboard is dismissed
    _phoneFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate phone number
    if (!_validatePhoneNumber()) return;

    final response = await AuthService().generateOTP(
      phoneNumber: _phoneController.text,
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );
    if (response != null && mounted) {
      if (response.success) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.phoneNumberOtpSent);
        _startTimer();
        Get.to(
          () => PhoneOTPVerifyScreen(phoneNumber: _phoneController.text),
          transition: Transition.rightToLeft,
        );
      } else {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.phoneNumberOtpSendFailed,
          parameters: {AnalyticsParams.errorMessage: response.message},
        );
        // Show error message from the server
        setState(() {
          _errorMessage = response.message;
        });
      }
    } else {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.phoneNumberOtpSendFailed,
        parameters: {
          AnalyticsParams.errorMessage: 'Failed to connect to server',
        },
      );
      setState(() {
        _errorMessage = "Failed to connect to server. Please try again.";
      });
    }
  }

  Future<void> _unlockInvestments() async {
    // Unfocus any text field first to ensure keyboard is dismissed
    _phoneFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate phone number
    if (!_validatePhoneNumber()) return;

    if (!_agreed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show the connection screen, but pass phone so consent/initiate uses it.
      await AccountAggregatorRouter().openConnection(
        context,
        phoneNumber: _phoneController.text,
        showConnectionScreen: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _collectOnlyAndReturn() async {
    // Unfocus any text field first to ensure keyboard is dismissed
    _phoneFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    if (!_validatePhoneNumber()) return;

    if (!_agreed) return;

    Get.back(result: _phoneController.text);
  }

  PhoneNumberInputMode get _effectiveMode {
    // Prefer explicit mode if provided.
    if (widget.mode != null) return widget.mode!;
    return widget.unlockInvestmentsMode
        ? PhoneNumberInputMode.unlockInvestments
        : PhoneNumberInputMode.otpVerification;
  }

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = '+91';
    _selectedCountryFlag = '🇮🇳';
    _getHintPhoneNumber();

    // Auto-focus the phone input field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(name: AnalyticsEvents.phoneScreenViewed);
      AppLogger.info(AnalyticsEvents.phoneScreenViewed, tag: 'event');
      _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          "Sign in with phone",
                          variant: AppTextVariant.headline1,
                          weight: AppTextWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      AppText(
                        "We'll send you a verification code to get started",
                        variant: AppTextVariant.bodyLarge,
                        colorType: AppTextColorType.secondary,
                      ),
                      SizedBox(height: 40.h),

                      // Phone Field
                      _buildPhoneInput(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding.w,
                vertical: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show T&C only for non-OTP modes
                  if (_effectiveMode != PhoneNumberInputMode.otpVerification)
                    Column(
                      children: [
                        MergeSemantics(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Semantics(
                                label:
                                    'I accept the Terms of Use and Privacy Policy',
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Checkbox(
                                    value: _agreed,
                                    activeColor: AppColors.info,
                                    onChanged: (val) {
                                      setState(() {
                                        _agreed = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                    children: [
                                      const TextSpan(text: 'I accept the '),
                                      TextSpan(
                                        text: 'Terms of Use',
                                        style: const TextStyle(
                                          color: AppColors.info,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap =
                                                  () => _launchUrl(
                                                    'https://www.pivotmoney.app/termsconditions',
                                                  ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: const TextStyle(
                                          color: AppColors.info,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap =
                                                  () => _launchUrl(
                                                    'https://www.pivotmoney.app/privacy-policy',
                                                  ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  AppButton(
                    text:
                        _effectiveMode == PhoneNumberInputMode.unlockInvestments
                            ? 'Unlock Investments'
                            : _effectiveMode == PhoneNumberInputMode.collectOnly
                            ? 'Continue'
                            : (_resendSeconds > 0
                                ? 'Continue in ${_resendSeconds}s'
                                : 'Continue'),
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed:
                        _effectiveMode ==
                                    PhoneNumberInputMode.otpVerification &&
                                _resendSeconds > 0
                            ? null
                            : () {
                              final isAgreedForMode =
                                  _effectiveMode ==
                                          PhoneNumberInputMode.otpVerification
                                      ? true
                                      : _agreed;
                              if (!_isLoading &&
                                  _phoneController.text.isNotEmpty &&
                                  isAgreedForMode) {
                                AnalyticsService.to.logEvent(
                                  name: AnalyticsEvents.phoneSubmitClicked,
                                );
                                AppLogger.info(
                                  AnalyticsEvents.phoneSubmitClicked,
                                  tag: 'event',
                                );
                                switch (_effectiveMode) {
                                  case PhoneNumberInputMode.unlockInvestments:
                                    _unlockInvestments();
                                    break;
                                  case PhoneNumberInputMode.collectOnly:
                                    _collectOnlyAndReturn();
                                    break;
                                  case PhoneNumberInputMode.otpVerification:
                                    _generateOTP();
                                    break;
                                }
                              }
                            },
                    isDisabled:
                        _isLoading ||
                        _phoneController.text.isEmpty ||
                        (_effectiveMode !=
                                PhoneNumberInputMode.otpVerification &&
                            !_agreed),
                  ),
                  SizedBox(
                    height:
                        MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        16,
                  ),
                ],
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
          GestureDetector(
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code Card
            GestureDetector(
              onTap: _showCountryPicker,
              child: Semantics(
                label: 'Select country code. Current: $_selectedCountryCode',
                button: true,
                child: Container(
                  height: 58.h, // Match TextField height
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          _selectedCountryFlag,
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      AppText(
                        _selectedCountryCode,
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.medium,
                      ),
                      SizedBox(width: 4.w),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Phone Number Input
            Expanded(
              child: Semantics(
                label: 'Enter 10 digit mobile number',
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  onChanged: _onPhoneNumberChanged,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    hintText: "Enter 10 digit number",
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
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
                            _errorMessage != null
                                ? Colors.red
                                : Colors.transparent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            _errorMessage != null
                                ? Colors.red
                                : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            _errorMessage != null ? Colors.red : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: AppText(
              _errorMessage!,
              variant: AppTextVariant.bodySmall,
              customColor: Colors.red,
            ),
          ),
        ],
        if (_errorMessage == null) ...[
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
}

enum PhoneNumberInputMode { otpVerification, unlockInvestments, collectOnly }
