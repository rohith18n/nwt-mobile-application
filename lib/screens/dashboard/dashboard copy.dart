// import 'dart:async';
// import 'dart:ui';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:nwt_app/constants/colors.dart';
// import 'package:nwt_app/constants/enums.dart';
// import 'package:nwt_app/constants/sizing.dart';
// import 'package:nwt_app/constants/storage_keys.dart';
// import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
// import 'package:nwt_app/controllers/dashboard/data_fetch_status_controller.dart';
// import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
// import 'package:nwt_app/controllers/deeplink.dart';
// import 'package:nwt_app/controllers/theme_controller.dart';
// import 'package:nwt_app/controllers/user_controller.dart';
// import 'package:nwt_app/screens/assets/banks/banks.dart';
// import 'package:nwt_app/screens/assets/insurance/insurance.dart';
// import 'package:nwt_app/screens/assets/investments/investments.dart';
// import 'package:nwt_app/screens/assets/nps/nps.dart';
// import 'package:nwt_app/screens/connections/connections.dart';
// import 'package:nwt_app/screens/dashboard/types/dashboard_assets.dart';
// import 'package:nwt_app/screens/dashboard/widgets/asset_card.dart';
// import 'package:nwt_app/screens/dashboard/widgets/mf_top_performers_widget.dart';
// import 'package:nwt_app/screens/dashboard/zerodha_webview.dart';
// import 'package:nwt_app/screens/explore/explore.dart';
// import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_banks.dart';
// import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_insurance.dart';
// import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_investment.dart';
// import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_nps.dart';
// import 'package:nwt_app/screens/family_finance/screens/family_management.dart';
// import 'package:nwt_app/screens/family_finance/types/family_dashboard_assets.dart';
// import 'package:nwt_app/screens/mf_switch/mf_switch.dart';
// import 'package:nwt_app/screens/notifications/notification_list.dart';
// import 'package:nwt_app/screens/paper_trading/paper_trading_portfolio.dart';
// import 'package:nwt_app/screens/personal_assets/all_personal_assets.dart';
// import 'package:nwt_app/screens/profile/user_profile.dart';
// import 'package:nwt_app/screens/search/global_search/global_search.dart';
// import 'package:nwt_app/services/account_aggregators/saafe_integration_service.dart';
// import 'package:nwt_app/services/auth/auth_flow.dart';
// import 'package:nwt_app/services/dashboard/total_networth.dart';
// import 'package:nwt_app/services/family_finance/family_dashboard_assets.dart';
// import 'package:nwt_app/services/global_storage.dart';
// import 'package:nwt_app/services/remote_config/remote_config_service.dart';
// import 'package:nwt_app/services/update_service.dart';
// import 'package:nwt_app/services/zerodha/zerodha.dart';
// import 'package:nwt_app/utils/circular_reveal_clipper.dart';
// import 'package:nwt_app/utils/currency_formatter.dart';
// import 'package:nwt_app/utils/date_formatter.dart';
// import 'package:nwt_app/utils/logger.dart';
// import 'package:nwt_app/widgets/avatar.dart';
// import 'package:nwt_app/widgets/common/animated_amount.dart';
// import 'package:nwt_app/widgets/common/data_fetch_status_bar.dart';
// import 'package:nwt_app/widgets/common/promotional_card.dart';
// import 'package:nwt_app/widgets/common/shimmer_text.dart';
// import 'package:nwt_app/widgets/common/text_widget.dart';
// import 'package:nwt_app/widgets/status_card_swiper.dart';
// import 'package:package_info_plus/package_info_plus.dart';

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard>
//     with SingleTickerProviderStateMixin {
//   int _selectedIndex = 0;
//   final dashboardAssetController = Get.put(DashboardAssetController());
//   final mfTopPerformersController = Get.put(MFTopPerformersController());
//   final dataFetchStatusController = Get.put(DataFetchStatusController());
//   final _zerodhaService = ZerodhaService();
//   final _totalNetworthService = TotalNetworthService();
//   final _saafeIntegrationService = SaafeIntegrationService();
//   late AnimationController _refreshController;
//   bool isNetworthLoading = true;
//   bool isAssetsLoading = false;
//   bool isZerodhaLoading = false;

//   final ScrollController _scrollController = ScrollController();

//   double _networthAmount = 0.0;
//   String _lastFetchedTime = "";
//   String familyId = "";
//   // double _mfsavings = 0.0;
//   bool _isFamilyMode = false;

//   // Flag to track if data is currently being loaded during mode switch
//   bool _isSwitchingMode = false;

//   // List of recommendations for dynamic mapping
//   List<Map<String, dynamic>> get _recommendations => [
//     {
//       'title': 'Safeguard Gains',
//       'description':
//           'Be mindful to avoid the common pitfalls which people usually unknowingly do',
//       'buttonText': 'Switch Funds',
//       'imagePath': 'assets/imgs/dashboard/recommendation/switch.png',
//       'gradientColors': [Color(0xFFB29CE2), Color(0xFF17181A)],
//       'gradientCenter': Alignment.topCenter,
//       'gradientRadius': 1.4,
//       'useBackdropFilter': true,
//       'onTap':
//           () => Get.to(
//             () => MutualFundSwitchScreen(),
//             transition: Transition.rightToLeft,
//           ),
//     },
//     {
//       'title': 'One Dashboard. Full Control',
//       'description':
//           'No more playing financial hide-and-seek with your family\'s wealth.',
//       'buttonText': 'Create',
//       'imagePath': 'assets/imgs/dashboard/recommendation/family.png',
//       'gradientColors': [Color(0xFF7186F4), Color(0xFF17181A)],
//       'gradientCenter': Alignment.topCenter,
//       'gradientRadius': 1.4,
//       'useBackdropFilter': true,
//       'onTap':
//           () => Get.to(
//             () => FamilyManagement(),
//             transition: Transition.rightToLeft,
//           ),
//     },
//     {
//       'title': 'Paper Trading Portfolio',
//       'description':
//           'Track your virtual investments! Your portfolio is currently worth ₹11.25L with a 12.5% return.',
//       'buttonText': 'View',
//       'imagePath': 'assets/imgs/dashboard/recommendation/paper_trading.png',
//       'gradientColors': [Color(0xFFA28676), Color(0xFF17181A)],
//       'gradientCenter': Alignment.topCenter,
//       'gradientRadius': 1.4,
//       'useBackdropFilter': true,
//       'onTap':
//           () => Get.to(
//             () => PaperTradingPortfolio(),
//             transition: Transition.rightToLeft,
//           ),
//     },
//   ];

//   /// Toggles between family mode and personal mode and refreshes data
//   void toggleFamilyMode() async {
//     final mode = !_isFamilyMode ? 'Family Mode' : 'Personal Mode';
//     final center = Offset(
//       MediaQuery.of(context).size.width / 2,
//       MediaQuery.of(context).size.height / 2,
//     );

//     // Record the start time to enforce minimum animation duration
//     final startTime = DateTime.now();

//     // Set switching mode flag
//     setState(() {
//       _isFamilyMode = !_isFamilyMode;
//       _isSwitchingMode = true;
//     });

//     // Start the animation
//     _startSwitchAnimation(context, mode, center);

//     try {
//       // Refresh data based on the new mode
//       await _initializeData();

//       // Log completion of data loading
//       AppLogger.info(
//         'Data loaded for ${_isFamilyMode ? "Family" : "Personal"} mode',
//         tag: 'Dashboard',
//       );
//     } catch (e) {
//       AppLogger.error('Error loading data: $e', tag: 'Dashboard');
//     } finally {
//       // Calculate elapsed time and determine if we need to wait longer
//       final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
//       final remainingMs = 4000 - elapsedMs;

//       // Wait for remaining time if animation hasn't lasted 4 seconds yet
//       if (remainingMs > 0) {
//         AppLogger.info(
//           'Waiting additional ${remainingMs}ms to complete animation (minimum 4s)',
//           tag: 'Dashboard',
//         );
//         await Future.delayed(Duration(milliseconds: remainingMs));
//       }

//       // After ensuring minimum animation time, update state
//       if (mounted) {
//         setState(() {
//           _isSwitchingMode = false;
//         });

//         // Stop the animation with smooth fade out
//         _stopSwitchAnimation();
//       }
//     }
//   }

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   final FamilyDashboardAssetsService _familyDashboardAssetsService =
//       FamilyDashboardAssetsService();
//   FamilyDashboardAssetsResponse? familyDashboardAssetsResponse;

//   Widget _buildAssetCard({
//     required String title,
//     required Rx<AssetData?> assetData,
//     required IconData icon,
//     required Widget destination,
//     required bool isAmountVisible,
//     required bool hideDelta,
//     required bool isShouldSafe,
//     required bool isTestAccount,
//   }) {
//     return Obx(() {
//       // Check if we're in family mode
//       if (_isFamilyMode &&
//           familyDashboardAssetsResponse != null &&
//           familyDashboardAssetsResponse!.data != null) {
//         double familyAmount = 0.0;
//         double familyDelta = 0.0;
//         String assetTypeKey = '';
//         print("dummydata family mode");
//         if (title == "Banks") {
//           double depositValue = 0.0;
//           double termDepositValue = 0.0;
//           double recurringDepositValue = 0.0;
//           double depositDelta = 0.0;
//           double termDepositDelta = 0.0;
//           double recurringDepositDelta = 0.0;

//           try {
//             final depositSummary = familyDashboardAssetsResponse!.data!.summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'deposit',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             depositValue = depositSummary.totalcurrentvalue.toDouble();
//             depositDelta = depositSummary.deltavalue.toDouble();

//             final termDepositSummary = familyDashboardAssetsResponse!
//                 .data!
//                 .summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'term_deposit',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             termDepositValue = termDepositSummary.totalcurrentvalue.toDouble();
//             termDepositDelta = termDepositSummary.deltavalue.toDouble();

//             final recurringDepositSummary = familyDashboardAssetsResponse!
//                 .data!
//                 .summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'recurring_deposit',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             recurringDepositValue =
//                 recurringDepositSummary.totalcurrentvalue.toDouble();
//             recurringDepositDelta =
//                 recurringDepositSummary.deltavalue.toDouble();

//             familyAmount =
//                 depositValue + termDepositValue + recurringDepositValue;
//             familyDelta =
//                 depositDelta + termDepositDelta + recurringDepositDelta;

//             AppLogger.info(
//               'Family mode: Banks total = ${CurrencyFormatter.formatRupee(familyAmount)} '
//               '(DEPOSIT: ${CurrencyFormatter.formatRupee(depositValue)}, '
//               'TERM_DEPOSIT: ${CurrencyFormatter.formatRupee(termDepositValue)}, '
//               'RECURRING_DEPOSIT: ${CurrencyFormatter.formatRupee(recurringDepositValue)})',
//               tag: 'Dashboard',
//             );

//             assetTypeKey = '';
//           } catch (e) {
//             AppLogger.error(
//               'Error calculating bank values in family mode',
//               error: e,
//               tag: 'Dashboard',
//             );
//             assetTypeKey = 'bank';
//           }
//         } else if (title == "Investments") {
//           double mutualFundsValue = 0.0;
//           double equityValue = 0.0;
//           double etfValue = 0.0;
//           double mutualFundsDelta = 0.0;
//           double equityDelta = 0.0;
//           double etfDelta = 0.0;

//           try {
//             final mutualFundsSummary = familyDashboardAssetsResponse!
//                 .data!
//                 .summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'mutual_funds',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             mutualFundsValue = mutualFundsSummary.totalcurrentvalue.toDouble();
//             mutualFundsDelta = mutualFundsSummary.deltavalue.toDouble();

//             final equitySummary = familyDashboardAssetsResponse!.data!.summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'equity',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             equityValue = equitySummary.totalcurrentvalue.toDouble();
//             equityDelta = equitySummary.deltavalue.toDouble();

//             final etfSummary = familyDashboardAssetsResponse!.data!.summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'etf',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             etfValue = etfSummary.totalcurrentvalue.toDouble();
//             etfDelta = etfSummary.deltavalue.toDouble();

//             familyAmount = mutualFundsValue + equityValue + etfValue;
//             familyDelta = mutualFundsDelta + equityDelta + etfDelta;

//             AppLogger.info(
//               'Family mode: Investments total = ${CurrencyFormatter.formatRupee(familyAmount)} '
//               '(MF: ${CurrencyFormatter.formatRupee(mutualFundsValue)}, '
//               'Equity: ${CurrencyFormatter.formatRupee(equityValue)}, '
//               'ETF: ${CurrencyFormatter.formatRupee(etfValue)})',
//               tag: 'Dashboard',
//             );

//             assetTypeKey = '';
//           } catch (e) {
//             AppLogger.error(
//               'Error calculating family investments total: $e',
//               tag: 'Dashboard',
//             );
//             familyAmount = 0.0;
//             familyDelta = 0.0;
//             assetTypeKey = '';
//           }
//         } else if (title == "NPS") {
//           assetTypeKey = 'nps';
//         } else if (title == "Insurance") {
//           double lifeInsuranceValue = 0.0;
//           double generalInsuranceValue = 0.0;
//           double insurancePoliciesValue = 0.0;
//           double lifeInsuranceDelta = 0.0;
//           double generalInsuranceDelta = 0.0;
//           double insurancePoliciesDelta = 0.0;

//           try {
//             final lifeInsuranceSummary = familyDashboardAssetsResponse!
//                 .data!
//                 .summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'life_insurance',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             lifeInsuranceValue =
//                 lifeInsuranceSummary.totalcurrentvalue.toDouble();
//             lifeInsuranceDelta = lifeInsuranceSummary.deltavalue.toDouble();

//             final generalInsuranceSummary = familyDashboardAssetsResponse!
//                 .data!
//                 .summary
//                 .firstWhere(
//                   (item) => item.assettype.toLowerCase() == 'general_insurance',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             generalInsuranceValue =
//                 generalInsuranceSummary.totalcurrentvalue.toDouble();
//             generalInsuranceDelta =
//                 generalInsuranceSummary.deltavalue.toDouble();

//             final insurancePoliciesSummary = familyDashboardAssetsResponse!
//                 .data!
//                 .summary
//                 .firstWhere(
//                   (item) =>
//                       item.assettype.toLowerCase() == 'insurance_policies',
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             insurancePoliciesValue =
//                 insurancePoliciesSummary.totalcurrentvalue.toDouble();
//             insurancePoliciesDelta =
//                 insurancePoliciesSummary.deltavalue.toDouble();

//             familyAmount =
//                 lifeInsuranceValue +
//                 generalInsuranceValue +
//                 insurancePoliciesValue;
//             familyDelta =
//                 lifeInsuranceDelta +
//                 generalInsuranceDelta +
//                 insurancePoliciesDelta;

//             AppLogger.info(
//               'Family mode: Insurance total = ${CurrencyFormatter.formatRupee(familyAmount)} '
//               '(Life: ${CurrencyFormatter.formatRupee(lifeInsuranceValue)}, '
//               'General: ${CurrencyFormatter.formatRupee(generalInsuranceValue)}, '
//               'Policies: ${CurrencyFormatter.formatRupee(insurancePoliciesValue)})',
//               tag: 'Dashboard',
//             );

//             assetTypeKey = '';
//           } catch (e) {
//             AppLogger.error(
//               'Error calculating family insurance total: $e',
//               tag: 'Dashboard',
//             );
//             familyAmount = 0.0;
//             familyDelta = 0.0;
//             assetTypeKey = '';
//           }
//         }

//         if (assetTypeKey.isNotEmpty) {
//           try {
//             final summaryItem = familyDashboardAssetsResponse!.data!.summary
//                 .firstWhere(
//                   (item) =>
//                       item.assettype.toLowerCase() ==
//                       assetTypeKey.toLowerCase(),
//                   orElse:
//                       () => Summary(
//                         assettype: '',
//                         totalcurrentvalue: 0,
//                         deltavalue: 0,
//                       ),
//                 );
//             familyAmount = summaryItem.totalcurrentvalue.toDouble();
//             familyDelta = summaryItem.deltavalue.toDouble();

//             AppLogger.info(
//               'Family mode: Found $title ($assetTypeKey) with value ${CurrencyFormatter.formatRupee(familyAmount)}',
//               tag: 'Dashboard',
//             );
//           } catch (e) {
//             AppLogger.error(
//               'Error finding family asset for $title: $e',
//               tag: 'Dashboard',
//             );
//             familyAmount = 0.0;
//             familyDelta = 0.0;
//           }
//         } else {
//           AppLogger.info(
//             'Family mode: No asset type key mapped for "$title"',
//             tag: 'Dashboard',
//           );
//         }

//         // Calculate delta percentage for display
//         double deltaPercentage = 0.0;
//         if (familyAmount > 0) {
//           deltaPercentage = (familyDelta / (familyAmount - familyDelta)) * 100;
//         }
//         final deltaType =
//             deltaPercentage >= 0 ? DeltaType.positive : DeltaType.negative;

//         // In family mode, show delta if available
//         return InkWell(
//           onTap: () {
//             // Navigate to destination screen for family data
//             Get.to(destination, transition: Transition.rightToLeft);
//           },
//           child: AssetCard(
//             title: title,
//             isAmountVisible: isAmountVisible,
//             amount: CurrencyFormatter.formatRupee(familyAmount),
//             delta:
//                 familyAmount > 0
//                     ? "${deltaPercentage.abs().toStringAsFixed(2)}%"
//                     : "",
//             deltaType: deltaType,
//             icon: icon,
//             isLinked: true, // Always show as linked in family mode
//             hideDelta:
//                 familyAmount <= 0 ||
//                 hideDelta, // Show delta if amount > 0 and not explicitly hidden
//           ),
//         );
//       } else {
//         print("dummydata personal mode");
//         print("dummydata_1 ${assetData.value?.islinked}");
//         final isLinked = assetData.value?.islinked ?? false;
//         final amount = assetData.value?.value ?? 0.0;
//         final delta = assetData.value?.deltapercentage ?? 0.0;
//         final deltaType = delta >= 0 ? DeltaType.positive : DeltaType.negative;

//         AppLogger.info(
//           "ASSET_CARD_main11111: $title - ${assetData.value?.islinked}",
//           tag: 'AssetCard',
//         );

//         return InkWell(
//           onTap: () {
//             AppLogger.info(
//               "dummydata_1_ASSET_CARD_main11: $title - ${assetData.value?.islinked} $isTestAccount",
//               tag: 'AssetCard',
//             );
//             if (isTestAccount) {
//               Get.to(destination, transition: Transition.rightToLeft);
//             } else if (isLinked) {
//               // If already linked, navigate to destination screen
//               Get.to(destination, transition: Transition.rightToLeft);
//             } else {
//               if (isShouldSafe) {
//                 _openSaafeSdk(context);
//               } else {
//                 Get.to(destination, transition: Transition.rightToLeft);
//               }
//             }
//           },
//           child: AssetCard(
//             title: title,
//             isAmountVisible: isAmountVisible,
//             amount: CurrencyFormatter.formatRupee(amount),
//             delta: isLinked ? "${delta.abs().toStringAsFixed(2)}%" : "",
//             deltaType: deltaType,
//             icon: icon,
//             isLinked: isTestAccount ? true : isLinked,
//             hideDelta: hideDelta,
//           ),
//         );
//       }
//     });
//   }

//   Future<void> _openSaafeSdk(BuildContext context) async {
//     await _saafeIntegrationService.openSaafeSdk(context: context);
//   }

//   Future<void> _checkAppVersion() async {
//     // Get current version
//     final packageInfo = await PackageInfo.fromPlatform();
//     final currentVersion = packageInfo.version;

//     // Get required version from remote config
//     final remoteConfig = RemoteConfigService.to;
//     final requiredVersion = remoteConfig.minimumAppVersion.value;

//     if (requiredVersion.isNotEmpty) {
//       AppLogger.info(
//         'Checking version on dashboard - Current: $currentVersion, Required: $requiredVersion',
//         tag: 'Dashboard',
//       );

//       // Split version strings
//       final current = currentVersion.split('.');
//       final required = requiredVersion.split('.');

//       // Compare versions
//       bool needsUpdate = false;

//       if (current.length >= 3 && required.length >= 3) {
//         final currentMajor = int.parse(current[0]);
//         final currentMinor = int.parse(current[1]);
//         final currentPatch = int.parse(current[2]);

//         final requiredMajor = int.parse(required[0]);
//         final requiredMinor = int.parse(required[1]);
//         final requiredPatch = int.parse(required[2]);

//         if (currentMajor < requiredMajor ||
//             (currentMajor == requiredMajor && currentMinor < requiredMinor) ||
//             (currentMajor == requiredMajor &&
//                 currentMinor == requiredMinor &&
//                 currentPatch < requiredPatch)) {
//           needsUpdate = true;
//         }
//       }

//       if (needsUpdate && mounted) {
//         AppLogger.info(
//           'Update needed - Current: $currentVersion is older than required: $requiredVersion',
//           tag: 'Dashboard',
//         );

//         // Show update dialog
//         final updateService = Get.find<UpdateService>();
//         updateService.showUpdateDialog(
//           context,
//           isCritical: true,
//           message:
//               'Your app version ($currentVersion) needs to be updated to the latest version ($requiredVersion) to continue using the app.',
//           canDismiss: false,
//         );
//       }
//     }
//   }

//   Future<void> fetchFamilyData() async {
//     try {
//       await _fetchFamilyDashboardAssets();
//       // Force rebuild after data fetch
//       if (mounted) {
//         setState(() {});
//       }
//       AppLogger.info('Family data fetched successfully', tag: 'Dashboard');
//     } catch (e) {
//       AppLogger.error('Error fetching family data: $e', tag: 'Dashboard');
//     }
//   }

//   Future<void> _fetchFamilyDashboardAssets() async {
//     try {
//       // Clear existing data first to ensure we don't have stale data
//       if (mounted) {
//         setState(() {
//           familyDashboardAssetsResponse = null;
//         });
//       }

//       final response = await _familyDashboardAssetsService
//           .getFamilyDashboardAssets(
//             onLoading: (isLoading) {
//               if (mounted) {
//                 setState(() {
//                   isAssetsLoading = isLoading;
//                   isNetworthLoading = isLoading;
//                 });
//               }
//             },
//           );

//       if (mounted) {
//         setState(() {
//           // Set the response in state to trigger rebuild
//           familyDashboardAssetsResponse = response;
//           _networthAmount = familyDashboardAssetsResponse?.data?.total ?? 0;
//           familyId = familyDashboardAssetsResponse?.data?.familyid ?? "";
//         });
//       }

//       final membersCount = response.data?.members.length ?? 0;
//       AppLogger.info(
//         'Family dashboard assets fetched successfully: $membersCount members',
//         tag: 'FAMILY_CHART',
//       );
//     } catch (e) {
//       AppLogger.error('Error fetching dashboard assets: $e', tag: 'Dashboard');
//     }
//   }

//   Future<void> _initializeData() async {
//     try {
//       final userResponse = await _userController.fetchUserProfile(
//         onLoading: (_) {},
//       );
//       if (_isFamilyMode) {
//         await fetchFamilyData();
//       } else {
//         await fetchDashboardData();
//       }

//       if (mounted) {
//         setState(() {
//           _notificationTimer?.cancel();
//           _notificationTimer = Timer(const Duration(seconds: 3), () {
//             if (mounted) {
//               setState(() {});
//             }
//           });
//         });
//       }

//       // Check if user is MF verified and bottom sheet hasn't been shown yet
//       if (userResponse.data?.user.ismfverified == true) {
//         // Check if we've already shown the bottom sheet before
//         final hasShownBottomSheet =
//             StorageService.read(StorageKeys.MF_BOTTOMSHEET_SHOWN_KEY) ?? false;

//         if (!hasShownBottomSheet && mounted) {
//           // Show the bottom sheet after a delay
//           // Future.delayed(const Duration(milliseconds: 1900), () {
//           //   _showBottomSheet(_mfsavings);

//           //   // Mark that we've shown the bottom sheet
//           //   StorageService.write(StorageKeys.MF_BOTTOMSHEET_SHOWN_KEY, true);
//           // });
//         }
//       }
//       // Fetch user profile for other initialization
//     } catch (e) {
//       debugPrint('Dashboard initData error: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _refreshController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//     );
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(const Duration(seconds: 2), _checkAppVersion);
//     });
//     _initializeData();
//     _markOnboardingComplete();
//     fetchMFTopPerformers();
//   }

//   Future<void> _markOnboardingComplete() async {
//     final authFlow = Get.find<AuthFlow>();
//     await authFlow.clearOnboardingState();
//   }

//   final UserController _userController = Get.find<UserController>();

//   @override
//   void dispose() {
//     _refreshController.dispose();
//     _notificationTimer?.cancel();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _onRefresh() {
//     if (_isFamilyMode) {
//       fetchFamilyData();
//     } else {
//       fetchDashboardData();
//     }
//     fetchMFTopPerformers();
//   }

//   Future<void> fetchDashboardAssets() async {
//     if (mounted) {
//       setState(() {
//         isAssetsLoading = true;
//       });
//       _refreshController.repeat();
//     }

//     try {
//       await dashboardAssetController.fetchDashboardAssets();

//       // Log the response data
//       final bankData = dashboardAssetController.bankAssetData.value;
//       final investmentData = dashboardAssetController.investmentAssetData.value;

//       AppLogger.info(
//         'Dashboard Assets Fetched - Bank: ${bankData?.value}, Investment: ${investmentData?.value}',
//         tag: 'Dashboard',
//       );

//       if (mounted) {
//         setState(() {
//           isAssetsLoading = false;
//         });
//         _refreshController.stop();
//         _refreshController.reset();
//       }
//     } catch (e) {
//       AppLogger.error('Error fetching dashboard assets: $e', tag: 'Dashboard');
//       if (mounted) {
//         setState(() {
//           isAssetsLoading = false;
//         });
//         _refreshController.stop();
//         _refreshController.reset();
//       }
//     }
//   }

//   /// Fetches mutual fund top performers data and updates the status bar
//   Future<void> fetchMFTopPerformers() async {
//     try {
//       // Simulate API call with delay
//       await Future.delayed(const Duration(seconds: 3));
//       await mfTopPerformersController.fetchTopPerformers();

//       // Update statuses based on result
//       dataFetchStatusController.updateBankStatus(
//         bankName: 'CAMS',
//         status: DataFetchStatus.successful,
//       );
//       dataFetchStatusController.updateBankStatus(
//         bankName: 'Karvy',
//         status:
//             DataFetchStatus
//                 .processing, // Simulate still processing for demonstration
//       );

//       // Simulate completion of Karvy after a delay
//       Future.delayed(const Duration(seconds: 2), () {
//         dataFetchStatusController.updateBankStatus(
//           bankName: 'Karvy',
//           status: DataFetchStatus.successful,
//         );
//       });
//     } catch (e) {
//       AppLogger.error('Error fetching MF top performers: $e', tag: 'Dashboard');

//       // Update statuses to failed
//       dataFetchStatusController.updateBankStatus(
//         bankName: 'CAMS',
//         status: DataFetchStatus.failed,
//       );
//       dataFetchStatusController.updateBankStatus(
//         bankName: 'Karvy',
//         status: DataFetchStatus.failed,
//       );
//     }
//   }

//   Future<void> fetchDashboardData() async {
//     await fetchDashboardAssets();
//     await fetchTotalNetworth();
//   }

//   Future<void> fetchTotalNetworth() async {
//     _totalNetworthService
//         .getTotalNetworth(
//           onLoading: (isLoading) {
//             if (mounted) {
//               setState(() {
//                 isNetworthLoading = isLoading;
//               });
//               if (isLoading) {
//                 _refreshController.repeat();
//               } else {
//                 _refreshController.stop();
//                 _refreshController.reset();
//               }
//             }
//           },
//         )
//         .then((response) {
//           if (response.data != null) {
//             if (mounted) {
//               setState(() {
//                 _networthAmount = response.data!.totalNetWorth;
//                 _lastFetchedTime =
//                     response.data!.balancedatetime != null
//                         ? DateFormatter.formatToDateTimeWithAmPm(
//                           DateTime.parse(response.data!.balancedatetime!),
//                         )
//                         : "";
//                 // _mfsavings = response.data!.mfsavings ?? 0.0;
//               });
//             }
//           }
//         });
//   }

//   bool isUserLoading = false;
//   Future<void> connectToZerodha() async {
//     Get.dialog(
//       const Center(child: CircularProgressIndicator()),
//       barrierDismissible: false,
//     );

//     setState(() {
//       isZerodhaLoading = true;
//     });
//     final response = await _zerodhaService.getZerodhaLoginUrl(
//       onLoading: (loading) {
//         setState(() {
//           isZerodhaLoading = loading;
//         });
//       },
//     );

//     Get.back();

//     if (response == null) {
//       Get.snackbar(
//         'Error',
//         'Failed to get Zerodha login URL. Please try again.',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red.withValues(alpha: 0.1),
//         colorText: Colors.red,
//       );
//       return;
//     }

//     if (response.success && response.data?.loginurl != null) {
//       String decodeUrl(String encodedUrl) {
//         return Uri.decodeFull(encodedUrl);
//       }

//       Get.to(
//         () => ZerodhaWebView(
//           url: decodeUrl(response.data!.loginurl),
//           title: 'Zerodha Login',
//         ),
//         transition: Transition.rightToLeft,
//       );
//     } else {
//       Get.snackbar(
//         'Error',
//         'Invalid Zerodha login URL received. Please try again.',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red.withValues(alpha: 0.1),
//         colorText: Colors.red,
//       );
//     }
//   }

//   String _getGreetingMessage() {
//     final hour = DateTime.now().hour;

//     if (hour < 12) {
//       return "Good morning!";
//     } else if (hour < 17) {
//       return "Good afternoon!";
//     } else if (hour < 21) {
//       return "Good evening!";
//     } else {
//       return "Good evening!";
//     }
//   }

//   bool _isAmountVisible = true;
//   Timer? _notificationTimer;
//   Timer? _overlayTimer;

//   bool _showOverlay = false;
//   String _switchMode = '';
//   double _overlayOpacity = 0.0;
//   double _overlayScale = 0.8;
//   double _revealFraction = 0.0;
//   Offset _revealCenter = Offset.zero;

//   // Start the switch animation with mode and center point
//   void _startSwitchAnimation(BuildContext context, String mode, Offset center) {
//     // Cancel any existing timer
//     _overlayTimer?.cancel();

//     setState(() {
//       _showOverlay = true;
//       _switchMode = mode;
//       _overlayOpacity = 0.0;
//       _overlayScale =
//           0.7; // Start with a smaller scale for more dramatic effect
//       _revealFraction = 0.0;
//       _revealCenter = center;
//     });

//     // Show the animation with a small delay for smoother start
//     // Increased delay for smoother visual transition
//     Future.delayed(const Duration(milliseconds: 200), () {
//       if (mounted) {
//         setState(() {
//           _overlayOpacity = 1.0;
//           _overlayScale = 1.0;
//           _revealFraction = 1.0;
//         });
//       }
//     });
//   }

//   // Stop the switch animation with a smooth fade out
//   void _stopSwitchAnimation() {
//     // Cancel any existing timer
//     _overlayTimer?.cancel();

//     if (mounted) {
//       setState(() {
//         _overlayOpacity = 0.0;
//         _overlayScale = 0.8;
//         _revealFraction = 0.0;
//       });

//       // Hide overlay completely after animation completes
//       // Use a longer duration for smoother fade out
//       Future.delayed(const Duration(milliseconds: 1800), () {
//         if (mounted) {
//           setState(() {
//             _showOverlay = false;
//           });
//         }
//       });
//     }
//   }

//   // Animation control methods are now used directly instead of this legacy wrapper
//   DateTime? _lastBackPressTime;
//   static const Duration _backPressTimeout = Duration(seconds: 2);

//   // Method to handle back press
//   Future<bool> _onWillPop() async {
//     final DateTime now = DateTime.now();

//     if (_lastBackPressTime == null ||
//         now.difference(_lastBackPressTime!) > _backPressTimeout) {
//       // First back press or timeout exceeded
//       _lastBackPressTime = now;

//       // Show snackbar or toast message
//       Get.showSnackbar(
//         GetSnackBar(
//           message: 'Press back again to exit',
//           duration: _backPressTimeout,
//           backgroundColor: Colors.black87,
//           margin: EdgeInsets.all(16),
//           borderRadius: 8,
//           snackPosition: SnackPosition.BOTTOM,
//         ),
//       );

//       return false; // Don't exit
//     }

//     SystemNavigator.pop();
//     return true;
//   }

//   PageController pageViewController = PageController();
//   int currentPage = 0;
//   @override
//   Widget build(BuildContext context) {
//     Get.put(DeepLinkController());
//     return GetBuilder<ThemeController>(
//       builder: (themeController) {
//         return GetBuilder<UserController>(
//           builder: (userController) {
//             return GetBuilder<DashboardAssetController>(
//               builder: (dashboardAssetController) {
//                 return PopScope(
//                   canPop: false, // Prevent automatic pop
//                   onPopInvoked: (didPop) async {
//                     if (!didPop) {
//                       await _onWillPop();
//                     }
//                   },
//                   child: Scaffold(
//                     key: _scaffoldKey,
//                     backgroundColor: AppColors.darkCardBG,
//                     body: SafeArea(
//                       bottom: false,
//                       child: Stack(
//                         children: [
//                           RefreshIndicator(
//                             onRefresh: () async {
//                               _onRefresh();
//                             },
//                             color:
//                                 themeController.isDarkMode
//                                     ? AppColors.darkPrimary
//                                     : AppColors.lightPrimary,
//                             backgroundColor:
//                                 themeController.isDarkMode
//                                     ? AppColors.darkCardBG
//                                     : AppColors.lightBackground,
//                             displacement: 20.0,
//                             strokeWidth: 3.0,
//                             child: Stack(
//                               children: [
//                                 SingleChildScrollView(
//                                   controller: _scrollController,
//                                   physics: const ClampingScrollPhysics(),
//                                   child: Column(
//                                     children: [
//                                       // Padding(
//                                       //   padding: const EdgeInsets.only(
//                                       //     left: AppSizing.scaffoldHorizontalPadding,
//                                       //     right: AppSizing.scaffoldHorizontalPadding,
//                                       //     bottom: 8,
//                                       //   ),
//                                       //   child: DataFetchStatusBar(
//                                       //     bankStatuses:
//                                       //         dataFetchStatusController.bankStatuses,
//                                       //   ),
//                                       // ),
//                                       const SizedBox(height: 16),
//                                       Container(
//                                         padding: EdgeInsets.symmetric(
//                                           horizontal:
//                                               AppSizing
//                                                   .scaffoldHorizontalPadding,
//                                         ),
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         child: Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.spaceBetween,
//                                           children: [
//                                             Row(
//                                               children: [
//                                                 Row(
//                                                   children: [
//                                                     GestureDetector(
//                                                       onTap: () {
//                                                         Get.to(
//                                                           () => UserProfile(),
//                                                         );
//                                                       },
//                                                       child: Avatar(
//                                                         path:
//                                                             userController
//                                                                         .userData
//                                                                         ?.gender
//                                                                         ?.toLowerCase() ==
//                                                                     'female'
//                                                                 ? 'assets/svgs/dashboard/female.png'
//                                                                 : 'assets/svgs/dashboard/male.png',
//                                                         width: 40,
//                                                         height: 40,
//                                                         isNetworkImage: false,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 16),
//                                                     Column(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         AppText(
//                                                           "Hi, ${userController.userData?.firstname != null ? userController.userData!.firstname : 'User'}",
//                                                           variant:
//                                                               AppTextVariant
//                                                                   .headline4,
//                                                           weight:
//                                                               AppTextWeight
//                                                                   .bold,
//                                                           colorType:
//                                                               AppTextColorType
//                                                                   .primary,
//                                                         ),
//                                                         AppText(
//                                                           _getGreetingMessage(),
//                                                           variant:
//                                                               AppTextVariant
//                                                                   .bodySmall,
//                                                           weight:
//                                                               AppTextWeight
//                                                                   .medium,
//                                                           colorType:
//                                                               AppTextColorType
//                                                                   .secondary,
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                             Row(
//                                               children: [
//                                                 IconButton(
//                                                   onPressed:
//                                                       () => Get.to(
//                                                         () =>
//                                                             GlobalSearchScreen(),
//                                                         transition:
//                                                             Transition
//                                                                 .rightToLeft,
//                                                       ),
//                                                   icon: Icon(
//                                                     CupertinoIcons.search,
//                                                     color:
//                                                         AppColors.darkTextMuted,
//                                                   ),
//                                                 ),
//                                                 IconButton(
//                                                   onPressed:
//                                                       () => Get.to(
//                                                         () =>
//                                                             NotificationListScreen(),
//                                                         transition:
//                                                             Transition
//                                                                 .rightToLeft,
//                                                       ),
//                                                   icon: const Icon(
//                                                     Icons
//                                                         .notifications_outlined,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),

//                                       Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           // SizedBox(
//                                           //   height:
//                                           //       MediaQuery.of(context).size.height,
//                                           //   child: AnimatedTextExample(),
//                                           // ),
//                                           SizedBox(height: 12),
//                                           Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal:
//                                                   AppSizing
//                                                       .scaffoldHorizontalPadding,
//                                             ),
//                                             child: Column(
//                                               spacing: 5,
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 AppText(
//                                                   _isFamilyMode
//                                                       ? "Family Networth"
//                                                       : "Your Networth",
//                                                   variant:
//                                                       AppTextVariant.bodyMedium,
//                                                   weight: AppTextWeight.bold,
//                                                   colorType:
//                                                       AppTextColorType
//                                                           .secondary,
//                                                 ),
//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   children: [
//                                                     isNetworthLoading
//                                                         ? ShimmerTextPlaceholder(
//                                                           width: 220,
//                                                           height: 55,
//                                                           borderRadius:
//                                                               BorderRadius.circular(
//                                                                 8,
//                                                               ),
//                                                         )
//                                                         : AnimatedAmount(
//                                                           amount:
//                                                               CurrencyFormatter.formatRupee(
//                                                                 _networthAmount,
//                                                               ),
//                                                           isAmountVisible:
//                                                               _isAmountVisible,
//                                                           style:
//                                                               const TextStyle(
//                                                                 color:
//                                                                     Colors
//                                                                         .white,
//                                                                 fontSize: 36,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                               ),
//                                                         ),
//                                                     Row(
//                                                       children: [
//                                                         GestureDetector(
//                                                           onTap: () {
//                                                             setState(() {
//                                                               _isAmountVisible =
//                                                                   !_isAmountVisible;
//                                                             });
//                                                           },
//                                                           child: Icon(
//                                                             _isAmountVisible
//                                                                 ? Icons
//                                                                     .visibility_outlined
//                                                                 : Icons
//                                                                     .visibility_off_outlined,
//                                                             color:
//                                                                 AppColors
//                                                                     .darkButtonPrimaryBackground,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 12,
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 AppText(
//                                                   _lastFetchedTime.isNotEmpty
//                                                       ? "Last data fetched at $_lastFetchedTime"
//                                                       : "No data fetched yet",
//                                                   variant: AppTextVariant.tiny,
//                                                   weight:
//                                                       AppTextWeight.semiBold,
//                                                   colorType:
//                                                       AppTextColorType
//                                                           .secondary,
//                                                 ),
//                                                 const SizedBox(height: 16),
//                                               ],
//                                             ),
//                                           ),
//                                           // if (!_isFamilyMode)
//                                           //   NetworthChartMain(
//                                           //     currentProjection:
//                                           //         _currentProjection ?? [],
//                                           //     futureProjection:
//                                           //         _futureProjection,
//                                           //     isLoading: isNetworthLoading,
//                                           //   ),
//                                           // if (_isFamilyMode)
//                                           //   Builder(
//                                           //     // Force rebuild with a key based on response data
//                                           //     key: ValueKey(
//                                           //       'family-chart-${familyDashboardAssetsResponse?.hashCode}',
//                                           //     ),
//                                           //     builder: (context) {
//                                           //       // Calculate members count safely
//                                           //       final membersCount =
//                                           //           familyDashboardAssetsResponse ==
//                                           //                   null
//                                           //               ? 0
//                                           //               : (familyDashboardAssetsResponse!
//                                           //                           .data ==
//                                           //                       null
//                                           //                   ? 0
//                                           //                   : (familyDashboardAssetsResponse!
//                                           //                       .data!
//                                           //                       .members
//                                           //                       .length));
//                                           //       AppLogger.info(
//                                           //         "Rendering family chart with data: $membersCount members at ${DateTime.now()}",
//                                           //         tag: "FAMILY_CHART",
//                                           //       );
//                                           //       return FamilyFinanceChart(
//                                           //         // Use ValueKey with hashCode to ensure rebuild when data changes
//                                           //         key: ValueKey(
//                                           //           familyDashboardAssetsResponse
//                                           //                   ?.hashCode ??
//                                           //               UniqueKey(),
//                                           //         ),
//                                           //         familyDashboardAssetsResponse:
//                                           //             familyDashboardAssetsResponse,
//                                           //       );
//                                           //     },
//                                           //   ),
//                                           const SizedBox(height: 12),

//                                           if (userController
//                                                       .userData
//                                                       ?.isfamily !=
//                                                   null &&
//                                               userController
//                                                       .userData
//                                                       ?.isfamily ==
//                                                   true)
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: [
//                                                 Container(
//                                                   padding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 8,
//                                                         vertical: 6,
//                                                       ),
//                                                   decoration: BoxDecoration(
//                                                     color:
//                                                         themeController
//                                                                 .isDarkMode
//                                                             ? Colors
//                                                                 .grey
//                                                                 .shade900
//                                                             : Colors
//                                                                 .grey
//                                                                 .shade100,
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           24,
//                                                         ),
//                                                   ),
//                                                   child: Row(
//                                                     mainAxisSize:
//                                                         MainAxisSize.min,
//                                                     children: [
//                                                       GestureDetector(
//                                                         onTap: () {
//                                                           if (_isFamilyMode) {
//                                                             // Use the toggleFamilyMode method
//                                                             // which handles both animation and data loading
//                                                             toggleFamilyMode();
//                                                           }
//                                                         },
//                                                         child: AnimatedContainer(
//                                                           duration:
//                                                               const Duration(
//                                                                 milliseconds:
//                                                                     300,
//                                                               ),
//                                                           width: 100,
//                                                           padding:
//                                                               const EdgeInsets.symmetric(
//                                                                 vertical: 8,
//                                                                 horizontal: 12,
//                                                               ),
//                                                           decoration: BoxDecoration(
//                                                             color:
//                                                                 !_isFamilyMode
//                                                                     ? themeController
//                                                                             .isDarkMode
//                                                                         ? AppColors
//                                                                             .darkCardBG
//                                                                         : Colors
//                                                                             .white
//                                                                     : Colors
//                                                                         .transparent,
//                                                             borderRadius:
//                                                                 BorderRadius.circular(
//                                                                   20,
//                                                                 ),
//                                                             boxShadow:
//                                                                 !_isFamilyMode
//                                                                     ? [
//                                                                       BoxShadow(
//                                                                         color: Colors
//                                                                             .black
//                                                                             .withOpacity(
//                                                                               0.1,
//                                                                             ),
//                                                                         blurRadius:
//                                                                             4,
//                                                                         offset:
//                                                                             const Offset(
//                                                                               0,
//                                                                               2,
//                                                                             ),
//                                                                       ),
//                                                                     ]
//                                                                     : null,
//                                                           ),
//                                                           child: Row(
//                                                             mainAxisAlignment:
//                                                                 MainAxisAlignment
//                                                                     .center,
//                                                             children: [
//                                                               Icon(
//                                                                 Icons
//                                                                     .person_rounded,
//                                                                 size: 16,
//                                                                 color:
//                                                                     !_isFamilyMode
//                                                                         ? AppColors
//                                                                             .darkPrimary
//                                                                         : Colors
//                                                                             .grey,
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 4,
//                                                               ),
//                                                               AppText(
//                                                                 'Individual',
//                                                                 variant:
//                                                                     AppTextVariant
//                                                                         .tiny,
//                                                                 weight:
//                                                                     !_isFamilyMode
//                                                                         ? AppTextWeight
//                                                                             .semiBold
//                                                                         : AppTextWeight
//                                                                             .regular,
//                                                                 colorType:
//                                                                     !_isFamilyMode
//                                                                         ? AppTextColorType
//                                                                             .primary
//                                                                         : AppTextColorType
//                                                                             .secondary,
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       GestureDetector(
//                                                         onTap: () {
//                                                           if (!_isFamilyMode) {
//                                                             // Use the toggleFamilyMode method
//                                                             // which handles both animation and data loading
//                                                             toggleFamilyMode();
//                                                           }
//                                                         },
//                                                         child: AnimatedContainer(
//                                                           duration:
//                                                               const Duration(
//                                                                 milliseconds:
//                                                                     300,
//                                                               ),
//                                                           width: 100,
//                                                           padding:
//                                                               const EdgeInsets.symmetric(
//                                                                 vertical: 8,
//                                                                 horizontal: 12,
//                                                               ),
//                                                           decoration: BoxDecoration(
//                                                             color:
//                                                                 _isFamilyMode
//                                                                     ? themeController
//                                                                             .isDarkMode
//                                                                         ? AppColors
//                                                                             .darkCardBG
//                                                                         : Colors
//                                                                             .white
//                                                                     : Colors
//                                                                         .transparent,
//                                                             borderRadius:
//                                                                 BorderRadius.circular(
//                                                                   20,
//                                                                 ),
//                                                             boxShadow:
//                                                                 _isFamilyMode
//                                                                     ? [
//                                                                       BoxShadow(
//                                                                         color: Colors
//                                                                             .black
//                                                                             .withOpacity(
//                                                                               0.1,
//                                                                             ),
//                                                                         blurRadius:
//                                                                             4,
//                                                                         offset:
//                                                                             const Offset(
//                                                                               0,
//                                                                               2,
//                                                                             ),
//                                                                       ),
//                                                                     ]
//                                                                     : null,
//                                                           ),
//                                                           child: Row(
//                                                             mainAxisAlignment:
//                                                                 MainAxisAlignment
//                                                                     .center,
//                                                             children: [
//                                                               Icon(
//                                                                 Icons
//                                                                     .family_restroom_rounded,
//                                                                 size: 16,
//                                                                 color:
//                                                                     _isFamilyMode
//                                                                         ? AppColors
//                                                                             .darkPrimary
//                                                                         : Colors
//                                                                             .grey,
//                                                               ),
//                                                               const SizedBox(
//                                                                 width: 4,
//                                                               ),
//                                                               AppText(
//                                                                 'Family',
//                                                                 variant:
//                                                                     AppTextVariant
//                                                                         .tiny,
//                                                                 weight:
//                                                                     _isFamilyMode
//                                                                         ? AppTextWeight
//                                                                             .semiBold
//                                                                         : AppTextWeight
//                                                                             .regular,
//                                                                 colorType:
//                                                                     _isFamilyMode
//                                                                         ? AppTextColorType
//                                                                             .primary
//                                                                         : AppTextColorType
//                                                                             .secondary,
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           const SizedBox(height: 16),
//                                         ],
//                                       ),
//                                       SingleChildScrollView(
//                                         child: Column(
//                                           children: [
//                                             Container(
//                                               color: AppColors.darkBackground,
//                                               child: SizedBox(
//                                                 width:
//                                                     MediaQuery.of(
//                                                       context,
//                                                     ).size.width,
//                                                 child: Column(
//                                                   children: [
//                                                     AnimatedContainer(
//                                                       duration: const Duration(
//                                                         milliseconds: 300,
//                                                       ),
//                                                       height: 15,
//                                                       curve: Curves.easeInOut,
//                                                     ),
//                                                     Padding(
//                                                       padding: EdgeInsets.symmetric(
//                                                         horizontal:
//                                                             AppSizing
//                                                                 .scaffoldHorizontalPadding,
//                                                       ),
//                                                       child: Row(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .spaceBetween,
//                                                         children: [
//                                                           AppText(
//                                                             "Assets",
//                                                             variant:
//                                                                 AppTextVariant
//                                                                     .headline5,
//                                                             weight:
//                                                                 AppTextWeight
//                                                                     .bold,
//                                                             colorType:
//                                                                 AppTextColorType
//                                                                     .primary,
//                                                           ),
//                                                           if (false)
//                                                             AppText(
//                                                               "See All",
//                                                               variant:
//                                                                   AppTextVariant
//                                                                       .bodySmall,
//                                                               weight:
//                                                                   AppTextWeight
//                                                                       .medium,
//                                                               colorType:
//                                                                   AppTextColorType
//                                                                       .link,
//                                                             ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     SizedBox(height: 12),

//                                                     SingleChildScrollView(
//                                                       scrollDirection:
//                                                           Axis.horizontal,
//                                                       padding: EdgeInsets.only(
//                                                         left:
//                                                             AppSizing
//                                                                 .scaffoldHorizontalPadding,
//                                                         right:
//                                                             AppSizing
//                                                                 .scaffoldHorizontalPadding,
//                                                       ),

//                                                       child: Row(
//                                                         spacing: 12,
//                                                         children: [
//                                                           if (!(userController
//                                                                   .userData
//                                                                   ?.istestaccount ??
//                                                               true))
//                                                             InkWell(
//                                                               onTap:
//                                                                   () => Get.to(
//                                                                     const ConnectionsScreen(),
//                                                                     transition:
//                                                                         Transition
//                                                                             .rightToLeft,
//                                                                   ),
//                                                               // () => Get.to(
//                                                               //   const ConnectionsScreen(),
//                                                               //   transition:
//                                                               //       Transition
//                                                               //           .rightToLeft,
//                                                               // ),
//                                                               child: Container(
//                                                                 width: 50,
//                                                                 height: 105,
//                                                                 decoration: BoxDecoration(
//                                                                   color:
//                                                                       AppColors
//                                                                           .darkCardBG,
//                                                                   borderRadius:
//                                                                       BorderRadius.circular(
//                                                                         12,
//                                                                       ),
//                                                                   border: Border.all(
//                                                                     color:
//                                                                         AppColors
//                                                                             .darkButtonBorder,
//                                                                   ),
//                                                                 ),
//                                                                 child: const Center(
//                                                                   child: Icon(
//                                                                     Icons
//                                                                         .add_rounded,
//                                                                     size: 26,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ),

//                                                           _buildAssetCard(
//                                                             isAmountVisible:
//                                                                 _isAmountVisible,
//                                                             title: "Banks",
//                                                             assetData:
//                                                                 dashboardAssetController
//                                                                     .bankAssetData,
//                                                             icon:
//                                                                 Icons
//                                                                     .account_balance_rounded,
//                                                             destination:
//                                                                 _isFamilyMode
//                                                                     ? FamilyFinanceBanksScreen(
//                                                                       familyId:
//                                                                           familyId,
//                                                                     )
//                                                                     : AssetBankScreen(),
//                                                             hideDelta: false,
//                                                             isShouldSafe: true,
//                                                             isTestAccount:
//                                                                 (userController
//                                                                         .userData
//                                                                         ?.istestaccount ??
//                                                                     true),
//                                                           ),

//                                                           _buildAssetCard(
//                                                             title:
//                                                                 "Investments",
//                                                             isAmountVisible:
//                                                                 _isAmountVisible,
//                                                             assetData:
//                                                                 dashboardAssetController
//                                                                     .investmentAssetData,
//                                                             icon:
//                                                                 Icons
//                                                                     .pie_chart_rounded,
//                                                             destination:
//                                                                 _isFamilyMode
//                                                                     ? FamilyFinanceInvestmentScreen(
//                                                                       familyId:
//                                                                           familyId,
//                                                                     )
//                                                                     : AssetInvestmentScreen(),
//                                                             hideDelta: false,
//                                                             isShouldSafe: true,
//                                                             isTestAccount:
//                                                                 (userController
//                                                                         .userData
//                                                                         ?.istestaccount ??
//                                                                     true),
//                                                           ),
//                                                           _buildAssetCard(
//                                                             title: "NPS",
//                                                             isAmountVisible:
//                                                                 _isAmountVisible,
//                                                             assetData:
//                                                                 dashboardAssetController
//                                                                     .npsAssetData,
//                                                             icon:
//                                                                 Icons
//                                                                     .account_balance_wallet_rounded,
//                                                             destination:
//                                                                 _isFamilyMode
//                                                                     ? FamilyFinanceNPSScreen(
//                                                                       familyId:
//                                                                           familyId,
//                                                                     )
//                                                                     : NPSScreen(),
//                                                             hideDelta: true,
//                                                             isShouldSafe: true,
//                                                             isTestAccount:
//                                                                 (userController
//                                                                         .userData
//                                                                         ?.istestaccount ??
//                                                                     true),
//                                                           ),

//                                                           _buildAssetCard(
//                                                             title: "Insurance",
//                                                             isAmountVisible:
//                                                                 _isAmountVisible,
//                                                             assetData:
//                                                                 dashboardAssetController
//                                                                     .insuranceAssetData,
//                                                             icon:
//                                                                 Icons
//                                                                     .shield_rounded,
//                                                             destination:
//                                                                 _isFamilyMode
//                                                                     ? FamilyFinanceInsuranceListScreen(
//                                                                       familyId:
//                                                                           familyId,
//                                                                     )
//                                                                     : InsuranceListScreen(),
//                                                             hideDelta: true,
//                                                             isShouldSafe: true,
//                                                             isTestAccount:
//                                                                 (userController
//                                                                         .userData
//                                                                         ?.istestaccount ??
//                                                                     true),
//                                                           ),
//                                                           if (!_isFamilyMode)
//                                                             _buildAssetCard(
//                                                               title:
//                                                                   "Personal Assets",
//                                                               isAmountVisible:
//                                                                   _isAmountVisible,
//                                                               assetData:
//                                                                   dashboardAssetController
//                                                                       .personalAssetsData,
//                                                               icon: Icons.money,
//                                                               destination:
//                                                                   AllPersonalAssetsScreen(),
//                                                               hideDelta: true,
//                                                               isShouldSafe:
//                                                                   false,
//                                                               isTestAccount:
//                                                                   (userController
//                                                                           .userData
//                                                                           ?.istestaccount ??
//                                                                       true),
//                                                             ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                             Container(
//                                               color: AppColors.darkBackground,
//                                               child: Column(
//                                                 children: [
//                                                   Container(
//                                                     color:
//                                                         AppColors
//                                                             .darkBackground,
//                                                     child: StatusCardSwiper(),
//                                                   ),
//                                                   MFTopPerformersWidget(
//                                                     controller:
//                                                         mfTopPerformersController,
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             Material(
//                                               color: AppColors.darkBackground,
//                                               child: Column(
//                                                 children: [
//                                                   Padding(
//                                                     padding: EdgeInsets.only(
//                                                       left:
//                                                           AppSizing
//                                                               .scaffoldHorizontalPadding,
//                                                       right:
//                                                           AppSizing
//                                                               .scaffoldHorizontalPadding,
//                                                     ),
//                                                     child: Row(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         AppText(
//                                                           "Recommendations",
//                                                           variant:
//                                                               AppTextVariant
//                                                                   .headline5,
//                                                           weight:
//                                                               AppTextWeight
//                                                                   .bold,
//                                                           colorType:
//                                                               AppTextColorType
//                                                                   .primary,
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                   SizedBox(height: 8),
//                                                   SizedBox(
//                                                     width:
//                                                         MediaQuery.of(
//                                                           context,
//                                                         ).size.width,
//                                                     height:
//                                                         MediaQuery.of(
//                                                           context,
//                                                         ).size.height *
//                                                         0.18,
//                                                     child: PageView.builder(
//                                                       itemCount:
//                                                           _recommendations
//                                                               .length,
//                                                       controller:
//                                                           pageViewController,
//                                                       physics:
//                                                           const ClampingScrollPhysics(),
//                                                       onPageChanged: (pageNo) {
//                                                         setState(() {
//                                                           currentPage = pageNo;
//                                                         });
//                                                       },
//                                                       itemBuilder: (
//                                                         context,
//                                                         index,
//                                                       ) {
//                                                         final recommendation =
//                                                             _recommendations[index];
//                                                         return PromotionalCard(
//                                                           title:
//                                                               recommendation['title'],
//                                                           description:
//                                                               recommendation['description'],
//                                                           buttonText:
//                                                               recommendation['buttonText'],
//                                                           onButtonTap:
//                                                               recommendation['onTap'],
//                                                           imagePath:
//                                                               recommendation['imagePath'],
//                                                           gradientColors:
//                                                               recommendation['gradientColors'],
//                                                           gradientCenter:
//                                                               recommendation['gradientCenter'],
//                                                           gradientRadius:
//                                                               recommendation['gradientRadius'],
//                                                           useBackdropFilter:
//                                                               recommendation['useBackdropFilter'],
//                                                         );
//                                                       },
//                                                     ),
//                                                   ),
//                                                   SizedBox(height: 8),
//                                                   SizedBox(
//                                                     height: 8,
//                                                     child: Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       children: List.generate(_recommendations.length, (
//                                                         index,
//                                                       ) {
//                                                         return AnimatedContainer(
//                                                           duration: Duration(
//                                                             milliseconds: 300,
//                                                           ),
//                                                           curve:
//                                                               Curves.easeInOut,
//                                                           margin:
//                                                               EdgeInsets.symmetric(
//                                                                 horizontal: 2,
//                                                               ),
//                                                           width:
//                                                               currentPage ==
//                                                                       index
//                                                                   ? 30
//                                                                   : 8,
//                                                           height: 8,
//                                                           decoration: BoxDecoration(
//                                                             borderRadius:
//                                                                 BorderRadius.circular(
//                                                                   8,
//                                                                 ),
//                                                             color:
//                                                                 currentPage ==
//                                                                         index
//                                                                     ? themeController
//                                                                             .isDarkMode
//                                                                         ? AppColors
//                                                                             .darkPrimary
//                                                                         : AppColors
//                                                                             .lightPrimary
//                                                                     : themeController
//                                                                         .isDarkMode
//                                                                     ? AppColors
//                                                                         .darkButtonBorder
//                                                                     : AppColors
//                                                                         .lightButtonBorder,
//                                                           ),
//                                                         );
//                                                       }),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),

//                                             Material(
//                                               color: AppColors.darkBackground,
//                                               child: Column(
//                                                 children: [
//                                                   SizedBox(height: 60),
//                                                   Padding(
//                                                     padding:
//                                                         const EdgeInsets.symmetric(
//                                                           horizontal:
//                                                               AppSizing
//                                                                   .scaffoldHorizontalPadding,
//                                                         ),
//                                                     child: Row(
//                                                       children: [
//                                                         Text(
//                                                           "make your \nmoney grow.",
//                                                           style: TextStyle(
//                                                             fontSize: 38,
//                                                             fontWeight:
//                                                                 FontWeight.w900,
//                                                             color: Colors.white
//                                                                 .withValues(
//                                                                   alpha: 0.30,
//                                                                 ),
//                                                             height: 1.0,
//                                                             fontFamily:
//                                                                 "Montserrat",
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                   // AppButton(
//                                                   //   onPressed: () {
//                                                   //     Get.to(
//                                                   //       () => const SaafeDataFetch(),
//                                                   //     );
//                                                   //   },
//                                                   //   text: 'Get Started',
//                                                   // ),
//                                                   SizedBox(height: 20),
//                                                   Padding(
//                                                     padding:
//                                                         const EdgeInsets.symmetric(
//                                                           horizontal:
//                                                               AppSizing
//                                                                   .scaffoldHorizontalPadding,
//                                                         ),
//                                                     child: Row(
//                                                       children: [
//                                                         Text(
//                                                           "Made with ❤️ in India",
//                                                           style: TextStyle(
//                                                             fontSize: 18,
//                                                             fontWeight:
//                                                                 FontWeight.w800,
//                                                             color: Colors.white
//                                                                 .withValues(
//                                                                   alpha: 0.30,
//                                                                 ),
//                                                             height: 1.0,
//                                                             fontFamily:
//                                                                 "Montserrat",
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 40),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),

//                                 // Refresh notification
//                                 // if (_showRefreshNotification)
//                                 // Positioned(
//                                 //   top: 16,
//                                 //   left: 0,
//                                 //   right: 0,
//                                 //   child: Center(
//                                 //     child: Container(
//                                 //       padding: const EdgeInsets.symmetric(
//                                 //         horizontal: 16,
//                                 //         vertical: 8,
//                                 //       ),
//                                 //       decoration: BoxDecoration(
//                                 //         color:
//                                 //             themeController.isDarkMode
//                                 //                 ? AppColors.darkPrimary.withOpacity(
//                                 //                   0.9,
//                                 //                 )
//                                 //                 : AppColors.lightPrimary
//                                 //                     .withOpacity(0.9),
//                                 //         borderRadius: BorderRadius.circular(20),
//                                 //         boxShadow: [
//                                 //           BoxShadow(
//                                 //             color: Colors.black.withOpacity(0.1),
//                                 //             blurRadius: 10,
//                                 //             offset: const Offset(0, 2),
//                                 //           ),
//                                 //         ],
//                                 //       ),
//                                 //       child: AppText(
//                                 //         'Data refreshed successfully',
//                                 //         colorType: AppTextColorType.white,
//                                 //         variant: AppTextVariant.bodySmall,
//                                 //       ),
//                                 //     ),
//                                 //   ),
//                                 // ),
//                               ],
//                             ),
//                           ),
//                           if (_showOverlay)
//                             TweenAnimationBuilder<double>(
//                               duration: const Duration(milliseconds: 800),
//                               curve: Curves.easeInOutCubic,
//                               tween: Tween<double>(
//                                 begin: 0.0,
//                                 end: _overlayOpacity,
//                               ),
//                               builder: (context, opacity, child) {
//                                 return TweenAnimationBuilder<double>(
//                                   duration: const Duration(milliseconds: 800),
//                                   curve: Curves.easeInOutCubic,
//                                   tween: Tween<double>(
//                                     begin: 0.0,
//                                     end: _revealFraction,
//                                   ),
//                                   builder: (context, fraction, child) {
//                                     return ClipPath(
//                                       clipper: CircularRevealClipper(
//                                         fraction: fraction,
//                                         centerOffset: _revealCenter,
//                                       ),
//                                       child: Container(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         height:
//                                             MediaQuery.of(context).size.height,
//                                         color: Colors.black.withOpacity(
//                                           opacity * 1,
//                                         ),
//                                         child: BackdropFilter(
//                                           filter: ImageFilter.blur(
//                                             sigmaX: opacity * 0,
//                                             sigmaY: opacity * 0,
//                                           ),
//                                           child: Center(
//                                             child: TweenAnimationBuilder<
//                                               double
//                                             >(
//                                               duration: const Duration(
//                                                 milliseconds: 1800,
//                                               ),
//                                               curve: Curves.easeOutCubic,
//                                               tween: Tween<double>(
//                                                 begin: 0.7,
//                                                 end: _overlayScale,
//                                               ),
//                                               builder: (context, scale, child) {
//                                                 return Transform.scale(
//                                                   scale: scale,
//                                                   child: Container(
//                                                     padding:
//                                                         const EdgeInsets.symmetric(
//                                                           horizontal: 40,
//                                                           vertical: 32,
//                                                         ),
//                                                     decoration: BoxDecoration(
//                                                       color:
//                                                           AppColors.darkCardBG,
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                             24,
//                                                           ),
//                                                     ),
//                                                     child: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         TweenAnimationBuilder<
//                                                           double
//                                                         >(
//                                                           duration:
//                                                               const Duration(
//                                                                 milliseconds:
//                                                                     2000,
//                                                               ),
//                                                           curve:
//                                                               Curves
//                                                                   .easeInOutSine,
//                                                           tween: Tween<double>(
//                                                             begin: 0.95,
//                                                             end: 1.05,
//                                                           ),
//                                                           builder: (
//                                                             context,
//                                                             iconScale,
//                                                             child,
//                                                           ) {
//                                                             return TweenAnimationBuilder<
//                                                               double
//                                                             >(
//                                                               duration:
//                                                                   const Duration(
//                                                                     milliseconds:
//                                                                         4000,
//                                                                   ),
//                                                               curve:
//                                                                   Curves
//                                                                       .easeInOutCubic,
//                                                               tween:
//                                                                   Tween<double>(
//                                                                     begin:
//                                                                         -0.04,
//                                                                     end: 0.04,
//                                                                   ),
//                                                               builder: (
//                                                                 context,
//                                                                 rotateValue,
//                                                                 child,
//                                                               ) {
//                                                                 return Transform.rotate(
//                                                                   angle: 0,
//                                                                   child: Transform.scale(
//                                                                     scale:
//                                                                         iconScale,
//                                                                     child: Container(
//                                                                       padding:
//                                                                           const EdgeInsets.all(
//                                                                             20,
//                                                                           ),
//                                                                       decoration: BoxDecoration(
//                                                                         color: AppColors
//                                                                             .darkPrimary
//                                                                             .withOpacity(
//                                                                               0.15,
//                                                                             ),
//                                                                         shape:
//                                                                             BoxShape.circle,
//                                                                         boxShadow: [
//                                                                           BoxShadow(
//                                                                             color: AppColors.darkPrimary.withOpacity(
//                                                                               0.2,
//                                                                             ),
//                                                                             blurRadius:
//                                                                                 20,
//                                                                             spreadRadius:
//                                                                                 5,
//                                                                           ),
//                                                                         ],
//                                                                       ),
//                                                                       child: Icon(
//                                                                         _switchMode.contains(
//                                                                               'Family',
//                                                                             )
//                                                                             ? Icons.family_restroom
//                                                                             : Icons.person,
//                                                                         color:
//                                                                             AppColors.darkPrimary,
//                                                                         size:
//                                                                             40,
//                                                                       ),
//                                                                     ),
//                                                                   ),
//                                                                 );
//                                                               },
//                                                             );
//                                                           },
//                                                         ),
//                                                         const SizedBox(
//                                                           height: 32,
//                                                         ),
//                                                         TweenAnimationBuilder<
//                                                           Offset
//                                                         >(
//                                                           duration:
//                                                               const Duration(
//                                                                 milliseconds:
//                                                                     5000,
//                                                               ),
//                                                           curve:
//                                                               Curves
//                                                                   .easeInOutQuart,
//                                                           tween: Tween<Offset>(
//                                                             begin: const Offset(
//                                                               0,
//                                                               -0.02,
//                                                             ),
//                                                             end: const Offset(
//                                                               0,
//                                                               0.02,
//                                                             ),
//                                                           ),
//                                                           builder: (
//                                                             context,
//                                                             offset,
//                                                             child,
//                                                           ) {
//                                                             return Transform.translate(
//                                                               offset: Offset(
//                                                                 0,
//                                                                 offset.dy * 100,
//                                                               ),
//                                                               child: Transform.scale(
//                                                                 scale:
//                                                                     1 -
//                                                                     (offset.dy *
//                                                                         0.3),
//                                                                 child: AppText(
//                                                                   'Switching to',
//                                                                   variant:
//                                                                       AppTextVariant
//                                                                           .bodyLarge,
//                                                                   colorType:
//                                                                       AppTextColorType
//                                                                           .secondary,
//                                                                 ),
//                                                               ),
//                                                             );
//                                                           },
//                                                         ),
//                                                         const SizedBox(
//                                                           height: 12,
//                                                         ),
//                                                         TweenAnimationBuilder<
//                                                           Offset
//                                                         >(
//                                                           duration:
//                                                               const Duration(
//                                                                 milliseconds:
//                                                                     2000,
//                                                               ),
//                                                           curve:
//                                                               Curves
//                                                                   .easeInOutSine,
//                                                           tween: Tween<Offset>(
//                                                             begin: const Offset(
//                                                               0,
//                                                               -0.02,
//                                                             ),
//                                                             end: const Offset(
//                                                               0,
//                                                               0.02,
//                                                             ),
//                                                           ),
//                                                           builder: (
//                                                             context,
//                                                             offset,
//                                                             child,
//                                                           ) {
//                                                             return Transform.translate(
//                                                               offset: Offset(
//                                                                 0,
//                                                                 offset.dy * 100,
//                                                               ),
//                                                               child: Transform.scale(
//                                                                 scale:
//                                                                     1 -
//                                                                     (offset.dy *
//                                                                         0.2),
//                                                                 child: AppText(
//                                                                   _switchMode,
//                                                                   variant:
//                                                                       AppTextVariant
//                                                                           .headline4,
//                                                                   weight:
//                                                                       AppTextWeight
//                                                                           .bold,
//                                                                 ),
//                                                               ),
//                                                             );
//                                                           },
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                         ],
//                       ),
//                     ),
//                     bottomNavigationBar:
//                         !_showOverlay
//                             ? Container(
//                               decoration: BoxDecoration(
//                                 border: Border(
//                                   top: BorderSide(
//                                     color: const Color.fromARGB(
//                                       255,
//                                       96,
//                                       96,
//                                       96,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               child: BottomNavigationBar(
//                                 currentIndex: _selectedIndex,
//                                 onTap: (index) {
//                                   setState(() {
//                                     _selectedIndex = index;
//                                   });

//                                   if (index == 1) {
//                                     Get.to(
//                                       () => const MutualFundSwitchScreen(),
//                                       transition: Transition.rightToLeft,
//                                     );
//                                   } else if (index == 2) {
//                                     Get.to(
//                                       () => const AssetBankScreen(),
//                                       transition: Transition.rightToLeft,
//                                     );
//                                   } else if (index == 3) {
//                                     Get.to(
//                                       () => const ExploreScreen(),
//                                       transition: Transition.rightToLeft,
//                                     );
//                                   }
//                                 },
//                                 selectedItemColor: AppColors.darkTextGray,
//                                 unselectedItemColor: AppColors.darkTextGray,
//                                 type: BottomNavigationBarType.fixed,
//                                 items: [
//                                   BottomNavigationBarItem(
//                                     icon: Icon(
//                                       Icons.home_rounded,
//                                       color: AppColors.darkPrimary,
//                                     ),
//                                     label: "Home",
//                                   ),
//                                   BottomNavigationBarItem(
//                                     icon: Icon(Icons.category_rounded),
//                                     label: "Switch",
//                                   ),
//                                   BottomNavigationBarItem(
//                                     icon: Icon(Icons.smart_toy_rounded),
//                                     label: "Banks",
//                                   ),
//                                   BottomNavigationBarItem(
//                                     icon: Icon(Icons.explore_rounded),
//                                     label: "Explore",
//                                   ),
//                                 ],
//                               ),
//                             )
//                             : null,
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
