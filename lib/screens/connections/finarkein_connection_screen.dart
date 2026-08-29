import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/connections/nri_phonenumber.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_integration_service.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/snackbar_helper.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// Finarkein AA connection screen. Same layout as Saafe connection; "I ACKNOWLEDGE" starts Finarkein flow.
class FinarkeinConnectionScreen extends StatefulWidget {
  /// Optional phone number passed from an upstream flow (e.g. post-PAN phone screen).
  /// When present, tapping "I ACKNOWLEDGE" will initiate consent with this phone.
  final String? phoneNumber;

  /// When true, hides the back button in the app bar (e.g. when coming from a one-way onboarding flow).
  final bool hideBackButton;

  const FinarkeinConnectionScreen({
    super.key,
    this.phoneNumber,
    this.hideBackButton = false,
  });

  @override
  State<FinarkeinConnectionScreen> createState() =>
      _FinarkeinConnectionScreenState();
}

class _FinarkeinConnectionScreenState extends State<FinarkeinConnectionScreen> {
  final FinarkeinIntegrationService _finarkeinService =
      FinarkeinIntegrationService();
  final UserController userController = Get.find<UserController>();
  bool _isProcessing = false;

  void _handleAcknowledge() async {
    if (_isProcessing ||
        FinarkeinIntegrationService.isConsentStatusInProgress) {
      SnackbarHelper.showInfo(
        title: 'Please wait',
        message:
            'Linking is already in progress. Please wait for it to complete.',
        position: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = userController.userData;
      AppLogger.info(
        'User Profile: ${user?.toJson() ?? 'null'}',
        tag: 'FinarkeinConnection',
      );

      if (user?.isNri == true && user?.nri_phone_exists == false) {
        // If we already have a valid 10-digit Indian number passed from upstream, use it.
        final passedPhone = (widget.phoneNumber ?? '').trim();
        final isIndian =
            passedPhone.length == 10 &&
            RegExp(r'^[6789]').hasMatch(passedPhone);

        if (isIndian) {
          AppLogger.info(
            'NRI user - using passed Indian phone number: $passedPhone',
            tag: 'FinarkeinConnection',
          );
          await _finarkeinService.initiateAndOpenRedirect(
            context: context,
            phoneNumber: passedPhone,
          );
          return;
        }

        // Otherwise, navigate to NRI phone number screen
        final phoneNumber = await Get.to(
          () => const NriPhonenumber(),
          transition: Transition.rightToLeft,
        );

        if (phoneNumber != null && mounted) {
          if (FinarkeinIntegrationService.isConsentStatusInProgress) {
            SnackbarHelper.showInfo(
              title: 'Please wait',
              message:
                  'Linking is already in progress. Please wait for it to complete.',
              position: SnackPosition.TOP,
            );
            return;
          }
          await _finarkeinService.initiateAndOpenRedirect(
            context: context,
            phoneNumber: phoneNumber,
          );
        }
      } else if (user?.isNri == true && user?.nri_phone_exists == true) {
        await _finarkeinService.initiateAndOpenRedirect(
          context: context,
          phoneNumber: user?.secondaryphonenumber,
        );
      } else {
        await _finarkeinService.initiateAndOpenRedirect(
          context: context,
          phoneNumber: widget.phoneNumber,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error in _handleAcknowledge',
        error: e,
        tag: 'FinarkeinConnection',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildBulletPoint(IconData icon, Color color, String text) {
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
              Semantics(
                label: 'Go back',
                button: true,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const ExcludeSemantics(
                    child: Icon(Icons.chevron_left, size: 32),
                  ),
                ),
              )
            else
              const ExcludeSemantics(
                child: Opacity(
                  opacity: 0,
                  child: Icon(Icons.chevron_left, size: 32),
                ),
              ),
            Semantics(
              header: true,
              child: AppText(
                "Redirection",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
            const ExcludeSemantics(
              child: Opacity(
                opacity: 0,
                child: Icon(Icons.chevron_left, size: 32),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/app/pivot_money.svg'),
                      // const Spacer(),
                      // SvgPicture.asset(
                      //   'assets/svgs/connections/connection.svg',
                      //   height: 36,
                      // ),
                      // const Spacer(),
                      // const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                MergeSemantics(
                  child: Column(
                    children: [
                      const ExcludeSemantics(
                        child: AppText(
                          'Redirecting to Finarkein\nAccount Aggregator',
                          variant: AppTextVariant.headline4,
                          weight: AppTextWeight.bold,
                          textAlign: TextAlign.center,
                          colorType: AppTextColorType.primary,
                          lineHeight: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label:
                            'Redirecting to Finarkein Account Aggregator. RBI authorized institution that securely finds and shares your financial data with us.',
                        child: ExcludeSemantics(
                          child: AppText(
                            'RBI authorized institution that securely finds and shares your financial data with us',
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label:
                      'Please note: Account Aggregators do not support Joint Accounts, Current Accounts. Indian phone number is required. Insurance is partly supported.',
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkButtonBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ExcludeSemantics(
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
                          // _buildBulletPoint(
                          //   Icons.close_rounded,
                          //   Colors.redAccent,
                          //   'JOINT ACCOUNTS',
                          // ),
                          const SizedBox(height: 8),
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
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  enabled: !_isProcessing,
                  label: 'I Acknowledge',
                  hint:
                      _isProcessing
                          ? 'Linking in progress, please wait'
                          : 'Double tap to proceed to Finarkein Account Aggregator',
                  child: SizedBox(
                    width: double.infinity,
                    child: ExcludeSemantics(
                      child: AppButton(
                        text: "I ACKNOWLEDGE",
                        isDisabled: _isProcessing,
                        onPressed: _handleAcknowledge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Semantics(
                    label: 'Cancel, go back',
                    button: true,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: const ExcludeSemantics(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MergeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ExcludeSemantics(
                        child: Icon(Icons.lock_outline, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const AppText(
                        'Your data is encrypted and 100% secure',
                        variant: AppTextVariant.bodyMedium,
                        colorType: AppTextColorType.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
