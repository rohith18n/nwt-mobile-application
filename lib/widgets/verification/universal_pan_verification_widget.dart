import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/validators.dart';
import 'package:nwt_app/services/bse_v2_final/onboarding_service.dart';

/// Universal PAN Verification Widget
///
/// A reusable widget that handles:
/// 1. Phone number validation (if not already validated)
/// 2. OTP verification for phone
/// 3. PAN number collection and verification
/// 4. Retry logic for failed PAN verification
///
/// Usage:
/// ```dart
/// UniversalPanVerificationWidget(
///   phoneNumber: '+919876543210', // Optional: pre-validated phone
///   isPhoneValidated: true, // Set to true if phone is already validated
///   onSuccess: (panData) {
///     // Handle successful PAN verification
///     print('PAN verified: ${panData['pan_number']}');
///   },
///   onError: (error) {
///     // Handle errors
///     print('Error: $error');
///   },
/// )
/// ```
class UniversalPanVerificationWidget extends StatefulWidget {
  /// Pre-filled phone number (optional)
  final String? phoneNumber;

  /// Whether the phone number is already validated
  final bool isPhoneValidated;

  /// Whether email verification is needed (when phone is already verified)
  final bool needsEmailVerification;

  /// Whether email is already validated (for email-first flow users)
  final bool isEmailValidated;

  /// Pre-filled email (optional)
  final String? email;

  /// Pre-filled PAN number (optional)
  final String? panNumber;

  /// Callback when PAN verification succeeds
  final Function(Map<String, dynamic> panData) onSuccess;

  /// Callback when an error occurs
  final Function(String error)? onError;

  /// Custom title for the screen
  final String? title;

  /// Show progress indicator (e.g., "Step 1 of 6")
  final bool showProgress;

  /// Current step number for progress indicator
  final int currentStep;

  /// Total steps for progress indicator
  final int totalSteps;

  const UniversalPanVerificationWidget({
    super.key,
    this.phoneNumber,
    this.isPhoneValidated = false,
    this.needsEmailVerification = false,
    this.isEmailValidated = false,
    this.email,
    this.panNumber,
    required this.onSuccess,
    this.onError,
    this.title,
    this.showProgress = true,
    this.currentStep = 1,
    this.totalSteps = 6,
  });

  @override
  State<UniversalPanVerificationWidget> createState() =>
      _UniversalPanVerificationWidgetState();
}

class _UniversalPanVerificationWidgetState
    extends State<UniversalPanVerificationWidget> {
  final OnboardingV2Service _onboardingService = OnboardingV2Service();

  // Controllers
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Focus nodes
  final FocusNode _panFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  // State
  String _selectedCountryCode = '+91';
  bool _isPhoneValid = false;
  bool _isPanValid = false;
  bool _isEmailValid = false;
  bool _isLoading = false;
  bool _showOtpField = false;
  bool _phoneValidated = false;
  bool _emailValidated = false;
  bool _panVerified = false;
  bool _showEmailSuccess = false;
  bool? _panVerificationSuccess; // null = not verified, true = success, false = failed
  String? _errorMessage;
  String? _verifiedName;
  String? _verifiedEmail;
  Map<String, dynamic>? _panVerificationData;
  int _otpResendCountdown = 0;
  bool _isEmailOtp = false;

  // Country codes list
  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'name': 'India'},
    {'code': '+1', 'name': 'USA/Canada'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+61', 'name': 'Australia'},
    {'code': '+971', 'name': 'UAE'},
    {'code': '+65', 'name': 'Singapore'},
    {'code': '+60', 'name': 'Malaysia'},
    {'code': '+81', 'name': 'Japan'},
    {'code': '+86', 'name': 'China'},
    {'code': '+82', 'name': 'South Korea'},
    {'code': '+49', 'name': 'Germany'},
    {'code': '+33', 'name': 'France'},
    {'code': '+39', 'name': 'Italy'},
    {'code': '+34', 'name': 'Spain'},
    {'code': '+7', 'name': 'Russia'},
    {'code': '+27', 'name': 'South Africa'},
    {'code': '+234', 'name': 'Nigeria'},
    {'code': '+52', 'name': 'Mexico'},
    {'code': '+55', 'name': 'Brazil'},
    {'code': '+54', 'name': 'Argentina'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with provided values
    if (widget.phoneNumber != null) {
      // Handle phone number with or without country code
      final phoneWithoutCode = widget.phoneNumber!.replaceAll(
        _selectedCountryCode,
        '',
      );
      _phoneController.text = phoneWithoutCode;

      // If phone is already validated, mark it as valid
      if (widget.isPhoneValidated) {
        _isPhoneValid = true;
      }
    }
    if (widget.panNumber != null) {
      _panController.text = widget.panNumber!;
    }

    // Initialize email if provided
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }

    _phoneValidated = widget.isPhoneValidated;
    // Email is validated if:
    // 1. Explicitly marked as validated (isEmailValidated), OR
    // 2. Phone-first flow where email verification is not needed AND phone is validated
    _emailValidated = widget.isEmailValidated || (widget.isPhoneValidated && !widget.needsEmailVerification);

    // Add listeners
    _panController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _otpController.addListener(_validateForm);
    _emailController.addListener(_validateForm);

    // Initial validation
    _validateForm();

    AppLogger.info(
      'UniversalPanVerificationWidget initialized - Phone: ${widget.phoneNumber}, Phone validated: $_phoneValidated, Email: ${widget.email}, Needs email verification: ${widget.needsEmailVerification}',
      tag: 'UniversalPanVerification',
    );
  }

  @override
  void dispose() {
    _panController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _panFocusNode.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _resetPhoneValidation() {
    setState(() {
      _phoneValidated = false;
      _showOtpField = false;
      _otpController.clear();
      _errorMessage = null;
    });
    _phoneFocusNode.requestFocus();
    AppLogger.info(
      'Phone validation reset - user can re-enter number',
      tag: 'UniversalPanVerification',
    );
  }

  void _validateForm() {
    final pan = _panController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final cleanPhone = AppValidators.cleanPhoneNumber(phone);

    // PAN validation: 10 characters, format: ABCDE1234F
    final panValid =
        pan.length == 10 &&
        RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan.toUpperCase());

    // Phone validation: 10 digits for Indian numbers, >= 7 for international
    final isInternational =
        _selectedCountryCode != '+91' && _selectedCountryCode != '91';

    bool phoneValid = false;
    if (isInternational) {
      phoneValid = cleanPhone.length >= 7;
    } else {
      phoneValid = cleanPhone.length == 10;
    }

    // Email validation: valid email format
    final emailValid = _isValidEmail(email);

    setState(() {
      _isPanValid = panValid;
      _isPhoneValid = phoneValid;
      _isEmailValid = emailValid;
    });
  }

  /// Check if email format is valid
  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Show country code picker dialog
  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBG,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      header: true,
                      child: AppText(
                        'Select Country Code',
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.semiBold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _countryCodes.length,
                  itemBuilder: (context, index) {
                    final country = _countryCodes[index];
                    final isSelected = _selectedCountryCode == country['code'];

                    return ListTile(
                      leading: Container(
                        width: 60.w,
                        alignment: Alignment.center,
                        child: AppText(
                          country['code']!,
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.medium,
                        ),
                      ),
                      title: Semantics(
                        selected: isSelected,
                        child: AppText(
                          country['name']!,
                          variant: AppTextVariant.bodyMedium,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: AppColors.darkPrimary,
                                size: 24.sp,
                              )
                              : null,
                      selected: isSelected,
                      selectedTileColor: AppColors.darkPrimary.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = country['code']!;
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

  /// Send OTP to phone number (Indian) or save directly (International)
  Future<void> _sendOtp() async {
    if (!_isPhoneValid) {
      _showError('Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      final isIndianNumber = _selectedCountryCode == '+91';

      if (isIndianNumber) {
        // Indian number: Use OTP flow
        final phone = _selectedCountryCode + phoneNumber;

        final response = await _onboardingService.sendContactOtp(
          kind: 'phone',
          value: phone,
        );

        setState(() {
          _isLoading = false;
        });

        if (response != null && response['success'] == true) {
          AppLogger.info(
            'OTP sent successfully to $phone',
            tag: 'UniversalPanVerification',
          );

          setState(() {
            _showOtpField = true;
          });

          // Start countdown timer
          _startOtpCountdown();

          // Focus on OTP field
          Future.delayed(const Duration(milliseconds: 300), () {
            _otpFocusNode.requestFocus();
          });
        } else {
          _showError(response?['message'] ?? 'Failed to send OTP');
        }
      } else {
        // International number: Save directly without OTP
        final response = await _onboardingService.saveContactPhone(
          countryCode: _selectedCountryCode,
          phoneNumber: phoneNumber,
        );

        setState(() {
          _isLoading = false;
        });

        if (response != null && response['success'] == true) {
          AppLogger.info(
            'International phone saved successfully: $_selectedCountryCode$phoneNumber',
            tag: 'UniversalPanVerification',
          );

          setState(() {
            _phoneValidated = true;
          });

          // Focus on PAN field
          Future.delayed(const Duration(milliseconds: 300), () {
            _panFocusNode.requestFocus();
          });
        } else {
          _showError(response?['message'] ?? 'Failed to save phone number');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error processing phone',
        error: e,
        tag: 'UniversalPanVerification',
      );
      _showError('Failed to process phone number. Please try again.');
    }
  }

  /// Verify OTP (routes to phone or email based on _isEmailOtp flag)
  Future<void> _verifyOtp() async {
    if (_isEmailOtp) {
      await _verifyEmailOtp();
    } else {
      await _verifyPhoneOtp();
    }
  }

  /// Verify Phone OTP
  Future<void> _verifyPhoneOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _selectedCountryCode + _phoneController.text.trim();

      final response = await _onboardingService.verifyContactOtp(
        kind: 'phone',
        value: phone,
        otp: otp,
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info(
          'Phone OTP verified successfully',
          tag: 'UniversalPanVerification',
        );

        setState(() {
          _phoneValidated = true;
          _showOtpField = false;
        });

        // Dismiss keyboard from OTP field and switch to PAN field
        _otpFocusNode.unfocus();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_panVerified) {
            _panFocusNode.requestFocus();
          }
        });

        // Automatically proceed to PAN verification if PAN is valid
        if (_isPanValid) {
          await _verifyPan();
        }
      } else {
        _showError(response?['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error verifying phone OTP',
        error: e,
        tag: 'UniversalPanVerification',
      );
      _showError('Failed to verify OTP. Please try again.');
    }
  }

  /// Send OTP to email
  Future<void> _sendEmailOtp() async {
    if (!_isEmailValid) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();

      final response = await _onboardingService.sendContactOtp(
        kind: 'email',
        value: email,
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info(
          'OTP sent successfully to email: $email',
          tag: 'UniversalPanVerification',
        );

        setState(() {
          _showOtpField = true;
          _isEmailOtp = true;
        });

        // Start countdown timer
        _startOtpCountdown();

        // Focus on OTP field
        Future.delayed(const Duration(milliseconds: 300), () {
          _otpFocusNode.requestFocus();
        });
      } else {
        _showError(response?['message'] ?? 'Failed to send OTP to email');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error sending email OTP',
        error: e,
        tag: 'UniversalPanVerification',
      );
      _showError('Failed to send OTP to email. Please try again.');
    }
  }

  /// Verify Email OTP
  Future<void> _verifyEmailOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();

      final response = await _onboardingService.verifyContactOtp(
        kind: 'email',
        value: email,
        otp: otp,
      );

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info(
          'Email OTP verified successfully',
          tag: 'UniversalPanVerification',
        );

        setState(() {
          _emailValidated = true;
          _showOtpField = false;
          _isEmailOtp = false;
          _verifiedEmail = email;
          _showEmailSuccess = true; // Show success state
        });

        // Auto-hide email success after 2 seconds and show PAN input
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showEmailSuccess = false;
            });
            // Focus on PAN field
            if (!_panVerified) {
              _panFocusNode.requestFocus();
            }
          }
        });

        // Automatically proceed to PAN verification if PAN is valid
        if (_isPanValid) {
          await _verifyPan();
        }
      } else {
        _showError(response?['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error verifying email OTP',
        error: e,
        tag: 'UniversalPanVerification',
      );
      _showError('Failed to verify email OTP. Please try again.');
    }
  }

  /// Verify PAN
  Future<void> _verifyPan() async {
    if (!_isPanValid) {
      _showError('Please enter a valid PAN number');
      return;
    }

    // Check if either phone or email is validated (depending on flow)
    final bool contactVerified = _phoneValidated || _emailValidated;
    if (!contactVerified) {
      _showError('Please verify your phone number or email first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pan = _panController.text.trim().toUpperCase();

      final response = await _onboardingService.verifyPan(panNumber: pan);

      setState(() {
        _isLoading = false;
      });

      if (response != null && response['success'] == true) {
        AppLogger.info(
          'PAN verified successfully: $pan',
          tag: 'UniversalPanVerification',
        );

        // Store verification data and show verified name
        final data = response['data'] ?? {'pan_number': pan};
        final nameAtSource = data['name_at_source'] as String?;

        // Add contact info to data for downstream use
        if (_phoneValidated) {
          // Use widget.phoneNumber if phone field was hidden (pre-validated flow)
          final phoneNumber = _phoneController.text.trim().isNotEmpty
              ? _selectedCountryCode + _phoneController.text.trim()
              : (widget.phoneNumber ?? '');
          data['phone_number'] = phoneNumber;
          AppLogger.info(
            'Phone number: $phoneNumber',
            tag: 'UniversalPanVerification',
          );
        }
        if (_emailValidated) {
          data['email'] = _verifiedEmail ?? _emailController.text.trim();
          AppLogger.info(
            'Email: ${data['email']}',
            tag: 'UniversalPanVerification',
          );
        }

        AppLogger.info(
          'Verified name: $nameAtSource',
          tag: 'UniversalPanVerification',
        );

        // Add user info from UserController if available
        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          if (userController.userData != null) {
            data['user_id'] = userController.userData!.id;
            data['name'] = '${userController.userData!.firstname ?? ''} ${userController.userData!.lastname ?? ''}'.trim();
            AppLogger.info(
              'Added user info to panData - ID: ${data['user_id']}, Name: ${data['name']}',
              tag: 'UniversalPanVerification',
            );
          }
        }

        setState(() {
          _panVerified = true;
          _panVerificationSuccess = true;
          _verifiedName = nameAtSource;
          _panVerificationData = data;
        });

        // 🚀 REFRESH PROFILE
        // Trigger a background profile refresh so the home screen/profile
        // shows the verified name immediately.
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().fetchUserProfile(onLoading: (_) {});
        }
      } else if (response != null && response['code'] == 'user_pan_exists') {
        // PAN already exists - treat as success
        AppLogger.info(
          'PAN already exists: $pan',
          tag: 'UniversalPanVerification',
        );
        final data = response['data'] ?? {'pan_number': pan};
        final nameAtSource = data['name_at_source'] as String?;

        // Add phone number to data for downstream use
        final phoneNumber = _phoneController.text.trim().isNotEmpty
            ? _selectedCountryCode + _phoneController.text.trim()
            : (widget.phoneNumber ?? '');
        data['phone_number'] = phoneNumber;

        // Add email if validated
        if (_emailValidated) {
          data['email'] = _verifiedEmail ?? _emailController.text.trim();
        }

        // Add user info from UserController if available
        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          if (userController.userData != null) {
            data['user_id'] = userController.userData!.id;
            data['name'] = '${userController.userData!.firstname ?? ''} ${userController.userData!.lastname ?? ''}'.trim();
            AppLogger.info(
              'Added user info to panData (existing PAN) - ID: ${data['user_id']}, Name: ${data['name']}',
              tag: 'UniversalPanVerification',
            );
          }
        }

        AppLogger.info(
          'Verified name (existing PAN): $nameAtSource',
          tag: 'UniversalPanVerification',
        );
        AppLogger.info(
          'Phone number: $phoneNumber',
          tag: 'UniversalPanVerification',
        );

        setState(() {
          _panVerified = true;
          _panVerificationSuccess = true;
          _verifiedName = nameAtSource;
          _panVerificationData = data;
        });

        // 🚀 REFRESH PROFILE
        // Trigger a background profile refresh so the home screen/profile
        // shows the verified name immediately.
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().fetchUserProfile(onLoading: (_) {});
        }
      } else {
        // PAN verification failed - show error and allow retry
        final errorMsg = response?['message'] ?? 'PAN verification failed';
        _showError(errorMsg);

        setState(() {
          _panVerificationSuccess = false;
          _panController.clear();
          _isPanValid = false;
        });

        // Focus on PAN field for retry
        Future.delayed(const Duration(milliseconds: 300), () {
          _panFocusNode.requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.error(
        'Error verifying PAN',
        error: e,
        tag: 'UniversalPanVerification',
      );
      _showError('Failed to verify PAN. Please try again.');

      // Clear PAN field to allow retry
      setState(() {
        _panController.clear();
        _isPanValid = false;
      });
    }
  }

  /// Start OTP resend countdown
  void _startOtpCountdown() {
    setState(() {
      _otpResendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _otpResendCountdown--;
      });
      

      return _otpResendCountdown > 0;
    });
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    if (widget.onError != null) {
      widget.onError!(message);
    }

    // Auto-hide error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  /// Handle next button press
  void _handleNext() {
    if (widget.needsEmailVerification) {
      // Email verification flow
      if (!_emailValidated && !_showOtpField) {
        // Step 1: Send Email OTP
        _sendEmailOtp();
      } else if (_showOtpField && !_emailValidated) {
        // Step 2: Verify Email OTP
        _verifyOtp();
      } else if (_emailValidated && !_panVerified) {
        // Step 3: Verify PAN
        _verifyPan();
      } else if (_panVerified) {
        // Step 4: Continue to next screen
        widget.onSuccess(
          _panVerificationData ?? {'pan_number': _panController.text.trim()},
        );
      }
    } else {
      // Phone verification flow
      if (!_phoneValidated && !_showOtpField) {
        // Step 1: Send OTP
        _sendOtp();
      } else if (_showOtpField && !_phoneValidated) {
        // Step 2: Verify OTP
        _verifyOtp();
      } else if (_phoneValidated && !_panVerified) {
        // Step 3: Verify PAN
        _verifyPan();
      } else if (_panVerified) {
        // Step 4: Continue to next screen
        widget.onSuccess(
          _panVerificationData ?? {'pan_number': _panController.text.trim()},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Progress indicator
            if (widget.showProgress) _buildProgressBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),

                    // Illustration
                    _buildIllustration(),

                    SizedBox(height: 32.h),

                    // Title
                    Semantics(
                      header: true,
                      child: AppText(
                        _getTitle(),
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Subtitle
                    AppText(
                      _getSubtitle(),
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                    ),

                    SizedBox(height: 24.h),

                    // Phone Input (when phone verification needed and not already validated)
                    // Only show if phone-first flow AND phone not validated
                    if (!widget.needsEmailVerification && !_phoneValidated) ...[
                      _buildPhoneInput(),
                      SizedBox(height: 24.h),
                    ],

                    // Email Input (when email verification needed)
                    // Only show if email needs verification AND email not validated
                    if (widget.needsEmailVerification && !_emailValidated) ...[
                      _buildEmailInput(),
                      SizedBox(height: 24.h),
                    ],

                    // OTP Input (if OTP sent and not yet validated)
                    if (_showOtpField &&
                        ((!_phoneValidated && !widget.needsEmailVerification) ||
                            (!_emailValidated && widget.needsEmailVerification))) ...[
                      _buildOtpInput(),
                      SizedBox(height: 24.h),
                    ],

                    // Email Verified Success State (shown briefly after email verification)
                    if (_showEmailSuccess) ...[
                      _buildEmailSuccessState(),
                      SizedBox(height: 24.h),
                    ],

                    // PAN Input (only visible after BOTH phone AND email are validated)
                    if (_phoneValidated && _emailValidated && !_showEmailSuccess) ...[
                      _buildPanInput(),
                      SizedBox(height: 24.h),
                    ],

                    // PAN Verification Failure State
                    if (_panVerificationSuccess == false) ...[
                      _buildPanFailureState(),
                      SizedBox(height: 24.h),
                    ],

                    // Error message
                    if (_errorMessage != null) ...[
                      _buildErrorMessage(),
                      SizedBox(height: 24.h),
                    ],

                    // Info Cards
                    _buildInfoCards(),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            // Next Button
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (widget.title != null) return widget.title!;

    if (widget.needsEmailVerification) {
      // Email verification flow
      if (!_emailValidated && !_showOtpField) {
        return 'Verify your email';
      } else if (_showOtpField) {
        return 'Enter OTP';
      } else {
        return 'Enter your PAN';
      }
    } else {
      // Phone verification flow
      if (!_phoneValidated && !_showOtpField) {
        return 'Verify your phone number';
      } else if (_showOtpField) {
        return 'Enter OTP';
      } else {
        return 'Enter your PAN';
      }
    }
  }

  String _getSubtitle() {
    if (widget.needsEmailVerification) {
      // Email verification flow
      if (!_emailValidated && !_showOtpField) {
        return 'We\'ll send you a verification code via email';
      } else if (_showOtpField) {
        return 'Enter the 6-digit code sent to ${_emailController.text}';
      } else {
        return 'We\'ll use this to fetch your investment details securely';
      }
    } else {
      // Phone verification flow
      if (!_phoneValidated && !_showOtpField) {
        return 'We\'ll send you a verification code';
      } else if (_showOtpField) {
        return 'Enter the 6-digit code sent to ${_phoneController.text}';
      } else {
        return 'We\'ll use this to fetch your investment details securely';
      }
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            onTap: () => Get.back(),
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Semantics(
                header: true,
                child: AppText(
                  'PAN VERIFICATION',
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                ),
              ),
            ),
          ),
          SizedBox(width: 36.w),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Verification Progress',
            child: LinearProgressIndicator(
              value: widget.currentStep / widget.totalSteps,
              backgroundColor: AppColors.darkCardBG,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.darkPrimary,
              ),
              minHeight: 4.h,
            ),
          ),
          SizedBox(height: 8.h),
          Semantics(
            label: 'Step ${widget.currentStep} of ${widget.totalSteps}',
            child: AppText(
              'Question ${widget.currentStep} of ${widget.totalSteps}',
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: AppColors.darkCardBG.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            _showOtpField ? Icons.sms_outlined : Icons.verified_user_outlined,
            size: 60.sp,
            color: AppColors.darkPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Phone Number',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            // Country Code Picker
            Semantics(
              button: true,
              label: 'Select Country Code',
              onTap: _phoneValidated ? null : _showCountryCodePicker,
              child: GestureDetector(
                onTap: _phoneValidated ? null : _showCountryCodePicker,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _phoneValidated
                            ? AppColors.darkCardBG.withOpacity(0.5)
                            : AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.darkCardBG, width: 1),
                  ),
                  child: Row(
                    children: [
                      AppText(
                        _selectedCountryCode,
                        variant: AppTextVariant.bodyMedium,
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_drop_down,
                        color: _phoneValidated ? Colors.grey : Colors.white,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Phone Number
            Expanded(
              child: Semantics(
                label: 'Phone Number',
                textField: true,
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  enabled: !_phoneValidated,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    letterSpacing: 1,
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16.sp,
                    ),
                    filled: true,
                    fillColor:
                        _phoneValidated
                            ? AppColors.darkCardBG.withOpacity(0.5)
                            : AppColors.darkCardBG,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.darkPrimary,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                    suffixIcon:
                        (_showOtpField && !_phoneValidated)
                            ? Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: InkWell(
                                onTap: _resetPhoneValidation,
                                borderRadius: BorderRadius.circular(20.r),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20.sp,
                                ),
                              ),
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Email Address',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
        ),
        SizedBox(height: 8.h),
        Semantics(
          label: 'Email Address',
          textField: true,
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            enabled: !_emailValidated,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
            ),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'your@email.com',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor:
                  _emailValidated
                      ? AppColors.darkCardBG.withOpacity(0.5)
                      : AppColors.darkCardBG,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.darkPrimary,
                  width: 2,
                ),
              ),
              suffixIcon:
                  (_showOtpField && !_emailValidated)
                      ? Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _emailValidated = false;
                              _showOtpField = false;
                              _otpController.clear();
                              _errorMessage = null;
                            });
                            _emailFocusNode.requestFocus();
                          },
                          borderRadius: BorderRadius.circular(20.r),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white.withOpacity(0.7),
                            size: 20.sp,
                          ),
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'OTP',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
        ),
        SizedBox(height: 8.h),
        Semantics(
          label: 'OTP',
          textField: true,
          child: TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              letterSpacing: 4,
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor: AppColors.darkCardBG,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
              ),
              counterText: '',
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              'Didn\'t receive OTP?',
              variant: AppTextVariant.caption,
              colorType: AppTextColorType.secondary,
            ),
            SizedBox(width: 5.w),
            AppButton(
              customBorderRadius: 6.r,
              text:
                  _otpResendCountdown > 0
                      ? "Resend in ${_otpResendCountdown}s"
                      : "Resend",
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              customHeight: 20.h,
              customPadding: EdgeInsets.symmetric(horizontal: 12.w),
              onPressed: _otpResendCountdown > 0 || _isLoading
                  ? null
                  : (widget.needsEmailVerification ? _sendEmailOtp : _sendOtp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'PAN',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
        ),
        SizedBox(height: 8.h),
        Semantics(
          label: 'PAN',
          textField: true,
          child: TextField(
            controller: _panController,
            focusNode: _panFocusNode,
            enabled: _phoneValidated,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              letterSpacing: 2,
            ),
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            autofocus: false,
            inputFormatters: [
              PanInputFormatter(), // Enforces PAN format: 5 letters + 4 numbers + 1 letter
            ],
            maxLength: 10,
            decoration: InputDecoration(
              hintText: 'ABCDE1234F',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor:
                  _phoneValidated
                      ? AppColors.darkCardBG
                      : AppColors.darkCardBG.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
              ),
              counterText: '',
            ),
          ),
        ),
        // Show verified name after successful PAN verification
        if (_panVerified && _verifiedName != null) ...[
          SizedBox(height: 20.h),
          Semantics(
            container: true,
            label: 'Identity Verified for ${_verifiedName!}',
            child: MergeSemantics(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.15),
                      const Color(0xFF059669).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identity Verified',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            _verifiedName!,
                            style: TextStyle(
                              fontSize: 17.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: AppText(
                _errorMessage!,
                variant: AppTextVariant.caption,
                customColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.check_circle_outline,
          text:
              'We share your PAN and mobile with BSE to securely help you invest',
        ),
        SizedBox(height: 12.h),
        _buildInfoCard(
          icon: Icons.verified_user_outlined,
          text: 'SEBI Registered Investment Advisor: INA000020396',
        ),
        SizedBox(height: 12.h),
        _buildInfoCard(
          icon: Icons.lock_outline,
          text: 'Your data is encrypted and 100% secure',
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Semantics(
      container: true,
      child: MergeSemantics(
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.darkCardBG, width: 1),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(icon, color: AppColors.darkPrimary, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppText(
                  text,
                  variant: AppTextVariant.caption,
                  colorType: AppTextColorType.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    bool isButtonEnabled = false;
    String buttonText = 'NEXT';

    if (widget.needsEmailVerification) {
      // Email verification flow
      if (!_emailValidated && !_showOtpField) {
        isButtonEnabled = _isEmailValid;
        buttonText = 'SEND OTP';
      } else if (_showOtpField) {
        isButtonEnabled = _otpController.text.length == 6;
        buttonText = 'VERIFY OTP';
      } else if (_emailValidated && !_panVerified) {
        isButtonEnabled = _isPanValid;
        buttonText = 'VERIFY PAN';
      } else if (_panVerified) {
        isButtonEnabled = true;
        buttonText = 'CONTINUE';
      }
    } else {
      // Phone verification flow
      if (!_phoneValidated && !_showOtpField) {
        isButtonEnabled = _isPhoneValid;
        // Show different text for Indian vs International numbers
        buttonText = _selectedCountryCode == '+91' ? 'SEND OTP' : 'SAVE PHONE';
      } else if (_showOtpField) {
        isButtonEnabled = _otpController.text.length == 6;
        buttonText = 'VERIFY OTP';
      } else if (_phoneValidated && !_panVerified) {
        isButtonEnabled = _isPanValid;
        buttonText = 'VERIFY PAN';
      } else if (_panVerified) {
        isButtonEnabled = true;
        buttonText = 'CONTINUE';
      }
    }

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AppButton(
        text: buttonText,
        isFullWidth: true,
        onPressed: (isButtonEnabled && !_isLoading) ? _handleNext : null,
        isDisabled: !isButtonEnabled || _isLoading,
        isLoading: _isLoading,
      ),
    );
  }

  /// Build email verification success state
  Widget _buildEmailSuccessState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Email Verified',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.success,
                ),
                SizedBox(height: 4.h),
                AppText(
                  _verifiedEmail ?? '',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build PAN verification failure state
  Widget _buildPanFailureState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'PAN Verification Failed',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.error,
                ),
                SizedBox(height: 4.h),
                AppText(
                  'Please check your PAN and try again',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom TextInputFormatter for PAN format: 5 letters + 4 numbers + 1 letter
/// Example: JVHPK6199D
class PanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    final length = text.length;

    // If text is empty or being deleted, allow it
    if (text.isEmpty || length < oldValue.text.length) {
      return TextEditingValue(text: text, selection: newValue.selection);
    }

    // Validate based on position
    String validatedText = '';
    for (int i = 0; i < length && i < 10; i++) {
      final char = text[i];

      if (i < 5) {
        // Positions 1-5: Only letters (A-Z)
        if (RegExp(r'^[A-Z]$').hasMatch(char)) {
          validatedText += char;
        } else {
          // Invalid character for this position, reject the input
          return oldValue;
        }
      } else if (i < 9) {
        // Positions 6-9: Only numbers (0-9)
        if (RegExp(r'^[0-9]$').hasMatch(char)) {
          validatedText += char;
        } else {
          // Invalid character for this position, reject the input
          return oldValue;
        }
      } else {
        // Position 10: Only letter (A-Z)
        if (RegExp(r'^[A-Z]$').hasMatch(char)) {
          validatedText += char;
        } else {
          // Invalid character for this position, reject the input
          return oldValue;
        }
      }
    }

    return TextEditingValue(
      text: validatedText,
      selection: TextSelection.collapsed(offset: validatedText.length),
    );
  }
}
