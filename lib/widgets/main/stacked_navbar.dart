import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_controller_v1.dart';
import 'package:nwt_app/screens/advisory/advisory_strategic_review.dart';
import 'package:nwt_app/screens/assets/investments/investments.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/invest_and_services/invest_and_services_screen.dart';
import 'package:nwt_app/screens/orders/orders_screen.dart';
import 'package:nwt_app/screens/portfolio/order_history_v1_screen.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/controllers/orders/orders_controller.dart';

class StackedNavbar extends StatefulWidget {
  const StackedNavbar({super.key, required this.selectedIdx});
  final int selectedIdx;

  @override
  State<StackedNavbar> createState() => _StackedNavbarState();
}

class _StackedNavbarState extends State<StackedNavbar> {
  final navbarController = Get.put(NavbarController());
  int _selectedIdx = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIdx = widget.selectedIdx;
    // Initialize OrdersController early to ensure it's ready for the first tab click
    Get.put(MutualFundPortfolioControllerV1());
    _screens = [
      Dashboard(),
      OrderHistoryV1Screen(),
      AssetInvestmentScreen(isstacknavbar: true),
      InvestAndServicesScreen(),
      AdvisoryStrategicReviewScreen(),
    ];
  }

  void _handleNavigation(int index) {
    final previousIndex = _selectedIdx;
    setState(() {
      _selectedIdx = index;
    });

    // Refresh Orders data whenever the tab is selected
    if (index == 1) {
      // New index for Orders
      Get.find<MutualFundPortfolioControllerV1>().fetchMfOrders(refresh: false);
    }

    // Trigger investments data refresh whenever the My Investments tab is selected
    if (index == 2 && Get.isRegistered<InvestmentController>()) {
      Get.find<InvestmentController>().triggerRefresh();
    }

    // Track tab navigation
    if (index == 0) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dashboardBottomTabHomeClicked,
        parameters: {
          AnalyticsParams.tabIndex: index,
          AnalyticsParams.tabName: 'home',
          AnalyticsParams.previousTabIndex: previousIndex,
        },
      );
    } else if (index == 1) {
      // Orders
      AnalyticsService.to.logEvent(
        name: 'dashboard_bottom_tab_orders_clicked',
        parameters: {
          AnalyticsParams.tabIndex: index,
          AnalyticsParams.tabName: 'orders',
          AnalyticsParams.previousTabIndex: previousIndex,
        },
      );
    } else if (index == 2) {
      // My Investments
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dashboardBottomTabInvestmentsClicked,
        parameters: {
          AnalyticsParams.tabIndex: index,
          AnalyticsParams.tabName: 'investments',
          AnalyticsParams.previousTabIndex: previousIndex,
        },
      );
    } else if (index == 3) {
      // Invest & Services
      AnalyticsService.to.logEvent(
        name: 'dashboard_bottom_tab_services_clicked',
        parameters: {
          AnalyticsParams.tabIndex: index,
          AnalyticsParams.tabName: 'invest_and_services',
          AnalyticsParams.previousTabIndex: previousIndex,
        },
      );
    } else if (index == 4) {
      // Advisory
      AnalyticsService.to.logEvent(
        name: 'dashboard_bottom_tab_advisory_clicked',
        parameters: {
          AnalyticsParams.tabIndex: index,
          AnalyticsParams.tabName: 'advisory',
          AnalyticsParams.previousTabIndex: previousIndex,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIdx == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_selectedIdx != 0) {
          _handleNavigation(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIdx.clamp(0, _screens.length - 1),
          children: _screens,
        ),
        bottomNavigationBar: Obx(
          () =>
              (navbarController.isSwitchingMode.value)
                  ? const SizedBox()
                  : SafeArea(child: _buildCustomNavBar()),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom nav bar — built as a plain Row so TalkBack traverses in widget-tree
  // order: Home → Orders → My Investments → Wealth → Advisory.
  // The BottomNavigationBar + Positioned overlay approach placed the floating
  // button last in the Stack, causing an incorrect focus order.
  // ---------------------------------------------------------------------------

  Widget _buildCustomNavBar() {
    return Container(
      decoration: BoxDecoration(
        //    color: AppColors.darkCardBG,
        border: Border(
          top: BorderSide(color: AppColors.darkButtonBorder, width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Row of 5 items in the correct semantic order.
          // The centre slot holds an invisible tap-target for "My Investments";
          // the visible floating circle is rendered by the Positioned child below.
          Row(
            children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                iconAsset: 'assets/app/Icon.png',
              ),
              _buildNavItem(
                index: 1,
                label: 'Orders',
                iconAsset: 'assets/app/Icon-2.png',
              ),
              // ── Centre slot ─────────────────────────────────────────────────
              // Semantics live here (correct widget-tree position = 3rd child).
              // Visual rendering happens via the Positioned overlay below.
              Expanded(
                child: Semantics(
                  label: 'My Investments',
                  button: true,
                  selected: _selectedIdx == 2,
                  hint: 'Double tap to switch to My Investments tab',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleNavigation(2),
                    // The visible content is rendered by the Positioned overlay;
                    // this slot is intentionally transparent.
                    child: ExcludeSemantics(
                      child: SizedBox(height: 64.h, width: double.infinity),
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                index: 3,
                label: 'Wealth',
                iconAsset: 'assets/app/Icon-4.png',
              ),
              _buildNavItem(
                index: 4,
                label: 'Advisory',
                iconAsset: 'assets/app/Icon-5.png',
              ),
            ],
          ),
          // ── Floating visual for "My Investments" ──────────────────────────
          // Semantics are excluded here — they live in the Row slot above.
          // IgnorePointer lets taps fall through to the Row's GestureDetector.
          Positioned(
            top: -13.h,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58.w,
                      height: 58.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2D),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.darkButtonBorder,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/app/Icon-3.png',
                          width: 28.w,
                          height: 28.w,
                          color:
                              _selectedIdx == 2
                                  ? AppColors.darkPrimary
                                  : AppColors.darkTextGray,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'My Investments',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color:
                            _selectedIdx == 2
                                ? AppColors.darkPrimary
                                : AppColors.darkTextGray,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconAsset,
  }) {
    final bool isSelected = _selectedIdx == index;
    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        hint: 'Double tap to switch to $label tab',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleNavigation(index),
          child: ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.only(bottom: 4.h, top: 10.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    iconAsset,
                    width: 24.w,
                    height: 24.w,
                    color:
                        isSelected
                            ? AppColors.darkPrimary
                            : AppColors.darkTextGray,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppColors.darkPrimary
                              : AppColors.darkTextGray,
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
