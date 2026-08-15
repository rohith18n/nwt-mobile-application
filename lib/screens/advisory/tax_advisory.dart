import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/advisory/types/tax_advisory.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/services/advisory/taxt_advisory.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:url_launcher/url_launcher.dart';

class TaxAdvisoryScreen extends StatefulWidget {
  const TaxAdvisoryScreen({super.key});

  @override
  State<TaxAdvisoryScreen> createState() => _TaxAdvisoryScreenState();
}

// New default bottom sheet per design (separate from the existing ones)
void _showDefaultDetailedBreakdownBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.darkInputBackground,
    builder:
        (context) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
            vertical: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'DETAILED BREAKDOWN',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 16),
              Container(
                // decoration: BoxDecoration(
                //   color: AppColors.darkCardBG,
                //   borderRadius: BorderRadius.circular(14),
                //   border: Border.all(color: AppColors.darkButtonBorder),
                // ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppText(
                      'The tax amount shown above is calculated without considering any deductions you may be eligible for. This means your actual tax liability could be lower.',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.medium,
                    ),
                    SizedBox(height: 16),
                    AppText(
                      'Why the difference?',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.semiBold,
                    ),
                    SizedBox(height: 8),
                    // Bullet 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '•  ',
                          variant: AppTextVariant.bodyMedium,
                          colorType: AppTextColorType.primary,
                        ),
                        Expanded(
                          child: AppText(
                            'Overview: Shows gross tax payable (before deductions)',
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // Bullet 2
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '•  ',
                          variant: AppTextVariant.bodyMedium,
                          colorType: AppTextColorType.primary,
                        ),
                        Expanded(
                          child: AppText(
                            'Detailed breakdown: Calculated without standard deductions such as the ₹1,25,000 exemption on Long Term Capital Gains (LTCG)',
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    AppText(
                      'What this means for you: Your final tax outgo may be reduced after applying eligible deductions during filing.',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.medium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
  );
}

class _TaxAdvisoryScreenState extends State<TaxAdvisoryScreen> {
  void _onConsultUsTap() {
    AppLogger.info('Consult us tapped', tag: 'TaxAdvisory');
    SpeakToAdvisor.speakToAdvisor();
  }

  String _selectedCategory = "Stocks";
  final TaxAdvisoryService _taxAdvisoryService = TaxAdvisoryService();
  bool _isLoading = true;
  TaxAdvisoryResponse? _taxData;
  String _errorMessage = '';
  // Switch state for: Have you claimed any LTCG for this year?
  final bool _ltcgClaimed = false;

  @override
  void initState() {
    super.initState();
    _fetchTaxAdvisoryData();
  }

  Future<void> _fetchTaxAdvisoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _taxAdvisoryService.getTaxAdvisoryData();

      if (mounted) {
        if (response.statusCode == 200 && response.data != null) {
          AppLogger.info(response.data.toString(), tag: 'TaxAdvisoryScreen');
          setState(() {
            _taxData = response.data!;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_errorMessage)));
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching tax data',
        error: e,
        tag: 'TaxAdvisoryScreen',
      );
      setState(() {
        _errorMessage = 'Failed to load tax data. Please try again.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load tax data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // if (_errorMessage.isNotEmpty) {
    //   return Center(
    //     child: Padding(
    //       padding: const EdgeInsets.all(16.0),
    //       child: Text(
    //         _errorMessage,
    //         textAlign: TextAlign.center,
    //         style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    //       ),
    //     ),
    //   );
    // }

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Icon(
                Icons.chevron_left,
                color:
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
              ),
            ),
            AppText(
              "Tax Advisory",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // spacing: 12,
          children: [
            _buildTaxSummaryCard(
              "SHORT TERM CAPITAL GAINS",
              "Net off Short Term Capital Losses",
              (_taxData?.taxAdvisoryResponseData?.shortterm.gain ?? 0.0).toDouble(),
              (_taxData?.taxAdvisoryResponseData?.shortterm.taxpayable ?? 0.0).toDouble() +
                  0.0,
              (_taxData?.taxAdvisoryResponseData?.shortterm.taxpayable ?? 0.0).toDouble() +
                  0.0,
              Colors.red,
              _taxData?.taxAdvisoryResponseData?.shortterm.taxondebt,
              _taxData?.taxAdvisoryResponseData?.shortterm.debttaxrate,
              _taxData?.taxAdvisoryResponseData?.shortterm.taxonequity,
              _taxData?.taxAdvisoryResponseData?.shortterm.equitytaxrate,
            ),
            const SizedBox(height: 12),
            _buildTaxSummaryCard(
              "LONG TERM CAPITAL GAINS",
              "Net off Long Term Capital Losses",
              (_taxData?.taxAdvisoryResponseData?.longterm.gain ?? 0.0).toDouble(),
              (_taxData?.taxAdvisoryResponseData?.longterm.taxpayable ?? 0.0).toDouble() +
                  0.0,
              (_taxData?.taxAdvisoryResponseData?.longterm.taxpayable ?? 0.0).toDouble() +
                  0.0,
              Colors.orange,
              _taxData?.taxAdvisoryResponseData?.longterm.taxondebt,
              _taxData?.taxAdvisoryResponseData?.longterm.debttaxrate,
              _taxData?.taxAdvisoryResponseData?.longterm.taxonequity,
              _taxData?.taxAdvisoryResponseData?.longterm.equitytaxrate,
            ),
            const SizedBox(height: 12),
            _buildTaxSummaryCard(
              "TOTAL CAPITAL GAINS",
              null,
              (_taxData?.taxAdvisoryResponseData?.total.gain ?? 0.0).toDouble() ,
              (_taxData?.taxAdvisoryResponseData?.total.taxpayable ?? 0.0).toDouble() ,
              (_taxData?.taxAdvisoryResponseData?.total.taxpayable ?? 0.0).toDouble() ,
              Colors.blue,
              null,
              null,
              _taxData
                  ?.taxAdvisoryResponseData
                  ?.total
                  .breakdown
                  .debt
                  .taxpayable,
              _taxData
                  ?.taxAdvisoryResponseData
                  ?.total
                  .breakdown
                  .equity
                  .taxpayable,
            ),

            const SizedBox(height: 12),
            // Disclaimer note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Please note that these figures are estimates only. ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: InkWell(
                              onTap: () async {
                                SpeakToAdvisor.speakToAdvisor();
                              },
                              child: Text(
                                'Consult us',
                                style: TextStyle(
                                  color: AppColors.linkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(
                            text: ' to determine your accurate tax liability.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tax Optimization Insights
            // CustomAccordion(
            //   title: "Tax Optimization Insights",
            //   initiallyExpanded: true,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _buildInsightItem(
            //         "Harvest Tax Losses:",
            //         "Consider booking losses in underperforming stocks to offset your capital gains and reduce tax liability.",
            //         isDarkMode,
            //       ),
            //       const SizedBox(height: 12),
            //       _buildInsightItem(
            //         "Hold Period Strategy:",
            //         "68% of your gains qualify for short-term tax rates. Consider holding investments for more than 1 year to benefit from reduced tax rates.",
            //         isDarkMode,
            //       ),
            //       const SizedBox(height: 12),
            //       _buildInsightItem(
            //         "Annual Exemptions:",
            //         "₹1,00 up to ₹1,00,000 is tax-free. You've utilized 29% of the exemption limit.",
            //         isDarkMode,
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 12),

            // Detailed Tax Breakdown
            Visibility(
              visible:
                  (_taxData?.taxAdvisoryResponseData?.details ?? []).isNotEmpty,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 4,
                children: [
                  AppText(
                    "Detailed Tax Breakdown",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.semiBold,
                  ),

                  GestureDetector(
                    onTap:
                        () => _showDefaultDetailedBreakdownBottomSheet(context),
                    child: Icon(
                      Icons.info_outline,
                      size: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children:
                  (_taxData?.taxAdvisoryResponseData?.details ?? [])
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: FundBreakdownCard(
                            fundLogo: d.icon,
                            fundName: d.fundname,
                            marketValue: d.marketvalue,
                            investedValue: d.investedvalue,
                            totalGain: d.totalgain,
                            totalGainpct: d.totalgainpct,
                            ltcgValue:
                                ((d.breakdown.ltcg.amount ?? 0) as num)
                                    .toDouble(),
                            stcgValue:
                                ((d.breakdown.stcg.amount ?? 0) as num)
                                    .toDouble(),
                            ltcgTaxPayable:
                                ((d.breakdown.ltcg.taxpayable ?? 0) as num)
                                    .toDouble(),
                            stcgTaxPayable:
                                ((d.breakdown.stcg.taxpayable ?? 0) as num)
                                    .toDouble(),
                            ltcgtaxPayablePercentage:
                                ((d.breakdown.ltcg.taxrate ?? 0) as num)
                                    .toDouble(),
                            stcgtaxPayablePercentage:
                                ((d.breakdown.stcg.taxrate ?? 0) as num)
                                    .toDouble(),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),

            // Category Chips
            // Row(
            //   children: [
            //     _buildCategoryChip("Stocks"),
            //     _buildCategoryChip("Mutual Funds"),
            //     _buildCategoryChip("ETF"),
            //   ],
            // ),

            // Content based on selected category
            // _buildSelectedCategoryContent(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageCard(Color accentColor, double percentage) {
    return AppText(
      "${percentage.toString()}%",
      variant: AppTextVariant.bodySmall,
      weight: AppTextWeight.semiBold,
      customColor: accentColor,
    );
  }

  Widget _buildTaxSummaryCard(
    String title,
    String? description,
    double amount,
    double taxPayable,
    double percentage,
    Color accentColor,
    double? debtTaxRate,
    double? equityTaxRate,
    double? taxOnDebt,
    double? taxOnEquity,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 85,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 4),
                if (description != null)
                  AppText(
                    description,
                    variant: AppTextVariant.tiny,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.secondary,
                  ),
                const SizedBox(height: 4),
                AppText(
                  CurrencyFormatter.formatRupee(amount),
                  variant: AppTextVariant.headline3,
                  weight: AppTextWeight.bold,
                ),
                const SizedBox(height: 4),
                if (taxOnDebt != null)
                  Row(
                    children: [
                      AppText(
                        "Tax Payable on ",
                        weight: AppTextWeight.medium,
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.secondary,
                      ),
                      InkWell(
                        onTap: () {
                         _showTaxadvisoryBottomSheet(context, "DEBT CAPITAL GAINS", "Debt mutual funds are taxed based on the investor's applicable income tax slab rate for gains from investments made on or after April 1, 2023, regardless of the holding period. Since individual tax rates vary, Debt MF gains are generally assumed to be taxed at your highest applicable slab rate. Please consult us for personalized details", _onConsultUsTap, "Consult Us");
                        },
                        child: Row(
                          spacing: 4,
                          children: [
                            AppText(
                              "DEBT STCG",
                              weight: AppTextWeight.medium,
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.primary,
                            ),
                            Icon(
                              Icons.info_outline,
                              color: AppColors.darkTextSecondary,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          spacing: 8,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppText(
                              CurrencyFormatter.formatRupee(taxOnDebt),
                              variant: AppTextVariant.bodyMedium,
                              colorType: AppTextColorType.error,
                              weight: AppTextWeight.bold,
                            ),
                            if (debtTaxRate != null)
                              _buildPercentageCard(Colors.white, debtTaxRate),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (taxOnEquity != null)
                  Row(
                    children: [
                      AppText(
                        "Tax Payable on ",
                        weight: AppTextWeight.medium,
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.secondary,
                      ),
                      AppText(
                        "EQUITY STCG",
                        weight: AppTextWeight.medium,
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.primary,
                      ),
                      Expanded(
                        child: Row(
                          spacing: 8,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppText(
                              CurrencyFormatter.formatRupee(taxOnEquity),
                              variant: AppTextVariant.bodyMedium,
                              colorType: AppTextColorType.error,
                              weight: AppTextWeight.bold,
                            ),
                            if (equityTaxRate != null)
                              _buildPercentageCard(Colors.white, equityTaxRate),
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

  Widget _buildInsightItem(String title, String description, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(3),
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
              AppText(
                description,
                variant: AppTextVariant.bodySmall,
                customColor:
                    isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStocksTab(bool isDarkMode) {
    return Column(
      children: [
        _buildStockItem("Tata Motors", "₹45,220", "₹13,566", "30%", isDarkMode),
        _buildStockItem("Reliance", "₹32,100", "₹9,854", "30%", isDarkMode),
        _buildStockItem("L&T", "₹28,450", "₹8,535", "30%", isDarkMode),
      ],
    );
  }

  Widget _buildMutualFundsTab(bool isDarkMode) {
    return Column(
      children: [
        _buildStockItem(
          "Franklin India Opportunities Fund",
          "₹1,25,400",
          "₹7,540",
          "10%",
          isDarkMode,
        ),
        _buildStockItem(
          "Kotak Emerging Equity Scheme",
          "₹43,650",
          "₹2,346",
          "10%",
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildETFTab(bool isDarkMode) {
    return Column(
      children: [
        _buildStockItem(
          "Motilal Oswal Nifty 50 ETF",
          "₹43,650",
          "₹2,368",
          "5%",
          isDarkMode,
        ),
        _buildStockItem(
          "ICICI Prudential Nifty ETF",
          "₹2,15,680",
          "₹1,568",
          "10%",
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildStockItem(
    String name,
    String amount,
    String taxPayable,
    String percentage,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardBG : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company info row
          Row(
            children: [
              // Company logo/icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppColors.darkPrimary.withValues(alpha: 0.1)
                          : AppColors.darkPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: AppText(
                    name.substring(0, 1).toUpperCase(),
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.bold,
                    customColor: AppColors.darkPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Company name
              Expanded(
                child: AppText(
                  name,
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                  maxLines: 2,
                ),
              ),
              // Percentage badge moved to top right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  percentage,
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.semiBold,
                  customColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // STCG and Tax payable in a single row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "STCG Amount",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      CurrencyFormatter.formatRupee(
                        double.tryParse(
                              amount.replaceAll('₹', '').replaceAll(',', ''),
                            ) ??
                            0,
                      ),
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.bold,
                      colorType: AppTextColorType.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      "Tax Payable",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      CurrencyFormatter.formatRupee(
                        double.tryParse(
                              taxPayable
                                  .replaceAll('₹', '')
                                  .replaceAll(',', ''),
                            ) ??
                            0,
                      ),
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.bold,
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

  Widget _buildCategoryChip(String label) {
    return Row(
      children: [
        CategoryChip(
          label: label,
          isSelected: _selectedCategory == label,
          onTap: () {
            setState(() {
              _selectedCategory = label;
            });
          },
        ),
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildSelectedCategoryContent(bool isDarkMode) {
    switch (_selectedCategory) {
      case "Stocks":
        return _buildStocksTab(isDarkMode);
      case "Mutual Funds":
        return _buildMutualFundsTab(isDarkMode);
      case "ETF":
        return _buildETFTab(isDarkMode);
      default:
        return _buildStocksTab(isDarkMode);
    }
  }
}

class FundBreakdownCard extends StatelessWidget {
  const FundBreakdownCard({
    super.key,
    required this.fundLogo,
    required this.fundName,
    required this.marketValue,
    required this.investedValue,
    required this.totalGain,
    required this.totalGainpct,
    required this.ltcgValue,
    required this.stcgValue,
    required this.ltcgTaxPayable,
    required this.stcgTaxPayable,
    required this.ltcgtaxPayablePercentage,
    required this.stcgtaxPayablePercentage,
  });

  final String fundLogo;
  final String fundName;
  final double marketValue;
  final double investedValue;
  final double totalGain;
  final double totalGainpct;
  final double ltcgValue;
  final double stcgValue;
  final double ltcgTaxPayable;
  final double stcgTaxPayable;
  final double ltcgtaxPayablePercentage;
  final double stcgtaxPayablePercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            spacing: 12,
            children: [
              ClipOval(
                child: Image.network(
                  fundLogo,
                  height: 38,
                  width: 38,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: AppText(
                  fundName,
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                "Market Value",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                weight: AppTextWeight.medium,
              ),
              AppText(
                CurrencyFormatter.formatRupee(marketValue),
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
                weight: AppTextWeight.medium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                "Invested value",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                weight: AppTextWeight.medium,
              ),
              AppText(
                CurrencyFormatter.formatRupee(investedValue.toDouble()),
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
                weight: AppTextWeight.medium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                "Total gain",
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                weight: AppTextWeight.medium,
              ),
              Row(
                children: [
                  AppText(
                    "${totalGain >= 0 ? '+' : ''}${CurrencyFormatter.formatRupee(totalGain.toDouble())}",
                    variant: AppTextVariant.bodyMedium,
                    colorType:
                        totalGain >= 0
                            ? AppTextColorType.success
                            : AppTextColorType.error,
                    weight: AppTextWeight.medium,
                  ),
                  AppText(
                    " (${totalGainpct.toStringAsFixed(2)}%)",
                    variant: AppTextVariant.bodyMedium,
                    colorType:
                        totalGain >= 0
                            ? AppTextColorType.success
                            : AppTextColorType.error,
                    weight: AppTextWeight.medium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LTCG Card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppText(
                            "LTCG",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                            weight: AppTextWeight.semiBold,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      AppText(
                        CurrencyFormatter.formatRupee(ltcgValue.toDouble()),
                        variant: AppTextVariant.headline5,
                        colorType: AppTextColorType.success,
                        weight: AppTextWeight.semiBold,
                      ),

                      AppText(
                        "Tax Payable $ltcgtaxPayablePercentage%",
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.primary,
                        weight: AppTextWeight.semiBold,
                      ),

                      AppText(
                        CurrencyFormatter.formatRupee(
                          ltcgTaxPayable.toDouble(),
                        ),
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.error,
                        weight: AppTextWeight.semiBold,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // STCG Card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppText(
                            "STCG",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                            weight: AppTextWeight.semiBold,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      AppText(
                        CurrencyFormatter.formatRupee(stcgValue.toDouble()),
                        variant: AppTextVariant.headline5,
                        colorType: AppTextColorType.success,
                        weight: AppTextWeight.semiBold,
                      ),

                      AppText(
                        "Tax Payable $stcgtaxPayablePercentage%",
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.primary,
                        weight: AppTextWeight.semiBold,
                      ),

                      AppText(
                        CurrencyFormatter.formatRupee(
                          stcgTaxPayable.toDouble(),
                        ),
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.error,
                        weight: AppTextWeight.semiBold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showTaxadvisoryBottomSheet(
  BuildContext context,
  String title,
  String description,
  Function onPressed,
  String? buttonText,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.darkInputBackground,
    builder:
        (context) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
            vertical: 16,
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
              const SizedBox(height: 24),
              AppText(
                description,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 32),
              buttonText != null ? SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: () => onPressed(),
                  text: buttonText,
                  variant: AppButtonVariant.primary,
                ),
              ) : const SizedBox(),
              SizedBox(height: buttonText != null ? 16 : 0),
            ],
          ),
        ),
  );
}
