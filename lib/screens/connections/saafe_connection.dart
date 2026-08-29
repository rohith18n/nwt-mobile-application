import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nwt_app/constants/aa_branding.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/connections/nri_phonenumber.dart';
import 'package:nwt_app/services/account_aggregators/saafe_integration_service.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/controllers/user_controller.dart';

class SaafeConnectionScreen extends StatefulWidget {
  /// Optional phone number passed from an upstream flow (e.g. post-PAN phone screen).
  /// When present, tapping "I ACKNOWLEDGE" will start Saafe SDK with this phone.
  final String? phoneNumber;

  /// When true, hides the back button in the app bar (e.g. when coming from a one-way onboarding flow).
  final bool hideBackButton;

  const SaafeConnectionScreen({
    super.key,
    this.phoneNumber,
    this.hideBackButton = false,
  });

  @override
  State<SaafeConnectionScreen> createState() => _SaafeConnectionScreenState();
}

class _SaafeConnectionScreenState extends State<SaafeConnectionScreen> {
  final SaafeIntegrationService _saafeIntegrationService =
      SaafeIntegrationService();
  final userController = Get.find<UserController>();

  void _handleAcknowledge() {
    final user = userController.userData;
    
    // Log user profile data
    AppLogger.info(
      'User Profile: ${user?.toJson() ?? 'null'}',
      tag: 'SaafeConnection',
    );
    
    // Check if user is NRI and doesn't have Indian phone number
    if (user?.isNri == true && user?.nri_phone_exists == false) {
      // If we already have a valid 10-digit Indian number passed from upstream, use it.
      final passedPhone = (widget.phoneNumber ?? '').trim();
      final isIndian = passedPhone.length == 10 &&
          RegExp(r'^[6789]').hasMatch(passedPhone);

      if (isIndian) {
        AppLogger.info(
          'NRI user - using passed Indian phone number: $passedPhone',
          tag: 'SaafeConnection',
        );
        _saafeIntegrationService.openSaafeSdk(
          context: context,
          phoneNumber: passedPhone,
        );
        return;
      }

      // Otherwise, navigate to NRI phone number screen
      Get.to(
        () => const NriPhonenumber(),
        transition: Transition.rightToLeft,
      )?.then((phoneNumber) {
        // If phone number is provided, proceed with Saafe SDK using the entered phone number
        if (phoneNumber != null) {
          _saafeIntegrationService.openSaafeSdk(
            context: context,
            phoneNumber: phoneNumber,
          );
        }
      });
    } else if (user?.isNri == true && user?.nri_phone_exists == true) {
      // NRI user already has Indian phone number, use secondary phone number
      _saafeIntegrationService.openSaafeSdk(
        context: context,
        phoneNumber: user?.secondaryphonenumber,
      );
    } else {
      // Proceed with Saafe SDK. If phoneNumber is provided, use it.
      _saafeIntegrationService.openSaafeSdk(
        context: context,
        phoneNumber: widget.phoneNumber,
      );
    }
  }

  Widget _buildBulletPoint(IconData icon, Color color, String text) {
    AppLogger.info(
      'User Profile: ${userController.userData?.toJson() ?? 'null'}',
      tag: 'SaafeConnection',
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: AppText(
            text,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCardBG,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!widget.hideBackButton)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left, size: 32),
              )
            else
              const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
            AppText(
              "Redirection",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo section: pivot logo, redirection icon, AA provider logo (Finarkein or Saafe)
                Row(
                  children: [
                    SvgPicture.asset('assets/app/pivot_money.svg'),
                    const Spacer(),
                    SvgPicture.asset(
                      AaBranding.redirectionCenterSvgPath,
                      height: 36,
                    ),
                    const Spacer(),
                    Image.asset(AaBranding.logoAssetPath),
                  ],
                ),

                const SizedBox(height: 40),

                // Title
                Column(
                  children: [
                    AppText(
                      'Redirecting to ${AaBranding.providerName}\nAccount Aggregator',
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      textAlign: TextAlign.center,
                      colorType: AppTextColorType.primary,
                      lineHeight: 1.3,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    const AppText(
                      'RBI authorized institution that securely finds and shares your financial data with us',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Warning Box
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          AppText(
                            'PLEASE NOTE',
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.semiBold,
                            colorType: AppTextColorType.primary,
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const AppText(
                        'Account Aggregators DO NOT support',
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.secondary,
                      ),

                      const SizedBox(height: 16),

                      _buildBulletPoint(
                        Icons.close_rounded,
                        Colors.redAccent,
                        'JOINT ACCOUNTS',
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint(
                        Icons.close_rounded,
                        Colors.redAccent,
                        'CURRENT ACCOUNTS',
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint(
                        Icons.info_outline,
                        Colors.blueAccent,
                        'INDIAN PHONE NUMBER REQUIRED',
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint(
                        Icons.error_outline,
                        Colors.orangeAccent,
                        'INSURANCE (partly supported)',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  child: AppButton(
                    text: "I ACKNOWLEDGE",
                    onPressed: () {
                      _handleAcknowledge();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Learn More Link
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    const AppText(
                      'Your data is encrypted and 100% secure',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/svgs/saafe/indian_flag.jpg',
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const AppText(
                      'Used by 10+ million citizens across India',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
