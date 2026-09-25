import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/insights/types/insights.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class MutualFundsSignalsScreen extends StatefulWidget {
  final PerformanceScoreResponse? performanceData;
  final bool isLoading;
  final double nav;
  final double expenseratio;
  final String sebicategoryname;
  final double totalreturns;
  final String? fundCategory;
  final String? aum;
  final int? currentRank;
  final int? totalFunds;
  final double? currentValue;
  final double? investedAmount;
  final bool showAbsoluteReturns;

  const MutualFundsSignalsScreen({
    super.key,
    required this.sebicategoryname,
    this.performanceData,
    this.isLoading = false,
    required this.nav,
    required this.expenseratio,
    required this.totalreturns,
    this.fundCategory,
    this.aum,
    this.currentRank,
    this.totalFunds,
    this.currentValue,
    this.investedAmount,
    this.showAbsoluteReturns = false,
  });

  @override
  State<MutualFundsSignalsScreen> createState() =>
      _MutualFundsSignalsScreenState();
}

class _MutualFundsSignalsScreenState extends State<MutualFundsSignalsScreen> {
  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show no data message
    if (widget.performanceData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const AppText(
              'No Performance Data Available',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 8),
            const AppText(
              'Performance score data is not available for this fund at the moment.',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show normal content when data is available
    return Column(
      children: [
        // Fund Ranking Section
        if (widget.currentRank != null && widget.totalFunds != null)
          _buildRankingSection(),
        const SizedBox(height: 20),

        _buildSectionTitle('Performance Indicators'),
        const SizedBox(height: 6),
        _buildRiskIndicators(),

        const SizedBox(height: 20),

        // Performance Score Title
        _buildSectionTitle('Performance Score'),
        const SizedBox(height: 6),

        // Performance Metrics Grid
        _buildPerformanceMetrics(),
        const SizedBox(height: 20),

        // Recommendations Card
        // _buildSectionTitle('Recommendations'),
        // const SizedBox(height: 6),
        // _buildRecommendationsCard(),
        // const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRankingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fund Category Title
          AppText(
            widget.sebicategoryname,
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 20),
          widget.currentRank == null || widget.totalFunds == null ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppText(
              'We don\'t rank regular plans because direct plans offer the same investment strategy with lower costs. Direct plans skip distributor fees, meaning more of your money goes toward actual investment growth.',
              variant: AppTextVariant.tiny,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.tertiary,
            ),
          ) :
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Enhanced Circular Ranking Indicator
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '#${widget.currentRank ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'of ${widget.totalFunds}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Enhanced Ranking Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main ranking text
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Pivot Money ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const TextSpan(text: 'ranks this '),
                              TextSpan(
                                text: '#${widget.currentRank}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const TextSpan(text: ' out of '),
                              TextSpan(
                                text: '${widget.totalFunds}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text: ' mutual funds in this category.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Performance indicator
                        if (false)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRankingColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getRankingIcon(),
                                      size: 14,
                                      color: _getRankingColor(),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getRankingLabel(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getRankingColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Enhanced Fund Details Grid
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('AUM', "₹${widget.aum.toString()}"),
              ),
              Expanded(
                child: _buildDetailItem(
                  widget.showAbsoluteReturns ? 'Total Returns' : 'Annualized Returns',
                  '${widget.totalreturns.toStringAsFixed(1)}%',
                  isPositive: widget.totalreturns > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show investment details only if user has invested
          if (widget.investedAmount != null && widget.investedAmount! > 0) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Current NAV',
                    CurrencyFormatter.formatRupeeWithCommas(
                      widget.nav,
                      decimals: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Invested',
                    CurrencyFormatter.formatRupeeWithCommas(
                      widget.investedAmount!,
                      decimals: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Current Value',
                    widget.currentValue != null
                        ? CurrencyFormatter.formatRupeeWithCommas(
                          widget.currentValue!,
                          decimals: 2,
                        )
                        : '₹0',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Expense Ratio',
                    '${widget.expenseratio}%',
                  ),
                ),
              ],
            ),
          ] else
            // Show only NAV and Expense Ratio when no investment
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Current NAV',
                    CurrencyFormatter.formatRupeeWithCommas(
                      widget.nav,
                      decimals: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Expense Ratio',
                    '${widget.expenseratio}%',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Helper method for enhanced detail items
  Widget _buildEnhancedDetailItem(
    String label,
    String value,
    IconData icon, {
    bool? isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isPositive == true
                    ? Colors.green.shade600
                    : isPositive == false
                    ? Colors.red.shade600
                    : Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color:
                  isPositive == true
                      ? Colors.green.shade700
                      : isPositive == false
                      ? Colors.red.shade700
                      : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods for ranking indicators
  Color _getRankingColor() {
    final rank = widget.currentRank ?? 1;
    final total = widget.totalFunds ?? 1;
    final percentile = (rank / total) * 100;

    if (percentile <= 20) return Colors.green.shade600;
    if (percentile <= 50) return Colors.blue.shade600;
    if (percentile <= 75) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getRankingIcon() {
    final rank = widget.currentRank ?? 1;
    final total = widget.totalFunds ?? 1;
    final percentile = (rank / total) * 100;

    if (percentile <= 20) return Icons.emoji_events;
    if (percentile <= 50) return Icons.trending_up;
    if (percentile <= 75) return Icons.trending_flat;
    return Icons.trending_down;
  }

  String _getRankingLabel() {
    final rank = widget.currentRank ?? 1;
    final total = widget.totalFunds ?? 1;
    final percentile = (rank / total) * 100;

    if (percentile <= 20) return 'Top Performer';
    if (percentile <= 50) return 'Above Average';
    if (percentile <= 75) return 'Average';
    return 'Below Average';
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isPositive = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            widget.sebicategoryname,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                widget.showAbsoluteReturns ? 'Total Returns' : 'Annualized Returns',
                "${widget.totalreturns.toStringAsFixed(2)}%",
                isPositive: widget.totalreturns > 0,
              ),
              _buildSummaryItem(
                'Current NAV',
                CurrencyFormatter.formatRupee(widget.nav),
              ),
              _buildSummaryItem('Current Value', '₹1,23,456'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Invested', '₹1,00,000'),
              _buildSummaryItem('Expense Ratio', '${widget.expenseratio}%'),
              Opacity(
                opacity: 0,
                child: _buildSummaryItem('Current Value', '₹1,23,456'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool isPositive = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.caption,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(height: 4),
        AppText(
          value,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          colorType:
              isPositive ? AppTextColorType.success : AppTextColorType.primary,
        ),
      ],
    );
  }

  Widget _buildRiskIndicators() {
    final data = widget.performanceData!;
    return Column(
      children: [
        _buildRiskCard('High', data.green, AppColors.success),
        const SizedBox(height: 8),
        _buildRiskCard('Medium', data.yellow, AppColors.warning),
        const SizedBox(height: 8),
        _buildRiskCard('Low', data.red, AppColors.error),
        // const SizedBox(height: 8),
        // _buildRiskCard(
        //   'Insufficient Data',
        //   data.white,
        //   AppColors.darkTextSecondary,
        // ),
      ],
    );
  }

  Widget _buildRiskCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      child: Row(
        children: [
          // Color indicator bar
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: AppText(
              label,
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.primary,
              weight: AppTextWeight.medium,
            ),
          ),
          // Count
          AppText(
            count.toString(),
            variant: AppTextVariant.bodyLarge,
            colorType: AppTextColorType.primary,
            weight: AppTextWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        AppText(
          title,
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    final scores = widget.performanceData!.scores;

    if (scores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const AppText(
          'No performance metrics available',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.secondary,
        ),
      );
    }

    return Column(
      children:
          scores.map((score) {
            // Determine icon based on slug
            IconData icon = _getIconForSlug(score.slug);

            // Determine signal type
            bool isPositive = score.signal.toLowerCase() == 'g';
            bool isNegative = score.signal.toLowerCase() == 'r';
            bool isNeutral = score.signal.toLowerCase() == 'y';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMetricItem(
                score.line1,
                score.line2,
                icon,
                value: score.value,
                isPositive: isPositive,
                isNegative: isNegative,
                isNeutral: isNeutral,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildMetricItem(
    String title,
    String condition,
    IconData icon, {
    String? value,
    bool isPositive = false,
    bool isNegative = false,
    bool isNeutral = false,
  }) {
    Color valueColor =
        isNegative
            ? AppColors.error
            : isPositive
            ? AppColors.success
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.darkPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: valueColor),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Condition
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AppText(
                        title,
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.medium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (value != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: valueColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AppText(
                          value,
                          variant: AppTextVariant.caption,
                          colorType:
                              isNegative
                                  ? AppTextColorType.error
                                  : isPositive
                                  ? AppTextColorType.success
                                  : AppTextColorType.warning,
                          weight: AppTextWeight.semiBold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText(
                  condition.isEmpty ? 'N/A' : condition,
                  variant: AppTextVariant.caption,
                  colorType: AppTextColorType.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationItem('Consider increasing allocation by 10-15%'),
          _buildRecommendationItem(
            'Monitor sector concentration in top 5 sectors',
          ),
          _buildRecommendationItem(
            'Rebalance portfolio if allocation exceeds 15% of total portfolio',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: AppColors.warning),
          ),
          Expanded(
            child: AppText(
              text,
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSlug(String slug) {
    switch (slug.toLowerCase()) {
      case 'alpha':
        return Icons.trending_up;
      case 'beta':
        return Icons.show_chart;
      case 'sharpe':
      case 'sharpe_ratio':
        return Icons.balance;
      case 'expense':
      case 'expense_ratio':
        return Icons.account_balance_wallet;
      case 'standard_deviation':
      case 'volatility':
        return Icons.timeline;
      case 'turnover':
      case 'portfolio_turnover':
        return Icons.swap_horiz;
      case 'information':
      case 'information_ratio':
        return Icons.info_outline;
      case 'drawdown':
      case 'maximum_drawdown':
        return Icons.trending_down;
      case 'sortino':
      case 'sortino_ratio':
        return Icons.percent;
      case 'return':
      case 'returns':
        return Icons.trending_up;
      case 'asset':
      case 'top_asset':
        return Icons.pie_chart;
      case 'sector':
      case 'top_sector':
        return Icons.donut_small;
      case 'exit_load':
        return Icons.exit_to_app;
      default:
        return Icons.analytics;
    }
  }
}
