import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/screens/advisory/advisory_intelligence.dart';
import 'package:nwt_app/screens/dashboard/widgets/unlinked_state_widgets.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/controllers/dashboard/total_networth_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';

class AdvisoryStrategicReviewScreen extends StatefulWidget {
  const AdvisoryStrategicReviewScreen({super.key});

  @override
  State<AdvisoryStrategicReviewScreen> createState() =>
      _AdvisoryStrategicReviewScreenState();
}

class _AdvisoryStrategicReviewScreenState
    extends State<AdvisoryStrategicReviewScreen> {
  final AccountAggregatorRouter _accountAggregatorRouter =
      AccountAggregatorRouter();

  @override
  void initState() {
    super.initState();
    // Ensure controller is registered
    if (!Get.isRegistered<FinarkeinDataController>()) {
      Get.put(FinarkeinDataController());
    }
    if (!Get.isRegistered<TotalNetworthController>()) {
      Get.put(TotalNetworthController());
    }
    if (!Get.isRegistered<DashboardAssetController>()) {
      Get.put(DashboardAssetController());
    }
    if (!Get.isRegistered<InvestmentController>()) {
      Get.put(InvestmentController());
    }
  }

  bool _hasAnyFinarkeinDataNow() {
    // Check 1: TotalNetworthController (New standard API)
    if (Get.isRegistered<TotalNetworthController>()) {
      final data = Get.find<TotalNetworthController>().networthData.value?.data;
      if (data != null && data.totalNetWorth > 0) {
        return true;
      }
    }

    // Check 2: DashboardAssetController (New standard API)
    if (Get.isRegistered<DashboardAssetController>()) {
      final assets =
          Get.find<DashboardAssetController>().dashboardAssets.value?.data;
      if (assets != null && assets.any((a) => a.value > 0)) {
        return true;
      }
    }

    // Legacy checks
    if (Get.isRegistered<FinarkeinDataController>()) {
      final finarkeinCtrl = Get.find<FinarkeinDataController>();
      final data = finarkeinCtrl.dataResponse.value?.data;
      if (data != null) {
        final networth = data.summary['networth'];
        if (networth != null && networth > 0) return true;
      }
    }
    if (Get.isRegistered<RawAssetController>()) {
      final ctrl = Get.find<RawAssetController>();
      return ctrl.equities.isNotEmpty ||
          ctrl.mutualFunds.isNotEmpty ||
          ctrl.etfs.isNotEmpty ||
          ctrl.banks.isNotEmpty;
    }
    return false;
  }

  bool _shouldShowUnlockCard() {
    final isFamilyMode =
        GetStorage().read(StorageKeys.FAMILY_MODE_KEY) ?? false;
    if (isFamilyMode) return false;

    final userController = Get.find<UserController>();
    final isFinarkeinUser = userController.userData?.isFinarkeinAa == true;

    return !isFinarkeinUser || !_hasAnyFinarkeinDataNow();
  }

  Future<void> _onTapLinkAllAssets(BuildContext context) async {
    await AuthFlow().ensurePanAndPhoneThen(
      context: context,
      onReady: (capturedPhone) async {
        await _accountAggregatorRouter.openConnection(
          context,
          phoneNumber: capturedPhone,
          showConnectionScreen: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: AppText(
                          "Advisory Intelligence",
                          variant: AppTextVariant.headline2,
                          weight: AppTextWeight.bold,
                          customColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppText(
                        "Cross-Border Wealth & Tax Strategy",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.medium,
                        customColor: Colors.white60,
                      ),
                    ],
                  ),
                  WhatsAppSupportButton(size: 20, color: Colors.white),
                ],
              ),
              const SizedBox(height: 32),

              // Hero Card (Reactive)
              Obx(() {
                // Ensure controllers are registered before accessing
                if (!Get.isRegistered<TotalNetworthController>()) {
                  Get.put(TotalNetworthController());
                }
                if (!Get.isRegistered<DashboardAssetController>()) {
                  Get.put(DashboardAssetController());
                }

                // Accessing observables early to ensure Obx always has a dependency,
                // preventing "improper use of GetX" errors in conditional paths (like Family Mode).
                final networthObs =
                    Get.find<TotalNetworthController>().networthData.value;
                final assetObs =
                    Get.find<DashboardAssetController>().dashboardAssets.value;

                final showUnlock = _shouldShowUnlockCard();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showUnlock)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: UnlockDashboardCard(
                          onTap: () => _onTapLinkAllAssets(context),
                        ),
                      )
                    else
                      _buildNetWorthHero(),
                    SizedBox(height: showUnlock ? 20 : 48),
                  ],
                );
              }),

              // Advisory Modules Section
              AppText(
                "Advisory Modules",
                variant: AppTextVariant.headline4,
                weight: AppTextWeight.bold,
                customColor: Colors.white,
              ),
              const SizedBox(height: 24),

              // Modules Grid
              _buildModulesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthHero() {
    // Ensure controller is registered
    if (!Get.isRegistered<TotalNetworthController>()) {
      Get.put(TotalNetworthController());
    }

    final totalNetworthController = Get.find<TotalNetworthController>();
    final networthDataValue = totalNetworthController.networthData.value?.data;

    // Use centralized calculation synced with Dashboard.dart
    final networthValue = totalNetworthController.calculatedNetworth;

    final dayGain = networthDataValue?.deltaamount ?? 0.0;
    final dayGainPercent = networthDataValue?.deltapercentage ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkButtonBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                "Net Worth Tracked",
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.secondary,
              ),
              if (dayGain != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (dayGain >= 0 ? AppColors.success : AppColors.error)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (dayGain >= 0
                              ? AppColors.success
                              : AppColors.error)
                          .withOpacity(0.5),
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dayGain >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color:
                              dayGain >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          "${dayGainPercent.toStringAsFixed(2)}%",
                          variant: AppTextVariant.tiny,
                          weight: AppTextWeight.bold,
                          customColor:
                              dayGain >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedAmount(
            isAmountVisible: true,
            isLoading: false,
            amount: CurrencyFormatter.formatRupeeWithCommas(networthValue),
            alignment: Alignment.centerLeft,
            style: TextStyle(
              color: Colors.white,
              fontSize: 42.sp,
              fontWeight: FontWeight.bold,
              fontFamily: "Montserrat",
            ),
          ),
          if (dayGain != 0) ...[
            const SizedBox(height: 12),
            AppText(
              "${dayGain >= 0 ? '+' : ''}${CurrencyFormatter.formatRupee(dayGain.abs())} today",
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.secondary,
            ),
          ],
          const SizedBox(height: 32),
          Semantics(
            label: 'Start Strategic Review',
            button: true,
            hint: 'Opens advisor contact to begin your review',
            child: ElevatedButton(
              onPressed: () {
                SpeakToAdvisor.speakToAdvisor();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkButtonPrimaryBackground,
                foregroundColor: AppColors.darkButtonPrimaryText,
                minimumSize: const Size(double.infinity, 48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AppText(
                "Start Strategic Review",
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.72,
      children: [
        _buildModuleCard(
          title: "Tax Advisory",
          subtitle: "DTAA & treaty\nbenefits",
          //potential: "₹4.6L potential",
          bgAsset: 'assets/imgs/advisory/Group 6.png',
          onTap: () => Get.to(() => const AdvisoryIntelligenceScreen()),
        ),
        //  _buildModuleCard(
        //   title: "Curated Stock -\nEquity Baskets",
        //   subtitle: "Thematic investing\nstrategies",
        //   bgAsset: 'assets/imgs/advisory/Group  2.png',
        //   onTap: () {},
        // ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    String? potential,
    required String bgAsset,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      hint: 'Opens advisory module',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(28),
          ),
          child: CustomPaint(
            painter: _GradientBorderPainter(
              radius: 28,
              strokeWidth: 1.5,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkPrimary.withValues(alpha: 0.3),
                  AppColors.darkPrimary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  // Decorative Background Image (low opacity)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(bgAsset, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Globe Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        AppText(
                          title,
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                          customColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          subtitle,
                          variant: AppTextVariant.tiny,
                          weight: AppTextWeight.medium,
                          customColor: Colors.white60,
                        ),
                        const SizedBox(height: 12),
                        if (potential != null)
                          AppText(
                            potential,
                            variant: AppTextVariant.tiny,
                            weight: AppTextWeight.bold,
                            customColor: Colors.white,
                          )
                        else
                          SizedBox(height: 18.sp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint =
        Paint()
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..shader = gradient.createShader(rect);

    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient;
  }
}
