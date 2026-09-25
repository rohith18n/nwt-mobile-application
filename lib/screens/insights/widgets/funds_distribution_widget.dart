import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class FundsDistributionWidget extends StatefulWidget {
  final Map<String, dynamic> equityDistribution;
  final Map<String, dynamic> debtCashDistribution;

  const FundsDistributionWidget({
    super.key,
    required this.equityDistribution,
    required this.debtCashDistribution,
  });

  @override
  State<FundsDistributionWidget> createState() =>
      _FundsDistributionWidgetState();
}

class _FundsDistributionWidgetState extends State<FundsDistributionWidget> {
  int _selectedTabIndex = 0;
  String? _selectedCategory;
  final List<String> _tabs = ['Equity', 'Debt & Cash'];

  @override
  Widget build(BuildContext context) {
    return CustomAccordion(
      title: 'Funds Distribution',
      initiallyExpanded: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs for Equity and Debt & Cash
            _buildTabs(),
            const SizedBox(height: 24),

            // Show different content based on selected tab
            if (_selectedTabIndex == 0) ...[
              // Size Breakup section for Equity
              _buildSizeBreakup(),
              const SizedBox(height: 24),

              // Size categories with percentages for Equity
              _buildSizeCategories(),
            ] else ...[
              // Credit Rating Breakup for Debt & Cash
              _buildCreditRatingBreakup(),
              const SizedBox(height: 24),

              // Credit Rating categories for Debt & Cash
              _buildCreditRatingCategories(),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          _tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      _selectedTabIndex == index
                          ? Colors.white
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppText(
                  _tabs[index],
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.bold,
                  colorType:
                      _selectedTabIndex == index
                          ? AppTextColorType.tertiary
                          : AppTextColorType.primary,
                  customColor:
                      _selectedTabIndex == index
                          ? const Color(0xFF000000)
                          : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeBreakup() {
    // Get values from the equity distribution data
    final midcap = widget.equityDistribution['midcap'] ?? 0.0;
    final largecap = widget.equityDistribution['largecap'] ?? 0.0;
    final smallcap = widget.equityDistribution['smallcap'] ?? 0.0;

    // Calculate total for percentage display
    final total = midcap + largecap + smallcap;

    // Normalize values to ensure they sum to 100 for the graph
    final normalizedMidcap = total > 0 ? (midcap / total) * 100 : 0.0;
    final normalizedLargecap = total > 0 ? (largecap / total) * 100 : 0.0;
    final normalizedSmallcap = total > 0 ? (smallcap / total) * 100 : 0.0;

    // Convert to integer flex values for the progress bar using normalized values
    final midcapFlex = (normalizedMidcap * 10).round();
    final largecapFlex = (normalizedLargecap * 10).round();
    final smallcapFlex = (normalizedSmallcap * 10).round();

    // Width factor is always 1.0 since we're normalizing to 100%
    const widthFactor = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Size Breakup',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.secondary,
            ),
            AppText(
              '${total.toStringAsFixed(1)}%',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
              customColor: const Color(0xFF3ABFF8), // Light blue color
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Single stacked progress bar
        SizedBox(
          height: 8,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                // Background
                Container(
                  width: double.infinity,
                  color: const Color(0xFF2A2A2A),
                ),
                // Stacked progress bars
                FractionallySizedBox(
                  widthFactor: widthFactor, // Total width based on actual data
                  child: Row(
                    children: [
                      // Large Cap
                      Expanded(
                        flex: largecapFlex,
                        child: Container(
                          color: Color(0xFFD926AA).withValues(
                            alpha:
                                _selectedCategory == null ||
                                        _selectedCategory == 'Large Cap'
                                    ? 1
                                    : 0.2,
                          ),
                        ),
                      ),
                      // Mid Cap
                      Expanded(
                        flex: midcapFlex,
                        child: Container(
                          color: Color(0xFF3ABFF8).withValues(
                            alpha:
                                _selectedCategory == null ||
                                        _selectedCategory == 'Mid Cap'
                                    ? 1
                                    : 0.2,
                          ),
                        ),
                      ),
                      // Small Cap
                      Expanded(
                        flex: smallcapFlex,
                        child: Container(
                          color: Color(0xFFFBBD23).withValues(
                            alpha:
                                _selectedCategory == null ||
                                        _selectedCategory == 'Small Cap'
                                    ? 1
                                    : 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeCategories() {
    final midcap = widget.equityDistribution['midcap'] ?? 0.0;
    final largecap = widget.equityDistribution['largecap'] ?? 0.0;
    final smallcap = widget.equityDistribution['smallcap'] ?? 0.0;

    return Column(
      children: [
        _buildSizeCategory(
          'Large Cap',
          '${largecap.toStringAsFixed(1)}%',
          const Color(0xFFD926AA),
        ),
        const SizedBox(height: 16),
        _buildSizeCategory(
          'Mid Cap',
          '${midcap.toStringAsFixed(1)}%',
          const Color(0xFF3ABFF8),
        ),
        const SizedBox(height: 16),
        _buildSizeCategory(
          'Small Cap',
          '${smallcap.toStringAsFixed(1)}%',
          const Color(0xFFFBBD23),
        ),
      ],
    );
  }

  Widget _buildSizeCategory(String name, String percentage, Color color) {
    final bool isSelected = _selectedCategory == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = _selectedCategory == name ? null : name;
        });
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: color.withValues(
                alpha: _selectedCategory == null || isSelected ? 1 : 0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppText(
            name,
            variant: AppTextVariant.bodyMedium,
            weight: isSelected ? AppTextWeight.semiBold : AppTextWeight.medium,
            colorType: AppTextColorType.primary,
            customColor: Colors.white.withValues(
              alpha: _selectedCategory == null || isSelected ? 1 : 0.2,
            ),
          ),
          const Spacer(),
          AppText(
            percentage,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
            customColor: Colors.white.withValues(
              alpha: _selectedCategory == null || isSelected ? 1 : 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Credit Rating Breakup for Debt & Cash tab
  Widget _buildCreditRatingBreakup() {
    // Get values from the debt cash distribution data
    final aaa = widget.debtCashDistribution['aaa'] ?? 0.0;

    // Normalize values to ensure they sum to 100 for the graph
    final normalizedAAA = aaa > 0 ? (aaa / aaa) * 100 : 0.0;

    // Convert to integer flex values for the progress bar using normalized values
    final aaaFlex = (normalizedAAA * 10).round();

    // Width factor is always 1.0 since we're normalizing to 100%
    const widthFactor = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Credit Rating Breakup',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.secondary,
            ),
            AppText(
              '${aaa.toStringAsFixed(1)}%',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
              customColor: const Color(0xFF3ABFF8),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Multi-segment progress bar for all ratings
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              // AAA segment
              Flexible(
                flex: aaaFlex,
                child: FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(0xFF3ABFF8).withOpacity(
                        _selectedCategory == null || _selectedCategory == 'AAA'
                            ? 1
                            : 0.7,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditRatingCategories() {
    final aaa = widget.debtCashDistribution['aaa'] ?? 0.0;

    return Column(
      children: [
        _buildCreditRatingCategory(
          'AAA',
          '${aaa.toStringAsFixed(1)}%',
          const Color(0xFF3ABFF8),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCreditRatingCategory(
    String name,
    String percentage,
    Color color,
  ) {
    final bool isSelected = _selectedCategory == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = _selectedCategory == name ? null : name;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withOpacity(isSelected ? 1 : 0.7),
                border: Border.all(
                  color: color.withOpacity(isSelected ? 0.5 : 0.3),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppText(
              name,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
              customColor: Colors.white.withOpacity(isSelected ? 1 : 0.7),
            ),
            const Spacer(),
            AppText(
              percentage,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
              customColor: Colors.white.withOpacity(isSelected ? 1 : 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
