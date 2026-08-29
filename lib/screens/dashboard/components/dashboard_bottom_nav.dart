import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/assets/investments/investments.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds.dart';
import 'package:nwt_app/screens/advisory/advisory.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

class DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const DashboardBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedLabelStyle: TextStyle(
        color: AppColors.darkPrimary,
        fontSize: 12.sp,
      ),
      unselectedLabelStyle: TextStyle(
        color: AppColors.darkTextGray,
        fontSize: 12.sp,
      ),
      selectedIconTheme: const IconThemeData(color: AppColors.darkPrimary),
      unselectedIconTheme: const IconThemeData(color: AppColors.darkTextGray),
      currentIndex: selectedIndex,
      onTap: (index) {
        onTap(index);

        // Track tab navigation
        if (index == 0) {
          AnalyticsService.to.logEvent(
            name: AnalyticsEvents.dashboardBottomNavHomeClicked,
            parameters: {
              AnalyticsParams.tabIndex: index,
              AnalyticsParams.tabName: 'home',
              AnalyticsParams.previousTabIndex: selectedIndex,
            },
          );
        } else if (index == 1) {
          // Investments
          AnalyticsService.to.logEvent(
            name: AnalyticsEvents.dashboardBottomNavInvestmentsClicked,
            parameters: {
              AnalyticsParams.tabIndex: index,
              AnalyticsParams.tabName: 'investments',
              AnalyticsParams.previousTabIndex: selectedIndex,
              AnalyticsParams.destinationScreen: 'asset_investments',
              AnalyticsParams.navigationMethod: 'bottom_tab',
            },
          );
          Get.to(
            () => const AssetInvestmentScreen(isstacknavbar: false),
            transition: Transition.rightToLeft,
          );
        } else if (index == 2) {
          // Mutual Funds
          AnalyticsService.to.logEvent(
            name: AnalyticsEvents.dashboardBottomNavMutualFundsClicked,
            parameters: {
              AnalyticsParams.tabIndex: index,
              AnalyticsParams.tabName: 'mutual_funds',
              AnalyticsParams.previousTabIndex: selectedIndex,
              AnalyticsParams.destinationScreen: 'mutual_funds',
              AnalyticsParams.navigationMethod: 'bottom_tab',
            },
          );
          Get.to(() => const MutualFunds(), transition: Transition.rightToLeft);
        } else if (index == 3) {
          // Advisory
          AnalyticsService.to.logEvent(
            name: AnalyticsEvents.dashboardBottomNavAdvisoryClicked,
            parameters: {
              AnalyticsParams.tabIndex: index,
              AnalyticsParams.tabName: 'advisory',
              AnalyticsParams.previousTabIndex: selectedIndex,
              AnalyticsParams.destinationScreen: 'advisory',
              AnalyticsParams.navigationMethod: 'bottom_tab',
            },
          );
          Get.to(
            () => const AdvisoryScreen(),
            transition: Transition.rightToLeft,
          );
        }
      },
      selectedItemColor: AppColors.darkTextGray,
      unselectedItemColor: AppColors.darkTextGray,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: "Investments",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment_rounded),
          label: "Mutual Funds",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb_rounded),
          label: "Advisory",
        ),
      ],
    );
  }
}
