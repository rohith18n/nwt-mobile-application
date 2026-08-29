import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/bse_star/widgets/order_activity_card.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class BseOrderDetailScreen extends StatefulWidget {
  const BseOrderDetailScreen({super.key});

  @override
  State<BseOrderDetailScreen> createState() => _BseOrderDetailScreenState();
}

class _BseOrderDetailScreenState extends State<BseOrderDetailScreen> {
  
  void _handleBack() {
     Get.back();
  }
  
  String _getScreenTitle() {
    return 'Activity';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _handleBack,
              child: const Icon(
                Icons.chevron_left,
                size: 32,
                color: Colors.white,
              ),
            ),
            AppText(
              _getScreenTitle(),
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              customColor: Colors.white,
            ),
            const Opacity(
              opacity: 0,
              child: Icon(Icons.chevron_left, size: 32),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
        children: [
          // Sample order activity cards - replace with actual data
          OrderActivityCard(
            fundName: 'Kotak Emerging Fund Direct Growth',
            payAmount: 15000,
            date: DateTime(2025, 5, 10),
            orderId: '0456123789',
            status: 'Buy Pending',
            onTap: () {
              // Handle card tap - navigate to order details
            },
          ),
          OrderActivityCard(
            fundName: 'HDFC Mid-Cap Opportunities Fund',
            payAmount: 25000,
            date: DateTime(2025, 5, 8),
            orderId: '0456123788',
            status: 'Completed',
            onTap: () {
              // Handle card tap - navigate to order details
            },
          ),
          OrderActivityCard(
            fundName: 'SBI Small Cap Fund Direct Growth',
            payAmount: 10000,
            date: DateTime(2025, 5, 5),
            orderId: '0456123787',
            status: 'Processing',
            onTap: () {
              // Handle card tap - navigate to order details
            },
          ),
        ],
      ),
    );
  }
}