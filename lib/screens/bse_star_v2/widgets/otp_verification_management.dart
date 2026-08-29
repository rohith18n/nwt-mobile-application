import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/services/auth/ucc_service.dart';

class OTPVerificationManagement extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onError;
  final bool shouldSubmit;

  const OTPVerificationManagement({
    super.key,
    this.onNext,
    this.onBack,
    this.onError,
    this.shouldSubmit = false,
  });

  @override
  State<OTPVerificationManagement> createState() =>
      _OTPVerificationManagementState();
}

class _OTPVerificationManagementState
    extends State<OTPVerificationManagement> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _hasNominees = false;
  List<String> _clientCodes = [];
  int _currentStep = 0; // 0 = opt-out OTP (if no nominees), 1 = BSE OTP
  
  // Track which client codes have been verified
  final Map<String, bool> _verifiedCodes = {};
  int _currentClientIndex = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.info('initState called', tag: 'OTPVerification');
    _loadClientCodes();

    // Listen for shouldSubmit changes from parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('initState postFrameCallback - shouldSubmit: ${widget.shouldSubmit}', tag: 'OTPVerification');
      if (widget.shouldSubmit) {
        AppLogger.info('shouldSubmit is true in initState, calling _handleSubmit()', tag: 'OTPVerification');
        _handleSubmit();
      }
    });
  }

  @override
  void didUpdateWidget(OTPVerificationManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    AppLogger.info(
      'didUpdateWidget - oldWidget.shouldSubmit: ${oldWidget.shouldSubmit}, widget.shouldSubmit: ${widget.shouldSubmit}, _isLoading: $_isLoading',
      tag: 'OTPVerification',
    );
    
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isLoading) {
      AppLogger.info('shouldSubmit changed from false to true, calling _handleSubmit()', tag: 'OTPVerification');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSubmit();
      });
    }
  }

  Future<void> _loadClientCodes() async {
    try {
      final hasNomineesStr = await SecureStorage.read('has_nominees');
      final clientCodesStr = await SecureStorage.read('ucc_client_codes');

      setState(() {
        _hasNominees = hasNomineesStr == 'true';
        
        if (clientCodesStr != null && clientCodesStr.isNotEmpty) {
          final decoded = jsonDecode(clientCodesStr);
          _clientCodes = List<String>.from(decoded);
          
          // Initialize verification tracking
          for (var code in _clientCodes) {
            _verifiedCodes[code] = false;
          }
        }

        // Determine starting step
        // If no nominees, start with opt-out OTP (step 0)
        // If has nominees, start with BSE OTP (step 1)
        _currentStep = _hasNominees ? 1 : 0;
      });

      AppLogger.info(
        'OTP Verification initialized: hasNominees=$_hasNominees, clientCodes=$_clientCodes, step=$_currentStep',
        tag: 'OTPVerification',
      );
    } catch (e) {
      AppLogger.error(
        'Error loading client codes',
        error: e,
        tag: 'OTPVerification',
      );
    }
  }

  void _handleSubmit() {
    AppLogger.info('_handleSubmit called - OTP: ${_otpController.text}', tag: 'OTPVerification');
    _verifyOTP();
  }

  Future<void> _verifyOTP() async {
    AppLogger.info('=== OTP Verification Started ===', tag: 'OTPVerification');
    
    // Validate OTP
    final otp = _otpController.text;
    AppLogger.info('OTP entered: ${otp.length} digits', tag: 'OTPVerification');
    
    if (otp.length != 6) {
      AppLogger.info('OTP validation failed: not 6 digits', tag: 'OTPVerification');
      _showError('Please enter the complete 6-digit OTP');
      widget.onError?.call();
      return;
    }

    AppLogger.info('Setting loading state to true', tag: 'OTPVerification');
    setState(() {
      _isLoading = true;
    });

    try {
      final uccService = UCCService();
      final currentClientCode = _clientCodes[_currentClientIndex];
      
      AppLogger.info(
        'Current state - Step: $_currentStep, ClientIndex: $_currentClientIndex, ClientCode: $currentClientCode',
        tag: 'OTPVerification',
      );
      
      // Determine purpose based on current step
      String purpose;
      if (_currentStep == 0) {
        // Opt-out OTP verification
        purpose = 'nominee_opt_out';
        AppLogger.info(
          '>>> STEP 0: Verifying NOMINEE OPT-OUT OTP for client code: $currentClientCode',
          tag: 'OTPVerification',
        );
      } else {
        // BSE/Exchange OTP verification
        purpose = 'bse';
        AppLogger.info(
          '>>> STEP 1: Verifying BSE OTP for client code: $currentClientCode',
          tag: 'OTPVerification',
        );
      }

      AppLogger.info(
        'Calling UCCService.verifyOTP with purpose: $purpose, otp: $otp',
        tag: 'OTPVerification',
      );
      
      final response = await uccService.verifyOTP(
        clientCode: currentClientCode,
        otp: otp,
        purpose: purpose,
      );

      AppLogger.info(
        'UCCService.verifyOTP response received - success: ${response?.success}, message: ${response?.message}',
        tag: 'OTPVerification',
      );

      if (response == null || !response.success) {
        AppLogger.error(
          'OTP verification failed - response: ${response?.message}',
          tag: 'OTPVerification',
        );
        throw Exception(
          response?.message ?? 'OTP verification failed',
        );
      }

      AppLogger.info(
        '✓ OTP verified successfully for $currentClientCode with purpose $purpose',
        tag: 'OTPVerification',
      );

      // Mark this code as verified
      _verifiedCodes[currentClientCode] = true;

      // Handle next step based on current state
      if (_currentStep == 0) {
        // Just completed opt-out OTP, now move to BSE OTP
        AppLogger.info(
          '>>> Opt-out OTP verified successfully! Moving to BSE OTP step...',
          tag: 'OTPVerification',
        );
        
        AppLogger.info('Updating state: Step 0 → 1, clearing OTP field', tag: 'OTPVerification');
        setState(() {
          _currentStep = 1;
          _currentClientIndex = 0; // Reset to first client for BSE OTP
          _otpController.clear();
        });
        
        AppLogger.info('State updated. New step: $_currentStep', tag: 'OTPVerification');
        AppLogger.info('Resetting parent shouldSubmit state for next OTP', tag: 'OTPVerification');
        
        // Reset parent's shouldSubmit so it can be triggered again for BSE OTP
        widget.onError?.call();
        
        AppLogger.info('Screen will update to show BSE OTP input', tag: 'OTPVerification');
        AppLogger.info('=== OTP Verification Complete (Opt-out) ===', tag: 'OTPVerification');
      } else {
        // BSE OTP verified
        AppLogger.info(
          '>>> BSE OTP verified successfully! Current index: $_currentClientIndex, Total codes: ${_clientCodes.length}',
          tag: 'OTPVerification',
        );
        
        _currentClientIndex++;
        AppLogger.info('Incremented client index to: $_currentClientIndex', tag: 'OTPVerification');

        if (_currentClientIndex < _clientCodes.length) {
          // More client codes to verify
          AppLogger.info(
            'More accounts to verify. Moving to account ${_currentClientIndex + 1}/${_clientCodes.length}',
            tag: 'OTPVerification',
          );
          
          setState(() {
            _otpController.clear();
          });

          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && !Get.isSnackbarOpen) {
                Get.snackbar(
                  'Success',
                  'Verified! Enter OTP for next account (${_currentClientIndex + 1}/${_clientCodes.length})',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            });
          }
        } else {
          // All done!
          AppLogger.info(
            '🎉 All OTPs verified successfully! UCC creation complete!',
            tag: 'OTPVerification',
          );

          // Clear loading states before navigation
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          
          // Clear parent loading state
          AppLogger.info('Clearing parent loading state', tag: 'OTPVerification');
          widget.onError?.call(); // This resets parent's _isSubmitting to false

          // Navigate to next screen (completion/dashboard)
          AppLogger.info('Calling onNext callback to navigate to dashboard', tag: 'OTPVerification');
          if (widget.onNext != null) {
            widget.onNext!();
          } else {
            AppLogger.info('WARNING: onNext callback is null!', tag: 'OTPVerification');
          }
          
          AppLogger.info('=== OTP Verification Complete (All Accounts) ===', tag: 'OTPVerification');
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error verifying OTP',
        error: e,
        tag: 'OTPVerification',
      );

      _showError(e.toString().replaceAll('Exception: ', ''));
      
      // Clear both local and parent loading states on error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      widget.onError?.call();
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !Get.isSnackbarOpen) {
          Get.snackbar(
            'Error',
            message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String _getStepTitle() {
    if (_currentStep == 0) {
      return 'Verify Nominee Opt-Out';
    } else {
      if (_clientCodes.length > 1) {
        return 'Verify Account ${_currentClientIndex + 1}/${_clientCodes.length}';
      }
      return 'Verify Your Account';
    }
  }

  String _getStepDescription() {
    if (_currentStep == 0) {
      return 'Enter the 6-digit code sent to your email to confirm nominee opt-out.';
    } else {
      return 'Enter the 6-digit BSE verification code sent to your email.';
    }
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
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration!.copyWith(
        border: Border.all(color: Colors.white, width: 1),
      ),
    );

    final submittedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration!.copyWith(
        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
          separatorBuilder: (index) => SizedBox(width: 12.w),
          length: 6,
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          onChanged: (value) {
            setState(() {});
          },
          builder: (context, state) {
            final theme = switch (state.type) {
              PinItemStateType.focused => focusedPin,
              PinItemStateType.submitted => submittedPin,
              _ => defaultPin,
            };

            final display = state.value.isEmpty ? '' : state.value;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: theme.width ?? 48.w,
              height: theme.height ?? 56.h,
              decoration: theme.decoration,
              alignment: Alignment.center,
              child: display.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      display,
                      style: theme.textStyle ?? defaultPin.textStyle,
                    ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          
          // Title
          AppText(
            _getStepTitle(),
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            customColor: Colors.white,
          ),
          SizedBox(height: 8.h),
          
          // Description
          AppText(
            _getStepDescription(),
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
          ),
          
          SizedBox(height: 32.h),

          // Client Code Display
          if (_clientCodes.isNotEmpty && _currentClientIndex < _clientCodes.length)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Client Code',
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.gray,
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        _clientCodes[_currentClientIndex],
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        customColor: Colors.white,
                      ),
                    ],
                  ),
                  Icon(
                    Icons.verified_user,
                    color: Colors.blue.withOpacity(0.7),
                    size: 32.w,
                  ),
                ],
              ),
            ),

          SizedBox(height: 32.h),

          // OTP Input
          _buildOTPInput(),

          SizedBox(height: 32.h),

          // Resend OTP Info
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (mounted && !Get.isSnackbarOpen) {
                        Get.snackbar(
                          'Info',
                          'Please check your email for the verification code',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
              child: AppText(
                'Didn\'t receive code? Check your email',
                variant: AppTextVariant.bodyMedium,
                customColor: Colors.blue,
              ),
            ),
          ),

          SizedBox(height: 100.h),
        ],
      ),
    );
  }
}
