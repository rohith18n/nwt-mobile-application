import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/services/mf_onboarding/skip_mfc.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class ImportMf extends StatefulWidget {
  const ImportMf({super.key});

  @override
  State<ImportMf> createState() => _ImportMfState();
}

class _ImportMfState extends State<ImportMf> {
  final SkipMfcService _skipMfcService = SkipMfcService();
  bool _isLoading = false;

  void _importMutualFunds() {
    Get.to(
      () => const MutualFundHoldingsJourneyScreen(isInitialJourney: true),
      transition: Transition.rightToLeft,
    );
  }

  void _skipToInvesting() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Reset retry state to default when skipping
      final currentErrorFlowKey =
          'mf_error_current_flow_${DateTime.now().millisecondsSinceEpoch ~/ 60000}'; // Per minute
      StorageService.remove(currentErrorFlowKey);
      AppLogger.info(
        'Retry state reset to default after skip action',
        tag: 'ImportMf',
      );

      // Update user's skipmfc field to true using SkipMfcService
      final response = await _skipMfcService.skipMfc(
        onLoading: (isLoading) {
          // Loading is already handled by _isLoading state
        },
      );

      if (response != null && response.statusCode == 200) {
        // Navigate to dashboard
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
        tag: 'ImportMf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Top spacing
                    const SizedBox(height: 80),
                    
                    // SVG Illustration
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: SvgPicture.asset(
                        'assets/svgs/onboarding/import_mf.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Title
                    AppText(
                      "Import your existing\nmutual funds",
                      variant: AppTextVariant.headline4,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      textAlign: TextAlign.center,
                      lineHeight: 1.2,
                    ),
                    const SizedBox(height: 24),
                    
                    // Description with checkmark
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText(
                              "We'll fetch your mutual fund portfolio from MF Central to help you manage and redeem your holdings directly from Pivot Money.",
                              variant: AppTextVariant.bodyLarge,
                              colorType: AppTextColorType.secondary,
                              lineHeight: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacer to push buttons to bottom
                    const Spacer(),
                  ],
                ),
              ),
              
              // Bottom buttons
              Column(
                children: [
                  // Import button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: "IMPORT MY MUTUAL FUNDS",
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed: _importMutualFunds,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Skip button
                  GestureDetector(
                    onTap: _isLoading ? null : _skipToInvesting,
                    child: AppText(
                      _isLoading ? "SKIPPING..." : "SKIP TO DASHBOARD",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      colorType: _isLoading ? AppTextColorType.tertiary : AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}