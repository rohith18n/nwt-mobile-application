import 'package:flutter/material.dart';
import 'package:nwt_app/screens/family_finance/types/family_dashboard_assets.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class FamilyFinanceChart extends StatefulWidget {
  final FamilyDashboardAssetsResponse? familyDashboardAssetsResponse;

  const FamilyFinanceChart({super.key, this.familyDashboardAssetsResponse});

  @override
  State<FamilyFinanceChart> createState() => _FamilyFinanceChartState();
}

class _FamilyFinanceChartState extends State<FamilyFinanceChart> {
  late List<FamilyFinanceData> _chartData;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _chartData = getChartData();
    // Calculate members count safely
    final membersCount =
        widget.familyDashboardAssetsResponse == null
            ? 0
            : (widget.familyDashboardAssetsResponse!.data == null
                ? 0
                : widget.familyDashboardAssetsResponse!.data!.members.length);

    AppLogger.info(
      "FamilyFinanceChart initialized with $membersCount members",
      tag: "FAMILY_CHART",
    );
    _initTooltipBehavior();
  }

  @override
  void didUpdateWidget(FamilyFinanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get old and new member counts for logging
    final oldMembersCount =
        oldWidget.familyDashboardAssetsResponse == null
            ? 0
            : (oldWidget.familyDashboardAssetsResponse!.data == null
                ? 0
                : oldWidget
                    .familyDashboardAssetsResponse!
                    .data!
                    .members
                    .length);

    final newMembersCount =
        widget.familyDashboardAssetsResponse == null
            ? 0
            : (widget.familyDashboardAssetsResponse!.data == null
                ? 0
                : widget.familyDashboardAssetsResponse!.data!.members.length);

    // Always refresh chart data when widget updates, even if reference is the same
    // This ensures we catch any internal data changes
    AppLogger.info(
      "Family chart updated: $oldMembersCount -> $newMembersCount members",
      tag: "FAMILY_CHART",
    );

    setState(() {
      _chartData = getChartData();
    });
  }

  void _initTooltipBehavior() {
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      // Disable marker completely
      canShowMarker: false,
      // Customize tooltip appearance
      color: const Color(0xFF1C1C1E),
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      builder: (
        dynamic data,
        dynamic point,
        dynamic series,
        int pointIndex,
        int seriesIndex,
      ) {
        final FamilyFinanceData chartData = _chartData[pointIndex];
        final formattedAmount = CurrencyFormatter.formatRupee(chartData.amount);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chartData.name,
                style: TextStyle(
                  color: chartData.gradientColors.first,
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<FamilyFinanceData> getChartData() {
    // Color palette for family members
    final List<List<Color>> colorPalette = [
      // Sage Green
      [const Color(0xFF6B8E6B), const Color(0xFF4A6B4A)],
      // Coral Red
      [const Color(0xFFB8696B), const Color(0xFF8E4A4C)],
      // Lavender Purple
      [const Color(0xFF8B7BA8), const Color(0xFF6A5A7E)],
      // Amber Gold
      [const Color(0xFFA8956B), const Color(0xFF8E7E4A)],
      // Steel Blue
      [const Color(0xFF6B87A8), const Color(0xFF4A6B8E)],
    ];

    // Check if we have real family data
    if (widget.familyDashboardAssetsResponse != null) {
      AppLogger.info(
        "Family response status: ${widget.familyDashboardAssetsResponse!.statusCode}",
        tag: "FAMILY_CHART",
      );

      if (widget.familyDashboardAssetsResponse!.data != null) {
        final data = widget.familyDashboardAssetsResponse!.data!;
        AppLogger.info(
          "Family data: ${data.familylastname}, total: ${data.total}",
          tag: "FAMILY_CHART",
        );

        if (data.members.isNotEmpty) {
          final members = data.members;
          AppLogger.info(
            "Members found: ${members.length}",
            tag: "FAMILY_CHART",
          );

          // Sort members to put head member first
          // Head member is identified by matching lastname with family lastname
          final familyLastName = data.familylastname;
          final List<Member> sortedMembers = List.from(members);
          
          sortedMembers.sort((a, b) {
            // Head member (whose lastname matches family lastname) should come first
            final aIsHead = a.lastname.toLowerCase() == familyLastName.toLowerCase();
            final bIsHead = b.lastname.toLowerCase() == familyLastName.toLowerCase();
            
            if (aIsHead && !bIsHead) return -1;
            if (!aIsHead && bIsHead) return 1;
            // For other members, maintain original order
            return 0;
          });
          
          AppLogger.info(
            "Sorted members with head member first (family: $familyLastName): ${sortedMembers.map((m) => '${m.firstname} ${m.lastname}').join(', ')}",
            tag: "FAMILY_CHART",
          );

          final List<FamilyFinanceData> chartData = [];

          // Create chart data from sorted family members
          for (int i = 0; i < sortedMembers.length; i++) {
            final member = sortedMembers[i];
            final colorIndex = i % colorPalette.length;

            AppLogger.info(
              "Adding member: ${member.firstname}, amount: ${member.individualtotal}",
              tag: "FAMILY_CHART",
            );

            chartData.add(
              FamilyFinanceData(
                member.firstname,
                member.individualtotal.toDouble(),
                colorPalette[colorIndex],
              ),
            );
          }

          AppLogger.info(
            "Returning ${chartData.length} chart data items",
            tag: "FAMILY_CHART",
          );
          return chartData;
        }
      }
    }

    // Fallback to sample data if no real data is available
    AppLogger.info("Using fallback sample data for chart", tag: "FAMILY_CHART");
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Ensure chart data is always up-to-date when building
    // This is a safety measure in case setState wasn't called properly
    final currentChartData = getChartData();
    if (_chartData.length != currentChartData.length) {
      // Only update if there's a difference to avoid unnecessary rebuilds
      _chartData = currentChartData;
      AppLogger.info(
        "Chart data updated in build: ${_chartData.length} items",
        tag: "FAMILY_CHART",
      );
    }

    // Calculate fixed width based on number of members
    const double fixedBarWidth = 80.0; // Fixed width per bar in pixels
    const double barSpacing = 25.0; // Fixed spacing between bars
    const double sidePadding = 30.0; // Padding on each side

    final int memberCount = _chartData.length;
    final double totalWidth =
        memberCount == 0
            ? 200.0 // Minimum width when no data
            : (memberCount * fixedBarWidth) +
                ((memberCount - 1) * barSpacing) +
                (sidePadding * 2);

    return SizedBox(
      height: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: totalWidth,
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    majorTickLines: const MajorTickLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    crossesAt: 0,
                    placeLabelsNearAxisLine: false,
                  ),
                  primaryYAxis: NumericAxis(isVisible: false),
                  // Custom tooltip behavior
                  tooltipBehavior: _tooltipBehavior,
                  series: <CartesianSeries<FamilyFinanceData, String>>[
                    ColumnSeries<FamilyFinanceData, String>(
                      name: 'Family Finance',
                      dataSource: _chartData,
                      xValueMapper: (FamilyFinanceData data, _) => data.name,
                      yValueMapper: (FamilyFinanceData data, _) => data.amount,
                      pointColorMapper:
                          (FamilyFinanceData data, _) =>
                              data.gradientColors.first,
                      // Ensure no markers are visible anywhere
                      markerSettings: const MarkerSettings(
                        isVisible: false,
                        height: 0,
                        width: 0,
                      ),
                      // No data labels
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: false,
                      ),
                      enableTooltip: true,
                      borderRadius: BorderRadius.circular(16),
                      // Use proportional values that result in fixed pixel widths
                      width: 0.7, // Adjusted for fixed appearance
                      spacing: 0.3, // Adjusted spacing
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyFinanceData {
  final String name;
  final double amount;
  final List<Color> gradientColors;

  FamilyFinanceData(this.name, this.amount, this.gradientColors);
}
