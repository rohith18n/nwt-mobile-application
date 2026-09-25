import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/notifications/widgets/notification_card.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Notifications",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                dragStartBehavior: DragStartBehavior.start,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                ),
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 10,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppText(
                        "Advisory",
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.secondary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppText(
                        "Updates",
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.secondary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppText(
                        "Others",
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              
              Column(
                spacing: 16,
                children: [
                  NotificationCard(
                    notificationTitle: "Reminder",
                    icon: Icons.notifications_outlined,
                    notificationMessage: "Darshan, a minimum payment for card ending in 5614 is due.",
                    date: "May 08, 06:20 PM",
                    onTap: () {
                      // Handle notification tap
                    },
                  ),
                  NotificationCard(
                    notificationTitle: "Reminder",
                    icon: Icons.notifications_outlined,
                    notificationMessage: "Darshan, a minimum payment for card ending in 5614 is due.",
                    date: "May 08, 06:20 PM",
                    onTap: () {
                      // Handle notification tap
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
