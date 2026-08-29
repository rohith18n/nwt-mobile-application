import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/notifications/notification_list.dart';
import 'package:nwt_app/screens/search/global_search/global_search.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class DashboardHeader extends StatelessWidget {
  final UserController userController;
  final String Function() getGreetingMessage;

  const DashboardHeader({
    super.key,
    required this.userController,
    required this.getGreetingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.dashboardAvatarClicked,
                  );
                  _showLogoutDialog(context);
                },
                child: Avatar(
                  path:
                      userController.userData?.gender?.toLowerCase() == 'female'
                          ? 'assets/svgs/dashboard/female.png'
                          : 'assets/svgs/dashboard/male.png',
                  width: 40,
                  height: 40,
                  isNetworkImage: false,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    "Hi, ${userController.userData?.firstname != null ? userController.userData!.firstname : 'User'}",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                  ),
                  AppText(
                    getGreetingMessage(),
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.secondary,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.dashboardSearchIconClicked,
                  );
                  Get.to(
                    () => GlobalSearchScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
                icon: Icon(
                  CupertinoIcons.search,
                  color: AppColors.darkTextMuted,
                ),
              ),
              IconButton(
                onPressed: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.dashboardNotificationsIconClicked,
                  );
                  Get.to(
                    () => NotificationListScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardLogoutDialogShown,
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const AppText(
            "Logout",
            variant: AppTextVariant.headline4,
            weight: AppTextWeight.semiBold,
          ),
          content: const AppText(
            "Are you sure you want to logout?",
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.tertiary,
          ),
          actions: [
            TextButton(
              onPressed: () {
                AnalyticsService.to.logEvent(
                  name: AnalyticsEvents.dashboardLogoutCancelled,
                );
                Navigator.pop(context);
              },
              child: const AppText(
                "Cancel",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
              ),
            ),
            TextButton(
              onPressed: () {
                AnalyticsService.to.logEvent(
                  name: AnalyticsEvents.dashboardLogoutConfirmed,
                );
                Navigator.pop(context);

                try {
                  final authFlow = AuthFlow();
                  AppLogger.info('Logging out user', tag: 'Dashboard');
                  authFlow.logout();
                } catch (e) {
                  AppLogger.error(
                    'Error during logout',
                    error: e,
                    tag: 'Dashboard',
                  );
                }
              },
              child: const AppText(
                "Logout",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.error,
              ),
            ),
          ],
        );
      },
    );
  }
}
