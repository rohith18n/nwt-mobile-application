import 'package:get/get.dart';
import 'package:nwt_app/screens/bse_v2_final/bse_v2_final_journey.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/services/profile/investment_readiness_service.dart';
import 'package:nwt_app/utils/app_logger.dart';

class InvestmentFlow {
  static final InvestmentReadinessService _readinessService =
      InvestmentReadinessService();

  /// Starts the investment journey for a mutual fund.
  /// Checks user verification status and investment readiness to decide
  /// whether to show onboarding or the order screen.
  static Future<void> startInvestmentJourney({
    required String name,
    required String isin,
    required String schemeCode,
    double? nav,
    double? minAmount,
    String? fundLogo,
  }) async {
    try {
      AppLogger.info(
        'Starting investment journey for: $name ($isin)',
        tag: 'InvestmentFlow',
      );

      // 1. Check PAN and phone verification via validation API
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];
        final panStatus = data['pan']?['status'];
        final phoneStatus = data['phone']?['status'];

        AppLogger.info(
          'Validation status - PAN: $panStatus, Phone: $phoneStatus',
          tag: 'InvestmentFlow',
        );

        // If PAN or phone not verified, go to BSE journey for onboarding
        if (panStatus != 'verified' || phoneStatus != 'verified') {
          AppLogger.info(
            'PAN or phone not verified - redirecting to BSE journey',
            tag: 'InvestmentFlow',
          );

          Get.to(
            () => BseV2FinalJourney(
              fundName: name,
              isin: isin,
              schemeCode: schemeCode,
              nav: nav,
              minAmount: minAmount,
              fundLogo: fundLogo,
            ),
            transition: Transition.rightToLeft,
          );
          return;
        }
      }

      // 2. Check if user can invest directly (UCC readiness)
      final readiness = await _readinessService.canInvestDirectly();

      if (readiness['canInvest'] == true) {
        // ✅ User is ready - skip all onboarding steps!
        AppLogger.info(
          'User ready to invest - going to order screen',
          tag: 'InvestmentFlow',
        );

        Get.to(
          () => CreateOrderV1Screen(
            fundName: name,
            isin: isin,
            schemeCode: schemeCode,
            nav: nav,
            minAmount: minAmount,
            fundLogo: fundLogo,
          ),
          transition: Transition.rightToLeft,
        );
      } else {
        final nextStep = readiness['nextStep'] as String?;

        // If only UCC creation/setup is pending (profile steps are done),
        // go to CreateOrderV1Screen — it handles UCC creation internally.
        // Do NOT send back to BseV2FinalJourney or it will loop occupation→signature.
        const uccOnlySteps = ['create_ucc', 'ucc_setup', 'ucc_syncing', 'ucc_check_failed'];

        if (uccOnlySteps.contains(nextStep)) {
          AppLogger.info(
            'Profile complete, UCC pending ($nextStep) - going to order screen',
            tag: 'InvestmentFlow',
          );
          Get.to(
            () => CreateOrderV1Screen(
              fundName: name,
              isin: isin,
              schemeCode: schemeCode,
              nav: nav,
              minAmount: minAmount,
              fundLogo: fundLogo,
            ),
            transition: Transition.rightToLeft,
          );
        } else {
          // Profile steps still incomplete — go to BSE journey
          AppLogger.info(
            'Profile incomplete ($nextStep) - redirecting to BSE journey',
            tag: 'InvestmentFlow',
          );
          Get.to(
            () => BseV2FinalJourney(
              fundName: name,
              isin: isin,
              schemeCode: schemeCode,
              nav: nav,
              minAmount: minAmount,
              fundLogo: fundLogo,
              skipPanVerification: true,
            ),
            transition: Transition.rightToLeft,
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error in investment flow handler',
        error: e,
        tag: 'InvestmentFlow',
      );
      // On error, default to BSE journey as a safe fallback
      Get.to(
        () => BseV2FinalJourney(
          fundName: name,
          isin: isin,
          schemeCode: schemeCode,
          nav: nav,
          minAmount: minAmount,
          fundLogo: fundLogo,
        ),
        transition: Transition.rightToLeft,
      );
    }
  }
}
