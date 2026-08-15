import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class InvestmentActivityScreen extends StatefulWidget {
  const InvestmentActivityScreen({super.key});

  @override
  State<InvestmentActivityScreen> createState() => _InvestmentActivityScreenState();
}

class _InvestmentActivityScreenState extends State<InvestmentActivityScreen> {
  String selectedFilter = 'Pending';
  final List<String> filters = ['Pending', 'Buy', 'Sell', 'SIP', 'Switch', 'SWP'];
  
  final List<ActivityItem> activities = [
    ActivityItem(
      fundName: 'Motilal Oswal Focused Direct growth',
      amount: '₹2,000',
      nav: '₹35.10',
      units: '100.50',
      date: '02, May 2025',
      orderId: '0456123789',
      status: 'Success',
      iconColor: Colors.yellow,
    ),
    ActivityItem(
      fundName: 'Kotak Emerging Fund Direct Growth',
      amount: '₹15,000',
      nav: '₹50.12',
      units: '350.61',
      date: '12, May 2025',
      orderId: '0456123789',
      status: 'Failed',
      iconColor: Colors.red,
    ),
    ActivityItem(
      fundName: 'Franklin India Opportunities Fund',
      amount: '₹25,000',
      nav: '₹25.12',
      units: '250.91',
      date: '1, April 2025',
      orderId: '0123654789',
      status: 'Success',
      iconColor: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, color: AppColors.darkTextPrimary),
            ),
            AppText(
              "Activity",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const WhatsAppSupportButton(
              size: 20,
              color: AppColors.darkPrimary,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkButtonBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.filter_list,
                color: AppColors.darkTextPrimary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return CategoryChip(
                  label: filter,
                  isSelected: selectedFilter == filter,
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Activity List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityCard(activity);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with fund name and status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activity.iconColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    activity.fundName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      activity.fundName,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activity.status == 'Success' 
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AppText(
                  activity.status,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.medium,
                  colorType: activity.status == 'Success' 
                      ? AppTextColorType.success
                      : AppTextColorType.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transaction details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Amount',
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      activity.amount,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'NAV',
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      activity.nav,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Units',
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      activity.units,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date and Order ID
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Date',
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      activity.date,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Order ID',
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      activity.orderId,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
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
}

class ActivityItem {
  final String fundName;
  final String amount;
  final String nav;
  final String units;
  final String date;
  final String orderId;
  final String status;
  final Color iconColor;

  ActivityItem({
    required this.fundName,
    required this.amount,
    required this.nav,
    required this.units,
    required this.date,
    required this.orderId,
    required this.status,
    required this.iconColor,
  });
}