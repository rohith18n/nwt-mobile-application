import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class FundDetailsWidget extends StatelessWidget {
  final String expenseRatio;
  final String investmentStyle;
  final String fundManager;
  final String aum;
  final String exitLoad;
  final double? minsip;
  final double? minInvestment;

  const FundDetailsWidget({
    super.key,
    required this.expenseRatio,
    required this.investmentStyle,
    required this.fundManager,
    required this.aum,
    required this.exitLoad,
    this.minsip,
    this.minInvestment,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAccordion(
      title: 'Fund Details',
      initiallyExpanded: true,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        childAspectRatio: 2.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGridItem(label: 'Expense Ratio', value: expenseRatio),
          _buildGridItem(
            label: 'Min. SIP',
            value:
                minsip != null
                    ? CurrencyFormatter.formatRupeeWithCommas(minsip ?? 0.0)
                    : "-",
          ),
          _buildGridItem(
            label: 'Min. Investment',
            value:
                minInvestment != null
                    ? CurrencyFormatter.formatRupeeWithCommas(
                      minInvestment ?? 0.0,
                    )
                    : "-",
          ),
          _buildGridItem(label: 'Investment Style', value: investmentStyle),

          _buildGridItem(
            label: 'Fund Manager',
            value: fundManager,
          ),

          _buildGridItem(label: 'AUM', value: "₹${aum.toString()}"),

          _buildGridItem(
            label: 'Exit Load',
            value: exitLoad,
            labelSuffix: GestureDetector(
              onTap:
                  () => _showInfoBottomSheet(
                    context,
                    'What is Exit Load?',
                    'Exit load is a penalty that a mutual fund company charges if you sell your units before the specified exit load period.',
                  ),
              child: const Icon(
                Icons.info_outline,
                size: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required String label,
    required String value,
    Widget? suffix,
    Widget? labelSuffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            AppText(
              label,
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
            ),
            if (labelSuffix != null) ...[const SizedBox(width: 4), labelSuffix],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: AppText(
                value,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffix != null) ...[const SizedBox(width: 4), suffix],
          ],
        ),
      ],
    );
  }

  void _showInfoBottomSheet(
    BuildContext context,
    String title,
    String description,
  ) {
    if (title == 'Fund Manager') {
      _showFundManagerBottomSheet(context);
    } else if (title.contains('Exit Load')) {
      _showSimpleBottomSheet(context, title, description);
    } else {
      _showSimpleBottomSheet(context, title, description);
    }
  }

  void _showSimpleBottomSheet(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.headline4,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 12),
                AppText(
                  description,
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  void _showFundManagerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkInputBackground,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.95,
            padding: EdgeInsets.only(
              left: AppSizing.scaffoldHorizontalPadding,
              right: AppSizing.scaffoldHorizontalPadding,
              top: 16,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Fund Manager',
                  variant: AppTextVariant.headline4,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.darkInputBorder),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildManagerCard(
                          name: 'Kiran Sebastian',
                          since: 'Since 07, Feb 2022',
                          education:
                              'Mr. Sebastian is a MBA, University of Oxford. B.Tech, University of Calicut.',
                          experience:
                              'Prior to joining Franklin Templeton Mutual Fund, he has worked with ARCA Investment Management (India) Pvt. Ltd.',
                          fundsList: [
                            _buildFundItem(
                              'Franklin India Smaller Companies Fund - Regular Plan',
                              'since Feb 2008',
                              'Invest Online',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildManagerCard({
    required String name,
    required String since,
    required String education,
    required String experience,
    required List<Widget> fundsList,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                name,
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(width: 8),
              AppText(
                since,
                variant: AppTextVariant.caption,
                colorType: AppTextColorType.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            'Education:',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 4),
          AppText(
            education,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
          ),
          const SizedBox(height: 12),
          AppText(
            'Experience:',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 4),
          AppText(
            experience,
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
          const SizedBox(height: 12),
          AppText(
            'Funds Managed:',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 8),
          ...fundsList,
        ],
      ),
    );
  }

  Widget _buildFundItem(String fundName, String since, String investLink) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$fundName - ',
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: since,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const TextSpan(
                            text: ' | ',
                            style: TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: investLink,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
