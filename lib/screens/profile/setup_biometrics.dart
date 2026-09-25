import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/biometric_service.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class SetupBiometrics extends StatefulWidget {
  const SetupBiometrics({super.key});

  @override
  State<SetupBiometrics> createState() => _SetupBiometricsState();
}

class _SetupBiometricsState extends State<SetupBiometrics> {
  final BiometricService _biometricService = BiometricService.to;

  Future<void> _enableBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      await _biometricService.setBiometricEnabled(true);
      Get.back(result: true);
      // Get.snackbar(
      //   'Success',
      //   'Biometric authentication enabled successfully',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    }
  }

  void _skipToDashboard() {
    Get.back();
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
              "Setup Biometrics",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(
              opacity: 0,
              child: Icon(Icons.chevron_left, size: 32),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: Lottie.asset('assets/lottie/biometrics.json'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              AppText(
                "Enable Biometric Authentication",
                variant: AppTextVariant.headline4,
                lineHeight: 1.3,
                colorType: AppTextColorType.primary,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 16),
              AppText(
                "Use your fingerprint or face ID to quickly and securely access your account",
                variant: AppTextVariant.bodyLarge,
                lineHeight: 1.5,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Enable Biometrics',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    leadingIcon: Icons.fingerprint_rounded,
                    onPressed: _enableBiometrics,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  width: double.infinity,
                  child: AppButton(
                    text: 'Skip',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.large,
                    onPressed: _skipToDashboard,
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
