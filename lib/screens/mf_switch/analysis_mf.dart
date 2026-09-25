import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/mf_switch/mf_switch.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

import 'widgets/mutual_fund_analysis_card.dart';

class AnalysisMutualFund extends StatefulWidget {
  const AnalysisMutualFund({super.key});

  @override
  State<AnalysisMutualFund> createState() => _AnalysisMutualFundState();
}

class _AnalysisMutualFundState extends State<AnalysisMutualFund> {
  @override
  void initState() {
    super.initState();
    _fetchMutualFundAnalysis();
  }

  final InvestmentController investmentController = Get.put(
    InvestmentController(),
  );
  bool isHoldingLoading = true;
  Future<void> _fetchMutualFundAnalysis() async {
    await investmentController.getHoldings(
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            isHoldingLoading = isLoading;
          });
        }
      },
    );
  }

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
              "Analysis",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: GetBuilder<InvestmentController>(
          builder: (investmentController) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSizing.scaffoldHorizontalPadding,
                  right: AppSizing.scaffoldHorizontalPadding,
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  spacing: 16,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.darkInputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkButtonBorder),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Mutual fund analysis",
                            variant: AppTextVariant.headline5,
                            weight: AppTextWeight.bold,
                            colorType: AppTextColorType.primary,
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            "We saw that you have two regular mutual fund plans. Just so you know, regular plans come with distributor commissions, while direct fund plans don't have any commissions.",
                            variant: AppTextVariant.headline6,
                            weight: AppTextWeight.regular,
                            colorType: AppTextColorType.primary,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.darkInputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.linkColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/svgs/mf_switch/mf_advice.svg",
                            height: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Mutual fund",
                                        style: TextStyle(
                                          color: AppColors.linkColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      TextSpan(
                                        text: " advice!",
                                        style: TextStyle(
                                          color: AppColors.darkPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            "How about switching to direct mutual fund plans to ",
                                        style: TextStyle(
                                          color: AppColors.darkPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      TextSpan(
                                        text: "Save up to 1.45%",
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      TextSpan(
                                        text: ". It could be a smart move!",
                                        style: TextStyle(
                                          color: AppColors.darkPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Mutual Fund Holdings",
                            variant: AppTextVariant.headline5,
                            weight: AppTextWeight.bold,
                            colorType: AppTextColorType.primary,
                            decoration: TextDecoration.none,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            spacing: 12,
                            children: [
                              if (isHoldingLoading)
                                ...List.generate(
                                  5,
                                  (index) => ShimmerInvestmentCard(),
                                ),
                              if (!isHoldingLoading &&
                                  investmentController.holdings?.data != null)
                                ...(investmentController
                                    .holdings!
                                    .data!
                                    .investments
                                    .mf
                                    .where(
                                      (investment) =>
                                          (investment.type == Type.MF) &&
                                          (investment.planmode == 'R'),
                                    )).map((investment) {
                                  return MutualFundAnalysisCard(
                                    logoUrl:
                                        "https://s3-symbol-logo.tradingview.com/kotak-mahindra-bank--big.svg",
                                    schemeName: investment.name,
                                    fundType: investment.schemeoption,
                                    investedAmount:
                                        CurrencyFormatter.formatRupee(
                                          investment.costvalue,
                                        ),
                                  );
                                }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Continue',
                isLoading: false,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: () {
                  Get.to(
                    () => const MutualFundSwitchScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
