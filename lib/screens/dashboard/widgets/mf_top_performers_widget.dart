import 'package:flutter/material.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/services/orders/investment_flow.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/screens/orders/payment_processing_v1_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
import 'package:nwt_app/screens/dashboard/types/mf_top_performers.dart';
import 'package:nwt_app/screens/insights/insights.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/screens/buy_holdings/buy_holdings.dart';
import 'package:nwt_app/screens/bse_v2_final/bse_v2_final_journey.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';

class MFTopPerformersWidget extends StatefulWidget {
  final MFTopPerformersController controller;
  final bool dashboard;
  final String assetclass;
  final List<MFPerformers>? data;
  final bool shrinkWrap;
  final ScrollPhysics physics;
  final ScrollController? scrollController;

  const MFTopPerformersWidget({
    super.key,
    required this.controller,
    required this.dashboard,
    required this.assetclass,
    this.data,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.scrollController,
  });

  @override
  _MFTopPerformersWidgetState createState() => _MFTopPerformersWidgetState();
}

class _MFTopPerformersWidgetState extends State<MFTopPerformersWidget> {
  MFTopPerformersController get controller => widget.controller;
  bool _showAll = false; // Track if we're showing all items

  // Helper method to get the appropriate data list based on dashboard flag
  List<MFPerformers> get currentDataList {
    if (widget.data != null) {
      return widget.data ?? [];
    }
    if (widget.dashboard) {
      return widget.controller.topPerformers.value ?? [];
    } else {
      return widget.controller.collections.value ?? [];
    }
  }

  void _showSimpleBottomSheet(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder:
          (context) => SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'MF Top Performers',
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    'Our scoring system evaluates mutual funds across 12 key parameters in four areas:',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildScoringSection(
                    'Performance & Returns',
                    '3-year returns (14%), alpha (8%), information ratio (7%)',
                  ),
                  _buildScoringSection(
                    'Risk Management',
                    'Sharpe ratio (12%), Sortino ratio (11%), standard deviation (9%), beta (7%)',
                  ),
                  _buildScoringSection(
                    'Portfolio Quality',
                    'Asset concentration (7%), R-squared (6%), sector diversification (6%)',
                  ),
                  _buildScoringSection(
                    'Costs',
                    'Expense ratio (7%), exit load (6%)',
                  ),
                  const SizedBox(height: 16),
                  _buildScoringSection(
                    'Each parameter scores funds by quartile',
                    'Top quartile (excellent), median quartile (average), bottom quartile (poor).',
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Funds are ranked by their total score, with larger funds (higher AUM) prioritized when scores are identical.',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildScoringSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 4),
          AppText(
            description,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AppText(
                    widget.dashboard
                        ? 'MF Top ${currentDataList.length} Performers'
                        : widget.assetclass,
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                    decoration: TextDecoration.none,
                  ),
                  if (widget.dashboard) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        AnalyticsService.to.logEvent(
                          name: AnalyticsEvents.mfTopPerformersInfoIconClicked,
                        );
                        _showSimpleBottomSheet(
                          context,
                          'MF Top Performers',
                          'Information about mutual fund scoring system',
                        );
                      },
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              // GestureDetector(
              //   onTap: () {
              //     // Use the controller's method to cycle through return periods
              //     controller.cycleReturnPeriod();
              //   },
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       const Icon(
              //         Icons.unfold_more,
              //         color: Colors.white,
              //         size: 14,
              //       ),
              //       // const SizedBox(width: 2),
              //       // Use a fixed width container to prevent text movement
              //       SizedBox(
              //         width: 70, // Set a fixed width that fits all options
              //         child: Obx(
              //           () => AppText(
              //             controller.returnPeriods[controller
              //                 .currentReturnPeriodIndex
              //                 .value],
              //             variant: AppTextVariant.bodySmall,
              //             weight: AppTextWeight.medium,
              //             colorType: AppTextColorType.primary,
              //             decoration: TextDecoration.underline,
              //             decorationStyle: TextDecorationStyle.dotted,
              //             decorationThickness: 1.5,
              //             textAlign: TextAlign.end,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            Widget content;
            if (controller.isLoading.value) {
              content = _buildLoadingState();
            } else if (currentDataList.isEmpty) {
              content = _buildEmptyState();
            } else {
              content = Column(
                children: [
                  if (widget.shrinkWrap)
                    _buildTopPerformersList()
                  else
                    Expanded(child: _buildTopPerformersList()),

                  // Only show pagination loader (shimmer) here if shrinkWrapped
                  if (widget.shrinkWrap && controller.isPaginating.value)
                    _buildShimmerItem(),

                  // Only show See All/Less button when in dashboard mode
                  if (currentDataList.length > 5 && widget.dashboard)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAll = !_showAll;
                        });
                      },
                      child: Text(
                        _showAll ? 'See Less' : 'See All',
                        style: TextStyle(
                          color: AppColors.linkColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            }

            return widget.shrinkWrap ? content : Expanded(child: content);
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(children: List.generate(5, (index) => _buildShimmerItem()));
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: AppText(
          'No top performers data available',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.secondary,
        ),
      ),
    );
  }

  // Helper method to format return value as string with plus sign for positive values
  String _getReturnValueForPeriod(dynamic performer) {
    double returnValue = _getReturnValueForPeriodAsDouble(performer);
    String sign = returnValue >= 0 ? '+' : '';
    return '$sign${returnValue.toStringAsFixed(2)}%';
  }

  // Updated helper method to get return value as a double based on selected period
  double _getReturnValueForPeriodAsDouble(dynamic performer) {
    // Use the controller's method to get the current return value
    double? returnValue = controller.getCurrentReturnValue(performer);
    return returnValue ?? 0.0;
  }

  Future<void> _handleInvestTap(MFPerformers performer) async {
    // Start centralized investment journey
    await InvestmentFlow.startInvestmentJourney(
      name: performer.name ?? "",
      isin: performer.isincode ?? "",
      schemeCode: performer.schemeCode ?? "",
      nav: performer.nav,
      fundLogo: performer.icon,
      minAmount: performer.minAmount,
    );
  }

  Widget _buildTopPerformersList() {
    // In dashboard mode, limit to 5 items unless _showAll is true
    // In non-dashboard mode, always show all items
    final itemCount =
        widget.dashboard
            ? (_showAll
                ? currentDataList.length
                : currentDataList.length > 5
                ? 5
                : currentDataList.length)
            : currentDataList.length;

    // Add extra item for pagination loader if we are not shrinkwrapping
    final totalItemCount =
        !widget.shrinkWrap && controller.isPaginating.value
            ? itemCount + 1
            : itemCount;

    return ListView.builder(
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: totalItemCount,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (index < itemCount) {
          final performer = currentDataList[index];
          return buildFundCard(performer);
        } else {
          // Pagination loader (shimmer) as the last item
          return _buildShimmerItem();
        }
      },
    );
  }

  Widget buildFundCard(MFPerformers performer) {
    return InkWell(
      onTap: () => _handleInvestTap(performer),
      // onTap:
      //     () => Get.to(
      //       () => InsightsScreen(isincode: performer.isincode ?? ""),
      //       transition: Transition.rightToLeft,
      //     ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        child: Column(
          children: [
            // Header row with icon and fund name
            Row(
              children: [
                // performer.icon != null
                //     ? Avatar(
                //       path: performer.icon ?? "",
                //       width: 40,
                //       height: 40,
                //       fit: BoxFit.cover,
                //       isNetworkImage: true,
                //     )
                //     : Container(
                //       width: 40,
                //       height: 40,
                //       decoration: BoxDecoration(
                //         color: AppColors.darkBackground,
                //         borderRadius: BorderRadius.circular(20),
                //       ),
                //       child: const Icon(
                //         Icons.corporate_fare,
                //         color: Colors.white,
                //         size: 20,
                //       ),
                //     ),
                // const SizedBox(width: 12),
                Expanded(
                  child: AppText(
                    performer.name ?? 'N/A',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.primary,
                    decoration: TextDecoration.none,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                //  const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            // Metrics row
            Row(
              children: [
                // Min. Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'Min. Amount',
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.medium,
                        colorType: AppTextColorType.secondary,
                        decoration: TextDecoration.none,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        performer.minAmount != null
                            ? "₹${performer.minAmount}"
                            : "N/A",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.primary,
                        decoration: TextDecoration.none,
                      ),
                    ],
                  ),
                ),
                // Current NAV
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'Current NAV',
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.medium,
                        colorType: AppTextColorType.secondary,
                        decoration: TextDecoration.none,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        performer.nav != null
                            ? "₹${performer.nav?.toStringAsFixed(2)}"
                            : "N/A",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.primary,
                        decoration: TextDecoration.none,
                      ),
                    ],
                  ),
                ),
                // Returns
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => AppText(
                          controller.returnPeriods[controller.currentReturnPeriodIndex.value],
                          variant: AppTextVariant.bodySmall,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        _getReturnValueForPeriod(performer),
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType:
                            _getReturnValueForPeriodAsDouble(performer) >= 0
                                ? AppTextColorType.success
                                : AppTextColorType.error,
                        decoration: TextDecoration.none,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Invest Button - Full width like web
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleInvestTap(performer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkButtonPrimaryBackground,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const AppText(
                  'Invest Now',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.bold,
                  customColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
