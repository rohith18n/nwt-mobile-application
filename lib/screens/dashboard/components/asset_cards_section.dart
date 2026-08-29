import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/screens/connections/connections.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_assets.dart';
import 'package:nwt_app/screens/dashboard/widgets/asset_card.dart';
import 'package:nwt_app/utils/currency_formatter.dart';

class AssetCardsSection extends StatelessWidget {
  final bool isAmountVisible;
  final DashboardAssetController dashboardAssetController;

  const AssetCardsSection({
    super.key,
    required this.isAmountVisible,
    required this.dashboardAssetController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Assets",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "See All",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              _buildAddConnectionButton(),
              const SizedBox(width: 12),

              // _buildAssetCard(
              //   isAmountVisible: isAmountVisible,
              //   title: "Banks",
              //   assetData: dashboardAssetController.bankAssetData,
              //   icon: Icons.account_balance_rounded,
              //   destination: const AssetBankScreen(),
              // ),

              // const SizedBox(width: 12),

              // _buildAssetCard(
              //   isAmountVisible: isAmountVisible,
              //   title: "Investments",
              //   assetData: dashboardAssetController.investmentAssetData,
              //   icon: Icons.pie_chart_rounded,
              //   destination: const AssetInvestmentScreen(),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAddConnectionButton() {
    return InkWell(
      onTap:
          () => Get.to(
            const ConnectionsScreen(),
            transition: Transition.rightToLeft,
          ),
      child: Container(
        width: 50,
        height: 105,
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        child: const Center(child: Icon(Icons.add_rounded, size: 26)),
      ),
    );
  }

  Widget _buildAssetCard({
    required String title,
    required bool isAmountVisible,
    required Rx<AssetData?> assetData,
    required IconData icon,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () => Get.to(destination, transition: Transition.rightToLeft),
      child: Obx(() {
        final data = assetData.value;
        final isLinked = data?.islinked ?? false;
        final amount = data?.value ?? 0.0;
        final delta = data?.deltapercentage ?? 0.0;
        final deltaType = delta >= 0 ? DeltaType.positive : DeltaType.negative;

        return AssetCard(
          title: title,
          isAmountVisible: isAmountVisible,
          amount: isLinked ? CurrencyFormatter.formatRupee(amount) : "Link Now",
          delta: isLinked ? "${delta.abs().toStringAsFixed(2)}%" : "",
          deltaType: deltaType,
          icon: icon,
          isLinked: isLinked,
        );
      }),
    );
  }
}
