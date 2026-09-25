import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/screens/dashboard/widgets/mf_top_performers_widget.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds_collections.dart';
import 'package:nwt_app/screens/search/global_search/global_search.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/mf_action_card.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/screens/bse_star_v2/start_journey.dart';
import 'package:nwt_app/utils/back_navigation.dart';

class FundCategory {
  final String title;
  final String type;
  final IconData icon;

  FundCategory({required this.title, required this.type, required this.icon});
}

class MutualFunds extends StatefulWidget {
  final bool showBackButton;
  const MutualFunds({super.key, this.showBackButton = true});

  @override
  State<MutualFunds> createState() => _MutualFundsState();
}

class _MutualFundsState extends State<MutualFunds> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isUserHolding = false;

  final MFTopPerformersController mfTopPerformersController = Get.put(
    MFTopPerformersController(),
  );

  final OrderV1Controller _orderV1Controller = Get.put(OrderV1Controller());

  final _accountAggregatorRouter = AccountAggregatorRouter();

  final List<FundCategory> fundCategories = [
    FundCategory(
      title: 'EQUITY FUNDS',
      type: 'Equity',
      icon: Icons.trending_up,
    ),
    FundCategory(
      title: 'DEBT FUNDS',
      type: 'Debt',
      icon: Icons.monetization_on,
    ),
    FundCategory(title: 'HYBRID FUNDS', type: 'Hybrid', icon: Icons.pie_chart),
    FundCategory(
      title: 'INTERNATIONAL EQUITY',
      type: 'International Equity',
      icon: Icons.language,
    ),
    FundCategory(
      title: 'PRECIOUS METALS',
      type: 'Precious Metals',
      icon: Icons.diamond,
    ),
    FundCategory(title: 'OTHER FUNDS', type: 'Others', icon: Icons.category),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _orderV1Controller.fetchAccounts();
    mfTopPerformersController.fetchTopPerformers(
      dashboard: true,
      limit: 10,
      type: "",
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients && !_isUserHolding) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.offset;
        final double itemWidth = 240.w + 12.w; // Card width + separator spacing

        double nextScroll = currentScroll + itemWidth;
        if (nextScroll >= maxScroll + 10) {
          nextScroll = 0;
        }

        _scrollController.animateTo(
          nextScroll,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFundCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                width: 36.w,
                height: 36.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.darkButtonBorder,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.darkInputText, size: 20.sp),
              ),
              SizedBox(width: 12.w),

              // Fund type text
              Expanded(
                child: AppText(
                  title,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              floating: true,
              pinned: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: () {
                        BackNavigation.backOrHome(
                          homeTransition: Transition.rightToLeft,
                        );
                      },
                      child: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                  if (!widget.showBackButton) SizedBox(width: 24.w),
                  AppText(
                    "Mutual Funds",
                    variant: AppTextVariant.headline6,
                    weight: AppTextWeight.semiBold,
                  ),
                  const WhatsAppSupportButton(
                    size: 20,
                    color: AppColors.darkPrimary,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
              // Search Bar
              InkWell(
                onTap:
                    () => Get.to(
                      () => GlobalSearchScreen(),
                      transition: Transition.rightToLeft,
                    ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search for mutual funds...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Cards
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Column(
              //     children: [
              //       MFActionCard(
              //         title: "Link Mutual Funds",
              //         subtitle:
              //             "Fetch holdings automatically in under a minute",
              //         icon: Icons.link,
              //         isHighlighted: true,
              //         onTap:
              //             () =>
              //                 _accountAggregatorRouter.openConnection(context),
              //       ),
              //       const SizedBox(height: 12),
              //       MFActionCard(
              //         title: "Buy Mutual Funds",
              //         subtitle: "Start investing in Direct MFs",
              //         icon: Icons.shopping_bag_outlined,
              //         variant: MFActionCardVariant.dark,
              //         onTap: () {
              //           Get.to(
              //             () => BSEStartjourney(onBack: () => Get.back()),
              //             transition: Transition.rightToLeft,
              //           );
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText(
                      'Mutual Fund Collections',
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                      decoration: TextDecoration.none,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              // Fund Collections Carousel
              SizedBox(
                height: 72.h,
                child: Listener(
                  onPointerDown: (_) => setState(() => _isUserHolding = true),
                  onPointerUp: (_) => setState(() => _isUserHolding = false),
                  onPointerCancel:
                      (_) => setState(() => _isUserHolding = false),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding,
                    ),
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: fundCategories.length,
                    separatorBuilder: (context, index) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final category = fundCategories[index];
                      return SizedBox(
                        width: 240.w,
                        child: _buildFundCard(
                          category.title,
                          category.icon,
                          () => Get.to(
                            () => MutualFundsCollectionsScreen(
                              title: category.title,
                              type: category.type,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Static "Explore All Mutual Funds" Button
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 0),
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => const MutualFundsCollectionsScreen(
                        title: "All Mutual Fund",
                        type: "",
                      ),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Container(
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: AppColors.darkButtonBorder,
                      // gradient: const LinearGradient(
                      //   colors: [
                      //     Color(0xFF2E9DD8), // Blue link color
                      //     Color(0xFF1E6F9F), // Darker shade
                      //   ],
                      //   begin: Alignment.topLeft,
                      //   end: Alignment.bottomRight,
                      // ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        AppText(
                          "Explore All Mutual Funds",
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                          colorType: AppTextColorType.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                  // Top Performers Section
                  MFTopPerformersWidget(
                    controller: mfTopPerformersController,
                    dashboard: true,
                    assetclass: "",
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
