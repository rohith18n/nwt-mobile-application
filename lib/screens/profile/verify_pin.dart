import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/services/biometric_service.dart';
import 'package:nwt_app/services/mpin_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/common/pinput_peek.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:pinput/pinput.dart';

class VerifyPin extends StatefulWidget {
  const VerifyPin({super.key});

  @override
  State<VerifyPin> createState() => _VerifyPinState();
}

class _VerifyPinState extends State<VerifyPin>
    with TickerProviderStateMixin, PinPeekMixin {
  String? _errorMessage;
  bool _biometricsAvailable = false;
  final _biometricService = BiometricService.to;
  final _authFlow = AuthFlow();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    disposePeekMixin();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _checkBiometrics() async {
    try {
      final available = await _biometricService.isBiometricsAvailable();
      if (mounted) {
        setState(() {
          _biometricsAvailable = available;
        });
      }
      return available;
    } catch (e) {
      AppLogger.error("Error checking biometrics", error: e);
      return false;
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        Navigator.pop(context, true);
        return;
      }
      // If biometric auth fails or is cancelled, force MPIN entry
      setState(() {
        _errorMessage = 'Please enter your PIN to continue';
      });
      // Focus the PIN field
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    } catch (e) {
      // On error, force MPIN entry
      if (mounted) {
        setState(() {
          _errorMessage = 'Please enter your PIN to continue';
        });
        _pinFocusNode.requestFocus();
      }
      AppLogger.error("Biometric authentication error", error: e);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBiometrics();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final available = await _checkBiometrics();
        if (available && _biometricService.isBiometricEnabled) {
          await _authenticateWithBiometrics();
        }
        if (mounted) {
          _pinFocusNode.requestFocus();
        }
      }
    });
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mpinService = MPINService.to;
      final result = await mpinService.verifyPIN(pin);

      if (result) {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.otpVerifiedSuccess);
        Navigator.pop(context, true);
      } else {
        AnalyticsService.to.logEvent(name: AnalyticsEvents.otpVerifiedFailed);
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _pinController.clear();
          _pinFocusNode.requestFocus();
        });
      }
    } catch (e) {
      AppLogger.error("PIN verification error", error: e);
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSignOut() {
    _showSignOutConfirmation();
  }

  void _showSignOutConfirmation() {
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
                  color: Colors.black.withOpacity(0.2),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_alt_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Sign in as different user",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "This will clear all your data and sign you out. Are you sure you want to continue?",
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
                        color: AppColors.darkInputBorder.withOpacity(0.5),
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
                        color: AppColors.darkInputBorder.withOpacity(0.5),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _clearStorageAndNavigateToPhoneScreen();
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
                            "Continue",
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: TextStyle(
        fontSize: 18,
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkInputBackground
                : AppColors.lightInputPrimaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkInputBorder
                  : AppColors.lightInputPrimaryBorder,
          width: 1,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: primaryColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: primaryColor.withOpacity(isDark ? 0.1 : 0.05),
        border: Border.all(color: primaryColor, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        actions: [
          Semantics(
            label: 'Logout',
            hint: 'Opens sign out confirmation dialog',
            button: true,
            child: TextButton(
              onPressed: _handleSignOut,
              child: ExcludeSemantics(
                child: AppText(
                  "Logout",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.primary,
                  weight: AppTextWeight.medium,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height:
                            isKeyboardOpen
                                ? 16
                                : MediaQuery.of(context).size.height * 0.05,
                      ),

                      ExcludeSemantics(
                        child: Center(
                          child: SizedBox(
                            width:
                                !isKeyboardOpen
                                    ? MediaQuery.of(context).size.width * 0.45
                                    : MediaQuery.of(context).size.width * 0.35,
                            child: Lottie.asset('assets/lottie/lock.json'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Semantics(
                        header: true,
                        child: AppText(
                          "Verify PIN",
                          variant: AppTextVariant.headline4,
                          lineHeight: 1.3,
                          colorType: AppTextColorType.primary,
                          weight: AppTextWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AppText(
                        "Please enter your 6-digit PIN to continue",
                        variant: AppTextVariant.bodyMedium,
                        lineHeight: 1.3,
                        colorType: AppTextColorType.muted,
                        weight: AppTextWeight.medium,
                      ),
                      SizedBox(height: isKeyboardOpen ? 16 : 30),
                      Semantics(
                        label: 'PIN entry field, enter your 6-digit PIN',
                        textField: true,
                        child: Center(
                          child: Pinput.builder(
                            length: 6,
                            controller: _pinController,
                            focusNode: _pinFocusNode,
                            keyboardType: TextInputType.number,
                            onChanged: onPinChanged,
                            onCompleted: (_) => _verifyPin(),
                            autofocus: false,
                            builder: (context, state) {
                              // Pick the right theme decoration based on pin state
                              final theme = switch (state.type) {
                                PinItemStateType.focused => focusedPinTheme,
                                PinItemStateType.submitted => submittedPinTheme,
                                _ => defaultPinTheme,
                              };

                              final bool isPeeking =
                                  state.value.isNotEmpty &&
                                  state.index == peekIndex;
                              final display =
                                  state.value.isEmpty
                                      ? ''
                                      : isPeeking
                                      ? state.value
                                      : obscuringCharacter;

                              return ExcludeSemantics(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: theme.width ?? 48,
                                  height: theme.height ?? 56,
                                  decoration: theme.decoration,
                                  alignment: Alignment.center,
                                  child:
                                      display.isEmpty
                                          ? const SizedBox.shrink()
                                          : Text(
                                            display,
                                            style:
                                                theme.textStyle ??
                                                defaultPinTheme.textStyle,
                                          ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        liveRegion: true,
                        child: AnimatedErrorMessage(
                          errorMessage: _errorMessage,
                        ),
                      ),
                      if (_biometricsAvailable &&
                          _biometricService.isBiometricEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Semantics(
                                label: 'Use Biometric Login',
                                hint:
                                    'Authenticate with fingerprint or face ID',
                                button: true,
                                child: TextButton.icon(
                                  onPressed: _authenticateWithBiometrics,
                                  icon: ExcludeSemantics(
                                    child: Icon(
                                      Icons.fingerprint_rounded,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  label: ExcludeSemantics(
                                    child: AppText(
                                      "Use Biometric Login",
                                      variant: AppTextVariant.bodyMedium,
                                      colorType: AppTextColorType.primary,
                                      weight: AppTextWeight.medium,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Sign in as different user button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Sign in as different user',
                            hint: 'Clears all data and signs you out',
                            button: true,
                            child: TextButton.icon(
                              onPressed: _handleSignOut,
                              icon: ExcludeSemantics(
                                child: Icon(
                                  Icons.person_add_alt_rounded,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                              label: ExcludeSemantics(
                                child: AppText(
                                  "Sign in as different user",
                                  variant: AppTextVariant.bodyMedium,
                                  colorType: AppTextColorType.secondary,
                                  weight: AppTextWeight.medium,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 24),
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
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: "Confirm",
                      onPressed: _verifyPin,
                      isLoading: _isLoading,
                      isDisabled: _pinController.text.length != 6 || _isLoading,
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

  // Clear storage and navigate to phone number screen
  void _clearStorageAndNavigateToPhoneScreen() async {
    try {
      await _authFlow.logout();
    } catch (e) {
      AppLogger.error("Error during sign out", error: e, tag: 'VerifyPin');
    }
  }
}
