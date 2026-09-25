import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/biometric_service.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class BiometricsSetupScreen extends StatefulWidget {
  final bool showSkipOption;
  final Function()? onSkip;
  final Function()? onComplete;

  const BiometricsSetupScreen({
    super.key,
    this.showSkipOption = false,
    this.onSkip,
    this.onComplete,
  });

  @override
  State<BiometricsSetupScreen> createState() => _BiometricsSetupScreenState();
}

class _BiometricsSetupScreenState extends State<BiometricsSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    List<BiometricType> availableBiometrics;

    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.error('Error checking biometrics', error: e, tag: 'BiometricsSetup');
      canCheckBiometrics = false;
      availableBiometrics = [];
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
      _isLoading = false;
    });
  }

  Future<void> _enableBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        // Save biometrics preference
        await BiometricService.to.setBiometricEnabled(true);
        
        // Call onComplete callback if provided
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Get.back();
        }
      }
    } catch (e) {
      AppLogger.error('Error enabling biometrics', error: e, tag: 'BiometricsSetup');
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
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
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "Biometrics Error",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "There was an error setting up biometrics. Please try again later.",
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

  String _getBiometricType() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else {
      return 'Biometric';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Biometric Login",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  80,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 160,
                          child: Lottie.asset(
                            'assets/lottie/biometrics.json',
                            frameRate: FrameRate.max,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              AppText(
                                "Enable ${_getBiometricType()} Login",
                                variant: AppTextVariant.headline4,
                                lineHeight: 1.3,
                                colorType: AppTextColorType.primary,
                                weight: AppTextWeight.bold,
                              ),
                              const SizedBox(height: 16),
                              AppText(
                                "Secure your account with biometric authentication for faster access to your account.",
                                variant: AppTextVariant.bodyMedium,
                                lineHeight: 1.5,
                                colorType: AppTextColorType.secondary,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              children: [
                // Show skip button if showSkipOption is true
                if (widget.showSkipOption && widget.onSkip != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    child: TextButton(
                      onPressed: widget.onSkip,
                      child: const AppText(
                        'Skip for now',
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.secondary,
                      ),
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  width: double.infinity,
                  child: AppButton(
                    text: 'Enable ${_getBiometricType()} Login',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    onPressed: _canCheckBiometrics && _availableBiometrics.isNotEmpty
                        ? _enableBiometrics
                        : (){},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
