import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/insights/types/insights.dart';
import 'package:nwt_app/screens/insights/widgets/insights.dart';
import 'package:nwt_app/screens/insights/widgets/signals.dart';
import 'package:nwt_app/services/insights/insights.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/screens/orders/redeem_order_v1_screen.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/screens/orders/types/order_v1.dart';
import 'package:nwt_app/screens/bse_star_v2/start_journey.dart';

enum InsightsTab { insights, score }

class InsightsScreen extends StatefulWidget {
  final String isincode;

  const InsightsScreen({super.key, required this.isincode});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightsService _insightsService = InsightsService();
  final UserController _userController = Get.find<UserController>();
  bool _isLoading = true;
  InsightsSummary? _insightData;
  String? _error;
  InsightsTab _selectedTab = InsightsTab.insights;
  String _selectedPeriod = '3M';
  bool _showAbsoluteReturns = false; // Default to show annualized returns
  final OrderV1Controller _orderV1Controller =
      Get.isRegistered<OrderV1Controller>()
          ? Get.find<OrderV1Controller>()
          : Get.put(OrderV1Controller());
  bool _isUccLoading = false;

  // Performance Score state
  bool _isPerformanceLoading = false;
  PerformanceScoreResponse? _performanceData;
  String? _performanceError;

  // Method to get initials from fund name
  String _getInitials(String fundName) {
    final words = fundName.trim().split(' ');
    if (words.isEmpty) return 'MF';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return words
        .take(1)
        .map((word) => word.substring(0, 1).toUpperCase())
        .join();
  }

  // Method to get return value based on selected period and return type (absolute or annualized)
  double _getReturnValueForPeriod(String period) {
    if (_insightData?.returns == null) return 0.0;

    switch (period) {
      case '3M':
        return _showAbsoluteReturns
            ? _insightData!.returns.threeMonths.absolute
            : _insightData!.returns.threeMonths.annualized;
      case '6M':
        return _showAbsoluteReturns
            ? _insightData!.returns.sixMonths.absolute
            : _insightData!.returns.sixMonths.annualized;
      case '1Y':
        return _showAbsoluteReturns
            ? _insightData!.returns.oneYear.absolute
            : _insightData!.returns.oneYear.annualized;
      case '3Y':
        return _showAbsoluteReturns
            ? _insightData!.returns.threeYears.absolute
            : _insightData!.returns.threeYears.annualized;
      case '5Y':
        return _showAbsoluteReturns
            ? _insightData!.returns.fiveYears.absolute
            : _insightData!.returns.fiveYears.annualized;
      case 'MAX':
        return _showAbsoluteReturns
            ? _insightData!.returns.all.absolute
            : _insightData!.returns.all.annualized;
      default:
        return _showAbsoluteReturns
            ? _insightData!.returns.threeMonths.absolute
            : _insightData!.returns.threeMonths.annualized;
    }
  }

  // Method to get return label based on selected period and return type
  String _getReturnLabel(String period) {
    String returnType = _showAbsoluteReturns ? 'Return' : 'Annualized Return';
    return '$period $returnType';
  }

  // Callback to handle period selection
  void _onPeriodSelected(String period) {
    // Defer the setState call until after the current build phase is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedPeriod = period;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchInsightsData();
    // _fetchUccStatus(); // Skip legacy UCC check
  }

  Future<void> _fetchUccStatus() async {
    // Legacy fetch neutralised in favor of OrderV1 accounts
  }

  Future<void> _fetchPerformanceScore() async {
    if (_isPerformanceLoading || _performanceData != null) return;

    setState(() {
      _isPerformanceLoading = true;
      _performanceError = null;
    });

    try {
      final response = await _insightsService.getPerformanceScore(
        isincode: widget.isincode,
        onLoading: (isLoading) {
          // Loading state is handled by _isPerformanceLoading
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _performanceData = response;
          _isPerformanceLoading = false;
        });
      } else {
        setState(() {
          _performanceError =
              response.message.isNotEmpty
                  ? response.message
                  : 'Failed to load performance score data';
          _isPerformanceLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _performanceError = 'Error loading performance data: $e';
        _isPerformanceLoading = false;
      });
    }
  }

  final InvestmentController investmentController = Get.put(
    InvestmentController(),
  );
  Mf? holdingCurrentMF;

  Future<void> _fetchInsightsData() async {
    print(widget.isincode);
    // If no fund ID is provided, fetch general insights
    final response = await _insightsService.getMFInsights(
      isincode: widget.isincode,
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
          });
        }
      },
    );
    // Skip legacy holdings call until V1 equivalent is ready
    // final holdingsResponse = await investmentController.getHoldings(
    //   onLoading: (isLoading) {
    //     if (mounted) {
    //       setState(() {
    //         _isLoading = isLoading;
    //       });
    //     }
    //   },
    // );
    // final onlyMFHoldings = holdingsResponse.data?.investments.mf ?? [];
    // final etfHoldings = holdingsResponse.data?.investments.etf ?? [];
    final onlyMFHoldings = [];
    final etfHoldings = [];

    Mf? foundHolding;
    final String targetIsin = widget.isincode;

    // First search in Mutual Funds
    final mfMatch = onlyMFHoldings.where((mf) => mf.isin == targetIsin);
    if (mfMatch.isNotEmpty) {
      foundHolding = mfMatch.first;
    } else {
      // If not found, search in ETFs
      final etfMatch = etfHoldings.where((etf) => etf.isin == targetIsin);
      if (etfMatch.isNotEmpty) {
        final etf = etfMatch.first;
        // Map Etf to Mf structure so the downstream widgets can display it
        foundHolding = Mf.fromJson({
          'isin': etf.isin,
          'name': etf.name,
          'units': etf.units,
          'currentvalue': etf.currentMarketValue,
          'nav': etf.nav,
          'foliono': etf.foliono,
          'investedamount': etf.investedvalue,
          'gainloss': etf.gainloss,
          'gainlosspercentage': etf.gainlosspercentage,
        });
      }
    }

    if (mounted) {
      setState(() {
        holdingCurrentMF = foundHolding;
        if (holdingCurrentMF != null) {
          AppLogger.info(
            "Current_Holding found: ${holdingCurrentMF?.name} (${holdingCurrentMF?.isin})",
          );
        }
      });
    }
    if (response.data != null) {
      if (mounted) {
        setState(() {
          _insightData = response.data;
        });
      }
    } else {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _checkUccStatusAndProceed(
    BuildContext context, {
    required bool isSell,
  }) async {
    if (_orderV1Controller.isLoadingAccounts.value) {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );
      while (_orderV1Controller.isLoadingAccounts.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      Get.back();
    }

    // Refresh accounts if list is empty
    if (_orderV1Controller.accounts.isEmpty &&
        !_orderV1Controller.isLoadingAccounts.value) {
      await _orderV1Controller.fetchAccounts();
    }

    final accounts = _orderV1Controller.accounts;

    // Set first account as default if none selected
    if (_orderV1Controller.selectedAccount.value == null &&
        accounts.isNotEmpty) {
      _orderV1Controller.selectedAccount.value = accounts.first;
    }

    if (isSell) {
      Get.to(
        () => RedeemOrderV1Screen(
          fundName: _insightData?.fundname ?? "",
          isin: widget.isincode,
          schemeCode: _insightData?.schemeCode ?? "",
          nav: _insightData?.nav,
          fundLogo: _insightData?.icon,
        ),
      );
    } else {
      Get.to(
        () => CreateOrderV1Screen(
          fundName: _insightData?.fundname ?? "",
          isin: widget.isincode,
          schemeCode: _insightData?.schemeCode ?? "",
          nav: _insightData?.nav,
          fundLogo: _insightData?.icon,
          minAmount: _insightData?.sipdetail.minimumlumpsum,
        ),
      );
    }
  }

  void _showAlert(BuildContext context, String message) {
    bool isUccError =
        message.contains('investment account') ||
        message.contains('registration');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.darkCardBG,
            title: AppText(
              'Alert',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
            ),
            content: AppText(message, variant: AppTextVariant.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText(
                  'OK',
                  variant: AppTextVariant.bodyMedium,
                  customColor: AppColors.darkPrimary,
                ),
              ),
              if (isUccError)
                TextButton(
                  onPressed: () {
                    _userController.clearUccCache();
                    Navigator.pop(context);
                    Get.to(
                      () => const BSEStartjourney(),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: AppText(
                    'Complete Registration',
                    variant: AppTextVariant.bodyMedium,
                    customColor: AppColors.darkPrimary,
                  ),
                ),
            ],
          ),
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
              "Insights",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          ],
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                        ),
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(80 / 2),
                                border: Border.all(
                                  width: 1,
                                  color: AppColors.error.withValues(alpha: 0.5),
                                ),
                              ),
                              height: 80,
                              width: 80,

                              child: Icon(Icons.close_rounded),
                            ),
                            SizedBox(height: 8),
                            AppText(
                              _error!,
                              variant: AppTextVariant.headline4,
                              weight: AppTextWeight.medium,
                            ),
                          ],
                        ),
                        const Spacer(),
                        AppButton(
                          text: "Retry",
                          onPressed: _fetchInsightsData,
                          isFullWidth: true,
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      // Container(
                      //   height: 48,
                      //   margin: const EdgeInsets.only(bottom: 16),
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFF1E1E1E),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Stack(
                      //     children: [
                      //       // Segmented control background
                      //       Row(
                      //         children: [
                      //           // Insights Tab
                      //           Expanded(
                      //             child: GestureDetector(
                      //               onTap: () {
                      //                 // Handle tab change
                      //                 setState(() {
                      //                   _selectedTab = InsightsTab.insights;
                      //                 });
                      //               },
                      //               child: Container(
                      //                 height: 48,
                      //                 decoration: BoxDecoration(
                      //                   color:
                      //                       _selectedTab == InsightsTab.insights
                      //                           ? Colors.white
                      //                           : Colors.transparent,
                      //                   borderRadius: BorderRadius.circular(12),
                      //                 ),
                      //                 alignment: Alignment.center,
                      //                 child: AppText(
                      //                   'Insights',
                      //                   variant: AppTextVariant.bodyMedium,
                      //                   weight: AppTextWeight.semiBold,
                      //                   colorType:
                      //                       _selectedTab != InsightsTab.insights
                      //                           ? AppTextColorType.primary
                      //                           : AppTextColorType.tertiary,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //           // Score Tab
                      //           Expanded(
                      //             child: GestureDetector(
                      //               onTap: () {
                      //                 // Handle tab change
                      //                 setState(() {
                      //                   _selectedTab = InsightsTab.score;
                      //                 });
                      //               },
                      //               child: Container(
                      //                 height: 48,
                      //                 decoration: BoxDecoration(
                      //                   color:
                      //                       _selectedTab == InsightsTab.score
                      //                           ? Colors.white
                      //                           : Colors.transparent,
                      //                   borderRadius: BorderRadius.circular(12),
                      //                 ),
                      //                 alignment: Alignment.center,
                      //                 child: Row(
                      //                   mainAxisAlignment:
                      //                       MainAxisAlignment.center,
                      //                   children: [
                      //                     AppText(
                      //                       'Score',
                      //                       variant: AppTextVariant.bodyMedium,
                      //                       weight: AppTextWeight.semiBold,
                      //                       colorType:
                      //                           _selectedTab !=
                      //                                   InsightsTab.score
                      //                               ? AppTextColorType.primary
                      //                               : AppTextColorType.tertiary,
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      _buildHeader(),

                      if (_selectedTab == InsightsTab.insights)
                        MutualFundsInsightWidget(
                          holding: holdingCurrentMF,
                          insightData: _insightData,
                          onPeriodSelected: _onPeriodSelected,
                          isin: widget.isincode,
                          showAbsoluteReturns: _showAbsoluteReturns,
                          selectedPeriod: _selectedPeriod,
                        )
                      else
                        Builder(
                          builder: (context) {
                            // Fetch performance score data when score tab is selected
                            if (_selectedTab == InsightsTab.score &&
                                _performanceData == null &&
                                !_isPerformanceLoading &&
                                _performanceError == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _fetchPerformanceScore();
                              });
                            }

                            return MutualFundsSignalsScreen(
                              investedAmount:
                                  holdingCurrentMF?.costvalue ?? 0.0,
                              currentValue:
                                  holdingCurrentMF?.currentmktvalue ?? 0.0,
                              sebicategoryname:
                                  _insightData?.sebicategoryname ?? '',
                              performanceData: _performanceData,
                              isLoading: _isPerformanceLoading,
                              aum: _insightData?.funddetail.aum,
                              nav: _insightData?.nav ?? 0.0,
                              expenseratio:
                                  _insightData?.funddetail.expenseratio ?? 0.0,
                              totalreturns:
                                  _showAbsoluteReturns
                                      ? _insightData!.returns.all.absolute
                                      : _insightData!.returns.all.annualized,
                              showAbsoluteReturns: _showAbsoluteReturns,
                              currentRank: _insightData?.categoryrank,
                              totalFunds: _insightData?.categorytotal,
                            );
                          },
                        ),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar:
          _isLoading || _insightData == null
              ? null
              : SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkButtonBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AnimatedErrorMessage(errorMessage: ""),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Sell',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed:
                                  () => _checkUccStatusAndProceed(
                                    context,
                                    isSell: true,
                                  ),
                              customPadding: EdgeInsets.symmetric(
                                vertical: 14.h,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: AppButton(
                              text: 'Invest',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed:
                                  () => _checkUccStatusAndProceed(
                                    context,
                                    isSell: false,
                                  ),
                              customPadding: EdgeInsets.symmetric(
                                vertical: 14.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fund name with icon
              Row(
                children: [
                  // Fund icon/avatar
                  _insightData!.icon != null && _insightData!.icon!.isNotEmpty
                      ? Avatar(
                        path: _insightData!.icon ?? "",
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(8),
                        errorWidget: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.darkCardBG,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(_insightData!.fundname),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                        ),
                      )
                      : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_insightData!.fundname),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(width: 12),
                  // Fund name taking remaining width
                  Expanded(
                    child: AppText(
                      _insightData!.fundname,
                      variant: AppTextVariant.headline4,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.semiBold,
                      lineHeight: 1.2,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Fund type and category
              Row(
                children: [
                  AppText(
                    "${_insightData!.riskometer.name} Risk",
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                    weight: AppTextWeight.regular,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppText(
                    _insightData!.fundtype,
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                    weight: AppTextWeight.regular,
                  ),
                ],
              ),
              if (_selectedTab == InsightsTab.score) const SizedBox(height: 12),
              // Return percentage in large format with toggle switch
              if (_selectedTab == InsightsTab.insights)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side - NAV and 1D return
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.formatRupeeWithCommas(
                            _insightData!.nav,
                          ),
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            AppText(
                              "${_insightData!.returns.oneDay.absolute.toString()}%",
                              variant: AppTextVariant.bodySmall,
                              colorType:
                                  _insightData!.returns.oneDay.absolute > 0
                                      ? AppTextColorType.success
                                      : AppTextColorType.error,
                              weight: AppTextWeight.medium,
                            ),
                            AppText(
                              "1D",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                              weight: AppTextWeight.medium,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right side - Return value with toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Toggle switch with return type label
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              _showAbsoluteReturns ? "Absolute" : "Annualised",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                              weight: AppTextWeight.medium,
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 24,
                              width: 44,
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: CupertinoSwitch(
                                  value: _showAbsoluteReturns,
                                  onChanged: (value) {
                                    setState(() {
                                      _showAbsoluteReturns = value;
                                    });
                                  },
                                  activeColor: AppColors.darkPrimary,
                                  trackColor: AppColors.darkTextSecondary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Period label
                        AppText(
                          "${_showAbsoluteReturns ? "Absolute" : "Annualized"} $_selectedPeriod Returns",
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.secondary,
                          weight: AppTextWeight.medium,
                        ),
                        const SizedBox(height: 4),
                        // Return value
                        Text(
                          '${_getReturnValueForPeriod(_selectedPeriod) >= 0 ? "+" : ""}${_getReturnValueForPeriod(_selectedPeriod).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color:
                                _getReturnValueForPeriod(_selectedPeriod) >= 0
                                    ? Colors.green
                                    : Colors.red,
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
