import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/screens/profile/setup_biometrics.dart';

import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/services/biometric_service.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/otp_field.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class SetPin extends StatefulWidget {
  final String phoneNumber;
  final bool showSkipOption;
  final Function()? onSkip;
  final Function()? onComplete;
  final bool? isBiometricEnabled;
  final bool isFromProfile;

  const SetPin({
    super.key,
    required this.phoneNumber,
    this.showSkipOption = false,
    this.onSkip,
    this.onComplete,
    this.isBiometricEnabled,
    this.isFromProfile = false,
  });

  @override
  State<SetPin> createState() => _SetPinState();
}

class _SetPinState extends State<SetPin> {
  String _otpCode = '';
  final ValueNotifier<int> _otpKey = ValueNotifier<int>(0);
  bool _isConfirmationStep = false;
  String _firstPin = '';

  void _resetPinFields() {
    setState(() {
      _isConfirmationStep = false;
      _firstPin = '';
      _otpKey.value++; // Force OTPField recreation
    });
  }

  void _setPin(String pin) async {
    try {
      if (pin.length == 6) {
        if (!_isConfirmationStep) {
          // First PIN entry
          _firstPin = pin;
          setState(() {
            _isConfirmationStep = true;
            _otpCode = ''; // Clear the OTP code for confirmation step
            _otpKey.value++; // Force OTPField recreation for confirmation
          });
          return; // Exit early, don't proceed to confirmation dialog
        } else {
          // Confirmation PIN entry
          if (pin == _firstPin) {
            // PIN confirmed, save it directly
            await _savePinAndProceed(pin);
          } else {
            setState(() {
              _isConfirmationStep = false;
              _firstPin = '';
              _otpCode = ''; // Clear the OTP code
            });
            _showPinMismatchDialog(context);
          }
        }
      } else {
        AppLogger.error('Invalid pin', tag: 'SetPin');
      }
    } catch (e) {
      AppLogger.error('SetPin Error', error: e, tag: 'SetPin');
    }
  }

  Future<void> _savePinAndProceed(String pin) async {
    try {
      // Save PIN to secure storage
      await SecureStorage.write(StorageKeys.PIN_KEY, pin);
      await SecureStorage.write(StorageKeys.IS_PIN_SET_KEY, 'true');
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.userProfilePinSetSuccess,
      );

      AppLogger.info('PIN saved successfully', tag: 'SetPin');

      // Handle biometric setup if enabled
      if (widget.isBiometricEnabled != null) {
        final result = await Get.to(() => const SetupBiometrics());
        if (result == true) {
          // Save biometric preference
          await BiometricService.to.setBiometricEnabled(true);
          AppLogger.info('Biometric enabled', tag: 'SetPin');
        }
      }

      // Redirect based on origin
      if (widget.isFromProfile) {
        AppLogger.info('Returning to Profile after PIN setup', tag: 'SetPin');
        Get.back();
      } else {
        // Always redirect to Dashboard after PIN setup during onboarding
        AppLogger.info(
          'Redirecting to Dashboard after PIN setup',
          tag: 'SetPin',
        );
        Get.offAll(() => const StackedNavbar(selectedIdx: 0));
      }
    } catch (e) {
      AppLogger.error('Error saving PIN', error: e, tag: 'SetPin');
    }
  }

  void _showIncompletePinDialog(BuildContext context) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.userProfilePinIncompleteError,
    );
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
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.only(top: 28, bottom: 16),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AppText(
                      "Incomplete PIN",
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Please enter a complete 6-digit PIN to continue.",
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
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: AppText(
                      "OK",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPinMismatchDialog(BuildContext context) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.userProfilePinMismatchError,
    );
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
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.only(top: 28, bottom: 16),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AppText(
                      "PIN Mismatch",
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "The PIN you entered do not match, Please try again.",
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
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetPinFields();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: AppText(
                      "Try Again",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.semiBold,
                    ),
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
  void dispose() {
    _otpKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: 'Back',
              onTap: () {
                if (_isConfirmationStep) {
                  _resetPinFields();
                } else {
                  Get.back();
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_isConfirmationStep) {
                    _resetPinFields();
                  } else {
                    Get.back();
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: AppText(
                "Set Pin",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
            const Opacity(opacity: 0, child: SizedBox(width: 48, height: 48)),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Optimize Lottie animation with cacheWidth to reduce rendering load
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 160, // Fixed width instead of percentage
                          child: Lottie.asset(
                            'assets/lottie/lock.json',
                            frameRate: FrameRate.max,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: AppText(
                                _isConfirmationStep
                                    ? "Confirm 6 digit MPIN"
                                    : "Enter 6 digit MPIN",
                                variant: AppTextVariant.headline4,
                                lineHeight: 1.3,
                                colorType: AppTextColorType.primary,
                                weight: AppTextWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Use RepaintBoundary to optimize OTPField rendering
                      RepaintBoundary(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _otpKey,
                          builder:
                              (context, key, child) => Semantics(
                                label:
                                    _isConfirmationStep
                                        ? "Confirm 6 digit PIN"
                                        : "Enter 6 digit PIN",
                                textField: true,
                                child: OTPField(
                                  key: ValueKey(key),
                                  enableAutofill: false,
                                  onOTPFilled: (pin) {
                                    setState(() => _otpCode = pin);
                                    _setPin(pin);
                                  },
                                  length: 6,
                                  obscureText: true,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSkipOption && widget.onSkip != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          AnalyticsService.to.logEvent(
                            name: AnalyticsEvents.userProfilePinSkipClicked,
                          );
                          if (widget.onSkip != null) widget.onSkip!();
                        },
                        child: const AppText(
                          'Skip for now',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.secondary,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: _isConfirmationStep ? 'Confirm' : 'Proceed',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed: () {
                        if (_otpCode.length == 6) {
                          _setPin(_otpCode);
                        } else {
                          // Show error dialog for incomplete PIN
                          _showIncompletePinDialog(context);
                        }
                      },
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
