import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/advisory/select_equity_strategy.dart';

class AdvisoryV2Screen extends StatefulWidget {
  const AdvisoryV2Screen({super.key});

  @override
  State<AdvisoryV2Screen> createState() => _AdvisoryV2ScreenState();
}

class _AdvisoryV2ScreenState extends State<AdvisoryV2Screen> {
  bool _momentumExpanded = false;
  bool _rebalancingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AppText(
          "Advisory",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // HOW DOES IT WORK?
                Text(
                  'HOW DOES IT WORK?',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // MOMENTUM STRATEGIES
                _buildExpandableCard(
                  isDarkMode: isDarkMode,
                  icon: Icons.show_chart,
                  title: 'MOMENTUM STRATEGIES',
                  isExpanded: _momentumExpanded,
                  onTap: () {
                    setState(() {
                      _momentumExpanded = !_momentumExpanded;
                    });
                  },
                  content: 'We provide 2 expertly curated momentum-based strategies each month:\n\n• Mid-Cap Strategy: 10 carefully selected stocks from Nifty Midcap 150\n• Small-Cap Strategy: 15 high-potential stocks from Nifty Smallcap 250\n\nBoth strategies use systematic, rule driven approach combining Absolute and Relative Momentum principles for optimal performance.',
                ),
                const SizedBox(height: 12),
                
                // MONTHLY RE-BALANCING
                _buildExpandableCard(
                  isDarkMode: isDarkMode,
                  icon: Icons.show_chart,
                  title: 'MONTHLY RE-BALANCING',
                  isExpanded: _rebalancingExpanded,
                  onTap: () {
                    setState(() {
                      _rebalancingExpanded = !_rebalancingExpanded;
                    });
                  },
                  content: 'Portfolios are automatically re-balanced on the first business day of every month with fresh stock picks, ensuring you always have exposure to the strongest momentum performers in the market.',
                ),
                const SizedBox(height: 32),
                
                // Key Benefits
                Text(
                  'Key Benefits',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Benefits Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildBenefitCard(
                        isDarkMode: isDarkMode,
                        icon: Icons.bar_chart,
                        title: 'Data-backed\nstrategy',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBenefitCard(
                        isDarkMode: isDarkMode,
                        icon: Icons.trending_up,
                        title: 'Diversified\nportfolio (10\nstocks)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildBenefitCard(
                        isDarkMode: isDarkMode,
                        icon: Icons.autorenew,
                        title: 'Automated\nallocation',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBenefitCard(
                        isDarkMode: isDarkMode,
                        icon: Icons.shield_outlined,
                        title: 'Expert advisory',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Risk Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Color(0xFFFFA726),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Risk Disclaimer',
                            style: TextStyle(
                              color: const Color(0xFFFFA726),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is a market-linked investment product and is subject to market risks. Past performance is not indicative of future returns. Please read all scheme related documents carefully before investing.',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // I Understand Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectStrategyScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground,
                      foregroundColor: isDarkMode ? AppColors.darkButtonPrimaryText : AppColors.lightButtonPrimaryText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCard({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    String? content,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  size: 20,
                ),
              ],
            ),
            if (isExpanded && content != null) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required bool isDarkMode,
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
