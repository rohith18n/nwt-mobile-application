// import 'package:flutter/material.dart';
// import 'package:nwt_app/constants/colors.dart';
// import 'package:nwt_app/constants/sizing.dart';
// import 'package:nwt_app/screens/dashboard/types/dashboard_networth.dart';
// import 'package:nwt_app/screens/dashboard/widgets/networth_chart_main.dart';
// import 'package:nwt_app/utils/currency_formatter.dart';
// import 'package:nwt_app/widgets/common/animated_amount.dart';
// import 'package:nwt_app/widgets/common/shimmer_text.dart';
// import 'package:nwt_app/widgets/common/text_widget.dart';

// class NetworthSection extends StatelessWidget {
//   final bool isNetworthLoading;
//   final double networthAmount;
//   final bool isAmountVisible;
//   final String lastFetchedTime;
//   final List<Currentprojection> currentProjection;
//   final List<Futureprojection>? futureProjection;
//   final VoidCallback onToggleAmountVisibility;

//   const NetworthSection({
//     super.key,
//     required this.isNetworthLoading,
//     required this.networthAmount,
//     required this.isAmountVisible,
//     required this.lastFetchedTime,
//     required this.currentProjection,
//     this.futureProjection,
//     required this.onToggleAmountVisibility,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 12),
//         Padding(
//           padding: const EdgeInsets.symmetric(
//             horizontal: AppSizing.scaffoldHorizontalPadding,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const AppText(
//                 "Your Networth",
//                 variant: AppTextVariant.bodyMedium,
//                 weight: AppTextWeight.bold,
//                 colorType: AppTextColorType.secondary,
//               ),
//               const SizedBox(height: 5),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   isNetworthLoading
//                       ? ShimmerTextPlaceholder(
//                         width: 220,
//                         height: 55,
//                         borderRadius: BorderRadius.circular(8),
//                       )
//                       : AnimatedAmount(
//                         amount: CurrencyFormatter.formatRupee(networthAmount),
//                         isAmountVisible: isAmountVisible,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                   Row(
//                     children: [
//                       GestureDetector(
//                         onTap: onToggleAmountVisibility,
//                         child: Icon(
//                           isAmountVisible
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                           color: AppColors.darkButtonPrimaryBackground,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                     ],
//                   ),
//                 ],
//               ),
//               AppText(
//                 lastFetchedTime.isNotEmpty
//                     ? "Last data fetched at $lastFetchedTime"
//                     : "Last data fetched at 11:00pm",
//                 variant: AppTextVariant.tiny,
//                 weight: AppTextWeight.semiBold,
//                 colorType: AppTextColorType.secondary,
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         ),
//         NetworthChartMain(
//           currentProjection: currentProjection,
//           futureProjection: futureProjection,
//           isLoading: isNetworthLoading,
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }
// }
