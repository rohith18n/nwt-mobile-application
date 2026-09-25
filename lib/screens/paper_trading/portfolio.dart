import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/investments/widgets/stock_holding_card.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PaperTradingPortfolioScreen extends StatefulWidget {
  const PaperTradingPortfolioScreen({super.key});

  @override
  State<PaperTradingPortfolioScreen> createState() =>
      _PaperTradingPortfolioScreenState();
}

// Data classes for charts
class ChartData {
  final String date;
  final double value;

  ChartData(this.date, this.value);
}

class AssetData {
  final String category;
  final double percentage;
  final Color color;

  AssetData(this.category, this.percentage, this.color);
}

class _PaperTradingPortfolioScreenState
    extends State<PaperTradingPortfolioScreen> {
  String _selectedPeriod = '3M';
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
              child: Icon(Icons.chevron_left, color: Colors.white, size: 24.sp),
            ),
            AppText(
              "Portfolio",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // Portfolio Performance Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.darkInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Strategy Title
                      AppText(
                        "Velocity Mid-Cap Lumpsum",
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),

                      SizedBox(height: 4.h),

                      AppText(
                        "Started on 15 Nov 2024",
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.secondary,
                      ),

                      SizedBox(height: 16.h),

                      // Performance Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Invested Value",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "₹10,00,000",
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Current Value",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "₹11,23,400",
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Total Returns",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "₹1,23,400",
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.success,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Returns %",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                ),
                                SizedBox(height: 4.h),
                                AppText(
                                  "+12.34%",
                                  variant: AppTextVariant.bodyLarge,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Performance Chart
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.darkInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Performance",
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),

                      SizedBox(height: 16.h),

                      // Chart
                      SizedBox(
                        height: 200.h,
                        child: SfCartesianChart(
                          plotAreaBorderWidth: 0,
                          backgroundColor: Colors.transparent,
                          margin: EdgeInsets.zero,
                          primaryXAxis: CategoryAxis(
                            majorGridLines: const MajorGridLines(width: 0),
                            axisLine: const AxisLine(width: 0),
                            labelStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            labelIntersectAction: AxisLabelIntersectAction.hide,
                          ),
                          primaryYAxis: NumericAxis(
                            isVisible: false,
                            axisLine: const AxisLine(width: 0),
                            majorTickLines: const MajorTickLines(size: 0),
                            majorGridLines: const MajorGridLines(width: 0),
                          ),
                          series: <CartesianSeries>[
                            // Portfolio Performance Line
                            SplineSeries<ChartData, String>(
                              dataSource: _generateDummyChartData(),
                              xValueMapper: (ChartData data, _) => data.date,
                              yValueMapper: (ChartData data, _) => data.value,
                              color: const Color(0xFF4CAF50),
                              width: 3,
                              splineType: SplineType.natural,
                              markerSettings: const MarkerSettings(
                                isVisible: false,
                              ),
                            ),
                            // Benchmark Performance Line
                            SplineSeries<ChartData, String>(
                              dataSource: _generateBenchmarkData(),
                              xValueMapper: (ChartData data, _) => data.date,
                              yValueMapper: (ChartData data, _) => data.value,
                              color: const Color(0xFFFFB74D),
                              width: 3,
                              splineType: SplineType.natural,
                              markerSettings: const MarkerSettings(
                                isVisible: false,
                              ),
                            ),
                          ],
                          legend: const Legend(isVisible: false),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Asset Allocation Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBG,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.darkInputBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Velocity Midcap Holdings",
                        variant: AppTextVariant.bodyLarge,
                        weight: AppTextWeight.bold,
                        colorType: AppTextColorType.primary,
                      ),

                      SizedBox(height: 16.h),

                      // Asset Allocation Chart and Legend
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Donut Chart
                          SizedBox(
                            width: 120.w,
                            height: 120.w,
                            child: SfCircularChart(
                              margin: EdgeInsets.zero,
                              series: <CircularSeries>[
                                DoughnutSeries<AssetData, String>(
                                  dataSource: _generateAssetAllocationData(),
                                  xValueMapper:
                                      (AssetData data, _) => data.category,
                                  yValueMapper:
                                      (AssetData data, _) => data.percentage,
                                  pointColorMapper:
                                      (AssetData data, _) => data.color,
                                  innerRadius: '60%',
                                  radius: '80%',
                                  dataLabelSettings: const DataLabelSettings(
                                    isVisible: false,
                                  ),
                                ),
                              ],
                              legend: const Legend(isVisible: false),
                            ),
                          ),

                          SizedBox(width: 16.w),

                          // Legend
                          Expanded(
                            child: Column(
                              children:
                                  _generateAssetAllocationData()
                                      .map(
                                        (asset) => _buildAssetLegendItem(asset),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Current Holdings Section
                AppText(
                  "Current Holdings",
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),

                SizedBox(height: 12.h),

                // Holdings List
                ..._generateHoldingsData().map(
                  (holding) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: StockHoldingCard(
                      fundName: holding['name'],
                      currentAmount: holding['currentAmount'],
                      quantity: holding['quantity'],
                      rate: holding['rate'],
                      costValue: holding['costValue'],
                      gainloss: holding['gainloss'],
                      gainlosspercentage: holding['gainlosspercentage'],
                      delta: holding['delta'],
                      deltaValue: holding['deltaValue'],
                      isAmountVisible: true,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Simulation Notice
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A00),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF4A3300),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, color: Colors.amber, size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "Simulation Notice",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.bold,
                              customColor: Colors.amber,
                            ),
                            SizedBox(height: 8.h),
                            AppText(
                              "This is a virtual portfolio simulation. Past performance doesn't guarantee future results. All investments are subject to market risks. High volatility strategies may experience significant drawdowns.",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                              lineHeight: 1.4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for generating dummy data and UI components
  List<ChartData> _generateDummyChartData() {
    return [
      ChartData('Nov 15', 1000000),
      ChartData('Nov 20', 1015000),
      ChartData('Nov 25', 1008000),
      ChartData('Dec 1', 1045000),
      ChartData('Dec 5', 1032000),
      ChartData('Dec 10', 1078000),
      ChartData('Dec 15', 1095000),
      ChartData('Dec 20', 1123400),
    ];
  }

  List<ChartData> _generateBenchmarkData() {
    return [
      ChartData('Nov 15', 1000000),
      ChartData('Nov 20', 1008000),
      ChartData('Nov 25', 1012000),
      ChartData('Dec 1', 1025000),
      ChartData('Dec 5', 1018000),
      ChartData('Dec 10', 1045000),
      ChartData('Dec 15', 1052000),
      ChartData('Dec 20', 1065000),
    ];
  }

  List<AssetData> _generateAssetAllocationData() {
    return [
      AssetData('IT', 25.5, const Color(0xFF4CAF50)),
      AssetData('Banking', 18.2, const Color(0xFF2196F3)),
      AssetData('Healthcare', 15.8, const Color(0xFFFF9800)),
      AssetData('Consumer', 12.3, const Color(0xFF9C27B0)),
      AssetData('Auto', 10.1, const Color(0xFFE91E63)),
      AssetData('Telecom', 8.7, const Color(0xFF00BCD4)),
      AssetData('Energy', 6.2, const Color(0xFFFFEB3B)),
      AssetData('Others', 3.2, const Color(0xFF795548)),
    ];
  }

  List<Map<String, dynamic>> _generateHoldingsData() {
    return [
      {
        'name': 'Infosys Ltd',
        'currentAmount': 145000.0,
        'quantity': 850.0,
        'rate': 1750.50,
        'costValue': 135000.0,
        'gainloss': 10000.0,
        'gainlosspercentage': 7.41,
        'delta': 2.15,
        'deltaValue': 3500.0,
      },
      {
        'name': 'HDFC Bank Ltd',
        'currentAmount': 125000.0,
        'quantity': 750.0,
        'rate': 1665.80,
        'costValue': 118000.0,
        'gainloss': 7000.0,
        'gainlosspercentage': 5.93,
        'delta': 1.85,
        'deltaValue': 2300.0,
      },
      {
        'name': 'Dr Reddy\'s Labs',
        'currentAmount': 98000.0,
        'quantity': 150.0,
        'rate': 6533.33,
        'costValue': 92000.0,
        'gainloss': 6000.0,
        'gainlosspercentage': 6.52,
        'delta': -0.75,
        'deltaValue': -750.0,
      },
      {
        'name': 'Asian Paints Ltd',
        'currentAmount': 87500.0,
        'quantity': 250.0,
        'rate': 3500.00,
        'costValue': 85000.0,
        'gainloss': 2500.0,
        'gainlosspercentage': 2.94,
        'delta': 0.95,
        'deltaValue': 850.0,
      },
      {
        'name': 'Maruti Suzuki',
        'currentAmount': 156000.0,
        'quantity': 120.0,
        'rate': 13000.00,
        'costValue': 148000.0,
        'gainloss': 8000.0,
        'gainlosspercentage': 5.41,
        'delta': 3.25,
        'deltaValue': 5000.0,
      },
    ];
  }

  Widget _buildPeriodButton(String period) {
    final bool isSelected = period == _selectedPeriod;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: AppText(
          period,
          variant: AppTextVariant.bodySmall,
          colorType:
              isSelected ? AppTextColorType.link : AppTextColorType.secondary,
          weight: isSelected ? AppTextWeight.semiBold : AppTextWeight.regular,
        ),
      ),
    );
  }

  Widget _buildAssetLegendItem(AssetData asset) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.h,
            decoration: BoxDecoration(
              color: asset.color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  asset.category,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
                AppText(
                  '${asset.percentage.toStringAsFixed(1)}%',
                  variant: AppTextVariant.bodySmall,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
