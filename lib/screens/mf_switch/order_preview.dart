import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class OrderPreviewScreen extends StatefulWidget {
  const OrderPreviewScreen({super.key});

  @override
  State<OrderPreviewScreen> createState() => _OrderPreviewScreenState();
}

class _OrderPreviewScreenState extends State<OrderPreviewScreen> {
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
              "Order Preview",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            GestureDetector(
              onTap: () => _showInfoBottomSheet(context),
              child: const Icon(Icons.info_outline_rounded, size: 20),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            spacing: 12,
            children: [
              _buildOrderPreviewContainer(
                title: "Switch Amount",
                value: CurrencyFormatter.formatRupee(10000),
              ),
              _buildOrderPreviewContainer(title: "Exit Load", value: "0"),
              _buildOrderPreviewContainer(
                title: "Long term capital gains",
                value: '1.2%',
              ),
              _buildOrderPreviewContainer(title: "Tax on LTCG", value: "12.5%"),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     Container(
      //       padding: const EdgeInsets.symmetric(
      //         horizontal: AppSizing.scaffoldHorizontalPadding,
      //       ),
      //       margin: EdgeInsets.only(
      //         bottom: MediaQuery.of(context).padding.bottom + 16,
      //       ),
      //       child: SizedBox(
      //         width: double.infinity,
      //         child: AppButton(
      //           text: 'Confirm',
      //           variant: AppButtonVariant.primary,
      //           size: AppButtonSize.large,
      //           onPressed: () {},
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildOrderPreviewContainer({
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                ),
                AppText(
                  value,
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Mutual Fund Terms",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              _buildInfoItem(
                number: "1",
                title: "Exit Load",
                description:
                    "Exit load is a penalty that a mutual fund company charges if you sell your units before the specified exit load period.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "2",
                title: "Tax on LTCG",
                description:
                    "If you sell equity mutual funds after 1 year and make a profit over ₹1 lakh, you pay 10% tax on those profits.",
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.darkButtonBorder,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: AppText(
              number,
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.semiBold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
              ),
              const SizedBox(height: 4),
              AppText(description, variant: AppTextVariant.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
