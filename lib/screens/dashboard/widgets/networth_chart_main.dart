// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:nwt_app/screens/dashboard/types/dashboard_networth.dart';
// import 'package:nwt_app/utils/currency_formatter.dart';
// import 'package:nwt_app/widgets/common/text_widget.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class NetworthChartMain extends StatefulWidget {
//   final List<Currentprojection> currentProjection;
//   final List<Futureprojection>? futureProjection;
//   final bool isLoading;

//   const NetworthChartMain({
//     super.key,
//     required this.currentProjection,
//     this.futureProjection,
//     this.isLoading = false,
//   });

//   @override
//   State<NetworthChartMain> createState() => _NetworthChartMainState();
// }

// class _NetworthChartMainState extends State<NetworthChartMain> {
//   List<NetworthData> chartData = [];
//   List<NetworthData> futureChartData = [];
//   TrackballBehavior? _trackballBehavior;

//   @override
//   void initState() {
//     super.initState();
//     _processData();
//   }

//   @override
//   void didUpdateWidget(NetworthChartMain oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.currentProjection != widget.currentProjection ||
//         oldWidget.futureProjection != widget.futureProjection) {
//       _processData();
//     }
//   }

//   void _processData() {
//     setState(() {
//       chartData = [];
//       futureChartData = [];

//       // If we have no current projection data but have future projection data
//       // Create a synthetic current point using today's date and the total networth
//       if (widget.currentProjection.isEmpty &&
//           widget.futureProjection != null &&
//           widget.futureProjection!.isNotEmpty) {
//         final today = DateTime.now();
//         // Use the first future projection value as a fallback
//         final currentValue = widget.futureProjection!.first.projectedValue;

//         // Add today's point as current projection
//         chartData.add(NetworthData(today, currentValue, isToday: true));

//         // Add future data points to futureChartData
//         futureChartData.addAll(
//           widget.futureProjection!.map(
//             (data) => NetworthData(data.date, data.projectedValue),
//           ),
//         );
//       } else if (widget.currentProjection.isNotEmpty) {
//         // Add historical data
//         chartData.addAll(
//           widget.currentProjection.map((data) {
//             final isToday = _isDateEqualOrClosestToToday(
//               data.date,
//               widget.currentProjection,
//             );
//             return NetworthData(data.date, data.value, isToday: isToday);
//           }),
//         );

//         // Add future data if available
//         if (widget.futureProjection != null &&
//             widget.futureProjection!.isNotEmpty) {
//           // Add future data points to futureChartData
//           futureChartData.addAll(
//             widget.futureProjection!.map(
//               (data) => NetworthData(data.date, data.projectedValue),
//             ),
//           );
//         }
//       }

//       // Sort data by date to ensure proper line rendering
//       if (chartData.isNotEmpty) {
//         chartData.sort((a, b) => a.date.compareTo(b.date));
//       }

//       if (futureChartData.isNotEmpty) {
//         futureChartData.sort((a, b) => a.date.compareTo(b.date));
//       }

//       // Calculate padding for centering
//       if (chartData.isNotEmpty && chartData.length > 1) {
//         final today = DateTime.now();
//         final firstDate = chartData.first.date;
//         final lastDate = chartData.last.date;
//         final totalDuration = lastDate.difference(firstDate).inDays;
//         final daysBeforeToday = today.difference(firstDate).inDays;
//         final targetDaysBeforeToday = totalDuration ~/ 2;

//         if (daysBeforeToday < targetDaysBeforeToday) {
//           // Add padding days at the start
//           final daysToAdd = targetDaysBeforeToday - daysBeforeToday;
//           final firstValue = chartData.first.amount;
//           for (var i = daysToAdd; i > 0; i--) {
//             chartData.insert(
//               0,
//               NetworthData(firstDate.subtract(Duration(days: i)), firstValue),
//             );
//           }
//         }
//       }

//       _initializeTrackballBehavior();
//     });
//   }

//   // Helper method to get today's point for the scatter series
//   List<NetworthData> _getTodayPoint() {
//     // If there are no data points, return an empty list
//     if (chartData.isEmpty) {
//       return [];
//     }

//     // Find the point marked as today
//     final todayPoint = chartData.firstWhere(
//       (data) => data.isToday,
//       orElse:
//           () => chartData.last, // Use the last point if no today point is found
//     );

//     // Return a list with just the today point
//     return [todayPoint];
//   }

//   // Helper method to check if a date is today or closest to today
//   bool _isDateEqualOrClosestToToday(
//     DateTime date,
//     List<Currentprojection> projections,
//   ) {
//     final today = DateTime(
//       DateTime.now().year,
//       DateTime.now().month,
//       DateTime.now().day,
//     );

//     // If the date is today, return true
//     if (date.year == today.year &&
//         date.month == today.month &&
//         date.day == today.day) {
//       return true;
//     }

//     // Find the closest date to today
//     DateTime? closestDate;
//     int minDifference = 999999;

//     for (var projection in projections) {
//       final difference = (projection.date.difference(today).inDays).abs();
//       if (difference < minDifference) {
//         minDifference = difference;
//         closestDate = projection.date;
//       }
//     }

//     // Check if this date is the closest to today
//     return closestDate != null &&
//         date.year == closestDate.year &&
//         date.month == closestDate.month &&
//         date.day == closestDate.day;
//   }

//   // Helper method to create connected future data that starts from the last point of current data
//   List<NetworthData> _createConnectedFutureData(
//     List<NetworthData> currentData,
//     List<NetworthData> futureData,
//   ) {
//     if (currentData.isEmpty || futureData.isEmpty) {
//       return futureData;
//     }

//     // Get the last point from current data as the starting point
//     final lastCurrentPoint = currentData.last;

//     // Create a new list with the last current point + all future points
//     final result = <NetworthData>[lastCurrentPoint];

//     // Add future points that come after the last current point
//     result.addAll(
//       futureData.where((data) => data.date.isAfter(lastCurrentPoint.date)),
//     );

//     // Sort by date
//     result.sort((a, b) => a.date.compareTo(b.date));

//     return result;
//   }

//   void _initializeTrackballBehavior() {
//     _trackballBehavior = TrackballBehavior(
//       enable: true,
//       tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
//       activationMode: ActivationMode.singleTap,
//       lineType: TrackballLineType.vertical,
//       lineColor: Colors.white.withValues(alpha: 0.2),
//       lineWidth: 1,
//       // Hide the marker dot
//       markerSettings: const TrackballMarkerSettings(
//         markerVisibility: TrackballVisibilityMode.hidden,
//         height: 0,
//         width: 0,
//         borderWidth: 0,
//       ),
//       tooltipSettings: const InteractiveTooltip(
//         enable: true,
//         color: Color(0xFF1C1C1E),
//         borderWidth: 0,
//         borderColor: Colors.transparent,
//         borderRadius: 8,
//         canShowMarker: false,
//         decimalPlaces: 0,
//       ),
//       hideDelay: 2000,
//       shouldAlwaysShow: false,
//       builder: (BuildContext context, TrackballDetails trackballDetails) {
//         if (trackballDetails.point == null) {
//           return Container();
//         }
//         // Use the actual data from the chart point
//         final CartesianChartPoint<dynamic> chartPoint = trackballDetails.point!;
//         final DateTime pointDate = chartPoint.x as DateTime;
//         final double pointAmount = chartPoint.y as double;

//         // Adding z-index to ensure tooltip appears above the line

//         // Determine if this is a future projection point
//         final bool isFuturePoint = futureChartData.any(
//           (data) =>
//               data.date.year == pointDate.year &&
//               data.date.month == pointDate.month &&
//               data.date.day == pointDate.day,
//         );

//         // Find the previous data point for comparison
//         double? previousAmount;
//         bool isPositive = false;
//         double changePercent = 0;
//         double changeValue = 0;

//         // Get appropriate data source based on whether it's a future point
//         final dataSource =
//             isFuturePoint
//                 ? _createConnectedFutureData(chartData, futureChartData)
//                 : chartData;

//         // Find the index in the appropriate data source
//         int dataIndex = dataSource.indexWhere(
//           (data) =>
//               data.date.year == pointDate.year &&
//               data.date.month == pointDate.month &&
//               data.date.day == pointDate.day,
//         );

//         if (dataIndex > 0 && dataIndex < dataSource.length) {
//           previousAmount = dataSource[dataIndex - 1].amount;
//           changeValue = pointAmount - previousAmount;
//           isPositive = changeValue >= 0;

//           if (previousAmount != 0) {
//             changePercent = (changeValue / previousAmount.abs()) * 100;
//           } else if (pointAmount != 0) {
//             // Handle division by zero when previous amount was 0
//             changePercent = pointAmount > 0 ? 100 : -100;
//           }
//         }

//         // Use Material widget with elevation to ensure tooltip appears above chart line
//         return Material(
//           elevation: 16,
//           color: Colors.transparent,
//           shadowColor: Colors.black,
//           borderRadius: BorderRadius.circular(8),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1C1C1E),
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.2),
//                   blurRadius: 8,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Amount value
//                 Text(
//                   CurrencyFormatter.formatRupee(pointAmount),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                   ),
//                 ),
//                 // Show delta if we have previous data
//                 if (dataIndex > 0) ...[
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         isPositive
//                             ? Icons.arrow_upward_rounded
//                             : Icons.arrow_downward_rounded,
//                         color: isPositive ? Colors.green : Colors.red,
//                         size: 14,
//                       ),
//                       const SizedBox(width: 4),
//                       // Show percentage change
//                       Text(
//                         '${changePercent.toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           color: isPositive ? Colors.green : Colors.red,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // Show absolute change value
//                       Text(
//                         // changeValue.toStringAsFixed(2),
//                         CurrencyFormatter.formatRupee(changeValue),
//                         style: TextStyle(
//                           color: isPositive ? Colors.green : Colors.red,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//                 const SizedBox(height: 4),
//                 // Date
//                 Text(
//                   DateFormat('dd MMM yyyy').format(pointDate),
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//                 // Show 'Projected' label for future points
//                 if (isFuturePoint) ...[
//                   const SizedBox(height: 2),
//                   const Text(
//                     'Projected',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 10,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Format the first and last month for display
//     String firstMonth = '';
//     String lastMonth = '';

//     // Check if we have data to display
//     bool hasNoData = chartData.isEmpty && !widget.isLoading;

//     if (chartData.isNotEmpty) {
//       firstMonth = DateFormat('MMM yyyy').format(chartData.first.date);

//       // Get last date (either from future data or current data)
//       DateTime lastDate;
//       if (futureChartData.isNotEmpty) {
//         lastDate = futureChartData.last.date;
//       } else {
//         lastDate = chartData.last.date;
//       }
//       lastMonth = DateFormat('MMM yyyy').format(lastDate);
//     }

//     return SizedBox(
//       height: 220,
//       child:
//           widget.isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : hasNoData
//               ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.bar_chart_rounded,
//                       color: Colors.white.withOpacity(0.5),
//                       size: 48,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       "No Data Available",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.7),
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         fontFamily: "Montserrat",
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//               : Stack(
//                 children: [
//                   Stack(
//                     children: [
//                       SfCartesianChart(
//                         plotAreaBorderWidth: 0,
//                         margin: const EdgeInsets.all(0),
//                         primaryXAxis: DateTimeAxis(
//                           majorGridLines: const MajorGridLines(
//                             width: 0.5,
//                             color: Colors.transparent,
//                             dashArray: <double>[5, 5],
//                           ),
//                           intervalType: DateTimeIntervalType.months,
//                           interval: 2,
//                           dateFormat: DateFormat('MMM'),
//                           axisLine: const AxisLine(
//                             width: 0.0,
//                             color: Colors.transparent,
//                           ),
//                           labelStyle: const TextStyle(
//                             fontSize: 0,
//                             color: Colors.transparent,
//                           ),
//                           majorTickLines: const MajorTickLines(
//                             size: 0,
//                             color: Colors.transparent,
//                           ),
//                         ),
//                         primaryYAxis: NumericAxis(
//                           majorGridLines: const MajorGridLines(
//                             width: 0.5,
//                             color: Colors.transparent,
//                             dashArray: <double>[5, 5],
//                           ),
//                           axisLine: const AxisLine(
//                             width: 0.0,
//                             color: Colors.transparent,
//                           ),
//                           labelStyle: const TextStyle(
//                             fontSize: 0,
//                             color: Colors.transparent,
//                           ),
//                           majorTickLines: const MajorTickLines(
//                             size: 0,
//                             color: Colors.transparent,
//                           ),
//                           numberFormat: NumberFormat.compactCurrency(
//                             locale: 'en_IN',
//                             symbol: '₹',
//                             decimalDigits: 0,
//                           ),
//                         ),
//                         trackballBehavior: _trackballBehavior!,
//                         zoomPanBehavior: ZoomPanBehavior(
//                           enablePinching: false,
//                           enablePanning: false,
//                           enableDoubleTapZooming: false,
//                           enableMouseWheelZooming: false,
//                           enableSelectionZooming: false,
//                         ),
//                         series: <CartesianSeries<NetworthData, DateTime>>[
//                           // Area series (lowest z-order)
//                           AreaSeries<NetworthData, DateTime>(
//                             name: 'Area',
//                             dataSource:
//                                 chartData.isNotEmpty ||
//                                         futureChartData.isNotEmpty
//                                     ? [...chartData, ...futureChartData]
//                                     : [],
//                             xValueMapper: (NetworthData data, _) => data.date,
//                             yValueMapper: (NetworthData data, _) => data.amount,
//                             gradient: LinearGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                               colors: [
//                                 Color.fromRGBO(52, 168, 83, 0.3), // Green
//                                 Colors.transparent,
//                               ],
//                               stops: [0.0, 1.0],
//                             ),
//                             borderColor: Colors.transparent,
//                             borderWidth: 0,
//                             enableTooltip:
//                                 false, // Disable tooltip for area series
//                           ),

//                           // Single line series for all data (middle z-order)
//                           LineSeries<NetworthData, DateTime>(
//                             name: 'Networth',
//                             dataSource:
//                                 chartData.isNotEmpty ||
//                                         futureChartData.isNotEmpty
//                                     ? [...chartData, ...futureChartData]
//                                     : [],
//                             xValueMapper: (NetworthData data, _) => data.date,
//                             yValueMapper: (NetworthData data, _) => data.amount,
//                             // Using gradient instead of solid color
//                             width: 2,
//                             onCreateShader: (ShaderDetails details) {
//                               return ui.Gradient.linear(
//                                 Offset(details.rect.left, details.rect.top),
//                                 Offset(details.rect.right, details.rect.top),
//                                 [
//                                   Color(0xFF21b373),
//                                   Color(0xFF21b373),
//                                   Color.fromRGBO(52, 168, 83, 0.3),
//                                   Color.fromRGBO(52, 168, 83, 0.3),
//                                 ],
//                                 [0.0, 0.49, 0.51, 1.0],
//                               );
//                             },
//                             enableTooltip:
//                                 true, // Enable tooltip for line series
//                           ),

//                           // Today's point marker (highest z-order)
//                           ScatterSeries<NetworthData, DateTime>(
//                             name: 'Today',
//                             dataSource: _getTodayPoint(),
//                             xValueMapper: (NetworthData data, _) => data.date,
//                             yValueMapper: (NetworthData data, _) => data.amount,
//                             color: Colors.white,
//                             markerSettings: const MarkerSettings(
//                               height: 10,
//                               width: 10,
//                               shape: DataMarkerType.circle,
//                               borderWidth: 2,
//                               borderColor: Colors.white,
//                               color: Color(0xFF1C1C1E),
//                             ),
//                             enableTooltip:
//                                 false, // Disable tooltip for scatter points
//                           ),
//                         ],
//                       ),
//                       // Today marker at center bottom
//                       if (chartData.isNotEmpty)
//                         Positioned(
//                           bottom: 4,
//                           left: 0,
//                           right: 0,
//                           child: Center(
//                             child: const AppText(
//                               'Today',
//                               variant: AppTextVariant.bodySmall,
//                               weight: AppTextWeight.medium,
//                               colorType: AppTextColorType.white,
//                             ),
//                           ),
//                         ),
//                       // // Vertical line overlay
//                       // Positioned.fill(
//                       //   child: IgnorePointer(
//                       //     child: Center(
//                       //       child: Container(
//                       //         width: 2,
//                       //         color: Colors.white.withOpacity(0.3),
//                       //         height: double.infinity,
//                       //       ),
//                       //     ),
//                       //   ),
//                       // ),
//                       if (chartData.isNotEmpty)
//                         Positioned(
//                           left: 4,
//                           bottom: 4,
//                           child: Text(
//                             firstMonth,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.normal,
//                             ),
//                           ),
//                         ),
//                       if (chartData.isNotEmpty)
//                         Positioned(
//                           right: 4,
//                           bottom: 4,
//                           child: Text(
//                             lastMonth,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.normal,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   // Add first and last month labels
//                 ],
//               ),
//     );
//   }
// }

// class NetworthData {
//   final DateTime date;
//   final double amount;
//   final bool isToday;

//   NetworthData(this.date, this.amount, {this.isToday = false});
// }
