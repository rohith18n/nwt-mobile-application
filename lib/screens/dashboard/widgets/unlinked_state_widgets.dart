import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';

class UnlockDashboardCard extends StatefulWidget {
  final VoidCallback onTap;

  const UnlockDashboardCard({super.key, required this.onTap});

  @override
  State<UnlockDashboardCard> createState() => _UnlockDashboardCardState();
}

class _UnlockDashboardCardState extends State<UnlockDashboardCard> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardUnlockCardViewed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Unlock dashboard. Double tap to link your accounts.',
      button: true,
      child: InkWell(
        onTap: () {
          AnalyticsService.to.logEvent(
            name: AnalyticsEvents.dashboardUnlockCardClicked,
          );
          widget.onTap();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.darkButtonBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(Icons.lock_outline, color: Colors.white, size: 24.w),
              ),
              SizedBox(height: 20.h),
              AppText(
                "Your dashboard is\nready to be unlocked",
                variant: AppTextVariant.headline2,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
                lineHeight: 1.2,
              ),
              AppText(
                "Link your accounts to see your real investments, net worth, and insights — automatically.",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                lineHeight: 1.4,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    "Link Now",
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.chevron_right, color: Colors.white, size: 18.w),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompleteSetupCarousel extends StatefulWidget {
  final List<SetupTaskItem> tasks;

  const CompleteSetupCarousel({super.key, required this.tasks});

  @override
  State<CompleteSetupCarousel> createState() => _CompleteSetupCarouselState();
}

class _CompleteSetupCarouselState extends State<CompleteSetupCarousel> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardSetupCarouselViewed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.darkButtonBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "Complete your setup",
            variant: AppTextVariant.headline3,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.primary,
          ),
          SizedBox(height: 4.h),
          AppText(
            "Unlock tracking, investing, and insights",
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 155.h,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: widget.tasks.length,
              separatorBuilder: (context, index) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return SetupTaskCard(task: task);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SetupTaskItem {
  final String title;
  final String description;
  final IconData icon;
  final bool isPending;
  final bool isRecommended;
  final bool isDisabled;
  final VoidCallback onTap;

  SetupTaskItem({
    required this.title,
    required this.description,
    required this.icon,
    this.isPending = false,
    this.isRecommended = false,
    this.isDisabled = false,
    required this.onTap,
  });
}

class SetupTaskCard extends StatelessWidget {
  final SetupTaskItem task;

  const SetupTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: task.isDisabled
          ? '${task.title}. ${task.description}. Not available.'
          : '${task.title}. ${task.description}. Double tap to set up.',
      button: !task.isDisabled,
      child: InkWell(
        onTap:
            task.isDisabled
                ? null
                : () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.dashboardSetupTaskCardClicked,
                    parameters: {AnalyticsParams.taskTitle: task.title},
                  );
                  task.onTap();
                },
        borderRadius: BorderRadius.circular(16.r),
        child: ExcludeSemantics(
          child: Container(
            width: 210.w,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A), // Darker background for nested card
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(task.icon, color: Colors.white, size: 18.w),
                    ),
                    if (task.isRecommended) ...[
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const AppText(
                          "Recommended",
                          variant: AppTextVariant.tiny,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                AppText(
                  task.title,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppText(
                        task.description,
                        variant: AppTextVariant.tiny,
                        colorType: AppTextColorType.secondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        lineHeight: 1.3,
                      ),
                    ),
                    if (!task.isDisabled) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.darkTextMuted,
                        size: 14.w,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PivotMoneyInfoCard extends StatelessWidget {
  final VoidCallback onLearnMore;

  const PivotMoneyInfoCard({super.key, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.darkButtonBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: const BoxDecoration(
                  color: Color(0xFF14302E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt,
                  color: const Color(0xFF00FFA3),
                  size: 16.w,
                ),
              ),
              SizedBox(width: 10.w),
              AppText(
                "From Pivot Money",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 16.h),
          AppText(
            "You always stay in control. Pivot Money never holds your funds — investments remain in your name.",
            variant: AppTextVariant.bodyLarge,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
            lineHeight: 1.4,
          ),
          SizedBox(height: 16.h),
          InkWell(
            onTap: () {
              AnalyticsService.to.logEvent(
                name: AnalyticsEvents.dashboardPivotInfoLearnMoreClicked,
              );
              onLearnMore();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  "Learn how this works",
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
                SizedBox(width: 4.w),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.darkTextMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
