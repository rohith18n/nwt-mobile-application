import 'package:flutter/material.dart';
import 'package:nwt_app/screens/insights/types/insights.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class InsightsGraphWidget extends StatefulWidget {
  final String fundName;
  final String fundType;
  final double navValue;
  final String riskLevel;
  final double returnPercentage;
  final Function(String period, double returnValue)? onPeriodSelected;
  // Regular return data
  final List<MFPerformanceDataPoint> oneMonthData;
  final List<MFPerformanceDataPoint> threeMonthData;
  final List<MFPerformanceDataPoint> sixMonthData;
  final List<MFPerformanceDataPoint> oneYearData;
  final List<MFPerformanceDataPoint> threeYearData;
  final List<MFPerformanceDataPoint> fiveYearData;
  final List<MFPerformanceDataPoint> tenYearData;
  final List<MFPerformanceDataPoint> all;
  // SIP return data
  final List<MFPerformanceDataPoint> sipOneMonthData;
  final List<MFPerformanceDataPoint> sipThreeMonthData;
  final List<MFPerformanceDataPoint> sipSixMonthData;
  final List<MFPerformanceDataPoint> sipOneYearData;
  final List<MFPerformanceDataPoint> sipThreeYearData;
  final List<MFPerformanceDataPoint> sipFiveYearData;
  final List<MFPerformanceDataPoint> sipTenYearData;
  final List<MFPerformanceDataPoint> sipAll;
  final String? selectedPeriod;
  final bool? showAbsoluteReturns;

  const InsightsGraphWidget({
    super.key,
    required this.fundName,
    required this.fundType,
    required this.navValue,
    required this.riskLevel,
    required this.returnPercentage,
    this.onPeriodSelected,
    this.selectedPeriod,
    this.showAbsoluteReturns,
    required this.oneMonthData,
    required this.threeMonthData,
    required this.sixMonthData,
    required this.oneYearData,
    required this.threeYearData,
    required this.fiveYearData,
    required this.tenYearData,
    required this.all,
    required this.sipOneMonthData,
    required this.sipThreeMonthData,
    required this.sipSixMonthData,
    required this.sipOneYearData,
    required this.sipThreeYearData,
    required this.sipFiveYearData,
    required this.sipTenYearData,
    required this.sipAll,
  });

  @override
  State<InsightsGraphWidget> createState() => _InsightsGraphWidgetState();
}

class _InsightsGraphWidgetState extends State<InsightsGraphWidget> {
  List<FundReturnData>? _chartData;
  late TrackballBehavior _trackballBehavior;
  late TooltipBehavior _tooltipBehavior;
  String? _selectedSeries;
  String _startDate = '';
  String _endDate = '';
  // Selected time period
  String _selectedPeriod = '3M';

  // Available time periods
  final List<String> _timePeriods = ['3M', '6M', '1Y', '3Y', '5Y', 'MAX'];

  @override
  void initState() {
    super.initState();
    _initBehaviors();
    _selectedPeriod = widget.selectedPeriod ?? '3M';
    // Generate initial chart data for period
    _updateChartDataForPeriod(_selectedPeriod, notifyParent: false);
  }

  @override
  void didUpdateWidget(InsightsGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPeriod != null && widget.selectedPeriod != _selectedPeriod) {
      _updateChartDataForPeriod(widget.selectedPeriod!, notifyParent: false);
    }
  }

  void _updateChartDataForPeriod(String period, {bool notifyParent = true}) {
    // Use real data from the service based on the selected period
    final newChartData = _getDataForPeriod(period);

    // Debug: Print data info for current period
    if (newChartData.isNotEmpty) {
      final values = newChartData.map((d) => d.returnValue).toList();
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      print('Period $period: Data points: ${newChartData.length}, Min: $minVal, Max: $maxVal');
    }

    // Update chart data and selected period with setState to refresh UI
    setState(() {
      _chartData = newChartData;
      if (newChartData.isNotEmpty) {
        _startDate = newChartData.first.date;
        _endDate = newChartData.last.date;
      }
      _selectedPeriod = period;
    });

    // Call callback with selected period and a placeholder return value
    // The actual return value will be calculated in the parent widget
    if (notifyParent && widget.onPeriodSelected != null) {
      widget.onPeriodSelected!(period, 0.0);
    }
  }

  List<FundReturnData> _getDataForPeriod(String period) {
    // Use real data from the service based on the selected period
    List<MFPerformanceDataPoint> regularDataPoints;
    List<MFPerformanceDataPoint> sipDataPoints;

    switch (period) {
      case '3M':
        regularDataPoints = widget.threeMonthData;
        sipDataPoints = widget.sipThreeMonthData;
        break;
      case '6M':
        regularDataPoints = widget.sixMonthData;
        sipDataPoints = widget.sipSixMonthData;
        break;
      case '1Y':
        regularDataPoints = widget.oneYearData;
        sipDataPoints = widget.sipOneYearData;
        break;
      case '3Y':
        // Use 3-year data if available, fallback to available longer-term data
        regularDataPoints = widget.threeYearData;
        sipDataPoints = widget.sipThreeYearData;
        break;
      case '5Y':
        regularDataPoints = widget.fiveYearData;
        sipDataPoints = widget.sipFiveYearData;
        break;
      case 'MAX':
        // For 'All', we'll use the longest available data
        regularDataPoints = widget.all;
        sipDataPoints = widget.sipAll;
        break;
      default:
        regularDataPoints = widget.threeMonthData;
        sipDataPoints = widget.sipThreeMonthData;
    }

    // If we have no data, return empty list - the UI will handle this gracefully
    if (regularDataPoints.isEmpty) {
      return [];
    }

    // Create a map to quickly look up SIP data points by date
    final Map<String, double> sipValuesByDate = {};
    for (final point in sipDataPoints) {
      sipValuesByDate[point.date] = point.value;
    }

    // Convert MFPerformanceDataPoint to FundReturnData
    return regularDataPoints.map((point) {
      return FundReturnData(
        date: point.date,
        returnValue: point.value,
        sipReturnValue:
            sipValuesByDate[point.date] ?? 0.0, // Use SIP value if available
      );
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initBehaviors();
  }

  void _initBehaviors() {
    // Configure trackball behavior with custom tooltip
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
      lineType: TrackballLineType.vertical,
      lineWidth: 1,
      lineColor: Colors.grey.withValues(alpha: 0.5),
      lineDashArray: const [5, 5],
      shouldAlwaysShow: true,
      // Custom tooltip builder to show date and value
      builder: (context, trackballDetails) {
        if (trackballDetails.point == null) return Container();

        final dataPoint = trackballDetails.point!.x as String;
        final value = trackballDetails.point!.y as double;
        final seriesName = trackballDetails.series?.name ?? 'Returns';

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade600, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: $dataPoint',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatRupeeWithCommas(value),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );

    // Keep tooltip behavior for fallback
    _tooltipBehavior = TooltipBehavior(
      enable: false, // Disable since we're using trackball tooltip
      activationMode: ActivationMode.singleTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions based on available width
        final double availableWidth = constraints.maxWidth;
        // Significantly increase chart height to match professional apps like Grow
        final double chartHeight = availableWidth < 400 ? 320 : 400;

        // Check if we have valid chart data
        final bool hasData = _chartData != null && _chartData!.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // _buildLegend(),
              // const SizedBox(height: 8),
              Container(
                height: chartHeight,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Add minimal padding
                child: hasData ? _buildCartesianChart() : _buildNoDataWidget(),
              ),
              if (hasData && _chartData!.isNotEmpty) ...[
                SizedBox(
                  height: 20,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        _startDate,
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.primary,
                      ),
                      AppText(
                        _endDate,
                        variant: AppTextVariant.bodySmall,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.primary,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 16),
              _buildTimePeriodSelector(availableWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're in a narrow layout
        final bool isNarrow = constraints.maxWidth < 350;

        return Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // _buildLegendItem('Returns', const Color(0xFFB176E2), isNarrow),

              // _buildLegendItem(
              //   'SIP Returns',
              //   const Color(0xFFFFDD55),
              //   isNarrow,
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String title, Color color, [bool isNarrow = false]) {
    final bool isSelected = _selectedSeries == null || _selectedSeries == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSeries = _selectedSeries == title ? null : title;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isNarrow ? 12 : 14,
            height: isNarrow ? 12 : 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isSelected ? 1 : 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: color.withValues(alpha: isSelected ? 0.5 : 0.2),
                width: 1,
              ),
            ),
          ),
          SizedBox(width: isNarrow ? 8 : 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(isSelected ? 1 : 0.5),
              fontSize: isNarrow ? 13 : 14,
              fontFamily: 'Montserrat',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          AppText(
            'No data available',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.muted,
            weight: AppTextWeight.medium,
          ),
          const SizedBox(height: 8),
          AppText(
            'Chart data will appear here when available',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector([double availableWidth = double.infinity]) {
    final bool isNarrow = availableWidth < 350;

    return Center(
      child: Wrap(
        spacing: isNarrow ? 6 : 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children:
            _timePeriods
                .map((period) => _buildPeriodButton(period, isNarrow))
                .toList(),
      ),
    );
  }

  Widget _buildPeriodButton(String period, [bool isNarrow = false]) {
    final bool isSelected = period == _selectedPeriod;

    return GestureDetector(
      onTap: () {
        if (period != _selectedPeriod) {
          setState(() {
            _updateChartDataForPeriod(period);
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 8 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: AppText(
          period,
          variant: AppTextVariant.bodySmall,
          colorType:
              isSelected ? AppTextColorType.link : AppTextColorType.muted,
          weight: isSelected ? AppTextWeight.semiBold : AppTextWeight.regular,
        ),
      ),
    );
  }

  SfCartesianChart _buildCartesianChart() {
    double? minValue;
    double? maxValue;

    // Only consider the actual return values from current chart data (ignore SIP for now)
    if (_chartData != null && _chartData!.isNotEmpty) {
      for (final data in _chartData!) {
        if (minValue == null || data.returnValue < minValue) {
          minValue = data.returnValue;
        }
        if (maxValue == null || data.returnValue > maxValue) {
          maxValue = data.returnValue;
        }
      }
    }

    // Dynamic Y-axis range calculation based on actual data for current period
    final double actualMin = minValue ?? 0;
    final double actualMax = maxValue ?? 12;
    final double range = actualMax - actualMin;
    
    // Debug: Print the actual data range for current period
    print('Period: $_selectedPeriod, Min: $actualMin, Max: $actualMax, Range: $range');
    
    // Use very tight bounds to force maximum vertical scaling
    double yMin, yMax;
    
    if (range > 0) {
      // Use only 2% padding for non-zero ranges to maximize scaling
      final double tightPadding = range * 0.02;
      yMin = actualMin - tightPadding;
      yMax = actualMax + tightPadding;
    } else {
      // For flat data, create artificial range to show some variation
      final double center = actualMin;
      yMin = center - 1.0;
      yMax = center + 1.0;
    }

    int? interval;

    switch (_selectedPeriod) {
      case '3M':
        interval = 14;
        break;
      case '6M':
        interval = 30;
        break;
      case '1Y':
        interval = 60;
        break;
      case '3Y':
        interval = 90;
        break;
      case '5Y':
        interval = 120;
        break;
      case 'All':
        interval = 180;
        break;
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero, // Remove all margins to use full container space
      trackballBehavior: _trackballBehavior,
      tooltipBehavior: _tooltipBehavior,
      enableAxisAnimation: true,
      key: ValueKey<String>(_selectedPeriod),

      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 0),
        labelIntersectAction: AxisLabelIntersectAction.hide,
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        rangePadding: ChartRangePadding.none,
        interval: interval?.toDouble(),
        autoScrollingDelta: _chartData?.length,
        autoScrollingMode: AutoScrollingMode.end,
      ),
      primaryYAxis: NumericAxis(
        minimum: yMin,
        maximum: yMax,
        isVisible: false,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: const MajorGridLines(width: 0),
        rangePadding: ChartRangePadding.none, // Remove additional padding to use full height
        plotOffset: 0, // Remove any plot offset
        maximumLabels: 1, // Minimize label interference
      ),
      plotAreaBorderColor: Colors.transparent,
      plotAreaBackgroundColor: Colors.transparent,
      series: _buildSplineSeries(),
      legend: const Legend(isVisible: false),
    );
  }

  List<CartesianSeries> _buildSplineSeries() {
    final bool isReturnsSelected = _selectedSeries == 'Returns';
    final bool isSipReturnsSelected = _selectedSeries == 'SIP Returns';

    return <CartesianSeries>[
      SplineSeries<FundReturnData, String>(
        dataSource: _chartData!,
        xValueMapper: (FundReturnData data, _) => data.date,
        yValueMapper: (FundReturnData data, _) => data.returnValue,
        name: 'Returns',
        color: const Color(0xFFB176E2),
        width: 2.5, // Slightly thinner for cleaner look
        opacity: _selectedSeries == null || isReturnsSelected ? 1 : 0.3,
        onPointTap: (ChartPointDetails details) {
          setState(() {
            _selectedSeries = _selectedSeries == 'Returns' ? null : 'Returns';
          });
        },
        splineType: SplineType.cardinal, // Better curve smoothing
        cardinalSplineTension: 0.2, // Smoother curves
        markerSettings: const MarkerSettings(isVisible: false),
        animationDuration: 500,
        enableTooltip: true,
        isVisibleInLegend: false,
        emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
      ),
      // SplineSeries<FundReturnData, String>(
      //   dataSource: _chartData!,
      //   xValueMapper: (FundReturnData data, _) => data.date,
      //   yValueMapper: (FundReturnData data, _) => data.sipReturnValue,
      //   name: 'SIP Returns',
      //   color: const Color(0xFFFFDD55),
      //   width: 3,
      //   opacity: _selectedSeries == null || isSipReturnsSelected ? 1 : 0.3,
      //   onPointTap: (ChartPointDetails details) {
      //     setState(() {
      //       _selectedSeries =
      //           _selectedSeries == 'SIP Returns' ? null : 'SIP Returns';
      //     });
      //   },
      //   splineType: SplineType.natural,
      //   markerSettings: const MarkerSettings(isVisible: false),
      //   animationDuration: 500,
      //   enableTooltip: true,
      //   isVisibleInLegend: false,
      //   emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
      // ),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class FundReturnData {
  FundReturnData({
    required this.date,
    required this.returnValue,
    required this.sipReturnValue,
  });

  final String date;

  final double returnValue;

  final double sipReturnValue;
}
