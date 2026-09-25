import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/mf_switch/types/mutual_fund_switch_advise.dart';
import 'package:nwt_app/services/mutual_fund_switch/mf_switch_advice.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/financial_calculator.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/custom_checkbox.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final double year;
  final double value;

  ChartData({required this.year, required this.value});
}

class MutualFundSwitchScreen extends StatefulWidget {
  const MutualFundSwitchScreen({super.key});

  @override
  State<MutualFundSwitchScreen> createState() => _MutualFundSwitchScreenState();
}

class MFSwitchChartData {
  final double returns;
  final int years;
  final double regularPlanValue;
  final double directPlanValue;
  final double potentialSavings;

  MFSwitchChartData({
    this.returns = 10.0,
    this.years = 8,
    // Default values calculated using the formula FV = PV * (1+i)^n
    this.regularPlanValue =
        171659.14, // Using FinancialCalculator would be better but can't use in const constructor
    this.directPlanValue = 214358.88,
    this.potentialSavings = 42699.74,
  });

  /// Factory constructor that uses the FinancialCalculator utility
  factory MFSwitchChartData.calculate({
    required double regularReturns,
    required int years,
    required double investment,
    required double commissionRate,
  }) {
    // Direct plan returns = regular plan returns + commission rate
    final directReturns = regularReturns + commissionRate;

    final results = FinancialCalculator.calculateMutualFundSavings(
      presentValue: investment,
      directPlanRate: directReturns,
      regularPlanRate: regularReturns,
      years: years.toDouble(),
    );

    return MFSwitchChartData(
      returns: regularReturns, // Store regular plan returns as the base returns
      years: years,
      regularPlanValue: results['regularPlanValue']!,
      directPlanValue: results['directPlanValue']!,
      potentialSavings: results['potentialSavings']!,
    );
  }

  String get formattedRegularPlanValue =>
      CurrencyFormatter.formatRupee(regularPlanValue);
  String get formattedDirectPlanValue =>
      CurrencyFormatter.formatRupee(directPlanValue);
  String get formattedPotentialSavings =>
      CurrencyFormatter.formatRupee(potentialSavings);
  String get formattedGain =>
      "₹${(potentialSavings / 100000).toStringAsFixed(2)}L";
}

class _MutualFundSwitchScreenState extends State<MutualFundSwitchScreen> {
  late MFSwitchChartData chartData;
  double futurePotentialSavings = 0.0;
  final UserController userController = Get.find<UserController>();

  // Regular plan return percentage controlled by the slider
  double regularPlanReturnPercentage = 10.0;
  int investmentYears = 8;
  final double distributorCommission = 2.0;
  final double initialInvestment = 100000.0;

  final double currentMarkerPosition = 5.0;
  MutualFundSwitchAdvise? mfSwitchData;
  @override
  void initState() {
    super.initState();
    initSwitchPlanData();
    _updateChartValues();
    _calculateFuturePotentialSavings();
    _initFundSelectionState();
  }

  final MutualFundSwitchAdviceService _mutualFundSwitchAdviceService =
      MutualFundSwitchAdviceService();
  bool isSwitchPlanLoading = false;
  void _initFundSelectionState() {
    if (mfSwitchData != null) {
      for (var plan in mfSwitchData!.regtodirplans) {
        _selectedFunds[plan.regfundname] = false;
      }
      _updateSelectAllState();
    }
  }

  void _updateSelectAllState() {
    if (_selectedFunds.isEmpty) {
      _selectAllFunds = false;
    } else {
      _selectAllFunds = _selectedFunds.values.every((selected) => selected);
    }
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      _selectAllFunds = value;

      for (var key in _selectedFunds.keys) {
        _selectedFunds[key] = value;
      }
    });
  }

  void initSwitchPlanData() async {
    final response = await _mutualFundSwitchAdviceService
        .getMutualFundSwitchAdvice(
          onLoading: (isLoading) {
            if (mounted) {
              setState(() {
                isSwitchPlanLoading = isLoading;
              });
            }
          },
        );
    if (response != null) {
      setState(() {
        mfSwitchData = response.data;
        _initFundSelectionState();
      });
    }
  }

  void _updateChartValues() {
    final investment = mfSwitchData?.investment ?? initialInvestment;

    // Use the factory constructor to calculate values using the FinancialCalculator
    chartData = MFSwitchChartData.calculate(
      regularReturns: regularPlanReturnPercentage,
      years: investmentYears,
      investment: investment,
      commissionRate: distributorCommission,
    );
  }

  void _calculateFuturePotentialSavings() {
    final investment = mfSwitchData?.investment ?? initialInvestment;

    // Get the years until retirement
    final yearsUntilRetirement = _getRetirementAge();

    AppLogger.info(
      "Using years until retirement: $yearsUntilRetirement (Remote config: ${RemoteConfigService.to.ageTillRetirement.value}, User data: ${userController.userData?.yearsuntilretirement})",
    );

    // Calculate future potential savings using the utility
    // Direct plan returns = regular plan returns + commission rate
    final directPlanRate = regularPlanReturnPercentage + distributorCommission;
    final results = FinancialCalculator.calculateMutualFundSavings(
      presentValue: investment,
      directPlanRate: directPlanRate,
      regularPlanRate: regularPlanReturnPercentage,
      years: yearsUntilRetirement.toDouble(),
    );

    setState(() {
      futurePotentialSavings = results['potentialSavings']!;
    });
  }

  SfCartesianChart getChartData() {
    // Regular plan return is controlled by the slider
    final double regularPlanBaseReturn = regularPlanReturnPercentage;
    // Direct plan return is regular plan return + commission
    final double directPlanBaseReturn =
        regularPlanReturnPercentage + distributorCommission;

    final double yearFactor = investmentYears / 10.0;

    final List<ChartData> directPlanData = [];
    for (int i = 0; i <= 10; i++) {
      final double years = i * yearFactor;
      final double value = FinancialCalculator.calculateFutureValue(
        presentValue: 1.0,
        interestRate: directPlanBaseReturn,
        years: years,
      );
      directPlanData.add(ChartData(year: i.toDouble(), value: value));
    }

    final List<ChartData> regularPlanData = [];
    for (int i = 0; i <= 10; i++) {
      final double years = i * yearFactor;
      final double value = FinancialCalculator.calculateFutureValue(
        presentValue: 1.0,
        interestRate: regularPlanBaseReturn,
        years: years,
      );
      regularPlanData.add(ChartData(year: i.toDouble(), value: value));
    }

    double maxY = 0;
    for (var data in directPlanData) {
      if (data.value > maxY) maxY = data.value;
    }
    maxY = maxY * 1.1;

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(
        minimum: 0,
        maximum: 10,
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 1.0,
        maximum: maxY,
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      series: <CartesianSeries<ChartData, double>>[
        SplineAreaSeries<ChartData, double>(
          dataSource: regularPlanData,
          xValueMapper: (ChartData data, _) => data.year,
          yValueMapper: (ChartData data, _) => data.value,
          color: Colors.grey.withValues(alpha: 0.3),
          borderColor: Colors.grey.withValues(alpha: 0.7),
          borderWidth: 3,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.withValues(alpha: 0.5),
              Colors.grey.withValues(alpha: 0.05),
            ],
          ),
        ),
        SplineSeries<ChartData, double>(
          dataSource: directPlanData,
          xValueMapper: (ChartData data, _) => data.year,
          yValueMapper: (ChartData data, _) => data.value,
          color: Colors.white,
          width: 3,
          dashArray: const <double>[5, 5],
        ),
        LineSeries<ChartData, double>(
          dataSource: [
            ChartData(year: currentMarkerPosition, value: 1.0),
            ChartData(year: currentMarkerPosition, value: maxY),
          ],
          xValueMapper: (ChartData data, _) => data.year,
          yValueMapper: (ChartData data, _) => data.value,
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
          dashArray: const <double>[5, 5],
        ),
      ],
    );
  }

  bool _selectAllFunds = false;
  final Map<String, bool> _selectedFunds = {};

  // Get the retirement age from remote config or fallback to user data or default value
  int _getRetirementAge() {
    // Get AGE_TILL_RETIREMENT from remote config, fallback to user data or default value
    // Ensure retirement age is at least 50 years
    return userController.userData?.yearsuntilretirement ?? 40;
  }

  // Get the years until retirement from user data with fallback
  int _getYearsUntilRetirement() {
    // Simply return the user's years until retirement with fallback to 40
    return userController.userData?.yearsuntilretirement ?? 40;
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
              "Switch Plan",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSizing.scaffoldHorizontalPadding,
              right: AppSizing.scaffoldHorizontalPadding,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/svgs/mf_switch/commissions-icon.svg',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontFamily: 'Montserrat'),
                            children: [
                              TextSpan(
                                text: "You've already",
                                style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: " lost ",
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: CurrencyFormatter.formatRupee(
                                  mfSwitchData?.commissionpaid ?? 0,
                                ),
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text:
                                    " in hidden commissions on Regular Funds. Switch to Direct Funds now and",
                                style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: " save ",
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: "up to",
                                style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text:
                                    " ${CurrencyFormatter.formatRupee(futurePotentialSavings)}",
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: " in ",
                                style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: "${_getYearsUntilRetirement()} years",
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: "!",
                                style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Past Performance",
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkInputBorder,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkButtonBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Invested",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                AppText(
                                  CurrencyFormatter.formatRupee(
                                    mfSwitchData?.investment ?? 0,
                                  ),
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Held For",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                AppText(
                                  "${mfSwitchData?.held} year(s)",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Regular Plan value",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                AppText(
                                  CurrencyFormatter.formatRupee(
                                    mfSwitchData?.regularplanvalue ?? 0,
                                  ),
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Direct Plan value",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                AppText(
                                  CurrencyFormatter.formatRupee(
                                    mfSwitchData?.directplanvalue ?? 0,
                                  ),
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            const Divider(
                              color: AppColors.darkTextSecondary,
                              thickness: 1,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Commission Paid",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.error,
                                ),
                                AppText(
                                  CurrencyFormatter.formatRupee(
                                    mfSwitchData?.commissionpaid ?? 0,
                                  ),
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Future Opportunity Loss",
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        "From now untill you're ${max(50, RemoteConfigService.to.ageTillRetirement.value)}",
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.gray,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppText(
                                      "Direct Plan",
                                      variant: AppTextVariant.bodySmall,
                                      weight: AppTextWeight.medium,
                                      colorType: AppTextColorType.secondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppText(
                                      "Regular Plan",
                                      variant: AppTextVariant.bodySmall,
                                      weight: AppTextWeight.medium,
                                      colorType: AppTextColorType.secondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppText(
                                      "Gain: ",
                                      variant: AppTextVariant.bodySmall,
                                      weight: AppTextWeight.medium,
                                      colorType: AppTextColorType.secondary,
                                    ),
                                    AppText(
                                      chartData.formattedGain,
                                      variant: AppTextVariant.bodySmall,
                                      weight: AppTextWeight.semiBold,
                                      colorType: AppTextColorType.success,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.transparent,
                              ),
                              child: getChartData(),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Returns",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkButtonBorder,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AppText(
                                    "${regularPlanReturnPercentage.toStringAsFixed(1)}%",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                    colorType: AppTextColorType.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 6,
                                activeTrackColor: AppColors.darkPrimary,
                                inactiveTrackColor: AppColors.darkButtonBorder,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                              ),
                              child: Slider(
                                value: regularPlanReturnPercentage,
                                min: 6,
                                max: 20,
                                onChanged: (value) {
                                  setState(() {
                                    regularPlanReturnPercentage = value;
                                    _updateChartValues();
                                    _calculateFuturePotentialSavings();
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Years",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkButtonBorder,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AppText(
                                    "$investmentYears Years",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                    colorType: AppTextColorType.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 6,
                                activeTrackColor: AppColors.darkPrimary,
                                inactiveTrackColor: AppColors.darkButtonBorder,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                              ),
                              child: Slider(
                                value: investmentYears.toDouble(),
                                min: 1,
                                max: 15,
                                onChanged: (value) {
                                  setState(() {
                                    investmentYears = value.toInt();
                                    _updateChartValues();
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Regular Plan value",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.medium,
                                  colorType: AppTextColorType.secondary,
                                ),
                                AppText(
                                  chartData.formattedRegularPlanValue,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Direct Plan value",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.medium,
                                  colorType: AppTextColorType.secondary,
                                ),
                                AppText(
                                  chartData.formattedDirectPlanValue,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                            const Divider(
                              color: AppColors.darkButtonBorder,
                              height: 24,
                              thickness: 1,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Potential Savings",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.success,
                                ),
                                AppText(
                                  chartData.formattedPotentialSavings,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.semiBold,
                                  colorType: AppTextColorType.success,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkButtonBorder),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Switch Regular to Direct Plans",
                                  variant: AppTextVariant.headline6,
                                  weight: AppTextWeight.bold,
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            "Long term funds held over 12 months are selected.",
                                        style: TextStyle(
                                          color: AppColors.darkTextSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,

                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              backgroundColor:
                                                  AppColors.darkCardBG,
                                              showDragHandle: true,
                                              context: context,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(20),
                                                    ),
                                              ),
                                              builder:
                                                  (context) => Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.darkCardBG,
                                                    ),
                                                    padding: EdgeInsets.all(20),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Why long-term holdings?',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'Montserrat',
                                                            color:
                                                                AppColors
                                                                    .darkTextPrimary,
                                                          ),
                                                        ),
                                                        SizedBox(height: 12),
                                                        RichText(
                                                          text: TextSpan(
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  AppColors
                                                                      .darkPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontFamily:
                                                                  'Montserrat',
                                                            ),
                                                            children: [
                                                              const TextSpan(
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                ),
                                                                text:
                                                                    'To optimize post-tax returns, ',
                                                              ),
                                                              TextSpan(
                                                                style: TextStyle(
                                                                  color:
                                                                      AppColors
                                                                          .linkColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                                text:
                                                                    'only investments held for more than one year ',
                                                              ),
                                                              const TextSpan(
                                                                text:
                                                                    'are considered — ensuring they attract the ',
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    'lower LTCG rate ',
                                                                style: TextStyle(
                                                                  color:
                                                                      AppColors
                                                                          .linkColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              const TextSpan(
                                                                text:
                                                                    ' rather than the',
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    ' higher STCG rate.',
                                                                style: TextStyle(
                                                                  color:
                                                                      AppColors
                                                                          .linkColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        SizedBox(height: 20),
                                                      ],
                                                    ),
                                                  ),
                                            );
                                          },
                                          child: Text(
                                            " Why?",
                                            style: TextStyle(
                                              color: AppColors.linkColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              CustomCheckbox(
                                value: _selectAllFunds,
                                onChanged: _toggleSelectAll,
                                size: 14,
                                activeColor: Colors.white,
                                checkColor: AppColors.darkBackground,
                                borderWidth: 1,
                                borderColor: AppColors.darkInputText,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          if (mfSwitchData != null &&
                              mfSwitchData!.regtodirplans.isNotEmpty)
                            ...mfSwitchData!.regtodirplans.map((plan) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.darkInputBorder,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.darkButtonBorder,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 24,
                                          width: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.darkButtonBorder,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.info,
                                            color: AppColors.darkTextSecondary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: plan.regfundname,
                                                      style: TextStyle(
                                                        color:
                                                            AppColors
                                                                .darkPrimary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily:
                                                            'Montserrat',
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          " (${plan.regexpratio}% expense ratio) ",
                                                      style: TextStyle(
                                                        color:
                                                            AppColors
                                                                .darkTextSecondary,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily:
                                                            'Montserrat',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              AppText(
                                                "Regular Fund",
                                                variant:
                                                    AppTextVariant.bodyMedium,
                                                weight: AppTextWeight.medium,
                                                colorType:
                                                    AppTextColorType.link,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svgs/assets/mutual_funds/down_arrow.svg",
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .success
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: AppText(
                                                          "Gain ${CurrencyFormatter.formatRupee(plan.gain)}",
                                                          variant:
                                                              AppTextVariant
                                                                  .bodySmall,
                                                          weight:
                                                              AppTextWeight
                                                                  .bold,
                                                          colorType:
                                                              AppTextColorType
                                                                  .success,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      AppText(
                                                        "LTCG Tax Payable ${CurrencyFormatter.formatRupee(plan.ltcgtax)}",
                                                        variant:
                                                            AppTextVariant
                                                                .bodySmall,
                                                        weight:
                                                            AppTextWeight
                                                                .medium,
                                                        colorType:
                                                            AppTextColorType
                                                                .primary,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        CustomCheckbox(
                                          value:
                                              _selectedFunds[plan
                                                  .regfundname] ??
                                              false,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedFunds[plan.regfundname] =
                                                  value ?? false;
                                              _updateSelectAllState();
                                            });
                                          },
                                          size: 14,
                                          activeColor: AppColors.darkPrimary,
                                          checkColor: AppColors.darkBackground,
                                          borderWidth: 1,
                                          borderColor: AppColors.darkInputText,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 24,
                                          width: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.darkButtonBorder,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.info,
                                            color: AppColors.darkTextSecondary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: plan.dirfundname,
                                                      style: TextStyle(
                                                        color:
                                                            AppColors
                                                                .darkPrimary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily:
                                                            'Montserrat',
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          " (${plan.direxpratio}% expense ratio) ",
                                                      style: TextStyle(
                                                        color:
                                                            AppColors
                                                                .darkTextSecondary,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily:
                                                            'Montserrat',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              AppText(
                                                "Direct Fund",
                                                variant:
                                                    AppTextVariant.bodyMedium,
                                                weight: AppTextWeight.medium,
                                                colorType:
                                                    AppTextColorType.link,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          if (mfSwitchData == null ||
                              mfSwitchData!.regtodirplans.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  AppText(
                                    "Loading fund data...",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.medium,
                                    colorType: AppTextColorType.secondary,
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
          ),
        ),
      ),
    );
  }
}
