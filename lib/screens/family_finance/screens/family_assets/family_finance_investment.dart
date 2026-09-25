import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/widgets/etf_holding_card.dart';
import 'package:nwt_app/screens/assets/investments/widgets/holding_card.dart';
import 'package:nwt_app/screens/assets/investments/widgets/stock_holding_card.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_investments.dart';
import 'package:nwt_app/services/family_finance/assets/family_finance_assets_investments.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/graph_legend.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:shimmer/shimmer.dart';

class FamilyFinanceInvestmentScreen extends StatefulWidget {
  const FamilyFinanceInvestmentScreen({super.key, required this.familyId, this.initialCategory});

  final String familyId;
  final String? initialCategory;

  @override
  State<FamilyFinanceInvestmentScreen> createState() =>
      _FamilyFinanceInvestmentScreenState();
}

const categories = ["Stocks", "Mutual Funds", "ETF", "Commodities", "F&O"];

class _FamilyFinanceInvestmentScreenState
    extends State<FamilyFinanceInvestmentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isAmountVisible = true;
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  bool showFullHeader = true;
  bool isPortfolioLoading = true;
  bool isHoldingLoading = true;
  late AnimationController _refreshController;
  late String _selectedCategory;

  // Family Finance Investments
  final FamilyFinanceAssetsInvestmentsService _investmentsService =
      FamilyFinanceAssetsInvestmentsService();
  FamilyFinanceInvestmentsResponse? _familyInvestmentsResponse;
  bool _isFamilyInvestmentsLoading = false;
  String? _errorMessage;

  AppBar _buildAppbar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: const Icon(Icons.chevron_left, size: 32),
      ),
      centerTitle: true,
      title: AppText(
        "Family Investments",
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
      ),
    );
  }

  Widget _buildHeader(
    FamilyFinanceInvestmentsSummary? portfolio,
    Function onRefresh,
  ) {
    return Container(
      color: AppColors.darkBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkButtonBorder),
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Total balance",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.secondary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AnimatedAmount(
                            isAmountVisible: _isAmountVisible,
                            amount: CurrencyFormatter.formatRupee(
                              _calculateTotalBalance(portfolio),
                            ),
                            style: TextStyle(
                              fontSize: 36.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAmountVisible = !_isAmountVisible;
                              });
                            },
                            child: Icon(
                              Icons.visibility_outlined,
                              color:
                                  _isAmountVisible
                                      ? AppColors.darkPrimary
                                      : AppColors.darkTextMuted,
                              size: 22.sp,
                            ),
                          ),
                        ],
                      ),
                      AppText(
                        "No data fetched yet",
                        variant: AppTextVariant.tiny,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.secondary,
                      ),
                    ],
                  ),
                  // SizedBox(height: 4),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 8,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.success.withValues(alpha: 0.1),
                  //     borderRadius: BorderRadius.circular(6),
                  //   ),
                  //   child: AppText(
                  //     _isAmountVisible
                  //         ? "+ ${CurrencyFormatter.formatRupee(_calculateGain(portfolio))} (${_calculateGainPercentage(portfolio).toStringAsFixed(2)}%)"
                  //         : '•••••',
                  //     variant: AppTextVariant.bodySmall,
                  //     weight: AppTextWeight.medium,
                  //     colorType: AppTextColorType.success,
                  //   ),
                  // ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 8,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Get total investment value from summary
                        final double totalInvestment = _calculateTotalBalance(
                          portfolio,
                        );

                        // Calculate percentages for each investment type
                        final double equityPercentage =
                            totalInvestment > 0
                                ? (portfolio?.equity.totalsum ?? 0) /
                                    totalInvestment *
                                    100
                                : 0;

                        final double mfPercentage =
                            totalInvestment > 0
                                ? (portfolio?.mutualFunds.totalsum ?? 0) /
                                    totalInvestment *
                                    100
                                : 0;

                        final double etfPercentage =
                            totalInvestment > 0
                                ? (portfolio?.etf.totalsum ?? 0) /
                                    totalInvestment *
                                    100
                                : 0;

                        // Minimum flex value to ensure visibility
                        final int minFlex = 1;

                        // Calculate flex values for the graph
                        final int stocksFlex =
                            equityPercentage > 0
                                ? math.max(equityPercentage.round(), minFlex)
                                : 0;

                        final int mfFlex =
                            mfPercentage > 0
                                ? math.max(mfPercentage.round(), minFlex)
                                : 0;

                        final int etfFlex =
                            etfPercentage > 0
                                ? math.max(etfPercentage.round(), minFlex)
                                : 0;

                        // Log detailed data for debugging
                        AppLogger.info(
                          "Investment Graph Data:\n"
                          "Total Investment: ₹${totalInvestment.toStringAsFixed(2)}\n"
                          "Equity: ₹${(portfolio?.equity.totalsum ?? 0).toStringAsFixed(2)} (${equityPercentage.toStringAsFixed(2)}%)\n"
                          "Mutual Funds: ₹${(portfolio?.mutualFunds.totalsum ?? 0).toStringAsFixed(2)} (${mfPercentage.toStringAsFixed(2)}%)\n"
                          "ETF: ₹${(portfolio?.etf.totalsum ?? 0).toStringAsFixed(2)} (${etfPercentage.toStringAsFixed(2)}%)\n"
                          "Flex values - Stocks: $stocksFlex, MF: $mfFlex, ETF: $etfFlex",
                        );

                        // Check which segments should be visible
                        final bool hasStocks = stocksFlex > 0;
                        final bool hasMF = mfFlex > 0;
                        final bool hasETF = etfFlex > 0;

                        return Row(
                          children: [
                            // Equity/Stocks segment
                            if (hasStocks)
                              Expanded(
                                flex: stocksFlex,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: hasMF || hasETF ? 1 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(8),
                                      right:
                                          !(hasMF || hasETF)
                                              ? Radius.circular(8)
                                              : Radius.zero,
                                    ),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFC172FF),
                                        Color(0xFF993A3A),
                                      ],
                                    ),
                                  ),
                                  height: 8,
                                ),
                              ),

                            // Mutual Funds segment
                            if (hasMF)
                              Expanded(
                                flex: mfFlex,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: hasStocks ? 1 : 0,
                                    right: hasETF ? 1 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.horizontal(
                                      left:
                                          !hasStocks
                                              ? Radius.circular(8)
                                              : Radius.zero,
                                      right:
                                          !hasETF
                                              ? Radius.circular(8)
                                              : Radius.zero,
                                    ),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6393),
                                        Color(0xFFBD1448),
                                      ],
                                    ),
                                  ),
                                  height: 8,
                                ),
                              ),

                            // ETF segment
                            if (hasETF)
                              Expanded(
                                flex: etfFlex,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: hasStocks || hasMF ? 1 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.horizontal(
                                      left:
                                          !(hasStocks || hasMF)
                                              ? Radius.circular(8)
                                              : Radius.zero,
                                      right: Radius.circular(8),
                                    ),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFCA63),
                                        Color(0xFFFF8F6E),
                                      ],
                                    ),
                                  ),
                                  height: 8,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      CategoryLegend(
                        category: "Equity",
                        color: Color(0xFFC172FF),
                      ),
                      CategoryLegend(
                        category: "Mutual Funds",
                        color: Color(0xFFFF6393),
                      ),
                      CategoryLegend(category: "ETF", color: Color(0xFFFFCA63)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkButtonBorder,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    child: Column(
                      spacing: 6,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "Invested",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                            SizedBox(height: 3),
                            AnimatedAmount(
                              amount: CurrencyFormatter.formatRupee(
                                _calculateTotalInvested(portfolio),
                              ),
                              isAmountVisible: _isAmountVisible,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "Gain",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                              colorType: AppTextColorType.primary,
                            ),
                            SizedBox(height: 3),
                            AnimatedAmount(
                              amount: CurrencyFormatter.formatRupee(
                                _calculateGain(portfolio),
                              ),
                              isAmountVisible: _isAmountVisible,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    _calculateGain(portfolio) >= 0
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          SpeakToAdvisor.speakToAdvisor();
                        },
                        child: AppText(
                          "Speak to advisor for Investment advise",
                          variant: AppTextVariant.bodyMedium,
                          colorType: AppTextColorType.link,
                          weight: AppTextWeight.medium,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.linkColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Stocks';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start the initial animation
    _animationController.forward();
    fetchPortfolio();
    fetchFamilyInvestments();
  }

  // Fetch family investments data using the service
  Future<void> fetchFamilyInvestments() async {
    setState(() {
      _isFamilyInvestmentsLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _investmentsService
          .getFamilyFinanceAssetsInvestments(
            familyId: widget.familyId,
            onLoading: (isLoading) {
              setState(() {
                _isFamilyInvestmentsLoading = isLoading;
              });
            },
          );

      AppLogger.info(
        "Family investments response status: ${response.statusCode}",
      );
      if (response.data != null) {
        AppLogger.info("Members count: ${response.data!.members.length}");
        for (var member in response.data!.members) {
          AppLogger.info("Member: ${member.firstname} ${member.lastname}");
          AppLogger.info("Equity count: ${member.assets.equity.data.length}");
          AppLogger.info(
            "Mutual Funds count: ${member.assets.mutualFunds.data.length}",
          );
          AppLogger.info("ETF count: ${member.assets.etf.data.length}");
        }
      }

      setState(() {
        _familyInvestmentsResponse = response;
        if (response.statusCode != 200 && response.statusCode != 201) {
          _errorMessage = response.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load family investments: ${e.toString()}';
        _isFamilyInvestmentsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> fetchPortfolio() async {
    setState(() {
      isPortfolioLoading = true;
      isHoldingLoading = true;
    });

    try {
      _refreshController.reset();
      _refreshController.repeat();
      // code here
      _refreshController.stop();
    } catch (e) {
      if (mounted) {
        setState(() {
          isPortfolioLoading = false;
          isHoldingLoading = false;
          _errorMessage = 'Failed to load portfolio data: ${e.toString()}';
        });
        _refreshController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppbar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchPortfolio();
            await fetchFamilyInvestments();
          },
          color: AppColors.darkPrimary,
          backgroundColor: AppColors.darkCardBG,
          displacement: 20.0,
          strokeWidth: 3.0,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Show error message if any
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding,
                      vertical: 8,
                    ),
                    child: AnimatedErrorMessage(errorMessage: _errorMessage!),
                  ),

                _buildHeader(_familyInvestmentsResponse?.data?.summary, () {
                  fetchPortfolio();
                  fetchFamilyInvestments();
                }),

                // Category filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: AppSizing.scaffoldHorizontalPadding,
                        ),
                        ...categories.map(
                          (category) => _buildCategoryChip(category),
                        ),
                        const SizedBox(
                          width: AppSizing.scaffoldHorizontalPadding,
                        ),
                      ],
                    ),
                  ),
                ),

                // Family Finance Investments section
                _buildFamilyInvestmentsSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(text: "Add Investments", onPressed: () {}),
        ),
      ),
    );
  }

  // Build the family investments section with CustomAccordion
  Widget _buildFamilyInvestmentsSection() {
    if (_isFamilyInvestmentsLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
          vertical: 8,
        ),
        child: _buildShimmerInvestmentCard(),
      );
    }

    if (_familyInvestmentsResponse?.data == null) {
      return const SizedBox.shrink();
    }

    final data = _familyInvestmentsResponse!.data!;

    // Filter members who have investments of the selected category
    final filteredMembers =
        data.members.where((member) {
          AppLogger.info(
            "Member: ${member.firstname} ${member.lastname}, Equity count: ${member.assets.equity.data.length}",
          );
          // Only show members with investments based on the selected category
          switch (_selectedCategory) {
            case 'Stocks':
              return member.assets.equity.data.isNotEmpty;
            case 'Mutual Funds':
              return member.assets.mutualFunds.data.isNotEmpty;
            case 'ETF':
              return member.assets.etf.data.isNotEmpty;
            default: // 'All'
              return member.assets.equity.data.isNotEmpty ||
                  member.assets.mutualFunds.data.isNotEmpty ||
                  member.assets.etf.data.isNotEmpty;
          }
        }).toList();

    if (filteredMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
          vertical: 16,
        ),
        child: _buildNoHoldingsMessage(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      child: Column(
        children: [
          // Family members investments
          ...filteredMembers.map(
            (member) => _buildMemberInvestmentsAccordion(member),
          ),
        ],
      ),
    );
  }

  // Build accordion for each family member's investments
  Widget _buildMemberInvestmentsAccordion(
    FamilyFinanceInvestmentsMember member,
  ) {
    AppLogger.info(
      "Building accordion for ${member.firstname} ${member.lastname}",
    );
    AppLogger.info("Equity data count: ${member.assets.equity.data.length}");

    return CustomAccordion(
      title: "${member.firstname} ${member.lastname}",
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show only the selected category or all categories if 'All' is selected
          if (_selectedCategory == 'All' || _selectedCategory == 'Stocks')
            if (member.assets.equity.data.isNotEmpty)
              _buildInvestmentTypeSection("Stocks", member.assets.equity),

          if (_selectedCategory == 'All' || _selectedCategory == 'Mutual Funds')
            if (member.assets.mutualFunds.data.isNotEmpty)
              _buildInvestmentTypeSection(
                "Mutual Funds",
                member.assets.mutualFunds,
              ),

          if (_selectedCategory == 'All' || _selectedCategory == 'ETF')
            if (member.assets.etf.data.isNotEmpty)
              _buildInvestmentTypeSection("ETF", member.assets.etf),
        ],
      ),
    );
  }

  // Build section for each investment type (Equity, Mutual Funds, ETF)
  Widget _buildInvestmentTypeSection(String title, dynamic investmentData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((title == "Equity" || title == "Stocks") &&
            investmentData is FamilyFinanceInvestmentsEquity)
          _buildEquityItems(investmentData),
        if (title == "Mutual Funds" &&
            investmentData is FamilyFinanceInvestmentsMutualFunds)
          _buildMutualFundsItems(investmentData),
        if (title == "ETF" && investmentData is FamilyFinanceInvestmentsEtf)
          _buildEtfItems(investmentData),
      ],
    );
  }

  // Build equity investment items
  Widget _buildEquityItems(FamilyFinanceInvestmentsEquity equity) {
    AppLogger.info("LENGTH_OF_EQUITY ${equity.data.length}");
    AppLogger.info("Equity name: ${equity.name}");
    AppLogger.info("Equity summary: ${equity.summary.totalsum}");

    if (equity.data.isEmpty) {
      AppLogger.info("No equity data found");
      return const SizedBox.shrink();
    }

    return Column(
      children:
          equity.data.map((item) {
            AppLogger.info("Building equity item: ${item.name}");
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: StockHoldingCard(
                isAmountVisible: _isAmountVisible,
                fundName: item.name,
                costValue: item.costvalue ?? 0.0,
                currentAmount: item.currentmktvalue,
                gainloss: item.gainloss ?? 0.0,
                gainlosspercentage: item.gainlosspercentage ?? 0.0,
                quantity: item.quantity ?? 0.0,
                rate: item.rate,
                buydate: item.buydate,
                delta: item.delta,
                deltaValue: item.deltaValue,
                averageholdingprice: item.averageholdingprice,
                navdate: item.navdate,
                icon: item.icon,
                xirr: item.xirr,
              ),
            );
          }).toList(),
    );
  }

  // Build mutual funds investment items
  Widget _buildMutualFundsItems(
    FamilyFinanceInvestmentsMutualFunds mutualFunds,
  ) {
    return Column(
      children:
          mutualFunds.data.map((item) {
            // Calculate gain percentage if not available
            double gainPercentage = 0.0;
            if (item.costvalue != null &&
                item.costvalue != 0 &&
                item.gainloss != null) {
              double costValue = (item.costvalue ?? 0).toDouble();
              double gainLoss = (item.gainloss ?? 0).toDouble();
              gainPercentage = (gainLoss / costValue) * 100;
            }

            // Create a dummy Mf object from FamilyFinanceInvestmentsMutualFundsDatum
            final dummyMf = Mf(
              isin: item.isin,
              id: 0,
              logo: '',
              createdat: DateTime.now(),
              userguid: '',
              activestate: true,
              reqid: '',
              amc: '',
              amcname: '',
              taxstatus: '',
              modeofholding: '',
              transactionsource: '',
              name: item.name,
              idcwchangeallowed: false,
              schemeoption: '',
              schemetype: '',
              nav: item.nav,
              closingbalance: 0.0,
              currentmktvalue: item.currentmktvalue ?? 0.0,
              costvalue: item.costvalue?.toDouble() ?? 0.0,
              gainloss: item.gainloss?.toDouble() ?? 0.0,
              gainlosspercentage: gainPercentage,
              decimalunits: 0.0,
              decimalamount: 0.0,
              decimalnav: 0.0,
              brokercode: '',
              brokername: '',
              planmode: '',
              nomineestatus: 'N',
              investorname: '',
              guid: '',
              quantity: 0.0,
              folio: '',
              phonenumber: '',
              email: '',
              availableunits: 0.0,
              validpan: false,
              kycstatus: '',
              rtaname: '',
              mfsummaryguid: '',
              cagrvalue: 0.0,
              investoremail: '',
              investordataguid: '',
              deltavalue: 0.0,
              deltapercentage: 0.0,
              type: Type.MF,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: HoldingCard(
                mf: dummyMf,
                isAmountVisible: _isAmountVisible,
                icon: Icons.account_balance_outlined,
              ),
            );
          }).toList(),
    );
  }

  // Build ETF investment items
  Widget _buildEtfItems(FamilyFinanceInvestmentsEtf etf) {
    return Column(
      children:
          etf.data.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: EtfHoldingCard(
                isAmountVisible: _isAmountVisible,
                fundName: item.name,
                nav: item.nav,
                units: item.units,
                currentMarketValue: item.currentmktvalue,
                folioNo: item.foliono != null ? item.foliono.toString() : 'N/A',
                icon: Icons.bar_chart_rounded,
              ),
            );
          }).toList(),
    );
  }

  // Calculate total balance from mutual funds, equity, and ETF
  double _calculateTotalBalance(FamilyFinanceInvestmentsSummary? portfolio) {
    if (portfolio == null) return 0;

    // Use totalsum property which represents the total current market value
    double mutualFundsTotal = portfolio.mutualFunds.totalsum;
    double equityTotal = portfolio.equity.totalsum;
    double etfTotal = portfolio.etf.totalsum;

    AppLogger.info(
      "Total Balance: MF=$mutualFundsTotal, Equity=$equityTotal, ETF=$etfTotal",
    );
    return mutualFundsTotal + equityTotal + etfTotal;
  }

  double _calculateTotalInvested(FamilyFinanceInvestmentsSummary? portfolio) {
    if (portfolio == null) return 0;

    // Calculate total invested amount across all investment types
    double mutualFundsInvested = portfolio.mutualFunds.totalinvested;
    double equityInvested = portfolio.equity.totalinvested;
    // ETF doesn't have totalinvested directly, so we estimate using units and average current value
    double etfInvested =
        portfolio.etf.totalunits * portfolio.etf.avgcurrentvalue;

    double totalInvested = mutualFundsInvested + equityInvested + etfInvested;

    AppLogger.info(
      "Total Invested Calculation:\n"
      "Mutual Funds Invested: ₹${mutualFundsInvested.toStringAsFixed(2)}\n"
      "Equity Invested: ₹${equityInvested.toStringAsFixed(2)}\n"
      "ETF Invested: ₹${etfInvested.toStringAsFixed(2)}\n"
      "Total Invested: ₹${totalInvested.toStringAsFixed(2)}",
    );
    return totalInvested;
  }

  // Calculate total gain from investments
  double _calculateGain(FamilyFinanceInvestmentsSummary? portfolio) {
    if (portfolio == null) return 0;

    double mutualFundsGain = portfolio.mutualFunds.totalgain;
    double equityGain = portfolio.equity.totalgain;
    // ETF doesn't have a totalgain property, so we estimate it
    double etfGain =
        portfolio.etf.totalsum -
        (portfolio.etf.avgcurrentvalue * portfolio.etf.totalunits);

    double totalGain = mutualFundsGain + equityGain + etfGain;

    AppLogger.info(
      "Gain Calculation:\n"
      "Mutual Funds Gain: ₹${mutualFundsGain.toStringAsFixed(2)}\n"
      "Equity Gain: ₹${equityGain.toStringAsFixed(2)}\n"
      "ETF Gain: ₹${etfGain.toStringAsFixed(2)}\n"
      "Total Gain: ₹${totalGain.toStringAsFixed(2)}",
    );

    return totalGain;
  }

  // Calculate gain percentage
  double _calculateGainPercentage(FamilyFinanceInvestmentsSummary? portfolio) {
    if (portfolio == null) return 0;

    double totalInvested = _calculateTotalInvested(portfolio);
    double totalGain = _calculateGain(portfolio);

    if (totalInvested <= 0) return 0;

    double gainPercentage = (totalGain / totalInvested) * 100;

    AppLogger.info(
      "Gain Percentage Calculation:\n"
      "Total Invested: ₹${totalInvested.toStringAsFixed(2)}\n"
      "Total Gain: ₹${totalGain.toStringAsFixed(2)}\n"
      "Gain Percentage: ${gainPercentage.toStringAsFixed(2)}%",
    );

    return gainPercentage;
  }

  // Build shimmer placeholders for investment cards
  Widget _buildShimmerInvestmentCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNoHoldingsMessage() {
    // Don't show shimmers here since we're already showing them in the main list
    if (isHoldingLoading) {
      return const Center(
        child: SizedBox(), // Empty widget when loading
      );
    }

    final bool isAllCategory = _selectedCategory == 'All';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Modern illustration container with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkPrimary.withOpacity(0.1),
                  AppColors.darkPrimary.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isAllCategory
                    ? Icons.account_balance_wallet_outlined
                    : Icons.category_outlined,
                size: 56,
                color: AppColors.darkPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title with accent color
          AppText(
            isAllCategory
                ? 'No investments yet'
                : 'No ${_selectedCategory.toLowerCase()} found',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 12),
          // Description with better formatting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: AppText(
              isAllCategory
                  ? 'Start your investment journey by adding your first investment.'
                  : 'Try selecting a different category or add a new ${_selectedCategory.toLowerCase()} investment.',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.secondary,
              textAlign: TextAlign.center,
            ),
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
}
