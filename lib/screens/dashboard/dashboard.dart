import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/controllers/dashboard/total_networth_controller.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_refresh_controller.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/account_aggregators/aa_data_fetch_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_app_open_refresh_controller.dart';
import 'package:nwt_app/controllers/dashboard/data_fetch_status_controller.dart';
import 'package:nwt_app/controllers/dashboard/mf_top_performers_controller.dart';
import 'package:nwt_app/controllers/deeplink.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/services/bse_star/ucc_creation.dart';
import 'package:nwt_app/controllers/realtime_controller.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_realtime_controller.dart';
import 'package:nwt_app/controllers/theme_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/bse_star_v2/start_journey.dart';
import 'package:nwt_app/controllers/mf_central/mf_central_status_controller.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_instructions_screen.dart';
import 'package:nwt_app/services/mf_central/mf_central_linked_accounts_service.dart';
import 'package:nwt_app/types/account_aggregators/aa_data_fetch_options.dart';
import 'package:nwt_app/types/mf_central/mf_central_linked_account.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/screens/connections/connections.dart';
import 'package:nwt_app/screens/connections/finarkein_connection_screen.dart';
import 'package:nwt_app/screens/assets/banks/banks.dart';
import 'package:nwt_app/screens/assets/insurance/insurance.dart';
import 'package:nwt_app/screens/assets/investments/investments.dart';
import 'package:nwt_app/screens/assets/nps/nps.dart';
import 'package:nwt_app/screens/assets/investments/widgets/transaction.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/data_fetch_details_screen.dart';

import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_consents_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_status_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_integration_service.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_pending_operations.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_networth.dart';
import 'package:nwt_app/screens/dashboard/widgets/family_finance_chart.dart';
import 'package:nwt_app/screens/dashboard/widgets/unlinked_state_widgets.dart';
import 'package:nwt_app/screens/dashboard/widgets/explore_investing.dart';
import 'package:nwt_app/screens/dashboard/widgets/calculators_widget.dart';
import 'package:nwt_app/controllers/dashboard/blog_controller.dart';
import 'package:nwt_app/controllers/dashboard/calculator_controller.dart';
import 'package:nwt_app/screens/dashboard/zerodha_webview.dart';
import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_banks.dart';
import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_insurance.dart';
import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_investment.dart';
import 'package:nwt_app/screens/family_finance/screens/family_assets/family_finance_nps.dart';
import 'package:nwt_app/screens/family_finance/screens/family_management.dart';
import 'package:nwt_app/screens/family_finance/types/family_dashboard_assets.dart';
import 'package:nwt_app/screens/paper_trading/portfolio_simulator.dart';
import 'package:nwt_app/screens/personal_assets/all_personal_assets.dart';
import 'package:nwt_app/screens/personal_assets/personal_assets.dart';
import 'package:nwt_app/screens/profile/user_profile.dart';
import 'package:nwt_app/screens/kyc/kyc_flow_screen.dart';
import 'package:nwt_app/screens/advisory/advisory_intelligence.dart';
import 'package:nwt_app/services/kyc/kyc_kra_state.dart';
import 'package:nwt_app/services/kyc/kyc_service.dart';
import 'package:nwt_app/services/kyc/kyc_state_helper.dart';
import 'package:nwt_app/screens/transactions/banks/list.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/screens/dashboard/types/dashboard_assets.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'dart:developer' as dev;
import 'package:nwt_app/services/auth/auth_flow.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/fip_status_controller.dart';
import 'package:nwt_app/services/family_finance/family_dashboard_assets.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/widgets/common/otp_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/services/update_service.dart';
import 'package:nwt_app/services/zerodha/zerodha.dart';
import 'package:nwt_app/utils/circular_reveal_clipper.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/data_fetch_status_bar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/status_card_swiper.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/widgets/common/loading_widget.dart';
import 'package:nwt_app/widgets/verification/universal_pan_verification_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/screens/bse_v2_final/bse_v2_final_journey.dart';
import 'package:nwt_app/screens/mutual_funds/mutual_funds_browse_screen.dart';

// Create a controller for navbar visibility
class NavbarController extends GetxController {
  final RxBool isSwitchingMode = false.obs;

  void setIsSwitchingMode(bool value) {
    isSwitchingMode.value = value;
  }
}

enum DashboardEntryMode { unknown, linkedDashboard, unlinkedSetup }

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  final int _selectedIndex = 0;
  final dashboardAssetController = Get.put(DashboardAssetController());
  final totalNetworthController = Get.put(TotalNetworthController());
  final investmentController = Get.put(InvestmentController());
  final mfTopPerformersController = Get.put(MFTopPerformersController());
  final UserController _userController = Get.find<UserController>();
  final blogController = Get.put(BlogController());
  final calculatorController = Get.put(CalculatorController());
  final dataFetchStatusController = Get.put(DataFetchStatusController());
  late final FipStatusController _fipStatusController;
  // Realtime controller for auto-refresh on data success
  late final RealtimeController _realtimeController =
      Get.isRegistered<RealtimeController>()
          ? Get.find<RealtimeController>()
          : Get.put(RealtimeController(), permanent: true);
  late final PortfolioRealtimeController _portfolioRealtimeController;
  StreamSubscription? _realtimeTotalsSubscription;
  final _zerodhaService = ZerodhaService();
  final _accountAggregatorRouter = AccountAggregatorRouter();
  late AnimationController _refreshController;
  bool isNetworthLoading = true;
  bool isAssetsLoading = true;
  bool _isInitialLoading = true;
  bool isZerodhaLoading = false;
  bool _isRefreshing = false;
  bool _isUccMissing = false;
  bool _isAccountListFetched = false;
  final _uccService = BseUccCreationService();
  Future<List<Map<String, dynamic>>>? _swiperAccountsFuture;

  final Set<int> _loggedScrollDepths = {};

  void _onDashboardScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll <= 0) return;

    final scrollPercent =
        (currentScroll / maxScroll * 10).floor() * 10; // 10%, 20%, etc.
    if (scrollPercent > 0 && !_loggedScrollDepths.contains(scrollPercent)) {
      _loggedScrollDepths.add(scrollPercent);
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dashboardScrollDepthReached,
        parameters: {AnalyticsParams.scrollDepthPercent: scrollPercent},
      );
    }
  }

  List<Map<String, dynamic>> _getMergedAccountStatuses() {
    final List<Map<String, dynamic>> result = [];

    // 1. Add accounts from FipStatusController
    result.addAll(_fipStatusController.accounts);

    // 2. Add accounts from AaDataFetchController
    if (Get.isRegistered<AaDataFetchController>()) {
      final fetchOptions =
          Get.find<AaDataFetchController>()
              .fetchOptionsData
              .value
              ?.fetchOptions ??
          [];

      for (final option in fetchOptions) {
        // Avoid duplicates based on FIP name and masked account
        final exists = result.any(
          (acc) =>
              acc['fipname'] == option.fipName &&
              acc['maskedaccno'] == option.maskedAccNumber,
        );

        if (!exists) {
          // Default to MUTUAL_FUNDS if type is null, as these are usually MFs
          String defaultType = 'MUTUAL_FUNDS';
          if (option.fipName.toLowerCase().contains('bank')) {
            defaultType = 'SAVINGS';
          }

          result.add({
            'type': option.accountType ?? defaultType,
            'fetchstatus': option.status.toUpperCase(),
            'fipname': option.fipName,
            'guid': option.id,
            'maskedaccno': option.maskedAccNumber,
            'lastdatafetchedat': option.lastFetchedTime,
          });
        }
      }
    }

    return result;
  }

  /// Dashboard entry mode is decided based on Finarkein data availability.
  DashboardEntryMode _entryMode = DashboardEntryMode.unknown;
  bool _isFinarkeinUser() => _userController.userData?.isFinarkeinAa == true;

  bool _hasAnyFinarkeinDataNow() {
    // Check 1: TotalNetworthController (New standard API)
    if (Get.isRegistered<TotalNetworthController>()) {
      final data = Get.find<TotalNetworthController>().networthData.value?.data;
      if (data != null && data.totalNetWorth > 0) {
        return true;
      }
    }

    // Check 2: DashboardAssetController (New standard API)
    if (Get.isRegistered<DashboardAssetController>()) {
      final assets =
          Get.find<DashboardAssetController>().dashboardAssets.value?.data;
      if (assets != null && assets.any((a) => a.value > 0)) {
        return true;
      }
    }

    // Check 3: MF Central Holdings
    final mfCalc = _calculateMfFromHoldings();
    if (mfCalc != null && mfCalc > 0) {
      return true;
    }

    // Check 4: FinarkeinDataController (Legacy/Fallback)
    if (Get.isRegistered<FinarkeinDataController>()) {
      final finarkeinCtrl = Get.find<FinarkeinDataController>();
      final data = finarkeinCtrl.dataResponse.value?.data;
      if (data != null) {
        final networth = data.summary['networth'];
        if (networth != null && networth > 0) {
          return true;
        }
      }
    }

    // Check 4: RawAssetController (Legacy/Fallback)
    if (Get.isRegistered<RawAssetController>()) {
      final ctrl = Get.find<RawAssetController>();
      if (ctrl.equities.isNotEmpty ||
          ctrl.mutualFunds.isNotEmpty ||
          ctrl.etfs.isNotEmpty ||
          ctrl.banks.isNotEmpty) {
        return true;
      }
    }

    // Check 5: FipStatusController (Check for linked accounts even if data is 0)
    if (Get.isRegistered<FipStatusController>()) {
      final ctrl = Get.find<FipStatusController>();
      if (ctrl.accounts.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  bool _shouldShowUnlockCard() {
    if (_isFamilyMode) return false;
    // Don't show unlock card when data is loading - show networth section instead
    if (isNetworthLoading || isAssetsLoading || _isInitialLoading) return false;

    // All users are Finarkein users - show unlock card only if no data
    return !_hasAnyFinarkeinDataNow();
  }

  Widget _buildUnlockCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizing.scaffoldHorizontalPadding,
        right: AppSizing.scaffoldHorizontalPadding,
        top: 20.h,
      ),
      child: UnlockDashboardCard(onTap: () => _onTapLinkAllAssets(context)),
    );
  }

  Widget _buildSetupCarousel(List<SetupTaskItem> setupTasks) {
    if (_isFamilyMode || _isInitialLoading || setupTasks.isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizing.scaffoldHorizontalPadding,
        right: AppSizing.scaffoldHorizontalPadding,
        top: 16.h,
      ),
      child: CompleteSetupCarousel(tasks: setupTasks),
    );
  }

  Widget _buildNetworthHeader({required bool isLoading}) {
    if (Get.isRegistered<FinarkeinAppOpenRefreshController>()) {
      return Obx(() {
        final state = FinarkeinAppOpenRefreshController.to.currentState.value;
        final isAppOpenRefreshing =
            state == AppOpenRefreshState.started ||
            state == AppOpenRefreshState.inProgress;

        if (!_isRefreshing && !isAppOpenRefreshing) {
          return const SizedBox.shrink();
        }
        if (isLoading) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppText(
            'Refreshing…',
            variant: AppTextVariant.tiny,
            colorType: AppTextColorType.secondary,
          ),
        );
      });
    }

    // Fallback for non-Finarkein users (no observable to listen to)
    if (!_isRefreshing) return const SizedBox.shrink();
    if (isLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppText(
        'Refreshing…',
        variant: AppTextVariant.tiny,
        colorType: AppTextColorType.secondary,
      ),
    );
  }

  Widget _buildAssetsGridOrList() {
    // The assets list/grid UI is currently inlined where `_dashboardAssetList` is mapped.
    // This wrapper exists to make future refactors straightforward.
    return const SizedBox.shrink();
  }

  // FIP Status polling
  Timer? _fipPollingTimer;
  static const Duration _fipPollingInterval = Duration(seconds: 3);
  final Rx<FipStatusResponse?> _fipStatusResponse = Rx<FipStatusResponse?>(
    null,
  );

  final ScrollController _scrollController = ScrollController();
  DateTime? _lastLinkTime;

  double _networthAmount = 0.0;
  double _networthDelta = 0.0;
  double _networthDeltaAmount = 0.0;
  String familyId = "";
  // double _mfsavings = 0.0;
  bool _isFamilyMode = false;

  // Spends and Investments data
  SpendsData? _spendsData;
  InvestmentsData? _investmentsData;

  // List of recommendations for dynamic mapping
  List<Map<String, dynamic>> get _recommendations => [
    // {
    //   'title': 'Safeguard Gains',
    //   'description':
    //       'Be mindful to avoid the common pitfalls which people usually unknowingly do',
    //   'buttonText': 'Switch Funds',
    //   'imagePath': 'assets/imgs/dashboard/recommendation/switch.png',
    //   'gradientColors': [Color(0xFFB29CE2), Color(0xFF17181A)],
    //   'gradientCenter': Alignment.topCenter,
    //   'gradientRadius': 1.4,
    //   'useBackdropFilter': true,
    //   'onTap':
    //       () => Get.to(
    //         () => MutualFundSwitchScreen(),
    //         transition: Transition.rightToLeft,
    //       ),
    // },
    {
      'title': 'One Dashboard. Full Control',
      'description':
          'No more playing financial hide-and-seek with your family\'s wealth.',
      'buttonText': 'Create',
      'imagePath': 'assets/imgs/dashboard/recommendation/family.png',
      'gradientColors': [Color(0xFF7186F4), Color(0xFF17181A)],
      'gradientCenter': Alignment.topCenter,
      'gradientRadius': 1.4,
      'useBackdropFilter': true,
      'onTap': () {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.dashboardRecommendationFamilyFinanceClicked,
        );
        Get.to(() => FamilyManagement(), transition: Transition.rightToLeft);
      },
    },
    {
      'title': 'Paper Trading Portfolio',
      'description':
          'Track your virtual investments! Your portfolio is growing steadily with healthy overall returns',
      'buttonText': 'View',
      'imagePath': 'assets/imgs/dashboard/recommendation/paper_trading.png',
      'gradientColors': [Color(0xFFA28676), Color(0xFF17181A)],
      'gradientCenter': Alignment.topCenter,
      'gradientRadius': 1.4,
      'useBackdropFilter': true,
      'onTap': () {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.dashboardRecommendationPaperTradingClicked,
        );
        Get.to(
          () => PaperTradingPortfolio(),
          transition: Transition.rightToLeft,
        );
      },
    },
  ];

  /// Restores family mode state from persistent storage
  void _restoreFamilyModeState() {
    final savedFamilyMode =
        StorageService.read(StorageKeys.FAMILY_MODE_KEY) ?? false;
    _isFamilyMode = savedFamilyMode;
    AppLogger.info(
      'Dashboard: Restored family mode state: $_isFamilyMode',
      tag: 'Dashboard',
    );
  }

  /// Restores amount visibility state from persistent storage
  void _restoreAmountVisibilityState() {
    final savedAmountVisibility =
        StorageService.read(StorageKeys.AMOUNT_VISIBILITY_KEY) ?? false;
    _isAmountVisible = savedAmountVisibility;
    AppLogger.info(
      'Dashboard: Restored amount visibility state: $_isAmountVisible',
      tag: 'Dashboard',
    );
  }

  /// Toggles between family mode and personal mode and refreshes data
  void toggleFamilyMode() async {
    final previousMode = _isFamilyMode ? 'family' : 'individual';
    final newMode = !_isFamilyMode ? 'family' : 'individual';

    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardFamilyModeToggled,
      parameters: {
        AnalyticsParams.previousMode: previousMode,
        AnalyticsParams.newMode: newMode,
        AnalyticsParams.isFamilyMode: (!_isFamilyMode).toString(),
      },
    );

    final mode = !_isFamilyMode ? 'Family Mode' : 'Personal Mode';
    if (_userController.userData?.isfamily == false) {
      AppLogger.info(
        'User is not a family user, cannot toggle family mode',
        tag: 'Dashboard',
      );
      Get.to(() => FamilyManagement());
      return;
    }
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    // Record the start time to enforce minimum animation duration
    final startTime = DateTime.now();

    final navbarController = Get.put(NavbarController());
    navbarController.setIsSwitchingMode(true);

    // Set switching mode flag
    setState(() {
      _isFamilyMode = !_isFamilyMode;
    });

    // Save family mode state to storage or remove key when switching to individual mode
    if (_isFamilyMode) {
      StorageService.write(StorageKeys.FAMILY_MODE_KEY, _isFamilyMode);
      AppLogger.info(
        'Dashboard: Saved family mode state: $_isFamilyMode',
        tag: 'Dashboard',
      );
    } else {
      StorageService.remove(StorageKeys.FAMILY_MODE_KEY);
      AppLogger.info(
        'Dashboard: Removed family mode storage key (switched to individual mode)',
        tag: 'Dashboard',
      );
    }

    // Start the animation
    _startSwitchAnimation(context, mode, center);

    try {
      // Refresh data based on the new mode
      await _initializeData();

      // Log completion of data loading
      AppLogger.info(
        'Data loaded for ${_isFamilyMode ? "Family" : "Personal"} mode',
        tag: 'Dashboard',
      );
    } catch (e) {
      AppLogger.error('Error loading data: $e', tag: 'Dashboard');
    } finally {
      // Calculate elapsed time and determine if we need to wait longer
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      final remainingMs = 4000 - elapsedMs;

      // Wait for remaining time if animation hasn't lasted 4 seconds yet
      if (remainingMs > 0) {
        AppLogger.info(
          'Waiting additional ${remainingMs}ms to complete animation (minimum 4s)',
          tag: 'Dashboard',
        );
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      // After ensuring minimum animation time, update state
      if (mounted) {
        setState(() {
          navbarController.setIsSwitchingMode(false);
        });

        // Stop the animation with smooth fade out
        _stopSwitchAnimation();
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget getAssetScreen(String id, bool isFamilyMode, {String? familyId}) {
    switch (id.toLowerCase()) {
      case 'bank':
        return isFamilyMode
            ? FamilyFinanceBanksScreen(familyId: familyId!)
            : const AssetBankScreen(forceStandardApis: true);

      case 'equity':
        return isFamilyMode
            ? FamilyFinanceInvestmentScreen(
              familyId: familyId!,
              initialCategory: 'Stocks',
            )
            : AssetInvestmentScreen(
              isstacknavbar: false,
              initialCategory: 'Equity',
            );

      case 'mutualfunds':
        return isFamilyMode
            ? FamilyFinanceInvestmentScreen(
              familyId: familyId!,
              initialCategory: 'Mutual Funds',
            )
            : AssetInvestmentScreen(
              isstacknavbar: false,
              initialCategory: 'Mutual Funds',
            );

      case 'mf':
        return isFamilyMode
            ? FamilyFinanceInvestmentScreen(
              familyId: familyId!,
              initialCategory: 'Mutual Funds',
            )
            : AssetInvestmentScreen(
              isstacknavbar: false,
              initialCategory: 'Mutual Funds',
            );

      case 'etf':
        return isFamilyMode
            ? FamilyFinanceInvestmentScreen(
              familyId: familyId!,
              initialCategory: 'ETF',
            )
            : AssetInvestmentScreen(
              isstacknavbar: false,
              initialCategory: 'ETF',
            );

      case 'insurance':
        return isFamilyMode
            ? FamilyFinanceInsuranceListScreen(familyId: familyId!)
            : const InsuranceListScreen(forceStandardApis: true);

      case 'nps':
        return isFamilyMode
            ? FamilyFinanceNPSScreen(familyId: familyId!)
            : const NPSScreen(forceStandardApis: true);

      case 'personalassets':
        return PersonalAssetsScreen(isFamilyMode: isFamilyMode);

      default:
        // Return a default screen or throw an exception
        return Scaffold(
          appBar: AppBar(title: Text('Asset Not Found')),
          body: Center(
            child: Text(
              'Asset screen for "$id" not implemented yet',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }

  final FamilyDashboardAssetsService _familyDashboardAssetsService =
      FamilyDashboardAssetsService();
  FamilyDashboardAssetsResponse? familyDashboardAssetsResponse;
  // void _showSaafePreparationBottomSheet() {
  //   if (_isBottomSheetOpen) return;

  //   _isBottomSheetOpen = true;
  //   int countdown = 5;

  //   showModalBottomSheet(
  //     context: context,
  //     isDismissible: false,
  //     enableDrag: false,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (BuildContext bottomSheetContext) {
  //       return StatefulBuilder(
  //         builder: (context, setBottomSheetState) {
  //           // Start countdown timer
  //           if (_countdownTimer == null || !_countdownTimer!.isActive) {
  //             _countdownTimer = Timer.periodic(const Duration(seconds: 1), (
  //               timer,
  //             ) {
  //               if (countdown > 0) {
  //                 setBottomSheetState(() {
  //                   countdown--;
  //                 });
  //               } else {
  //                 timer.cancel();
  //                 _countdownTimer = null;

  //                 // Close bottom sheet and open Saafe SDK
  //                 if (bottomSheetContext.mounted &&
  //                     Navigator.canPop(bottomSheetContext)) {
  //                   Navigator.pop(bottomSheetContext);
  //                 }
  //                 _isBottomSheetOpen = false;

  //                 // Open Saafe SDK with a small delay to ensure navigation completes
  //                 Future.delayed(const Duration(milliseconds: 100), () {
  //                   if (mounted) {
  //                     _openSaafeSdk();
  //                   }
  //                 });
  //               }
  //             });
  //           }

  //           return Container(
  //             decoration: const BoxDecoration(
  //               color: AppColors.darkCardBG,
  //               borderRadius: BorderRadius.only(
  //                 topLeft: Radius.circular(24),
  //                 topRight: Radius.circular(24),
  //               ),
  //             ),
  //             padding: const EdgeInsets.all(32),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const SizedBox(height: 20),

  //                 // Logo section with arrows
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: Align(
  //                         alignment: Alignment.centerLeft,
  //                         child: SvgPicture.asset('assets/app/pivot_money.svg'),
  //                       ),
  //                     ),
  //                     Expanded(
  //                       child: Center(
  //                         child: SvgPicture.asset(
  //                           'assets/svgs/saafe/saafe_redirection.svg',
  //                           height: 36,
  //                         ),
  //                       ),
  //                     ),
  //                     Expanded(
  //                       child: Align(
  //                         alignment: Alignment.centerRight,
  //                         child: Image.asset(
  //                           'assets/svgs/saafe/saafe_logo.png',
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 40),

  //                 // Title
  //                 const AppText(
  //                   "Redirecting to Saafe\nAccount Aggregator",
  //                   variant: AppTextVariant.headline4,
  //                   weight: AppTextWeight.bold,
  //                   textAlign: TextAlign.center,
  //                   colorType: AppTextColorType.primary,
  //                   lineHeight: 1.3,
  //                 ),
  //                 const SizedBox(height: 16),

  //                 // Description
  //                 const AppText(
  //                   "RBI authorized institution that securely finds and\nshares your financial data with us",
  //                   variant: AppTextVariant.bodyMedium,
  //                   colorType: AppTextColorType.secondary,
  //                   textAlign: TextAlign.center,
  //                   lineHeight: 1.4,
  //                 ),
  //                 const SizedBox(height: 20),

  //                 // Failure-state note (AA limitations)
  //                 Container(
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                     color: AppColors.darkCardBG,
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(color: AppColors.darkButtonBorder),
  //                   ),
  //                   padding: const EdgeInsets.all(16),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: const [
  //                           Icon(
  //                             Icons.warning_amber_rounded,
  //                             color: Colors.amberAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'PLEASE NOTE',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                           SizedBox(width: 4),
  //                           Icon(
  //                             Icons.warning_amber_rounded,
  //                             color: Colors.amberAccent,
  //                             size: 18,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 12),
  //                       const AppText(
  //                         'Account Aggregators DO NOT support',
  //                         variant: AppTextVariant.bodyMedium,
  //                         colorType: AppTextColorType.secondary,
  //                       ),
  //                       const SizedBox(height: 12),

  //                       // Bullet: Joint Accounts
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.close_rounded,
  //                             color: Colors.redAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'JOINT ACCOUNTS',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),

  //                       // Bullet: Current Accounts
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.close_rounded,
  //                             color: Colors.redAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'CURRENT ACCOUNTS',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),

  //                       // Bullet: NRE/NRO Accounts
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.close_rounded,
  //                             color: Colors.redAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             'NRE/NRO ACCOUNTS',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),

  //                       // Bullet: Insurance partly supported
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: const [
  //                           Icon(
  //                             Icons.error_outline,
  //                             color: Colors.orangeAccent,
  //                             size: 18,
  //                           ),
  //                           SizedBox(width: 8),
  //                           AppText(
  //                             ' INSURANCE partly supported',
  //                             variant: AppTextVariant.bodyMedium,
  //                             weight: AppTextWeight.semiBold,
  //                             colorType: AppTextColorType.primary,
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),

  //                 // Learn More link
  //                 GestureDetector(
  //                   onTap: () async {
  //                     // Open Sahamati website
  //                     final Uri url = Uri.parse(
  //                       'https://sahamati.org.in/what-is-account-aggregator/',
  //                     );
  //                     if (await canLaunchUrl(url)) {
  //                       await launchUrl(
  //                         url,
  //                         mode: LaunchMode.externalApplication,
  //                       );
  //                     }
  //                   },
  //                   child: const AppText(
  //                     "Learn More",
  //                     variant: AppTextVariant.bodyMedium,
  //                     colorType: AppTextColorType.link,
  //                     weight: AppTextWeight.medium,
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 24),

  //                 // Trust indicator with Indian flag
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 20,
  //                     vertical: 12,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(25),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       // Indian flag
  //                       Container(
  //                         width: 24,
  //                         height: 16,
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(2),
  //                         ),
  //                         child: Column(
  //                           children: [
  //                             Expanded(
  //                               child: Container(
  //                                 decoration: const BoxDecoration(
  //                                   color: Color(0xFFFF9933),
  //                                   borderRadius: BorderRadius.only(
  //                                     topLeft: Radius.circular(2),
  //                                     topRight: Radius.circular(2),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                             Expanded(
  //                               child: Container(
  //                                 color: Colors.white,
  //                                 child: const Center(
  //                                   child: Icon(
  //                                     Icons.circle,
  //                                     color: Color(0xFF000080),
  //                                     size: 6,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                             Expanded(
  //                               child: Container(
  //                                 decoration: const BoxDecoration(
  //                                   color: Color(0xFF138808),
  //                                   borderRadius: BorderRadius.only(
  //                                     bottomLeft: Radius.circular(2),
  //                                     bottomRight: Radius.circular(2),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
  //                       const AppText(
  //                         "Used by 10+ million citizens across India",
  //                         variant: AppTextVariant.bodySmall,
  //                         colorType: AppTextColorType.black,
  //                         weight: AppTextWeight.semiBold,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 32),
  //                 GestureDetector(
  //                   onTap: () {
  //                     _countdownTimer?.cancel();
  //                     _countdownTimer = null;
  //                     _isBottomSheetOpen = false;
  //                     Navigator.pop(bottomSheetContext);
  //                   },
  //                   child: const AppText(
  //                     "Cancel",
  //                     variant: AppTextVariant.bodyMedium,
  //                     colorType: AppTextColorType.link,
  //                     weight: AppTextWeight.semiBold,
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),

  //                 // Bottom padding for safe area
  //                 SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   ).whenComplete(() {
  //     _isBottomSheetOpen = false;
  //     _countdownTimer?.cancel();
  //     _countdownTimer = null;
  //   });
  // }

  Future<void> _checkAppVersion() async {
    AppLogger.info('Starting app version check', tag: 'Dashboard');

    // Get current version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Get required version from remote config based on platform
    final remoteConfig = RemoteConfigService.to;
    String requiredVersion;
    String platform;

    if (GetPlatform.isIOS) {
      requiredVersion = remoteConfig.minimumIosVersion.value;
      platform = 'iOS';
    } else {
      requiredVersion = remoteConfig.minimumAppVersion.value;
      platform = 'Android';
    }

    if (requiredVersion.isNotEmpty) {
      AppLogger.info(
        'Checking version on dashboard - Platform: $platform, Current: $currentVersion, Required: $requiredVersion',
        tag: 'Dashboard',
      );

      // Split version strings
      final current = currentVersion.split('.');
      final required = requiredVersion.split('.');

      // Compare versions
      bool needsUpdate = false;

      if (current.length >= 3 && required.length >= 3) {
        final currentMajor = int.parse(current[0]);
        final currentMinor = int.parse(current[1]);
        final currentPatch = int.parse(current[2]);

        final requiredMajor = int.parse(required[0]);
        final requiredMinor = int.parse(required[1]);
        final requiredPatch = int.parse(required[2]);

        if (currentMajor < requiredMajor ||
            (currentMajor == requiredMajor && currentMinor < requiredMinor) ||
            (currentMajor == requiredMajor &&
                currentMinor == requiredMinor &&
                currentPatch < requiredPatch)) {
          needsUpdate = true;
        }
      }

      if (needsUpdate && mounted) {
        AppLogger.info(
          'Update needed - Platform: $platform, Current: $currentVersion is older than required: $requiredVersion',
          tag: 'Dashboard',
        );

        // Debug: Check current route
        AppLogger.info('Current route: ${Get.currentRoute}', tag: 'Dashboard');

        // Show update dialog
        try {
          final updateService = Get.find<UpdateService>();
          AppLogger.info(
            'UpdateService found, calling showUpdateDialog',
            tag: 'Dashboard',
          );

          await updateService.showUpdateDialog(
            context,
            isCritical: true,
            message:
                'Your app version ($currentVersion) needs to be updated to the latest version ($requiredVersion) to continue using the app.',
            canDismiss: false,
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Error calling UpdateService: $e',
            error: e,
            stackTrace: stackTrace,
            tag: 'Dashboard',
          );

          // Fallback: Show a simple dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
                    title: Text('Update Required'),
                    content: Text(
                      'Your app version ($currentVersion) needs to be updated to the latest version ($requiredVersion) to continue using the app.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Try to launch store URL
                          final remoteConfig = RemoteConfigService.to;
                          final storeUrl = remoteConfig.playStoreUrl.value;
                          if (storeUrl.isNotEmpty) {
                            launchUrl(Uri.parse(storeUrl));
                          }
                        },
                        child: Text('Update Now'),
                      ),
                    ],
                  ),
            );
          }
        }
      }
    }

    AppLogger.info('App version check completed', tag: 'Dashboard');
  }

  Future<void> fetchFamilyData() async {
    try {
      await _fetchFamilyDashboardAssets();
      // Force rebuild after data fetch
      if (mounted) {
        setState(() {});
      }
      AppLogger.info('Family data fetched successfully', tag: 'Dashboard');
    } catch (e) {
      AppLogger.error('Error fetching family data: $e', tag: 'Dashboard');
    }
  }

  Future<void> _fetchFamilyDashboardAssets() async {
    try {
      // Clear existing data first to ensure we don't have stale data
      if (mounted) {
        setState(() {
          familyDashboardAssetsResponse = null;
        });
      }

      final response = await _familyDashboardAssetsService
          .getFamilyDashboardAssets(
            onLoading: (isLoading) {
              if (mounted) {
                setState(() {
                  isAssetsLoading = isLoading;
                  isNetworthLoading = isLoading;
                });
              }
            },
          );

      if (mounted) {
        setState(() {
          // Set the response in state to trigger rebuild
          familyDashboardAssetsResponse = response;
          _networthAmount = familyDashboardAssetsResponse?.data?.total ?? 0;
          familyId = familyDashboardAssetsResponse?.data?.familyid ?? "";
        });
      }

      final membersCount = response.data?.members.length ?? 0;
      AppLogger.info(
        'Family dashboard assets fetched successfully: $membersCount members',
        tag: 'FAMILY_CHART',
      );
    } catch (e) {
      AppLogger.error('Error fetching dashboard assets: $e', tag: 'Dashboard');
    }
  }

  Future<void> _checkUccStatus() async {
    try {
      final response = await _uccService.checkUccStatus();
      if (mounted) {
        setState(() {
          // If response is null or has isUccNotFound true, set _isUccMissing to true
          _isUccMissing = response == null || response.isUccNotFound;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error checking UCC status in Dashboard: $e',
        tag: 'Dashboard',
      );
    }
  }

  Future<void> _initializeData() async {
    try {
      AppLogger.info('Initializing Dashboard data...', tag: 'Dashboard');

      // 1. Fetch user profile first to ensure we know Finarkein status
      var userResponse = await _userController.fetchUserProfile(
        onLoading: (_) {},
      );
      if (userResponse.user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        userResponse = await _userController.fetchUserProfile(
          onLoading: (_) {},
        );
      }

      final user = _userController.userData;
      final isFinarkein = user?.isFinarkeinAa == true;

      if (isFinarkein &&
          Get.isRegistered<FinarkeinAppOpenRefreshController>()) {
        final refreshController = FinarkeinAppOpenRefreshController.to;

        // Add a delay to prevent backend database locks from concurrent API calls on app open
        await Future.delayed(const Duration(seconds: 2));
        await refreshController.initiateAppOpenRefresh();

        // Show message if any
        // final msg = refreshController.getMessage();
        // if (msg != null && mounted) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text(msg),
        //         duration: const Duration(seconds: 3),
        //       ),
        //     );
        //   });
        // }

        // If no cached data, we must wait or show a skeleton.
        // For now, we will proceed but keep the loaders active if hasCachedData is false.
        if (!refreshController.hasCachedData.value &&
            (refreshController.currentState.value ==
                    AppOpenRefreshState.started ||
                refreshController.currentState.value ==
                    AppOpenRefreshState.inProgress)) {
          AppLogger.info(
            'No cached data and refresh in progress, showing loaders',
            tag: 'Dashboard',
          );
          setState(() {
            isAssetsLoading = true;
            isNetworthLoading = true;
            _isInitialLoading = true;
          });
        }
      }

      // 2. START PRIMARY DATA FETCHES (all in parallel)
      final primaryFetches = Future.wait([
        totalNetworthController.fetchTotalNetworth(),
        dashboardAssetController.fetchDashboardAssets(),
        // Fetch MFC holdings (V2 API) + update status so
        // _calculateMfFromHoldings picks up MFC data on first open
        investmentController.fetchMFCentralHoldings(),
        if (Get.isRegistered<MFCentralStatusController>())
          MFCentralStatusController.to.fetchAndUpdateStatus(),
      ]);

      // Wait for primary data to finish as the absolute priority
      await primaryFetches;

      // Only stop loaders if we have cached data or refresh is already fresh
      final hasDataToDisplay =
          !isFinarkein ||
          FinarkeinAppOpenRefreshController.to.hasCachedData.value ||
          FinarkeinAppOpenRefreshController.to.currentState.value ==
              AppOpenRefreshState.alreadyFresh;

      // Update local state with primary data immediately
      if (totalNetworthController.networthData.value?.data != null) {
        final data = totalNetworthController.networthData.value!.data!;

        // Get calculated MF, Equity and ETF values from holdings
        final mfCalc = _calculateMfFromHoldings() ?? 0.0;
        final backendMfValue = _getBackendMfValue();

        final eqCalc = _calculateEquityFromHoldings() ?? 0.0;
        final backendEquityValue = _getBackendEquityValue();

        final etfCalc = _calculateEtfFromHoldings() ?? 0.0;
        final backendEtfValue = _getBackendEtfValue();

        final wsTotals = _portfolioRealtimeController.totals.value;
        final wsEquity = wsTotals?.equityTotal ?? 0.0;
        final wsEtf = wsTotals?.etfTotal ?? 0.0;

        final hasLinkedData =
            mfCalc > 0 ||
            eqCalc > 0 ||
            etfCalc > 0 ||
            wsEquity > 0 ||
            wsEtf > 0;
        final double mfVal;
        final double eqVal;
        final double etfVal;

        if (hasLinkedData) {
          mfVal = mfCalc;
          eqVal = wsEquity > 0 ? wsEquity : (eqCalc > 0 ? eqCalc : backendEquityValue);
          etfVal = wsEtf > 0 ? wsEtf : (etfCalc > 0 ? etfCalc : backendEtfValue);
        } else {
          mfVal = backendMfValue;
          eqVal = backendEquityValue;
          etfVal = backendEtfValue;
        }

        // Safe replacement logic: subtract backend MF, Equity, and ETF if present to avoid double counting
        _networthAmount =
            (data.totalNetWorth -
                backendMfValue -
                backendEquityValue -
                backendEtfValue) +
            mfVal +
            eqVal +
            etfVal;
        _networthDeltaAmount = data.deltaamount ?? 0.0;
        _networthDelta = data.deltapercentage ?? 0.0;
        if (_networthDelta == 0.0 &&
            _networthDeltaAmount != 0.0 &&
            _networthAmount > 0) {
          final prevNetworth = _networthAmount - _networthDeltaAmount;
          if (prevNetworth > 0) {
            _networthDelta = (_networthDeltaAmount / prevNetworth) * 100;
          }
        }
        _spendsData = data.spends;

        // Add calculated MF, Equity, and ETF to backend investments with safe replacement
        if (data.investments != null) {
          _investmentsData = FinancialData.investments(
            amount: mfVal + eqVal + etfVal,
            delta: data.investments!.delta,
            deltarange: data.investments!.deltarange,
            islinked:
                data.investments!.islinked ||
                mfCalc > 0 ||
                eqCalc > 0 ||
                etfCalc > 0 ||
                wsEquity > 0 ||
                wsEtf > 0,
            deltaamount: data.investments!.deltaamount,
          );
        } else if (mfCalc > 0 || eqCalc > 0 || etfCalc > 0 || wsEquity > 0 || wsEtf > 0) {
          _investmentsData = FinancialData.investments(
            amount: mfVal + eqVal + etfVal,
            delta: 0,
            deltarange: "",
            islinked: true,
            deltaamount: 0,
          );
        } else {
          _investmentsData = null;
        }
      }

      // STOP THE LOADER FAST as soon as networth and assets are received
      if (mounted && hasDataToDisplay) {
        setState(() {
          isAssetsLoading = false;
          isNetworthLoading = false;
          _isInitialLoading = false; // Hide global dashboard loader
        });
        if (_refreshController.isAnimating) {
          _refreshController.stop();
          _refreshController.reset();
        }
      }

      if (_isFamilyMode) {
        await fetchFamilyData();
      } else {
        final user = _userController.userData;
        final isFinarkein = user?.isFinarkeinAa == true;

        // Register necessary controllers
        if (isFinarkein) {
          if (!Get.isRegistered<FinarkeinDataController>()) {
            Get.put(FinarkeinDataController());
          }
          if (!Get.isRegistered<RawAssetController>()) {
            Get.put(RawAssetController());
          }
        }

        // Determine entry mode based on the data we already fetched
        final hasData = _hasAnyFinarkeinDataNow();
        if (mounted) {
          setState(() {
            _entryMode =
                hasData
                    ? DashboardEntryMode.linkedDashboard
                    : DashboardEntryMode.unlinkedSetup;
          });
        }

        // Secondary background tasks
        if (isFinarkein) {
          final provider = getAccountAggregatorDataProvider();
          provider.fetchAccountList(fetchResults: false).then((response) {
            if (response != null && mounted) {
              setState(() {
                _fipStatusResponse.value = response;
                _fipStatusController.statusResponse.value = response;
                _isAccountListFetched = true;
              });
            }
          });
          await fetchDashboardData();
        } else if (hasData) {
          final provider = getAccountAggregatorDataProvider();
          final response = await provider.fetchAccountList(fetchResults: false);
          if (response != null) {
            _fipStatusResponse.value = response;
            _fipStatusController.statusResponse.value = response;
            _isAccountListFetched = true;
          }
          await fetchDashboardData();
        }
      }

      // Cleanup and UI update
      if (mounted) {
        setState(() {
          _notificationTimer?.cancel();
          _notificationTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() {});
          });
        });
      }

      // MF Bottom sheet logic
      if (userResponse.user?.ismfverified == true) {
        final hasShownBottomSheet =
            StorageService.read(StorageKeys.MF_BOTTOMSHEET_SHOWN_KEY) ?? false;
        if (!hasShownBottomSheet && mounted) {
          // Future logic for MF bottom sheet
        }
      }
    } catch (e) {
      AppLogger.error('Dashboard initData error: $e', tag: 'Dashboard');
    } finally {
      if (mounted) {
        setState(() {
          isAssetsLoading = false;
          isNetworthLoading = false;
          _isInitialLoading = false;
        });
        if (_refreshController.isAnimating) {
          _refreshController.stop();
          _refreshController.reset();
        }
      }
    }
  }

  /// Re-evaluates Finarkein data and refreshes dashboard accordingly.
  /// Used after link/delink callbacks.
  Future<void> _refreshAfterConsentChange() async {
    if (_isFamilyMode) {
      await fetchFamilyData();
      return;
    }

    // Perform a full refresh to ensure networth and assets are updated
    await _performRefresh();
  }

  @override
  void initState() {
    super.initState();
    _portfolioRealtimeController =
        Get.isRegistered<PortfolioRealtimeController>()
            ? Get.find<PortfolioRealtimeController>()
            : Get.put(PortfolioRealtimeController(), permanent: true);

    _portfolioRealtimeController.connectClient('dashboard');

    _realtimeTotalsSubscription = _portfolioRealtimeController.totals.listen((
      wsTotals,
    ) {
      if (wsTotals != null && mounted) {
        final mfCalc = _calculateMfFromHoldings() ?? 0.0;
        final eqCalc = _calculateEquityFromHoldings() ?? 0.0;
        final etfCalc = _calculateEtfFromHoldings() ?? 0.0;

        final wsEquity = wsTotals.equityTotal ?? 0.0;
        final wsEtf = wsTotals.etfTotal ?? 0.0;

        setState(() {
          final hasLinkedData =
              mfCalc > 0 ||
              eqCalc > 0 ||
              etfCalc > 0 ||
              wsEquity > 0 ||
              wsEtf > 0;
          final double mfVal;
          final double eqVal;
          final double etfVal;

          if (hasLinkedData) {
            mfVal = mfCalc;
            eqVal = wsEquity > 0 ? wsEquity : (eqCalc > 0 ? eqCalc : _getBackendEquityValue());
            etfVal = wsEtf > 0 ? wsEtf : (etfCalc > 0 ? etfCalc : _getBackendEtfValue());
          } else {
            mfVal = _getBackendMfValue();
            eqVal = _getBackendEquityValue();
            etfVal = _getBackendEtfValue();
          }

          if (wsTotals.totalNetworth != null) {
            _networthAmount =
                (wsTotals.totalNetworth! -
                    wsEquity -
                    wsEtf -
                    _getBackendMfValue()) +
                mfVal +
                eqVal +
                etfVal;
          }

          _investmentsData = FinancialData.investments(
            amount: mfVal + eqVal + etfVal,
            delta: _investmentsData?.delta ?? 0.0,
            deltarange: _investmentsData?.deltarange ?? "",
            islinked: true,
            deltaamount: _investmentsData?.deltaamount,
          );
        });
      }
    });

    _swiperAccountsFuture = _fetchSwiperAccounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logScreenView(screenName: 'dashboard');
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dashboardScreenViewed,
        parameters: {
          AnalyticsParams.isFamilyMode: _isFamilyMode.toString(),
          AnalyticsParams.userType: _isFamilyMode ? 'family' : 'individual',
        },
      );
    });
    // Initialize FipStatusController
    _fipStatusController =
        Get.isRegistered<FipStatusController>()
            ? Get.find<FipStatusController>()
            : Get.put(FipStatusController(), permanent: true);

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (!Get.isRegistered<DashboardRefreshController>()) {
      Get.put(DashboardRefreshController(), permanent: true);
    }
    final refreshController = Get.find<DashboardRefreshController>();
    if (refreshController.pendingLinkRefresh ||
        refreshController.pendingDelinkRefresh) {
      final bool isLink = refreshController.pendingLinkRefresh;
      refreshController.pendingLinkRefresh = false;
      refreshController.pendingDelinkRefresh = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (isLink) {
            // Wait 2 seconds as requested after giving consent
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _refreshAfterConsentChange();
            });
          } else {
            _refreshAfterConsentChange();
          }
        }
      });
    }
    refreshController.onAfterDelink = () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _refreshAfterConsentChange();
      }
    };
    refreshController.onAfterLink = () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Wait 2 seconds as requested after giving consent
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _refreshAfterConsentChange();
        });
      }
    };

    if (Get.isRegistered<FinarkeinAppOpenRefreshController>()) {
      FinarkeinAppOpenRefreshController.to.onRefreshComplete = () {
        if (mounted) {
          _performRefresh();
        }
      };
    }

    // Restore family mode state from storage
    _restoreFamilyModeState();

    // Restore amount visibility state from storage
    _restoreAmountVisibilityState();

    // Register dashboard refresh callback for realtime updates
    _realtimeController.setRefreshDataCallback(_onRefresh);
    AppLogger.info(
      'Dashboard: registered realtime refresh callback',
      tag: 'DashboardRealtimeCheck',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersion(); // Run version check immediately
    });
    _initializeData().then((_) {
      if (!mounted) return;

      if (_entryMode != DashboardEntryMode.unlinkedSetup) {
        // Start FIP status polling after core data is ready
        _startFipStatusPolling();
      }

      // Stagger secondary background fetches to avoid connection saturation
      Future.delayed(const Duration(seconds: 1), () {
        // KYC status refresh removed to prevent unnecessary API call on home screen
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          calculatorController.fetchCalculators();
          blogController.fetchBlogs();
        }
      });

      // Check for pending revoke and trigger data fetch
      _checkAndTriggerDataFetchAfterDelink();
      // Check for pending link and trigger data fetch
      _checkAndTriggerDataFetchAfterLink();
      // Check UCC status to show onboarding CTA for new users
      _checkUccStatus();
    });

    _showSetPin();
    _markOnboardingComplete();
    _scrollController.addListener(_onDashboardScroll);

    // Fetch MFC portfolio value; setState when done so asset row updates
    if (Get.isRegistered<MFCentralStatusController>()) {
      MFCentralStatusController.to.fetchAndUpdateStatus().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Checks for pending revoke operation and triggers data fetch if found.
  /// Called after Dashboard initialization when user lands from delink flow.
  Future<void> _checkAndTriggerDataFetchAfterDelink() async {
    if (!_isFinarkeinUser()) return;

    final pendingRequestId =
        FinarkeinConsentsService.pendingRevokeRequestIdFromUi;
    if (pendingRequestId == null || pendingRequestId.trim().isEmpty) return;

    // Clear the pending flag
    FinarkeinConsentsService.pendingRevokeRequestIdFromUi = null;

    try {
      AppLogger.info(
        'Dashboard: Found pending revoke, triggering data fetch for remaining consents',
        tag: 'AA_CONSENT_STATUS',
      );

      // Get active consents
      final consents = await FinarkeinConsentsService().getConsents(
        forceRefresh: true,
      );
      final activeConsents = consents.where((c) => c.isActive).toList();

      if (activeConsents.isEmpty) {
        AppLogger.info(
          'Dashboard: No remaining active consents after delink, refreshing dashboard to show unlinked state',
          tag: 'AA_CONSENT_STATUS',
        );
        if (mounted) await _performRefresh();
        return;
      }

      AppLogger.info(
        'Dashboard: Found ${activeConsents.length} remaining consent(s), calling triggerDataFetch',
        tag: 'AA_CONSENT_STATUS',
      );

      // Get first active consent
      final firstConsent = activeConsents.first;
      final consentHandle = firstConsent.consentHandle?.trim();
      final requestId = firstConsent.requestId?.trim();

      if (consentHandle == null ||
          consentHandle.isEmpty ||
          requestId == null ||
          requestId.isEmpty) {
        AppLogger.info(
          'Dashboard: First consent missing consentHandle or requestId',
          tag: 'AA_CONSENT_STATUS',
        );
        return;
      }

      AppLogger.info(
        'Dashboard: Calling triggerDataFetch consentHandle=$consentHandle requestId=$requestId',
        tag: 'AA_CONSENT_STATUS',
      );

      // Trigger data fetch
      await FinarkeinConsentsService().triggerDataFetch(
        consentHandle: consentHandle,
        requestId: requestId,
        onLoading: (_) {},
      );

      AppLogger.info(
        'Dashboard: triggerDataFetch completed successfully, refreshing dashboard',
        tag: 'AA_CONSENT_STATUS',
      );

      // Refresh dashboard after successful data fetch
      if (mounted) {
        await _performRefresh();
      }

      AppLogger.info(
        'Dashboard: Dashboard refreshed after delink data fetch',
        tag: 'AA_CONSENT_STATUS',
      );
    } catch (e, st) {
      AppLogger.error(
        'Dashboard: Error during post-delink data fetch',
        error: e,
        stackTrace: st,
        tag: 'AA_CONSENT_STATUS',
      );
    }
  }

  /// Checks for pending consent/link operation and triggers background polling if found.
  /// Called after Dashboard initialization to ensure UI updates automatically after AA redirect.
  Future<void> _checkAndTriggerDataFetchAfterLink() async {
    if (!_isFinarkeinUser()) return;

    final requestId = FinarkeinIntegrationService.pendingRequestId;
    if (requestId == null || requestId.trim().isEmpty) return;

    AppLogger.info(
      'Dashboard: Found pending consent requestId=$requestId, triggering background polling',
      tag: 'AA_CONSENT_STATUS',
    );

    // Wait 2 seconds as requested after giving consent
    await Future.delayed(const Duration(seconds: 2));

    // Polling of consent status is disabled on the dashboard to avoid 401 errors from legacy clearance API.
    // Instead, we trigger a full refresh to fetch data from standard V1 APIs (Total Networth, Dashboard Assets, etc.)
    unawaited(_performRefresh());

    // Set link time and start polling to ensure networth updates as backend processes data
    _lastLinkTime = DateTime.now();
    _startFipStatusPolling();

    // Clear the pending request so we don't trigger multiple refreshes
    FinarkeinIntegrationService.pendingRequestId = null;
  }

  /// On dashboard load: call pan/verify in background; persist new status and refresh UI.
  void _refreshKycStatusOnLoad() {
    KycService()
        .verifyPanStatus()
        .then((result) {
          if (!mounted) return;
          if (result.success) {
            KycStateHelper().setLastVerifiedStatus(result.statusForPersistence);
            // Store raw KRAKYCCOMPLETEDSTATUS value from API
            KycStateHelper().setRawKycStatus(result.kRAKYCCompletedStatus);

            // Force update dashboard controllers to refresh UI
            if (Get.isRegistered<DashboardAssetController>()) {
              Get.find<DashboardAssetController>().update();
            }
            if (mounted) setState(() {});
          }
        })
        .catchError((_) {
          // Leave persisted status as-is; optional: SnackbarHelper.showInfo('Could not refresh KYC status')
        });
  }

  /// KYC "already initiated" banner: inverted bottom-sheet style, below app bar. Non-dismissible. Single instance.
  /// Replaces stored error-style messages (e.g. "Unable to start KYC (401)") with a friendly status message.
  Widget _buildKycInProgressBanner(BuildContext context) {
    final stateHelper = KycStateHelper();
    if (!stateHelper.isAlreadyInitiatedInProgress)
      return const SizedBox.shrink();
    final raw = stateHelper.kycInProgressSnackbarMessage;
    if (raw == null || raw.isEmpty) return const SizedBox.shrink();
    final message = _kycBannerDisplayMessage(raw);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        border: Border.all(color: AppColors.darkButtonBorder, width: 1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Use friendly copy for the KYC banner when the stored message looks like an HTTP/API error.
  /// Replaces any message that contains a status code (e.g. (401), (500)) or error phrasing with a generic user message.
  static String _kycBannerDisplayMessage(String stored) {
    final lower = stored.toLowerCase();
    // Any parenthesized number (e.g. (401), (403), (500)) or common error phrases
    if (RegExp(r'\(\d{3}\)').hasMatch(stored) ||
        lower.startsWith('unable to start kyc') ||
        lower.startsWith('verification failed') ||
        lower.startsWith('could not verify')) {
      return "Your KYC is being verified. Check back later from the KYC card.";
    }
    return stored;
  }

  void _incrementAppOpenedCount() {
    final currentCount =
        StorageService.read(StorageKeys.APP_OPENED_COUNT_KEY) ?? 0;
    final newCount = currentCount + 1;
    StorageService.write(StorageKeys.APP_OPENED_COUNT_KEY, newCount);

    AppLogger.info(
      'App opened -> earlier: $currentCount now: $newCount',
      tag: 'AppOpenedCounter',
    );
  }

  void _showSetPin() {
    _incrementAppOpenedCount();
    _checkAndShowPinBottomSheet();
  }

  Future<void> _checkAndShowPinBottomSheet() async {
    final appOpenedCount =
        StorageService.read(StorageKeys.APP_OPENED_COUNT_KEY) ?? 0;
    final isPinSet =
        await SecureStorage.read(StorageKeys.IS_PIN_SET_KEY) == 'true';

    if (appOpenedCount >= 2 && !isPinSet) {
      _showPinSetupBottomSheet();
    }
    // Note: Unlinked state is now consent-bootstrapped; no unlinked bottom sheet on load.
  }

  void _showPinSetupBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: _PinSetupBottomSheet(
              onPinSetupComplete: () {
                // No-op: unlinked bottom sheet removed.
              },
            ),
          ),
    ).whenComplete(() {
      // No-op
    });
  }

  Future<void> _markOnboardingComplete() async {
    final authFlow = Get.find<AuthFlow>();
    await authFlow.clearOnboardingState();
  }

  @override
  void dispose() {
    _realtimeTotalsSubscription?.cancel();
    _portfolioRealtimeController.disconnectClient('dashboard');
    if (Get.isRegistered<DashboardRefreshController>()) {
      final c = Get.find<DashboardRefreshController>();
      c.onAfterDelink = null;
      c.onAfterLink = null;
    }
    _refreshController.dispose();
    _notificationTimer?.cancel();
    _scrollController.removeListener(_onDashboardScroll);
    _scrollController.dispose();
    _stopFipStatusPolling();
    super.dispose();
  }

  void _startFipStatusPolling() async {
    final isFinarkein = _userController.userData?.isFinarkeinAa == true;

    // Fetch initial status if not already fetched during initialization
    if (!_isAccountListFetched) {
      await _fetchAccountListFromProvider();
    }

    if (isFinarkein) {
      // For Finarkein users, always start polling to show real-time status updates
      _startFipPolling();
    } else {
      // For non-Finarkein users, use existing logic
      final provider = getAccountAggregatorDataProvider();
      if (provider.shouldPollAccountStatus()) _startFipPolling();
    }
  }

  void _startFipPolling() {
    if (!_shouldStartFipPolling()) {
      dev.log('No accounts with fetching status, skipping FIP polling');
      return;
    }
    _stopFipStatusPolling();
    _fipPollingTimer = Timer.periodic(_fipPollingInterval, (timer) {
      if (mounted && _shouldStartFipPolling()) {
        _fetchAccountListFromProvider();
      } else {
        dev.log('Stopping FIP polling - conditions not met');
        timer.cancel();
        _fipPollingTimer = null;
      }
    });
    dev.log(
      'Started FIP status polling every ${_fipPollingInterval.inSeconds} seconds',
    );
  }

  void _stopFipStatusPolling() {
    _fipPollingTimer?.cancel();
    _fipPollingTimer = null;
    dev.log('Stopped FIP status polling');
  }

  bool _shouldStartFipPolling() {
    final response = _fipStatusResponse.value;
    if (response == null || response.FIPStatusData == null) return false;

    final isFinarkein = _userController.userData?.isFinarkeinAa == true;

    if (isFinarkein) {
      // If we recently linked an account, keep polling for 45s to allow backend data processing
      if (_lastLinkTime != null &&
          DateTime.now().difference(_lastLinkTime!) <
              const Duration(seconds: 45)) {
        return true;
      }

      // For Finarkein: Continue polling if any account is PROCESSING or PENDING
      for (final account in response.FIPStatusData!) {
        final status = account.fetchstatus.toUpperCase();
        if (status == 'PROCESSING' || status == 'PENDING') {
          return true;
        }
      }
      return false;
    } else {
      // If we recently linked an account, keep polling for 45s to allow backend data processing
      if (_lastLinkTime != null &&
          DateTime.now().difference(_lastLinkTime!) <
              const Duration(seconds: 45)) {
        return true;
      }

      // For non-Finarkein: Continue if any account is FETCHING
      for (final account in response.FIPStatusData!) {
        if (account.fetchstatus.toLowerCase() == 'fetching') return true;
      }
      return false;
    }
  }

  Future<void> _fetchAccountListFromProvider() async {
    try {
      final isFinarkein = _userController.userData?.isFinarkeinAa == true;

      if (isFinarkein) {
        // Use Finarkein-specific status service
        final finarkeinStatusService = FinarkeinStatusService();
        final response = await finarkeinStatusService.getFinarkeinStatus(
          onLoading: (isLoading) {
            // Loading state handled by existing dashboard logic
          },
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          _fipStatusResponse.value = response;
          _fipStatusController.statusResponse.value = response;
          if (_fipPollingTimer != null) {
            unawaited(totalNetworthController.fetchTotalNetworth());
            unawaited(dashboardAssetController.fetchDashboardAssets());
          }
        } else {
          _fipStatusResponse.value = null;
          if (mounted) await fetchDashboardData();
        }
      } else {
        // Use standard account aggregator provider for non-Finarkein users
        final provider = getAccountAggregatorDataProvider();
        final response = await provider.fetchAccountList(fetchResults: false);
        if (response != null) {
          _fipStatusResponse.value = response;
          _fipStatusController.statusResponse.value = response;
          if (_fipPollingTimer != null) {
            unawaited(totalNetworthController.fetchTotalNetworth());
            unawaited(dashboardAssetController.fetchDashboardAssets());
          }
        } else {
          _fipStatusResponse.value = null;
          if (mounted) await fetchDashboardData();
        }
      }
    } catch (e) {
      dev.log('Error fetching account list: $e');
    }
  }

  List<AssetData> get _dashboardAssetList {
    List<AssetData> assets;
    if (dashboardAssetController.dashboardAssets.value?.data != null &&
        dashboardAssetController.dashboardAssets.value!.data.isNotEmpty) {
      assets = dashboardAssetController.dashboardAssets.value!.data;
    } else {
      assets = getAccountAggregatorDataProvider().getDashboardAssets();
    }

    if (assets.isEmpty) return assets;

    final mfCalc = _calculateMfFromHoldings();
    final eqCalc = _calculateEquityFromHoldings();
    final etfCalc = _calculateEtfFromHoldings();
    final wsTotals = _portfolioRealtimeController.totals.value;

    return assets.map((asset) {
      final id = asset.id.toLowerCase();
      double val = asset.value;
      bool isLinked = asset.islinked;

      if (id == 'mf' || id == 'mutualfunds') {
        if (mfCalc != null && mfCalc > 0) {
          val = mfCalc;
          isLinked = true;
        }
      } else if (id == 'etf') {
        if (wsTotals?.etfTotal != null && wsTotals!.etfTotal! > 0) {
          val = wsTotals.etfTotal!;
          isLinked = true;
        } else if (etfCalc != null && etfCalc > 0) {
          val = etfCalc;
          isLinked = true;
        }
      } else if (id == 'equity') {
        if (wsTotals?.equityTotal != null && wsTotals!.equityTotal! > 0) {
          val = wsTotals.equityTotal!;
          isLinked = true;
        } else if (eqCalc != null && eqCalc > 0) {
          val = eqCalc;
          isLinked = true;
        }
      }

      return AssetData(
        id: asset.id,
        title: asset.title,
        value: val,
        deltavalue: asset.deltavalue,
        deltapercentage: asset.deltapercentage,
        islinked: isLinked,
      );
    }).toList();
  }

  // Calculate MF total value — checks 3 sources in priority order:
  //   1. investmentController.mfCentralHoldings (parsed V2 endpoint)
  //   2. investmentController.holdings (V1 AA data)
  //   3. MFCentralStatusController.totalValue (pre-computed V2 summary fallback)
  double? _calculateMfFromHoldings() {
    // Priority 1: V2 MFC holdings list (summed from active holdings)
    final mfcHoldings = investmentController.mfCentralHoldings;
    if (mfcHoldings.isNotEmpty) {
      final total = mfcHoldings.fold<double>(
        0.0,
        (s, h) => s + h.currentmktvalue,
      );
      if (total > 0) {
        AppLogger.info(
          'Dashboard MF Total from mfCentralHoldings: ₹$total '
          '(${mfcHoldings.length} holdings)',
          tag: 'Dashboard',
        );
        return total;
      }
    }

    // Priority 2: V1 AA holdings (fallback — may not include MFC data)
    final holdings = investmentController.holdings?.data?.investments.mf;
    if (holdings != null && holdings.isNotEmpty) {
      double total = 0.0;
      for (final mf in holdings) {
        total += mf.currentmktvalue;
      }
      AppLogger.info(
        'Dashboard MF Total from V1 holdings: ₹$total '
        '(${holdings.length} holdings)',
        tag: 'Dashboard',
      );
      if (total > 0) {
        return total;
      }
    }

    // Priority 3: Pre-computed total from MFC status controller
    if (Get.isRegistered<MFCentralStatusController>()) {
      final mfcTotal = MFCentralStatusController.to.totalValue.value;
      if (mfcTotal > 0) {
        AppLogger.info(
          'Dashboard MF Total from MFCStatusController fallback: ₹$mfcTotal',
          tag: 'Dashboard',
        );
        return mfcTotal;
      }
    }

    return null;
  }

  // Safely get MF value from backend dashboard assets API
  double _getBackendMfValue() {
    if (dashboardAssetController.dashboardAssets.value?.data != null) {
      final assets = dashboardAssetController.dashboardAssets.value!.data;
      final mfAsset = assets.firstWhereOrNull(
        (a) =>
            a.id.toLowerCase() == 'mf' || a.id.toLowerCase() == 'mutualfunds',
      );
      return mfAsset?.value ?? 0.0;
    }
    return 0.0;
  }

  // Calculate Equity total value from stock holdings (applying websocket live prices if available)
  double? _calculateEquityFromHoldings() {
    List<dynamic> stocks = [];
    final standardStocks =
        investmentController.holdings?.data?.investments.stocks;
    if (standardStocks != null && standardStocks.isNotEmpty) {
      stocks = standardStocks;
    } else {
      final isFinarkein = _userController.userData?.isFinarkeinAa == true;

      // For Finarkein users, use RawAssetController to get all equities from API
      if (isFinarkein && Get.isRegistered<RawAssetController>()) {
        final rawController = Get.find<RawAssetController>();
        if (rawController.equities.isNotEmpty) {
          stocks = rawController.equities;
        }
      }

      if (stocks.isEmpty) {
        // Fallback to provider
        final list = getAccountAggregatorDataProvider().getStocks();
        if (list != null && list.isNotEmpty) stocks = list;
      }
    }

    if (stocks.isEmpty) return null;

    double total = 0.0;
    final liveHoldings = _portfolioRealtimeController.holdingsMap;

    final Map<String, double> isinValues = {};
    for (final s in stocks) {
      String? isin;
      double currentVal = 0.0;
      if (s is Map<String, dynamic>) {
        isin = s['isin']?.toString();
        currentVal =
            (s['currentvalue'] ?? s['currentmktvalue'] ?? 0.0).toDouble();
      } else {
        isin = s.isin;
        currentVal = s.currentMarketValue;
      }

      if (isin != null && isin.isNotEmpty) {
        isinValues[isin] = (isinValues[isin] ?? 0.0) + currentVal;
      } else {
        total += currentVal;
      }
    }

    for (final entry in isinValues.entries) {
      final isin = entry.key;
      double val = entry.value;
      if (liveHoldings.containsKey(isin)) {
        val = liveHoldings[isin]!.marketValue;
      }
      total += val;
    }

    return total > 0 ? total : null;
  }

  // Safely get Equity value from backend dashboard assets API
  double _getBackendEquityValue() {
    if (dashboardAssetController.dashboardAssets.value?.data != null) {
      final assets = dashboardAssetController.dashboardAssets.value!.data;
      final equityAsset = assets.firstWhereOrNull(
        (a) => a.id.toLowerCase() == 'equity',
      );
      return equityAsset?.value ?? 0.0;
    }
    return 0.0;
  }

  // Calculate ETF total value from ETF holdings (applying websocket live prices if available)
  double? _calculateEtfFromHoldings() {
    List<dynamic> etfs = [];
    final standardEtfs = investmentController.holdings?.data?.investments.etf;
    if (standardEtfs != null && standardEtfs.isNotEmpty) {
      etfs = standardEtfs;
    } else {
      final isFinarkein = _userController.userData?.isFinarkeinAa == true;

      // For Finarkein users, use RawAssetController to get all ETFs from API
      if (isFinarkein && Get.isRegistered<RawAssetController>()) {
        final rawController = Get.find<RawAssetController>();
        if (rawController.etfs.isNotEmpty) {
          etfs = rawController.etfs;
        }
      }

      if (etfs.isEmpty) {
        // Fallback to provider
        final list = getAccountAggregatorDataProvider().getEtf();
        if (list != null && list.isNotEmpty) etfs = list;
      }
    }

    if (etfs.isEmpty) return null;

    double total = 0.0;
    final liveHoldings = _portfolioRealtimeController.holdingsMap;

    final Map<String, double> isinValues = {};
    for (final e in etfs) {
      String? isin;
      double currentVal = 0.0;
      if (e is Map<String, dynamic>) {
        isin = e['isin']?.toString();
        currentVal =
            (e['currentvalue'] ?? e['currentmktvalue'] ?? 0.0).toDouble();
      } else {
        isin = e.isin;
        currentVal = e.currentMarketValue;
      }

      if (isin != null && isin.isNotEmpty) {
        isinValues[isin] = (isinValues[isin] ?? 0.0) + currentVal;
      } else {
        total += currentVal;
      }
    }

    for (final entry in isinValues.entries) {
      final isin = entry.key;
      double val = entry.value;
      if (liveHoldings.containsKey(isin)) {
        val = liveHoldings[isin]!.marketValue;
      }
      total += val;
    }

    return total > 0 ? total : null;
  }

  // Safely get ETF value from backend dashboard assets API
  double _getBackendEtfValue() {
    if (dashboardAssetController.dashboardAssets.value?.data != null) {
      final assets = dashboardAssetController.dashboardAssets.value!.data;
      final etfAsset = assets.firstWhereOrNull(
        (a) => a.id.toLowerCase() == 'etf',
      );
      return etfAsset?.value ?? 0.0;
    }
    return 0.0;
  }

  void _onRefresh() {
    AppLogger.info(
      'Dashboard: _onRefresh triggered (familyMode=$_isFamilyMode)',
      tag: 'Dashboard',
    );
    () async {
      try {
        await _performRefresh();
      } catch (e) {
        AppLogger.error('Dashboard: _onRefresh error: $e', tag: 'Dashboard');
      } finally {
        if (mounted) {
          setState(() {});
        }
        AppLogger.info('Dashboard: _onRefresh completed', tag: 'Dashboard');
      }
    }();
  }

  Future<void> _performRefresh() async {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dashboardPullToRefresh,
      parameters: {AnalyticsParams.isFamilyMode: _isFamilyMode.toString()},
    );
    AppLogger.info(
      'Dashboard: pull-to-refresh start (Finarkein only)',
      tag: 'Dashboard',
    );
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _isAccountListFetched = false;
        _swiperAccountsFuture = _fetchSwiperAccounts();
      });
    }

    if (_isFamilyMode) {
      await fetchFamilyData();
    } else {
      // Background task: Refresh FIP status (don't block the UI refresh)
      final provider = getAccountAggregatorDataProvider();
      provider.refreshDashboardData(fetchResults: false).then((response) {
        if (response != null && mounted) {
          setState(() {
            _fipStatusResponse.value = response;
            _fipStatusController.statusResponse.value = response;
          });
        }
      });

      // Also refresh AaDataFetchOptions for the swiper card
      if (Get.isRegistered<AaDataFetchController>()) {
        unawaited(AaDataFetchController.to.fetchDataFetchOptions(silent: true));
      }

      // Parallelize primary data fetches including MFC holdings for accuracy
      await Future.wait([
        totalNetworthController.fetchTotalNetworth(),
        dashboardAssetController.fetchDashboardAssets(),
        investmentController.fetchMFCentralHoldings(),
        if (Get.isRegistered<MFCentralStatusController>())
          MFCentralStatusController.to.fetchAndUpdateStatus(),
      ]);

      // Set networth, spends, and investments from TotalNetworthController
      if (totalNetworthController.networthData.value?.data != null) {
        final data = totalNetworthController.networthData.value!.data!;

        // Get calculated MF, Equity and ETF values from holdings
        final mfCalc = _calculateMfFromHoldings() ?? 0.0;
        final backendMfValue = _getBackendMfValue();

        final eqCalc = _calculateEquityFromHoldings() ?? 0.0;
        final backendEquityValue = _getBackendEquityValue();

        final etfCalc = _calculateEtfFromHoldings() ?? 0.0;
        final backendEtfValue = _getBackendEtfValue();

        final wsTotals = _portfolioRealtimeController.totals.value;
        final wsEquity = wsTotals?.equityTotal ?? 0.0;
        final wsEtf = wsTotals?.etfTotal ?? 0.0;

        final hasLinkedData =
            mfCalc > 0 ||
            eqCalc > 0 ||
            etfCalc > 0 ||
            wsEquity > 0 ||
            wsEtf > 0;
        final double mfVal;
        final double eqVal;
        final double etfVal;

        if (hasLinkedData) {
          mfVal = mfCalc;
          eqVal = wsEquity > 0 ? wsEquity : (eqCalc > 0 ? eqCalc : backendEquityValue);
          etfVal = wsEtf > 0 ? wsEtf : (etfCalc > 0 ? etfCalc : backendEtfValue);
        } else {
          mfVal = backendMfValue;
          eqVal = backendEquityValue;
          etfVal = backendEtfValue;
        }

        // Safe replacement logic: subtract backend MF, Equity, and ETF if present to avoid double counting
        _networthAmount =
            (data.totalNetWorth -
                backendMfValue -
                backendEquityValue -
                backendEtfValue) +
            mfVal +
            eqVal +
            etfVal;
        _networthDeltaAmount = data.deltaamount ?? 0.0;
        _networthDelta = data.deltapercentage ?? 0.0;
        if (_networthDelta == 0.0 &&
            _networthDeltaAmount != 0.0 &&
            _networthAmount > 0) {
          final prevNetworth = _networthAmount - _networthDeltaAmount;
          if (prevNetworth > 0) {
            _networthDelta = (_networthDeltaAmount / prevNetworth) * 100;
          }
        }

        AppLogger.info(
          'Refresh: Using networth: $_networthAmount (MF Calc: $mfCalc, Backend MF: $backendMfValue, Equity Calc: $eqCalc, Backend Equity: $backendEquityValue, ETF Calc: $etfCalc, Backend ETF: $backendEtfValue, WS Equity: $wsEquity, WS ETF: $wsEtf)',
          tag: 'Dashboard',
        );

        // Set spends data from TotalNetworth API
        _spendsData = data.spends;

        // Add calculated MF, Equity, and ETF to backend investments with safe replacement
        if (data.investments != null) {
          _investmentsData = FinancialData.investments(
            amount: mfVal + eqVal + etfVal,
            delta: data.investments!.delta,
            deltarange: data.investments!.deltarange,
            islinked:
                data.investments!.islinked ||
                mfCalc > 0 ||
                eqCalc > 0 ||
                etfCalc > 0 ||
                wsEquity > 0 ||
                wsEtf > 0,
            deltaamount: data.investments!.deltaamount,
          );
        } else if (mfCalc > 0 || eqCalc > 0 || etfCalc > 0 || wsEquity > 0 || wsEtf > 0) {
          _investmentsData = FinancialData.investments(
            amount: mfVal + eqVal + etfVal,
            delta: 0,
            deltarange: "",
            islinked: true,
            deltaamount: 0,
          );
        } else {
          _investmentsData = null;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _isInitialLoading = false;
        isAssetsLoading = false;
        isNetworthLoading = false;
      });
    }
    AppLogger.info('Dashboard: pull-to-refresh end', tag: 'Dashboard');
  }

  void _showSimpleBottomSheet(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
              vertical: 8,
            ),
            width: MediaQuery.of(context).size.width,
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
                const SizedBox(height: 12),
                AppText(
                  description,
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Future<void> fetchDashboardAssets() async {
    if (mounted) {
      setState(() {
        isAssetsLoading = true;
      });
      _refreshController.repeat();
    }

    try {
      await dashboardAssetController.fetchDashboardAssets();

      if (mounted) {
        setState(() {
          isAssetsLoading = false;
        });
        _refreshController.stop();
        _refreshController.reset();
        // Intentionally do not show any "unlinked assets" modal on initial load.
        // The dashboard entry mode is decided earlier via Finarkein `aa/consents` bootstrap.
      }
    } catch (e) {
      AppLogger.error('Error fetching dashboard assets: $e', tag: 'Dashboard');
      if (mounted) {
        setState(() {
          isAssetsLoading = false;
        });
        _refreshController.stop();
        _refreshController.reset();
      }
    }
  }

  Future<void> fetchMFTopPerformers() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      await mfTopPerformersController.fetchTopPerformers(
        dashboard: true,
        limit: 10,
        type: "",
      );
      dataFetchStatusController.updateBankStatus(
        bankName: 'CAMS',
        status: DataFetchStatus.successful,
      );
      dataFetchStatusController.updateBankStatus(
        bankName: 'Karvy',
        status:
            DataFetchStatus
                .processing, // Simulate still processing for demonstration
      );

      // Simulate completion of Karvy after a delay
      Future.delayed(const Duration(seconds: 2), () {
        dataFetchStatusController.updateBankStatus(
          bankName: 'Karvy',
          status: DataFetchStatus.successful,
        );
      });
    } catch (e) {
      AppLogger.error('Error fetching MF top performers: $e', tag: 'Dashboard');

      // Update statuses to failed
      dataFetchStatusController.updateBankStatus(
        bankName: 'CAMS',
        status: DataFetchStatus.failed,
      );
      dataFetchStatusController.updateBankStatus(
        bankName: 'Karvy',
        status: DataFetchStatus.failed,
      );
    }
  }

  Future<void> fetchDashboardData() async {
    AppLogger.info(
      'Dashboard: fetchDashboardData triggered (Finarkein only)',
      tag: 'DashboardRealtimeCheck',
    );
  }

  // Removed fetchTotalNetworth - all users are Finarkein users, networth comes from FinarkeinDataController

  bool isUserLoading = false;

  /// Fetch swiper accounts - combines AA data with MF Central linked accounts grouped by AMC
  Future<List<Map<String, dynamic>>> _fetchSwiperAccounts() async {
    final List<Map<String, dynamic>> result = [];

    // 1. Add AA accounts from AaDataFetchController
    if (Get.isRegistered<AaDataFetchController>()) {
      final data = Get.find<AaDataFetchController>().fetchOptionsData.value;
      if (data != null) {
        final categorizedMap = {
          'SAVINGS': data.deposit,
          'DEPOSIT': data.deposit,
          'TERM_DEPOSIT': data.deposit,
          'RECURRING_DEPOSIT': data.deposit,
          'EQUITIES': data.equities,
          'ETF': data.etf,
        };

        for (final entry in categorizedMap.entries) {
          final String categoryType = entry.key;
          final List<AaFetchOption> options = entry.value;

          for (final option in options) {
            final exists = result.any(
              (acc) =>
                  acc['fipname'] == option.fipName &&
                  acc['maskedaccno'] == option.maskedAccNumber,
            );

            if (!exists) {
              result.add({
                'type': categoryType,
                'fetchstatus': option.status.toUpperCase(),
                'fipname': option.fipName,
                'guid': option.id,
                'maskedaccno': option.maskedAccNumber,
                'lastdatafetchedat': option.lastFetchedTime,
              });
            }
          }
        }
      }
    }

    // 2. Fetch MF Central linked accounts and group by AMC
    try {
      final service = MFCentralLinkedAccountsService();
      final response = await service.fetchLinkedAccounts();

      if (response.success && response.data.isNotEmpty) {
        // Group accounts by AMC name
        final Map<String, List<MFCentralLinkedAccount>> groupedByAmc = {};

        for (final account in response.data) {
          final amcName =
              account.amcname.isNotEmpty
                  ? account.amcname
                  : 'Other Mutual Funds';
          if (!groupedByAmc.containsKey(amcName)) {
            groupedByAmc[amcName] = [];
          }
          groupedByAmc[amcName]!.add(account);
        }

        // Create swiper entries for each AMC group
        for (final entry in groupedByAmc.entries) {
          final amcName = entry.key;
          final accountsList = entry.value;

          // Determine overall status for the group
          final hasPending = accountsList.any(
            (a) =>
                a.status.toUpperCase() == 'PENDING' ||
                a.status.toUpperCase() == 'IN_PROGRESS',
          );
          final hasFailed = accountsList.any(
            (a) =>
                a.status.toUpperCase() == 'FAILED' ||
                a.status.toUpperCase() == 'ERROR',
          );
          final allCompleted = accountsList.every(
            (a) =>
                a.status.toUpperCase() == 'COMPLETED' ||
                a.status.toUpperCase() == 'SUCCESS',
          );

          final String groupStatus;
          if (hasPending) {
            groupStatus = 'PENDING';
          } else if (hasFailed && !allCompleted) {
            groupStatus = 'FAILED';
          } else {
            groupStatus = 'COMPLETED';
          }

          // Get most recent last_updated
          String mostRecentUpdate = '';
          for (final acc in accountsList) {
            if (acc.lastUpdated.isNotEmpty &&
                (mostRecentUpdate.isEmpty ||
                    acc.lastUpdated.compareTo(mostRecentUpdate) > 0)) {
              mostRecentUpdate = acc.lastUpdated;
            }
          }

          // Create account map for swiper
          result.add({
            'type': 'MUTUAL_FUNDS',
            'fetchstatus': groupStatus,
            'fipname': amcName,
            'guid': 'mfcentral_${amcName.hashCode}',
            'fipid': 'MF_CENTRAL',
            'userguid': '',
            'activestatus': 'ACTIVE',
            'fetchstatusupdatedat': mostRecentUpdate,
            'balancedatetime': mostRecentUpdate,
            'lastdatafetchedat': mostRecentUpdate, // For swiper display
            'imageurl': '',
            'maskedaccno':
                '${accountsList.length} folio${accountsList.length > 1 ? 's' : ''}',
            // Additional metadata for tap handling
            'isMFCentralGroup': true,
            'amcName': amcName,
            'folioCount': accountsList.length,
          });

          AppLogger.info(
            'Dashboard: Created MF Central swiper entry for $amcName with lastdatafetchedat: $mostRecentUpdate',
            tag: 'Dashboard',
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Dashboard: Error grouping MF Central accounts',
        error: e,
      );
    }

    return result;
  }

  /// Routes swiper card taps:
  /// - MFC cards → Investments screen (Mutual Funds tab)
  /// - All other cards → DataFetchDetailsScreen
  void _onSwiperCardTap(Map<String, dynamic> cardData) {
    final fipname = (cardData['fipname'] as String? ?? '').toLowerCase();
    if (fipname.contains('mutual fund holdings')) {
      Get.to(
        () => const AssetInvestmentScreen(
          isstacknavbar: false,
          initialCategory: 'Mutual Funds',
        ),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(
        () => const DataFetchDetailsScreen(),
        transition: Transition.rightToLeft,
      );
    }
  }

  Future<void> _onTapLinkAllAssets(BuildContext context) async {
    AppLogger.info(
      'Link All Assets clicked - checking validation status',
      tag: 'Dashboard',
    );

    // Check if PAN and phone are already verified
    try {
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];
        final panStatus = data['pan']?['status'];
        final phoneStatus = data['phone']?['status'];
        final contextData = data['context'] ?? {};
        final prefill = contextData['prefill'] ?? {};

        AppLogger.info(
          'Validation status - PAN: $panStatus, Phone: $phoneStatus',
          tag: 'Dashboard',
        );

        // If both PAN and phone are verified, skip verification and go directly to account aggregator
        if (panStatus == 'verified' && phoneStatus == 'verified') {
          final userController = Get.find<UserController>();

          // Try to get phone from prefill first, fallback to UserController
          final phoneNumber =
              (prefill['phone'] as String?) ??
              userController.userData?.phonenumber;

          AppLogger.info(
            'PAN and phone already verified - Phone: $phoneNumber',
            tag: 'Dashboard',
          );

          if (phoneNumber != null) {
            AppLogger.info(
              'Skipping PAN verification, going directly to account aggregator',
              tag: 'Dashboard',
            );

            await _accountAggregatorRouter.openConnection(
              context,
              phoneNumber: phoneNumber,
              showConnectionScreen: false,
            );
            return;
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error checking validation status: $e', tag: 'Dashboard');
    }

    // If not verified or error, show PAN verification widget
    AppLogger.info('Showing PAN verification widget', tag: 'Dashboard');

    final _linkAssetsUserController =
        Get.isRegistered<UserController>() ? Get.find<UserController>() : null;
    final _linkAssetsPhone =
        _linkAssetsUserController?.userData?.phonenumber ??
        _linkAssetsUserController?.userData?.secondaryphonenumber;
    final _linkAssetsEmail = _linkAssetsUserController?.userData?.email;
    bool _linkAssetsPhoneVerified = _linkAssetsPhone != null;
    bool _linkAssetsEmailVerified = false;
    bool _linkAssetsNeedsEmail = false;
    try {
      final _laValidate = await ProfileService().getProfileValidate();
      if (_laValidate != null && _laValidate['success'] == true) {
        final _laData = _laValidate['data'];
        _linkAssetsPhoneVerified = _laData['phone']?['status'] == 'verified';
        _linkAssetsEmailVerified = _laData['email']?['status'] == 'verified';
        final _laEmailStatus = _laData['email']?['status'] as String?;
        final _laCtx = _laData['context'] as Map<String, dynamic>? ?? {};
        _linkAssetsNeedsEmail =
            !_linkAssetsEmailVerified &&
            (_laCtx['needs_email'] == true || _laEmailStatus == 'pending');
      }
    } catch (_) {}

    Get.to(
      () => UniversalPanVerificationWidget(
        showProgress: false,
        title: 'Link Assets',
        phoneNumber: _linkAssetsPhone,
        isPhoneValidated: _linkAssetsPhoneVerified,
        isEmailValidated: _linkAssetsEmailVerified,
        needsEmailVerification: _linkAssetsNeedsEmail,
        email: _linkAssetsEmail,
        onSuccess: (panData) {
          // PAN verified successfully, proceed to account aggregator
          final phoneNumber = panData['phone_number'] as String?;

          AppLogger.info(
            'PAN verified for Assets linking - Phone: $phoneNumber',
            tag: 'Dashboard',
          );

          if (phoneNumber != null) {
            // Navigate to account aggregator
            _accountAggregatorRouter.openConnection(
              context,
              phoneNumber: phoneNumber,
              showConnectionScreen: false,
            );
          } else {
            AppLogger.error(
              'Missing phone number in verification data',
              tag: 'Dashboard',
            );
          }
        },
        onError: (error) {
          AppLogger.error(
            'PAN verification failed for Assets linking: $error',
            tag: 'Dashboard',
          );
        },
      ),
    );
  }

  Future<void> _onTapLinkStocksAndEtfs(BuildContext context) async {
    AppLogger.info(
      'Link Stocks and ETFs clicked - checking validation status',
      tag: 'Dashboard',
    );

    // Check if PAN and phone are already verified
    try {
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];
        final panStatus = data['pan']?['status'];
        final phoneStatus = data['phone']?['status'];
        final contextData = data['context'] ?? {};
        final prefill = contextData['prefill'] ?? {};

        AppLogger.info(
          'Validation status - PAN: $panStatus, Phone: $phoneStatus',
          tag: 'Dashboard',
        );

        // If both PAN and phone are verified, skip verification and go directly to account aggregator
        if (panStatus == 'verified' && phoneStatus == 'verified') {
          final userController = Get.find<UserController>();

          // Try to get phone from prefill first, fallback to UserController
          final phoneNumber =
              (prefill['phone'] as String?) ??
              userController.userData?.phonenumber;

          AppLogger.info(
            'PAN and phone already verified - Phone: $phoneNumber',
            tag: 'Dashboard',
          );

          if (phoneNumber != null) {
            AppLogger.info(
              'Skipping PAN verification, going directly to account aggregator',
              tag: 'Dashboard',
            );

            await _accountAggregatorRouter.openConnection(
              context,
              phoneNumber: phoneNumber,
              showConnectionScreen: false,
            );
            return;
          } else {
            AppLogger.warning(
              'Phone number not available - Phone: $phoneNumber',
              tag: 'Dashboard',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error checking validation status: $e', tag: 'Dashboard');
    }

    // If not verified or error, show PAN verification widget
    AppLogger.info('Showing PAN verification widget', tag: 'Dashboard');

    final _linkStocksUserController =
        Get.isRegistered<UserController>() ? Get.find<UserController>() : null;
    final _linkStocksPhone =
        _linkStocksUserController?.userData?.phonenumber ??
        _linkStocksUserController?.userData?.secondaryphonenumber;
    final _linkStocksEmail = _linkStocksUserController?.userData?.email;
    bool _linkStocksPhoneVerified = _linkStocksPhone != null;
    bool _linkStocksEmailVerified = false;
    bool _linkStocksNeedsEmail = false;
    try {
      final _lsValidate = await ProfileService().getProfileValidate();
      if (_lsValidate != null && _lsValidate['success'] == true) {
        final _lsData = _lsValidate['data'];
        _linkStocksPhoneVerified = _lsData['phone']?['status'] == 'verified';
        _linkStocksEmailVerified = _lsData['email']?['status'] == 'verified';
        final _lsEmailStatus = _lsData['email']?['status'] as String?;
        final _lsCtx = _lsData['context'] as Map<String, dynamic>? ?? {};
        _linkStocksNeedsEmail =
            !_linkStocksEmailVerified &&
            (_lsCtx['needs_email'] == true || _lsEmailStatus == 'pending');
      }
    } catch (_) {}

    Get.to(
      () => UniversalPanVerificationWidget(
        showProgress: false,
        title: 'Link Stocks and ETFs',
        phoneNumber: _linkStocksPhone,
        isPhoneValidated: _linkStocksPhoneVerified,
        isEmailValidated: _linkStocksEmailVerified,
        needsEmailVerification: _linkStocksNeedsEmail,
        email: _linkStocksEmail,
        onSuccess: (panData) {
          // PAN verified successfully, proceed to account aggregator
          final phoneNumber = panData['phone_number'] as String?;

          AppLogger.info(
            'PAN verified for Stocks/ETFs linking - Phone: $phoneNumber',
            tag: 'Dashboard',
          );

          if (phoneNumber != null) {
            // Navigate to account aggregator
            _accountAggregatorRouter.openConnection(
              context,
              phoneNumber: phoneNumber,
              showConnectionScreen: false,
            );
          } else {
            AppLogger.error(
              'Missing phone number in verification data',
              tag: 'Dashboard',
            );
          }
        },
        onError: (error) {
          AppLogger.error(
            'PAN verification failed for Stocks/ETFs linking: $error',
            tag: 'Dashboard',
          );
        },
      ),
    );
  }

  Future<void> _onTapLinkMutualFunds(BuildContext context) async {
    AppLogger.info(
      'Link Mutual Funds clicked - checking validation status',
      tag: 'Dashboard',
    );

    // Check if PAN and phone are already verified
    try {
      final profileService = ProfileService();
      final validateResponse = await profileService.getProfileValidate();

      if (validateResponse != null && validateResponse['success'] == true) {
        final data = validateResponse['data'];
        final panStatus = data['pan']?['status'];
        final phoneStatus = data['phone']?['status'];
        final contextData = data['context'] ?? {};
        final prefill = contextData['prefill'] ?? {};

        AppLogger.info(
          'Validation status - PAN: $panStatus, Phone: $phoneStatus',
          tag: 'Dashboard',
        );

        // If both PAN and phone are verified, skip verification and go directly to MF Central
        if (panStatus == 'verified' && phoneStatus == 'verified') {
          final userController = Get.find<UserController>();

          // Try to get PAN from prefill first, fallback to UserController
          final panNumber =
              (prefill['pan'] as String?) ?? userController.userData?.pannumber;
          final phoneNumber = userController.userData?.phonenumber;

          AppLogger.info(
            'PAN and phone already verified - PAN: $panNumber, Phone: $phoneNumber',
            tag: 'Dashboard',
          );

          if (panNumber != null && phoneNumber != null) {
            AppLogger.info(
              'Skipping PAN verification, going to MFC instructions screen',
              tag: 'Dashboard',
            );

            Get.to(
              () => MFCInstructionsScreen(
                panNumber: panNumber,
                phoneNumber: phoneNumber,
              ),
              transition: Transition.rightToLeft,
            );
            return;
          } else {
            AppLogger.warning(
              'PAN or phone number not available - PAN: $panNumber, Phone: $phoneNumber',
              tag: 'Dashboard',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error checking validation status: $e', tag: 'Dashboard');
    }

    // If not verified or error, show PAN verification widget
    AppLogger.info('Showing PAN verification widget', tag: 'Dashboard');

    final _linkMFUserController =
        Get.isRegistered<UserController>() ? Get.find<UserController>() : null;
    final _linkMFPhone =
        _linkMFUserController?.userData?.phonenumber ??
        _linkMFUserController?.userData?.secondaryphonenumber;
    final _linkMFEmail = _linkMFUserController?.userData?.email;
    bool _linkMFPhoneVerified = _linkMFPhone != null;
    bool _linkMFEmailVerified = false;
    bool _linkMFNeedsEmail = false;
    try {
      final _lmValidate = await ProfileService().getProfileValidate();
      if (_lmValidate != null && _lmValidate['success'] == true) {
        final _lmData = _lmValidate['data'];
        _linkMFPhoneVerified = _lmData['phone']?['status'] == 'verified';
        _linkMFEmailVerified = _lmData['email']?['status'] == 'verified';
        final _lmEmailStatus = _lmData['email']?['status'] as String?;
        final _lmCtx = _lmData['context'] as Map<String, dynamic>? ?? {};
        _linkMFNeedsEmail =
            !_linkMFEmailVerified &&
            (_lmCtx['needs_email'] == true || _lmEmailStatus == 'pending');
      }
    } catch (_) {}

    Get.to(
      () => UniversalPanVerificationWidget(
        showProgress: false,
        title: 'Link Mutual Funds',
        phoneNumber: _linkMFPhone,
        isPhoneValidated: _linkMFPhoneVerified,
        isEmailValidated: _linkMFEmailVerified,
        needsEmailVerification: _linkMFNeedsEmail,
        email: _linkMFEmail,
        onSuccess: (panData) {
          // PAN verified successfully, proceed to MF Central
          final panNumber = panData['pan_number'] as String?;
          final phoneNumber = panData['phone_number'] as String?;

          AppLogger.info(
            'PAN verified for MF linking - PAN: $panNumber, Phone: $phoneNumber',
            tag: 'Dashboard',
          );

          if (panNumber != null && phoneNumber != null) {
            // Show instructions screen before MF Central
            Get.to(
              () => MFCInstructionsScreen(
                panNumber: panNumber,
                phoneNumber: phoneNumber,
              ),
              transition: Transition.rightToLeft,
            );
          } else {
            AppLogger.error(
              'Missing PAN or phone number in verification data',
              tag: 'Dashboard',
            );
          }
        },
        onError: (error) {
          AppLogger.error(
            'PAN verification failed for MF linking: $error',
            tag: 'Dashboard',
          );
        },
      ),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _onTapCompleteKyc(BuildContext context) async {
    await AuthFlow().ensurePanAndPhoneThen(
      context: context,
      onReady: (capturedPhone) async {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.dashboardKycCardClicked,
        );
        Get.to(
          () => KycFlowScreen(capturedPhoneNumber: capturedPhone),
          transition: Transition.rightToLeft,
        );
      },
    );
  }

  Future<void> connectToZerodha() async {
    Get.dialog(const Center(child: LoadingWidget()), barrierDismissible: false);

    setState(() {
      isZerodhaLoading = true;
    });
    final response = await _zerodhaService.getZerodhaLoginUrl(
      onLoading: (loading) {
        setState(() {
          isZerodhaLoading = loading;
        });
      },
    );

    Get.back();

    if (response == null) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to get Zerodha login URL. Please try again.',
              style: TextStyle(color: Colors.red),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (response.success && response.data?.loginurl != null) {
      String decodeUrl(String encodedUrl) {
        return Uri.decodeFull(encodedUrl);
      }

      Get.to(
        () => ZerodhaWebView(
          url: decodeUrl(response.data!.loginurl),
          title: 'Zerodha Login',
        ),
        transition: Transition.rightToLeft,
      );
    } else {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Invalid Zerodha login URL received. Please try again.',
              style: TextStyle(color: Colors.red),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good morning!";
    } else if (hour < 17) {
      return "Good afternoon!";
    } else if (hour < 21) {
      return "Good evening!";
    } else {
      return "Good evening!";
    }
  }

  bool _isAmountVisible = false;
  Timer? _notificationTimer;
  Timer? _overlayTimer;

  bool _showOverlay = false;
  String _switchMode = '';
  double _overlayOpacity = 0.0;
  double _overlayScale = 0.8;
  double _revealFraction = 0.0;
  Offset _revealCenter = Offset.zero;

  void _startSwitchAnimation(BuildContext context, String mode, Offset center) {
    // Cancel any existing timer
    _overlayTimer?.cancel();

    setState(() {
      _showOverlay = true;
      _switchMode = mode;
      _overlayOpacity = 0.0;
      _overlayScale =
          0.7; // Start with a smaller scale for more dramatic effect
      _revealFraction = 0.0;
      _revealCenter = center;
    });

    // Show the animation with a small delay for smoother start
    // Increased delay for smoother visual transition
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _overlayOpacity = 1.0;
          _overlayScale = 1.0;
          _revealFraction = 1.0;
        });
      }
    });
  }

  void _stopSwitchAnimation() {
    _overlayTimer?.cancel();

    if (mounted) {
      setState(() {
        _overlayOpacity = 0.0;
        _overlayScale = 0.8;
        _revealFraction = 0.0;
      });

      // Hide overlay completely after animation completes
      // Use a longer duration for smoother fade out
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _showOverlay = false;
          });
        }
      });
    }
  }

  DateTime? _lastBackPressTime;
  static const Duration _backPressTimeout = Duration(seconds: 2);

  Future<bool> _onWillPop() async {
    final DateTime now = DateTime.now();

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > _backPressTimeout) {
      // First back press or timeout exceeded
      _lastBackPressTime = now;

      // Show snackbar or toast message
      Get.showSnackbar(
        GetSnackBar(
          message: 'Press back again to exit',
          duration: _backPressTimeout,
          backgroundColor: Colors.black87,
          margin: EdgeInsets.all(16),
          borderRadius: 8,
          snackPosition: SnackPosition.BOTTOM,
        ),
      );

      return false; // Don't exit
    }

    AnalyticsService.to.logEvent(name: AnalyticsEvents.dashboardBackPressExit);
    SystemNavigator.pop();
    return true;
  }

  Widget _buildHeaderActionChip({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkButtonBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            AppText(
              title,
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
          ],
        ),
      ),
    );
  }

  PageController pageViewController = PageController();
  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logScreenView(screenName: 'dashboard');
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dashboardScreenViewed,
        parameters: {
          AnalyticsParams.isFamilyMode: _isFamilyMode.toString(),
          AnalyticsParams.userType: _isFamilyMode ? 'family' : 'individual',
        },
      );
    });

    Get.put(DeepLinkController());
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetBuilder<UserController>(
          builder: (userController) {
            return GetBuilder<DashboardAssetController>(
              builder: (dashboardAssetController) {
                // Finarkein flow: treat "unlinked" purely as "no AA data",
                // not as a derivative of dashboard asset API responses (which can be slow / fallback).
                final isFinarkeinUser = _isFinarkeinUser();
                final hasAnyFinarkeinData = _hasAnyFinarkeinDataNow();
                final allAssetsUnlinked =
                    !_isFamilyMode &&
                    _entryMode != DashboardEntryMode.unknown &&
                    (isFinarkeinUser
                        ? !hasAnyFinarkeinData
                        : _entryMode == DashboardEntryMode.unlinkedSetup);

                final kycStateHelper = KycStateHelper();
                final lastKycStatus = kycStateHelper.lastKycStatus;
                final kycDisplayState = kraDisplayStateFromPersistedStatus(
                  lastKycStatus,
                );
                final isMfuKycDone =
                    kycStateHelper.hasSeenSuccessScreen ||
                    kycDisplayState == KycKraDisplayState.validated;
                final bool isFinarkeinLinked =
                    !_isFamilyMode && hasAnyFinarkeinData;
                // For Finarkein users: if they have data, assume all FI types are covered
                // Show link cards only if not linked
                // MFC Central is preferred for Mutual Funds even if Finarkein linked
                final isMfLinkedViaMfc =
                    userController.userData?.ismfverified ?? false;
                final mfCalcForSetup = _calculateMfFromHoldings();
                final hasMfHoldings =
                    mfCalcForSetup != null && mfCalcForSetup > 0;
                final shouldShowLinkMutualFunds =
                    !isMfLinkedViaMfc && !hasMfHoldings;

                final kycCopy = kycStateHelper.cardCopy;
                // Use raw KRAKYCCOMPLETEDSTATUS value from API instead of normalized message
                final String kycStatusLabel = kycStateHelper.rawKycStatus ?? '';
                final String kycStatusLower =
                    kycStatusLabel.toLowerCase().trim();
                final bool isKycCompleted =
                    kycStatusLower == 'completed' ||
                    kycStatusLower == 'validated';
                final bool isKycPending = kycStatusLower == 'pending';

                // Finarkein (Stocks/ETFs) card shows only if not linked
                final shouldShowLinkStocksAndEtfs = !isFinarkeinLinked;

                final bool isKycDisabled = isKycCompleted || isKycPending;
                final String kycTaskTitle;
                final String kycTaskSubtitle;

                // If KYC is completed, show "KYC Completed" regardless of cardCopy
                if (isKycCompleted) {
                  kycTaskTitle = 'KYC Completed';
                  kycTaskSubtitle = 'Status: $kycStatusLabel';
                } else {
                  switch (kycCopy) {
                    case KycCardCopy.completeKyc:
                      kycTaskTitle = 'Complete KYC';
                      kycTaskSubtitle =
                          kycStatusLabel.isNotEmpty
                              ? 'Status: $kycStatusLabel'
                              : 'Verify your identity to continue';
                      break;
                    case KycCardCopy.completeYourKyc:
                      kycTaskTitle = 'Complete your KYC';
                      kycTaskSubtitle =
                          kycStatusLabel.isNotEmpty
                              ? 'Status: $kycStatusLabel'
                              : 'Continue where you left off';
                      break;
                    case KycCardCopy.checkStatus:
                      kycTaskTitle = 'Check KYC status';
                      kycTaskSubtitle =
                          kycStatusLabel.isNotEmpty
                              ? 'Status: $kycStatusLabel'
                              : 'View your KYC verification status';
                      break;
                    case KycCardCopy.inProgress:
                      kycTaskTitle = 'In progress';
                      kycTaskSubtitle =
                          kycStatusLabel.isNotEmpty
                              ? 'Status: $kycStatusLabel'
                              : 'Your KYC is being verified';
                      break;
                  }
                }

                final setupTasks = <SetupTaskItem>[
                  // COMMENTED: Hide "Complete your KYC" card
                  // if (!isKycCompleted)
                  //   SetupTaskItem(
                  //     title: kycTaskTitle,
                  //     description: kycTaskSubtitle,
                  //     icon: Icons.assignment_ind_outlined,
                  //     isDisabled: isKycDisabled,
                  //     onTap: () {
                  //       _onTapCompleteKyc(context);
                  //     },
                  //   ),
                  if (shouldShowLinkMutualFunds)
                    SetupTaskItem(
                      title: "Link Mutual Funds",
                      description: "Link your mutual funds via OTP",
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () {
                        _onTapLinkMutualFunds(context);
                      },
                    ),
                  if (shouldShowLinkStocksAndEtfs)
                    SetupTaskItem(
                      title: "Link Stocks and ETFs",
                      description: "Connect your broker to see stocks",
                      icon: Icons.show_chart,
                      onTap: () {
                        _onTapLinkStocksAndEtfs(context);
                      },
                    ),
                  if (_isUccMissing)
                    SetupTaskItem(
                      title: "Start Investing",
                      description:
                          "Set up your investment account to buy mutual funds",
                      icon: Icons.rocket_launch_outlined,
                      onTap: () {
                        Get.to(
                          () => const MutualFundsBrowseScreen(),
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                  // Only show this in the carousel while there are setup tasks pending.
                  // if (!isMfuKycDone ||
                  //     shouldShowLinkMutualFunds ||
                  //     shouldShowLinkStocksAndEtfs)
                  //   SetupTaskItem(
                  //     title: "Calculate Independence",
                  //     description: "See when you can retire comfortably",
                  //     icon: Icons.calculate_outlined,
                  //     onTap: () {
                  //       Get.to(() => const AdvisoryScreen());
                  //     },
                  //   ),
                ];
                return PopScope(
                  canPop: false, // Prevent automatic pop
                  onPopInvoked: (didPop) async {
                    if (!didPop) {
                      await _onWillPop();
                    }
                  },
                  child: Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: AppColors.darkBackground,
                    body: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: _performRefresh,
                            color:
                                themeController.isDarkMode
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary,
                            backgroundColor:
                                themeController.isDarkMode
                                    ? AppColors.darkCardBG
                                    : AppColors.lightBackground,
                            displacement: 20.0,
                            strokeWidth: 3.0,
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      // Padding(
                                      //   padding: const EdgeInsets.only(
                                      //     left: AppSizing.scaffoldHorizontalPadding,
                                      //     right: AppSizing.scaffoldHorizontalPadding,
                                      //     bottom: 8,
                                      //   ),
                                      //   child: DataFetchStatusBar(
                                      //     bankStatuses:
                                      //         dataFetchStatusController.bankStatuses,
                                      //   ),
                                      // ),
                                      // _buildKycInProgressBanner(context),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              AppSizing
                                                  .scaffoldHorizontalPadding,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Row(
                                                  children: [
                                                    Semantics(
                                                      label: 'Profile',
                                                      button: true,
                                                      hint:
                                                          'Opens your profile',
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Get.to(
                                                            () => UserProfile(),
                                                          );
                                                        },
                                                        child: Avatar(
                                                          path:
                                                              userController
                                                                          .userData
                                                                          ?.gender
                                                                          ?.toLowerCase() ==
                                                                      'female'
                                                                  ? 'assets/svgs/dashboard/female.png'
                                                                  : 'assets/svgs/dashboard/male.png',
                                                          width: 40,
                                                          height: 40,
                                                          isNetworkImage: false,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        AppText(
                                                          "Hi, ${userController.userData?.firstname != null ? userController.userData!.firstname : ''}",
                                                          variant:
                                                              AppTextVariant
                                                                  .headline4,
                                                          weight:
                                                              AppTextWeight
                                                                  .bold,
                                                          colorType:
                                                              AppTextColorType
                                                                  .primary,
                                                        ),
                                                        AppText(
                                                          _getGreetingMessage(),
                                                          variant:
                                                              AppTextVariant
                                                                  .bodySmall,
                                                          weight:
                                                              AppTextWeight
                                                                  .medium,
                                                          colorType:
                                                              AppTextColorType
                                                                  .secondary,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const WhatsAppSupportButton(
                                                  size: 20,
                                                ),
                                                Semantics(
                                                  label: 'Search Mutual Funds',
                                                  button: true,
                                                  child: IconButton(
                                                    onPressed:
                                                        () => Get.to(
                                                          () =>
                                                              const MutualFundsBrowseScreen(),
                                                          transition:
                                                              Transition
                                                                  .rightToLeft,
                                                        ),
                                                    icon: Icon(
                                                      size: 20,
                                                      CupertinoIcons.search,
                                                      color:
                                                          AppColors
                                                              .darkButtonPrimaryBackground,
                                                    ),
                                                  ),
                                                ),
                                                // IconButton(
                                                //   onPressed:
                                                //       () => Get.to(
                                                //         () =>
                                                //             NotificationListScreen(),
                                                //         transition:
                                                //             Transition
                                                //                 .rightToLeft,
                                                //       ),
                                                //   icon: const Icon(
                                                //     Icons
                                                //         .notifications_outlined,
                                                //   ),
                                                // ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Horizontal action chips removed as per user request
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // SizedBox(
                                          //   height:
                                          //       MediaQuery.of(context).size.height,
                                          //   child: AnimatedTextExample(),
                                          // ),
                                          if (_shouldShowUnlockCard())
                                            _buildUnlockCard(context)
                                          else
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left:
                                                    AppSizing
                                                        .scaffoldHorizontalPadding,
                                                right:
                                                    AppSizing
                                                        .scaffoldHorizontalPadding,
                                                bottom: 12,
                                                top: 20,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  _buildNetworthHeader(
                                                    isLoading:
                                                        isNetworthLoading,
                                                  ),
                                                  Semantics(
                                                    header: true,
                                                    child: AppText(
                                                      _isFamilyMode
                                                          ? "${familyDashboardAssetsResponse?.data?.familylastname} Family Net worth from linked assets is:"
                                                          : "Net worth from your linked assets is:",
                                                      variant:
                                                          AppTextVariant
                                                              .bodyMedium,
                                                      weight:
                                                          AppTextWeight.medium,
                                                      colorType:
                                                          AppTextColorType
                                                              .secondary,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      SizedBox(width: 12),
                                                      Opacity(
                                                        opacity: 0,
                                                        child: Icon(
                                                          _isAmountVisible
                                                              ? Icons
                                                                  .visibility_outlined
                                                              : Icons
                                                                  .visibility_off_outlined,
                                                          color:
                                                              AppColors
                                                                  .darkButtonPrimaryBackground,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize
                                                                  .max, // important
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Expanded(
                                                              // important
                                                              child: AnimatedAmount(
                                                                isMain: true,
                                                                isLoading:
                                                                    isNetworthLoading ||
                                                                    _isInitialLoading ||
                                                                    _isRefreshing,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                isAmountVisible:
                                                                    _isAmountVisible,
                                                                amount: CurrencyFormatter.formatRupeeWithCommas(
                                                                  _networthAmount,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Semantics(
                                                        label:
                                                            _isAmountVisible
                                                                ? 'Hide net worth amount'
                                                                : 'Show net worth amount',
                                                        button: true,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            final previousVisibility =
                                                                _isAmountVisible;
                                                            setState(() {
                                                              _isAmountVisible =
                                                                  !_isAmountVisible;
                                                            });

                                                            AnalyticsService.to.logEvent(
                                                              name:
                                                                  AnalyticsEvents
                                                                      .dashboardAmountVisibilityToggled,
                                                              parameters: {
                                                                AnalyticsParams
                                                                        .isVisible:
                                                                    _isAmountVisible
                                                                        .toString(),
                                                                AnalyticsParams
                                                                        .previousVisibility:
                                                                    previousVisibility
                                                                        .toString(),
                                                              },
                                                            );

                                                            // Save amount visibility state to storage
                                                            StorageService.write(
                                                              StorageKeys
                                                                  .AMOUNT_VISIBILITY_KEY,
                                                              _isAmountVisible,
                                                            );
                                                            AppLogger.info(
                                                              'Dashboard: Saved amount visibility state: $_isAmountVisible',
                                                              tag: 'Dashboard',
                                                            );
                                                          },
                                                          child: Icon(
                                                            _isAmountVisible
                                                                ? Icons
                                                                    .visibility_outlined
                                                                : Icons
                                                                    .visibility_off_outlined,
                                                            color:
                                                                AppColors
                                                                    .darkButtonPrimaryBackground,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                    ],
                                                  ),
                                                  // here
                                                  const SizedBox(height: 4),
                                                  if (!_isFamilyMode &&
                                                      !allAssetsUnlinked)
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _networthDeltaAmount !=
                                                                0.00
                                                            ? Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    AppColors
                                                                        .darkBackground,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      20,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      AppColors
                                                                          .darkButtonBorder,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  AppText(
                                                                    "${_isAmountVisible ? '${_networthDeltaAmount >= 0 ? '+' : ''}${CurrencyFormatter.formatRupee(_networthDeltaAmount)}' : '••••••'} (${_networthDelta >= 0 ? '+' : ''}${_networthDelta.toStringAsFixed(2)}%) Today",
                                                                    variant:
                                                                        AppTextVariant
                                                                            .tiny,
                                                                    weight:
                                                                        AppTextWeight
                                                                            .medium,
                                                                    colorType:
                                                                        _networthDelta >=
                                                                                0
                                                                            ? AppTextColorType.success
                                                                            : AppTextColorType.error,
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                            : SizedBox.shrink(),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Semantics(
                                                          label: 'Refresh data',
                                                          button: true,
                                                          hint:
                                                              'Opens data fetch status screen',
                                                          child: GestureDetector(
                                                            onTap: () {
                                                              Get.to(
                                                                () =>
                                                                    const DataFetchDetailsScreen(),
                                                                transition:
                                                                    Transition
                                                                        .rightToLeft,
                                                              );
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    AppColors
                                                                        .darkBackground,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      20,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      AppColors
                                                                          .darkButtonBorder,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .refresh,
                                                                    size: 16,
                                                                    color:
                                                                        AppColors
                                                                            .darkButtonPrimaryBackground,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  AppText(
                                                                    "Refresh",
                                                                    variant:
                                                                        AppTextVariant
                                                                            .tiny,
                                                                    weight:
                                                                        AppTextWeight
                                                                            .medium,
                                                                    colorType:
                                                                        AppTextColorType
                                                                            .primary,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  // const SizedBox(height: 6),
                                                  // AppText(
                                                  //   _lastFetchedTime.isNotEmpty
                                                  //       ? "Last data fetched at $_lastFetchedTime"
                                                  //       : "No data fetched yet",
                                                  //   variant: AppTextVariant.tiny,
                                                  //   weight:
                                                  //       AppTextWeight.semiBold,
                                                  //   colorType:
                                                  //       AppTextColorType
                                                  //           .secondary,
                                                  // ),
                                                ],
                                              ),
                                            ),

                                          // if (!_isFamilyMode)
                                          //   NetworthChartMain(
                                          //     currentProjection:
                                          //         _currentProjection ?? [],
                                          //     futureProjection:
                                          //         _futureProjection,
                                          //     isLoading: isNetworthLoading,
                                          //   ),
                                          // if (_isFamilyMode)
                                          //   Builder(
                                          //     // Force rebuild with a key based on response data
                                          //     key: ValueKey(
                                          //       'family-chart-${familyDashboardAssetsResponse?.hashCode}',
                                          //     ),
                                          //     builder: (context) {
                                          //       // Calculate members count safely
                                          //       final membersCount =
                                          //           familyDashboardAssetsResponse ==
                                          //                   null
                                          //               ? 0
                                          //               : (familyDashboardAssetsResponse!
                                          //                           .data ==
                                          //                       null
                                          //                   ? 0
                                          //                   : (familyDashboardAssetsResponse!
                                          //                       .data!
                                          //                       .members
                                          //                       .length));
                                          //       AppLogger.info(
                                          //         "Rendering family chart with data: $membersCount members at ${DateTime.now()}",
                                          //         tag: "FAMILY_CHART",
                                          //       );
                                          //       return FamilyFinanceChart(
                                          //         // Use ValueKey with hashCode to ensure rebuild when data changes
                                          //         key: ValueKey(
                                          //           familyDashboardAssetsResponse
                                          //                   ?.hashCode ??
                                          //               UniqueKey(),
                                          //         ),
                                          //         familyDashboardAssetsResponse:
                                          //             familyDashboardAssetsResponse,
                                          //       );
                                          //     },
                                          //   ),
                                          // const SizedBox(height: 12),
                                          // Container(
                                          //   padding: const EdgeInsets.symmetric(
                                          //     horizontal: 16,
                                          //     vertical: 8,
                                          //   ),
                                          //   decoration: BoxDecoration(
                                          //     color: AppColors.darkCardBG,
                                          //     borderRadius:
                                          //         BorderRadius.circular(24),
                                          //     border: Border.all(
                                          //       color:
                                          //           AppColors.darkButtonBorder,
                                          //       width: 1,
                                          //     ),
                                          //   ),
                                          //   child: Row(
                                          //     mainAxisSize: MainAxisSize.min,
                                          //     children: [
                                          //       AppText(
                                          //         _isFamilyMode
                                          //             ? 'Family'
                                          //             : 'Individual',
                                          //         variant:
                                          //             AppTextVariant.bodyMedium,
                                          //         weight: AppTextWeight.medium,
                                          //         colorType:
                                          //             AppTextColorType.primary,
                                          //       ),
                                          //       const SizedBox(width: 16),
                                          //       CustomSwitch(
                                          //         value: _isFamilyMode,
                                          //         onChanged: (value) {
                                          //           toggleFamilyMode();
                                          //         },
                                          //       ),
                                          //     ],
                                          //   ),
                                          // ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                      if (_isFamilyMode)
                                        Builder(
                                          key: ValueKey(
                                            'family-chart-${familyDashboardAssetsResponse?.hashCode}',
                                          ),
                                          builder: (context) {
                                            final membersCount =
                                                familyDashboardAssetsResponse ==
                                                        null
                                                    ? 0
                                                    : (familyDashboardAssetsResponse!
                                                                .data ==
                                                            null
                                                        ? 0
                                                        : (familyDashboardAssetsResponse!
                                                            .data!
                                                            .members
                                                            .length));
                                            AppLogger.info(
                                              "Rendering family chart with data: $membersCount members at ${DateTime.now()}",
                                              tag: "FAMILY_CHART",
                                            );
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppSizing
                                                        .scaffoldHorizontalPadding,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkCardBG,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            AnalyticsService.to
                                                                .logEvent(
                                                                  name:
                                                                      AnalyticsEvents
                                                                          .dashboardFamilyChartManageClicked,
                                                                );
                                                            Get.to(
                                                              () =>
                                                                  FamilyManagement(),
                                                              transition:
                                                                  Transition
                                                                      .rightToLeft,
                                                            );
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .darkButtonBorder,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                AppText(
                                                                  "Manage",
                                                                  variant:
                                                                      AppTextVariant
                                                                          .bodySmall,
                                                                  weight:
                                                                      AppTextWeight
                                                                          .medium,
                                                                  colorType:
                                                                      AppTextColorType
                                                                          .link,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Icon(
                                                                  Icons
                                                                      .chevron_right,
                                                                  size: 16,
                                                                  color:
                                                                      AppColors
                                                                          .linkColor,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    FamilyFinanceChart(
                                                      key: ValueKey(
                                                        familyDashboardAssetsResponse
                                                                ?.hashCode ??
                                                            UniqueKey(),
                                                      ),
                                                      familyDashboardAssetsResponse:
                                                          familyDashboardAssetsResponse,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            // Spends and Investments Cards
                                            if (!_isFamilyMode &&
                                                !allAssetsUnlinked)
                                              Container(
                                                height: 118,
                                                color: AppColors.darkBackground,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppSizing
                                                          .scaffoldHorizontalPadding,
                                                ),
                                                child: Row(
                                                  children: [
                                                    // August Spends Card
                                                    Expanded(
                                                      child: Semantics(
                                                        label:
                                                            (_spendsData?.islinked ??
                                                                    false)
                                                                ? 'Spends. Double tap to view transactions.'
                                                                : 'Spends, not linked. Double tap to link.',
                                                        button: true,
                                                        child: InkWell(
                                                          onTap:
                                                              (_spendsData?.islinked ??
                                                                      false)
                                                                  ? () {
                                                                    AnalyticsService.to.logEvent(
                                                                      name:
                                                                          AnalyticsEvents
                                                                              .dashboardSpendsCardClicked,
                                                                      parameters: {
                                                                        AnalyticsParams.isLinked:
                                                                            'true',
                                                                      },
                                                                    );
                                                                    Get.to(
                                                                      () => BankTransactionListScreen(
                                                                        forceStandardApis:
                                                                            true,
                                                                      ),
                                                                    );
                                                                  }
                                                                  : () {
                                                                    AnalyticsService.to.logEvent(
                                                                      name:
                                                                          AnalyticsEvents
                                                                              .dashboardSpendsCardClicked,
                                                                      parameters: {
                                                                        AnalyticsParams.isLinked:
                                                                            'false',
                                                                      },
                                                                    );
                                                                    _accountAggregatorRouter
                                                                        .openConnection(
                                                                          context,
                                                                        );
                                                                  },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  16,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .darkCardBG,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    AppColors
                                                                        .darkButtonBorder,
                                                                width: 0.5,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: AppText(
                                                                        //  '${DateFormat('MMMM').format(DateTime.now()).toUpperCase()} SPENDS',
                                                                        'SPENDS',
                                                                        variant:
                                                                            AppTextVariant.bodySmall,
                                                                        weight:
                                                                            AppTextWeight.medium,
                                                                        colorType:
                                                                            AppTextColorType.secondary,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                (_spendsData?.islinked ??
                                                                        false)
                                                                    ? SizedBox(
                                                                      height:
                                                                          24,
                                                                      child: FittedBox(
                                                                        fit:
                                                                            BoxFit.scaleDown,
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        child: AnimatedAmount(
                                                                          isLoading:
                                                                              isNetworthLoading ||
                                                                              _isInitialLoading ||
                                                                              _isRefreshing,
                                                                          amount: CurrencyFormatter.formatRupee(
                                                                            _spendsData?.spendslast30days ??
                                                                                0,
                                                                          ),
                                                                          isAmountVisible:
                                                                              _isAmountVisible,
                                                                          alignment:
                                                                              Alignment.centerLeft,
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                18,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    )
                                                                    : (isAssetsLoading ||
                                                                        _isRefreshing)
                                                                    ? SizedBox(
                                                                      height:
                                                                          24,
                                                                      child: FittedBox(
                                                                        fit:
                                                                            BoxFit.scaleDown,
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        child: AnimatedAmount(
                                                                          isLoading:
                                                                              true,
                                                                          amount:
                                                                              "₹0",
                                                                          isAmountVisible:
                                                                              true,
                                                                          alignment:
                                                                              Alignment.centerLeft,
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize:
                                                                                18,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    )
                                                                    : AppText(
                                                                      "Link Now",
                                                                      variant:
                                                                          AppTextVariant
                                                                              .bodyMedium,
                                                                      colorType:
                                                                          AppTextColorType
                                                                              .link,
                                                                      weight:
                                                                          AppTextWeight
                                                                              .medium,
                                                                    ),
                                                                const SizedBox(
                                                                  height: 8,
                                                                ),

                                                                if (_spendsData
                                                                        ?.islinked ??
                                                                    false)
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Expanded(
                                                                        child: Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.max,
                                                                          children: [
                                                                            Row(
                                                                              mainAxisSize:
                                                                                  MainAxisSize.min,
                                                                              children: [
                                                                                AppText(
                                                                                  "For Last 30 Days",
                                                                                  variant:
                                                                                      AppTextVariant.tiny,
                                                                                  weight:
                                                                                      AppTextWeight.regular,
                                                                                  colorType:
                                                                                      AppTextColorType.gray,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Investments Card
                                                    Expanded(
                                                      child: Semantics(
                                                        label:
                                                            (_investmentsData
                                                                        ?.islinked ??
                                                                    false)
                                                                ? 'Investments. Double tap to view.'
                                                                : 'Investments, not linked. Double tap to link.',
                                                        button: true,
                                                        child: InkWell(
                                                          onTap: () {
                                                            AnalyticsService.to
                                                                .logEvent(
                                                                  name:
                                                                      AnalyticsEvents
                                                                          .dashboardInvestmentsCardClicked,
                                                                );
                                                            Get.to(
                                                              () => const AssetInvestmentScreen(
                                                                isstacknavbar:
                                                                    false,
                                                              ),
                                                              transition:
                                                                  Transition
                                                                      .rightToLeft,
                                                            );
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  16,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppColors
                                                                      .darkCardBG,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    AppColors
                                                                        .darkButtonBorder,
                                                                width: 0.5,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: AppText(
                                                                        'INVESTMENTS',
                                                                        variant:
                                                                            AppTextVariant.bodySmall,
                                                                        weight:
                                                                            AppTextWeight.medium,
                                                                        colorType:
                                                                            AppTextColorType.secondary,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                (_investmentsData
                                                                            ?.islinked ??
                                                                        false)
                                                                    ? FittedBox(
                                                                      fit:
                                                                          BoxFit
                                                                              .scaleDown,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: AnimatedAmount(
                                                                        isLoading:
                                                                            isAssetsLoading ||
                                                                            _isRefreshing,
                                                                        amount: CurrencyFormatter.formatRupee(
                                                                          _investmentsData?.amount ??
                                                                              0,
                                                                        ),
                                                                        isAmountVisible:
                                                                            _isAmountVisible,
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              18,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    : (isAssetsLoading ||
                                                                        _isRefreshing)
                                                                    ? FittedBox(
                                                                      fit:
                                                                          BoxFit
                                                                              .scaleDown,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: AnimatedAmount(
                                                                        isLoading:
                                                                            true,
                                                                        amount:
                                                                            "₹0",
                                                                        isAmountVisible:
                                                                            true,
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        style: const TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              18,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    : GestureDetector(
                                                                      onTap: () {
                                                                        AnalyticsService.to.logEvent(
                                                                          name:
                                                                              AnalyticsEvents.dashboardAssetLinkNowClicked,
                                                                          parameters: {
                                                                            AnalyticsParams.assetType:
                                                                                'investments',
                                                                            AnalyticsParams.navigationMethod:
                                                                                'link_now_button',
                                                                          },
                                                                        );
                                                                        _accountAggregatorRouter.openConnection(
                                                                          context,
                                                                        );
                                                                      },
                                                                      child: AppText(
                                                                        "Link Now",
                                                                        variant:
                                                                            AppTextVariant.bodyMedium,
                                                                        colorType:
                                                                            AppTextColorType.link,
                                                                        weight:
                                                                            AppTextWeight.medium,
                                                                      ),
                                                                    ),
                                                                // Only show Today when investments are linked
                                                                if (_investmentsData
                                                                        ?.islinked ??
                                                                    false) ...[
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  // Row(
                                                                  //   children: [
                                                                  //     AppText(
                                                                  //       "${_isAmountVisible ? '${(_investmentsData?.deltaamount ?? 0) >= 0 ? '+' : ''}${CurrencyFormatter.formatRupee((_investmentsData?.deltaamount ?? 0).toInt())}' : '••••••'} (${_investmentsData?.delta}%) Today",
                                                                  //       variant:
                                                                  //           AppTextVariant
                                                                  //               .tiny,
                                                                  //       weight:
                                                                  //           AppTextWeight
                                                                  //               .medium,
                                                                  //       colorType:
                                                                  //           (_investmentsData?.delta ??
                                                                  //                       0) >=
                                                                  //                   0
                                                                  //               ? AppTextColorType.success
                                                                  //               : AppTextColorType.error,
                                                                  //     ),
                                                                  //   ],
                                                                  // ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (!_isFamilyMode)
                                              Container(
                                                color: AppColors.darkBackground,
                                                child: FutureBuilder<
                                                  List<Map<String, dynamic>>
                                                >(
                                                  future: _swiperAccountsFuture,
                                                  builder: (context, snapshot) {
                                                    final accounts =
                                                        snapshot.data ?? [];
                                                    return Obx(() {
                                                      // Check if we already have MF Central accounts from FutureBuilder
                                                      final hasMFCentralAccounts =
                                                          accounts.any(
                                                            (a) =>
                                                                a['fipid'] ==
                                                                'MF_CENTRAL',
                                                          );
                                                      // Merge with real-time MFC status (only if no MF Central accounts yet)
                                                      final mergedAccounts = [
                                                        ...accounts,
                                                      ];
                                                      if (!hasMFCentralAccounts &&
                                                          Get.isRegistered<
                                                            MFCentralStatusController
                                                          >()) {
                                                        final _ =
                                                            MFCentralStatusController
                                                                .to
                                                                .status
                                                                .value;
                                                        final mfcEntry =
                                                            MFCentralStatusController
                                                                .to
                                                                .swiperEntry;
                                                        if (mfcEntry != null) {
                                                          mergedAccounts.insert(
                                                            0,
                                                            mfcEntry,
                                                          );
                                                        }
                                                      }
                                                      return StatusCardSwiper(
                                                        lastFetchedTime:
                                                            _fipStatusController
                                                                .lastFetchedTime,
                                                        category: 'all',
                                                        accounts:
                                                            mergedAccounts,
                                                        onCardTap:
                                                            _onSwiperCardTap,
                                                      );
                                                    });
                                                  },
                                                ),
                                              ),
                                            if (!allAssetsUnlinked)
                                              SizedBox(height: 12),
                                            if (!allAssetsUnlinked)
                                              Container(
                                                color: AppColors.darkBackground,
                                                child: SizedBox(
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width,
                                                  child: Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  AppSizing
                                                                      .scaffoldHorizontalPadding,
                                                            ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            AppText(
                                                              "Assets",
                                                              variant:
                                                                  AppTextVariant
                                                                      .headline5,
                                                              weight:
                                                                  AppTextWeight
                                                                      .bold,
                                                              colorType:
                                                                  AppTextColorType
                                                                      .primary,
                                                            ),
                                                            if (false)
                                                              AppText(
                                                                "See All",
                                                                variant:
                                                                    AppTextVariant
                                                                        .bodySmall,
                                                                weight:
                                                                    AppTextWeight
                                                                        .medium,
                                                                colorType:
                                                                    AppTextColorType
                                                                        .link,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),

                                                      Container(
                                                        margin: EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSizing
                                                                  .scaffoldHorizontalPadding,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors
                                                                  .darkCardBG,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                AppColors
                                                                    .darkButtonBorder,
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                        child:
                                                            _isFamilyMode
                                                                ? Column(
                                                                  children: [
                                                                    ...familyDashboardAssetsResponse?.data?.summary.map(
                                                                          (
                                                                            e,
                                                                          ) => _buildModernAssetItem(
                                                                            amount:
                                                                                e.value,
                                                                            title:
                                                                                e.title,
                                                                            assetType:
                                                                                e.id,
                                                                            destination: getAssetScreen(
                                                                              e.id,
                                                                              true,
                                                                              familyId:
                                                                                  familyId,
                                                                            ),
                                                                            isAmountVisible:
                                                                                _isAmountVisible,
                                                                            isLinked:
                                                                                true,
                                                                            isTestAccount:
                                                                                false,
                                                                          ),
                                                                        ) ??
                                                                        [],
                                                                  ],
                                                                )
                                                                : Column(
                                                                  children: [
                                                                    if (_isInitialLoading &&
                                                                        _dashboardAssetList
                                                                            .isEmpty)
                                                                      ...List.generate(
                                                                        6,
                                                                        (
                                                                          index,
                                                                        ) => _buildModernAssetLoadingItem(
                                                                          showDivider:
                                                                              true,
                                                                        ),
                                                                      ),
                                                                    ..._dashboardAssetList.map((
                                                                      e,
                                                                    ) {
                                                                      // Show MFC portfolio value for Mutual Funds
                                                                      // when MF Central sync is complete
                                                                      final isMf =
                                                                          e.id.toLowerCase() ==
                                                                              'mutualfunds' ||
                                                                          e.id.toLowerCase() ==
                                                                              'mf';
                                                                      final mfcReady =
                                                                          isMf &&
                                                                          Get.isRegistered<
                                                                            MFCentralStatusController
                                                                          >() &&
                                                                          MFCentralStatusController.to.status.value ==
                                                                              'success' &&
                                                                          MFCentralStatusController.to.totalValue.value >
                                                                              0;

                                                                      return _buildModernAssetItem(
                                                                        amount:
                                                                            mfcReady
                                                                                ? MFCentralStatusController.to.totalValue.value
                                                                                : e.value,
                                                                        title:
                                                                            e.title,
                                                                        assetType:
                                                                            e.id,
                                                                        destination: getAssetScreen(
                                                                          e.id,
                                                                          false,
                                                                          familyId:
                                                                              familyId,
                                                                        ),
                                                                        isAmountVisible:
                                                                            _isAmountVisible,
                                                                        isLinked:
                                                                            e.islinked ||
                                                                            mfcReady,
                                                                        isTestAccount:
                                                                            userController.userData?.istestaccount ??
                                                                            false,
                                                                      );
                                                                    }).toList(),
                                                                    if (!(userController
                                                                            .userData
                                                                            ?.istestaccount ??
                                                                        false))
                                                                      _isInitialLoading
                                                                          ? _buildModernAssetLoadingItem(
                                                                            showDivider:
                                                                                false,
                                                                          )
                                                                          : _buildModernAssetItem(
                                                                            title:
                                                                                "Add Assets",
                                                                            assetType:
                                                                                "add",
                                                                            destination:
                                                                                ConnectionsScreen(),
                                                                            isAmountVisible:
                                                                                false,
                                                                            isLinked:
                                                                                false,
                                                                            isTestAccount:
                                                                                userController.userData?.istestaccount ??
                                                                                false,
                                                                            amount:
                                                                                0,
                                                                          ),
                                                                  ],
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            _buildSetupCarousel(setupTasks),

                                            // Anchor call for extraction: asset list/grid remains inlined for now.
                                            _buildAssetsGridOrList(),

                                            // Padding(
                                            //   padding: EdgeInsets.symmetric(
                                            //     horizontal:
                                            //         AppSizing
                                            //             .scaffoldHorizontalPadding,
                                            //     vertical: 16.h,
                                            //   ),
                                            //   child: PivotMoneyInfoCard(
                                            //     onLearnMore: () {},
                                            //   ),
                                            // ),
                                            const SizedBox(height: 8),

                                            Obx(
                                              () => ExploreInvesting(
                                                blogs: [
                                                  ...blogController.blogs,
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Obx(
                                              () => CalculatorsSection(
                                                calculators: [
                                                  ...calculatorController
                                                      .calculators,
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 16),

                                            // Material(
                                            //   color: AppColors.darkBackground,
                                            //   child: Column(
                                            //     children: [
                                            //       Padding(
                                            //         padding: EdgeInsets.only(
                                            //           left:
                                            //               AppSizing
                                            //                   .scaffoldHorizontalPadding,
                                            //           right:
                                            //               AppSizing
                                            //                   .scaffoldHorizontalPadding,
                                            //         ),
                                            //         child: Row(
                                            //           crossAxisAlignment:
                                            //               CrossAxisAlignment
                                            //                   .start,
                                            //           mainAxisAlignment:
                                            //               MainAxisAlignment
                                            //                   .spaceBetween,
                                            //           children: [
                                            //             AppText(
                                            //               "Recommendations",
                                            //               variant:
                                            //                   AppTextVariant
                                            //                       .headline5,
                                            //               weight:
                                            //                   AppTextWeight
                                            //                       .bold,
                                            //               colorType:
                                            //                   AppTextColorType
                                            //                       .primary,
                                            //             ),
                                            //           ],
                                            //         ),
                                            //       ),
                                            //       SizedBox(height: 8),
                                            //       SizedBox(
                                            //         width:
                                            //             MediaQuery.of(
                                            //               context,
                                            //             ).size.width,
                                            //         height:
                                            //             MediaQuery.of(
                                            //               context,
                                            //             ).size.height *
                                            //             0.18,
                                            //         child: PageView.builder(
                                            //           itemCount:
                                            //               _recommendations
                                            //                   .length,
                                            //           controller:
                                            //               pageViewController,
                                            //           physics:
                                            //               const ClampingScrollPhysics(),
                                            //           onPageChanged: (pageNo) {
                                            //             setState(() {
                                            //               currentPage = pageNo;
                                            //             });
                                            //           },
                                            //           itemBuilder: (
                                            //             context,
                                            //             index,
                                            //           ) {
                                            //             final recommendation =
                                            //                 _recommendations[index];
                                            //             return PromotionalCard(
                                            //               title:
                                            //                   recommendation['title'],
                                            //               description:
                                            //                   recommendation['description'],
                                            //               buttonText:
                                            //                   recommendation['buttonText'],
                                            //               onButtonTap:
                                            //                   recommendation['onTap'],
                                            //               imagePath:
                                            //                   recommendation['imagePath'],
                                            //               gradientColors:
                                            //                   recommendation['gradientColors'],
                                            //               gradientCenter:
                                            //                   recommendation['gradientCenter'],
                                            //               gradientRadius:
                                            //                   recommendation['gradientRadius'],
                                            //               useBackdropFilter:
                                            //                   recommendation['useBackdropFilter'],
                                            //             );
                                            //           },
                                            //         ),
                                            //       ),
                                            //       SizedBox(height: 8),
                                            //       SizedBox(
                                            //         height: 8,
                                            //         child: Row(
                                            //           mainAxisAlignment:
                                            //               MainAxisAlignment
                                            //                   .center,
                                            //           children: List.generate(_recommendations.length, (
                                            //             index,
                                            //           ) {
                                            //             return AnimatedContainer(
                                            //               duration: Duration(
                                            //                 milliseconds: 300,
                                            //               ),
                                            //               curve:
                                            //                   Curves.easeInOut,
                                            //               margin:
                                            //                   EdgeInsets.symmetric(
                                            //                     horizontal: 2,
                                            //                   ),
                                            //               width:
                                            //                   currentPage ==
                                            //                           index
                                            //                       ? 30
                                            //                       : 8,
                                            //               height: 8,
                                            //               decoration: BoxDecoration(
                                            //                 borderRadius:
                                            //                     BorderRadius.circular(
                                            //                       8,
                                            //                     ),
                                            //                 color:
                                            //                     currentPage ==
                                            //                             index
                                            //                         ? themeController
                                            //                                 .isDarkMode
                                            //                             ? AppColors
                                            //                                 .darkPrimary
                                            //                             : AppColors
                                            //                                 .lightPrimary
                                            //                         : themeController
                                            //                             .isDarkMode
                                            //                         ? AppColors
                                            //                             .darkButtonBorder
                                            //                         : AppColors
                                            //                             .lightButtonBorder,
                                            //               ),
                                            //             );
                                            //           }),
                                            //         ),
                                            //       ),
                                            //     ],
                                            //   ),
                                            // ),
                                            // Container(
                                            //   color: AppColors.darkBackground,
                                            //   child: Column(
                                            //     children: [
                                            //       MFTopPerformersWidget(
                                            //         controller:
                                            //             mfTopPerformersController,
                                            //         dashboard: true,
                                            //         assetclass: "",
                                            //       ),
                                            //     ],
                                            //   ),
                                            // ),
                                            Material(
                                              color: AppColors.darkBackground,
                                              child: Column(
                                                children: [
                                                  SizedBox(height: 20),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSizing
                                                                  .scaffoldHorizontalPadding,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "make your \nmoney grow.",
                                                          style: TextStyle(
                                                            fontSize: 38,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.30,
                                                                ),
                                                            height: 1.0,
                                                            fontFamily:
                                                                "Montserrat",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // AppButton(
                                                  //   onPressed: () {
                                                  //     Get.to(
                                                  //       () => const SaafeDataFetch(),
                                                  //     );
                                                  //   },
                                                  //   text: 'Get Started',
                                                  // ),
                                                  SizedBox(height: 20),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSizing
                                                                  .scaffoldHorizontalPadding,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "Made with ❤️ in India",
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.30,
                                                                ),
                                                            height: 1.0,
                                                            fontFamily:
                                                                "Montserrat",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 40),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Refresh notification
                                // if (_showRefreshNotification)
                                // Positioned(
                                //   top: 16,
                                //   left: 0,
                                //   right: 0,
                                //   child: Center(
                                //     child: Container(
                                //       padding: const EdgeInsets.symmetric(
                                //         horizontal: 16,
                                //         vertical: 8,
                                //       ),
                                //       decoration: BoxDecoration(
                                //         color:
                                //             themeController.isDarkMode
                                //                 ? AppColors.darkPrimary.withOpacity(
                                //                   0.9,
                                //                 )
                                //                 : AppColors.lightPrimary
                                //                     .withOpacity(0.9),
                                //         borderRadius: BorderRadius.circular(20),
                                //         boxShadow: [
                                //           BoxShadow(
                                //             color: Colors.black.withOpacity(0.1),
                                //             blurRadius: 10,
                                //             offset: const Offset(0, 2),
                                //           ),
                                //         ],
                                //       ),
                                //       child: AppText(
                                //         'Data refreshed successfully',
                                //         colorType: AppTextColorType.white,
                                //         variant: AppTextVariant.bodySmall,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          if (_showOverlay)
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOutCubic,
                              tween: Tween<double>(
                                begin: 0.0,
                                end: _overlayOpacity,
                              ),
                              builder: (context, opacity, child) {
                                return TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeInOutCubic,
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: _revealFraction,
                                  ),
                                  builder: (context, fraction, child) {
                                    return ClipPath(
                                      clipper: CircularRevealClipper(
                                        fraction: fraction,
                                        centerOffset: _revealCenter,
                                      ),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height:
                                            MediaQuery.of(context).size.height,
                                        color: Colors.black.withOpacity(
                                          opacity * 1,
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: opacity * 0,
                                            sigmaY: opacity * 0,
                                          ),
                                          child: Center(
                                            child: TweenAnimationBuilder<
                                              double
                                            >(
                                              duration: const Duration(
                                                milliseconds: 1800,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              tween: Tween<double>(
                                                begin: 0.7,
                                                end: _overlayScale,
                                              ),
                                              builder: (context, scale, child) {
                                                return Transform.scale(
                                                  scale: scale,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 40,
                                                          vertical: 32,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.darkCardBG,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TweenAnimationBuilder<
                                                          double
                                                        >(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    2000,
                                                              ),
                                                          curve:
                                                              Curves
                                                                  .easeInOutSine,
                                                          tween: Tween<double>(
                                                            begin: 0.95,
                                                            end: 1.05,
                                                          ),
                                                          builder: (
                                                            context,
                                                            iconScale,
                                                            child,
                                                          ) {
                                                            return TweenAnimationBuilder<
                                                              double
                                                            >(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        4000,
                                                                  ),
                                                              curve:
                                                                  Curves
                                                                      .easeInOutCubic,
                                                              tween:
                                                                  Tween<double>(
                                                                    begin:
                                                                        -0.04,
                                                                    end: 0.04,
                                                                  ),
                                                              builder: (
                                                                context,
                                                                rotateValue,
                                                                child,
                                                              ) {
                                                                return Transform.rotate(
                                                                  angle: 0,
                                                                  child: Transform.scale(
                                                                    scale:
                                                                        iconScale,
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            20,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: AppColors
                                                                            .darkPrimary
                                                                            .withOpacity(
                                                                              0.15,
                                                                            ),
                                                                        shape:
                                                                            BoxShape.circle,
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color: AppColors.darkPrimary.withOpacity(
                                                                              0.2,
                                                                            ),
                                                                            blurRadius:
                                                                                20,
                                                                            spreadRadius:
                                                                                5,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child: Icon(
                                                                        _switchMode.contains(
                                                                              'Family',
                                                                            )
                                                                            ? Icons.family_restroom
                                                                            : Icons.person,
                                                                        color:
                                                                            AppColors.darkPrimary,
                                                                        size:
                                                                            40,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 32,
                                                        ),
                                                        TweenAnimationBuilder<
                                                          Offset
                                                        >(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    5000,
                                                              ),
                                                          curve:
                                                              Curves
                                                                  .easeInOutQuart,
                                                          tween: Tween<Offset>(
                                                            begin: const Offset(
                                                              0,
                                                              -0.02,
                                                            ),
                                                            end: const Offset(
                                                              0,
                                                              0.02,
                                                            ),
                                                          ),
                                                          builder: (
                                                            context,
                                                            offset,
                                                            child,
                                                          ) {
                                                            return Transform.translate(
                                                              offset: Offset(
                                                                0,
                                                                offset.dy * 100,
                                                              ),
                                                              child: Transform.scale(
                                                                scale:
                                                                    1 -
                                                                    (offset.dy *
                                                                        0.3),
                                                                child: AppText(
                                                                  'Switching to',
                                                                  variant:
                                                                      AppTextVariant
                                                                          .bodyLarge,
                                                                  colorType:
                                                                      AppTextColorType
                                                                          .secondary,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        TweenAnimationBuilder<
                                                          Offset
                                                        >(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    2000,
                                                              ),
                                                          curve:
                                                              Curves
                                                                  .easeInOutSine,
                                                          tween: Tween<Offset>(
                                                            begin: const Offset(
                                                              0,
                                                              -0.02,
                                                            ),
                                                            end: const Offset(
                                                              0,
                                                              0.02,
                                                            ),
                                                          ),
                                                          builder: (
                                                            context,
                                                            offset,
                                                            child,
                                                          ) {
                                                            return Transform.translate(
                                                              offset: Offset(
                                                                0,
                                                                offset.dy * 100,
                                                              ),
                                                              child: Transform.scale(
                                                                scale:
                                                                    1 -
                                                                    (offset.dy *
                                                                        0.2),
                                                                child: AppText(
                                                                  _switchMode,
                                                                  variant:
                                                                      AppTextVariant
                                                                          .headline4,
                                                                  weight:
                                                                      AppTextWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper method to get asset card click event name
  String _getAssetCardClickEvent(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'banks':
        return AnalyticsEvents.dashboardAssetBanksCardClicked;
      case 'insurance':
        return AnalyticsEvents.dashboardAssetInsuranceCardClicked;
      case 'investments':
        return AnalyticsEvents.dashboardAssetInvestmentsCardClicked;
      case 'nps':
        return AnalyticsEvents.dashboardAssetNpsCardClicked;
      case 'mutualfunds':
      case 'mf':
        return AnalyticsEvents.dashboardAssetMutualFundsCardClicked;
      case 'etf':
        return AnalyticsEvents
            .dashboardAssetInvestmentsCardClicked; // Using investments as fallback for ETF
      case 'add':
        return AnalyticsEvents.dashboardAssetAddCardClicked;
      default:
        return AnalyticsEvents.dashboardAssetInvestmentsCardClicked;
    }
  }

  // Helper method to get asset navigation event name
  String _getAssetNavigationEvent(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'banks':
        return AnalyticsEvents.dashboardNavigateToBanks;
      case 'insurance':
        return AnalyticsEvents.dashboardNavigateToInsurance;
      case 'investments':
        return AnalyticsEvents.dashboardNavigateToInvestments;
      case 'nps':
        return AnalyticsEvents.dashboardNavigateToNps;
      case 'mutualfunds':
      case 'mf':
        return AnalyticsEvents.dashboardNavigateToMutualFunds;
      case 'etf':
        return AnalyticsEvents
            .dashboardNavigateToInvestments; // Fallback to investments
      default:
        return AnalyticsEvents.dashboardNavigateToInvestments;
    }
  }

  Widget _buildModernAssetItem({
    required String title,
    required String assetType,
    required Widget destination,
    required bool isAmountVisible,
    required bool isLinked,
    bool showDivider = true,
    required double amount,
    required bool isTestAccount,
  }) {
    final formattedAmount = CurrencyFormatter.formatRupee(amount);
    AppLogger.info(
      "_buildModernAssetItem: title: $title  isLinked: $isLinked type: $assetType",
    );
    final semanticLabel =
        assetType == 'add'
            ? 'Add assets'
            : isLinked
            ? '$title, ${isAmountVisible ? formattedAmount : 'amount hidden'}'
            : '$title, not linked. Tap to link';
    return Column(
      children: [
        Semantics(
          label: semanticLabel,
          button: true,
          hint:
              assetType == 'add'
                  ? 'Opens asset connection screen'
                  : 'Navigates to $title details',
          child: InkWell(
            key: Key(title),
            onTap:
                isTestAccount && assetType != "add"
                    ? () {
                      // Track navigation for test accounts
                      AnalyticsService.to.logEvent(
                        name: _getAssetNavigationEvent(assetType),
                        parameters: {
                          AnalyticsParams.assetType: assetType.toLowerCase(),
                          AnalyticsParams.isLinked: isLinked.toString(),
                          AnalyticsParams.destinationScreen: title
                              .toLowerCase()
                              .replaceAll(' ', '_'),
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      Get.to(destination, transition: Transition.rightToLeft);
                    }
                    : assetType == "add"
                    ? () {
                      AnalyticsService.to.logEvent(
                        name: AnalyticsEvents.dashboardAssetAddCardClicked,
                        parameters: {
                          AnalyticsParams.assetType: 'add',
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      AnalyticsService.to.logEvent(
                        name: AnalyticsEvents.dashboardNavigateToConnections,
                        parameters: {
                          AnalyticsParams.destinationScreen:
                              'finarkein_connection',
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      // Directly open Finarkein connection screen without any checks
                      Get.to(
                        () => const FinarkeinConnectionScreen(),
                        transition: Transition.rightToLeft,
                      );
                    }
                    : (assetType.toLowerCase() == "mutualfunds" ||
                        assetType.toLowerCase() == "mf")
                    ? () {
                      AnalyticsService.to.logEvent(
                        name:
                            AnalyticsEvents
                                .dashboardAssetMutualFundsCardClicked,
                        parameters: {
                          AnalyticsParams.assetType: 'mutual_funds',
                          AnalyticsParams.isLinked: isLinked.toString(),
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      if (isLinked) {
                        AnalyticsService.to.logEvent(
                          name: AnalyticsEvents.dashboardNavigateToMutualFunds,
                          parameters: {
                            AnalyticsParams.destinationScreen: 'mutual_funds',
                            AnalyticsParams.navigationMethod: 'card_click',
                          },
                        );
                        Get.to(destination, transition: Transition.rightToLeft);
                      } else {
                        _onTapLinkMutualFunds(context);
                        // Check for service outage
                        // final isMfcWorking =
                        //     RemoteConfigService.to.isMfcWorking.value;
                        // if (!isMfcWorking) {
                        //   AnalyticsService.to.logEvent(
                        //     name:
                        //         AnalyticsEvents
                        //             .dashboardMfServiceUnavailableShown,
                        //   );
                        //   // Use ScaffoldMessenger with widget's context instead of Get.snackbar
                        //   // Get.snackbar uses Get.context internally which may not have Overlay access
                        //   if (mounted && context.mounted) {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(
                        //         content: Row(
                        //           children: [
                        //             const Icon(
                        //               Icons.error_outline,
                        //               color: Colors.white,
                        //             ),
                        //             const SizedBox(width: 12),
                        //             Expanded(
                        //               child: Column(
                        //                 crossAxisAlignment:
                        //                     CrossAxisAlignment.start,
                        //                 mainAxisSize: MainAxisSize.min,
                        //                 children: [
                        //                   const Text(
                        //                     "Service Unavailable",
                        //                     style: TextStyle(
                        //                       color: Colors.white,
                        //                       fontWeight: FontWeight.w600,
                        //                       fontSize: 16,
                        //                     ),
                        //                   ),
                        //                   const SizedBox(height: 4),
                        //                   Text(
                        //                     "We are currently facing downtime with our mutual fund data provider. Please try again later.",
                        //                     style: TextStyle(
                        //                       color: Colors.white.withOpacity(
                        //                         0.9,
                        //                       ),
                        //                       fontSize: 14,
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //         backgroundColor: AppColors.error,
                        //         behavior: SnackBarBehavior.floating,
                        //         margin: const EdgeInsets.all(16),
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         duration: const Duration(seconds: 4),
                        //       ),
                        //     );
                        //   }
                        //   return;
                        // }

                        // AnalyticsService.to.logEvent(
                        //   name: AnalyticsEvents.dashboardNavigateToMutualFunds,
                        //   parameters: {
                        //     AnalyticsParams.destinationScreen: 'import_mf',
                        //     AnalyticsParams.navigationMethod: 'card_click',
                        //   },
                        // );
                        // Get.to(
                        //   () => ImportMf(),
                        //   transition: Transition.rightToLeft,
                        // );
                      }
                    }
                    : assetType.toLowerCase() == "personalassets"
                    ? () => Get.to(
                      () =>
                          isLinked
                              ? AllPersonalAssetsScreen(
                                isFamilyMode: _isFamilyMode,
                              )
                              : PersonalAssetsScreen(
                                isFamilyMode: _isFamilyMode,
                              ),
                      transition: Transition.rightToLeft,
                    )
                    : isLinked
                    ? () {
                      // Track navigation for linked assets
                      final navEvent = _getAssetNavigationEvent(assetType);
                      AnalyticsService.to.logEvent(
                        name: _getAssetCardClickEvent(assetType),
                        parameters: {
                          AnalyticsParams.assetType: assetType.toLowerCase(),
                          AnalyticsParams.isLinked: isLinked.toString(),
                          AnalyticsParams.assetAmount: amount.toString(),
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      AnalyticsService.to.logEvent(
                        name: navEvent,
                        parameters: {
                          AnalyticsParams.destinationScreen: title
                              .toLowerCase()
                              .replaceAll(' ', '_'),
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      Get.to(destination, transition: Transition.rightToLeft);
                    }
                    : () {
                      AnalyticsService.to.logEvent(
                        name: _getAssetCardClickEvent(assetType),
                        parameters: {
                          AnalyticsParams.assetType: assetType.toLowerCase(),
                          AnalyticsParams.isLinked: isLinked.toString(),
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      AnalyticsService.to.logEvent(
                        name:
                            AnalyticsEvents.dashboardNavigateToSaafeConnection,
                        parameters: {
                          AnalyticsParams.destinationScreen: 'saafe_connection',
                          AnalyticsParams.navigationMethod: 'card_click',
                        },
                      );
                      _onTapLinkAllAssets(context);
                    },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: AppText(
                                title,
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            if (assetType.toLowerCase() == "insurance")
                              const SizedBox(width: 2),
                            if (assetType.toLowerCase() == "insurance")
                              InkWell(
                                onTap: () {
                                  AnalyticsService.to.logEvent(
                                    name:
                                        AnalyticsEvents
                                            .dashboardAssetInfoIconClicked,
                                    parameters: {
                                      AnalyticsParams.assetType:
                                          assetType.toLowerCase(),
                                    },
                                  );
                                  _showSimpleBottomSheet(
                                    context,
                                    title,
                                    'This amount reflects your investment value, which is included in your net worth calculation.\nInvestment Value is the current market worth of your life insurance investments (excluding term insurance). This amount is realizable upon policy maturity or surrender.',
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.darkPrimary,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isLinked &&
                            _networthAmount > 0 &&
                            assetType.toLowerCase() != "add")
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: AppText(
                              '${((amount / _networthAmount) * 100).toStringAsFixed(1)}% allocation',
                              variant: AppTextVariant.bodySmall,
                              weight: AppTextWeight.regular,
                              colorType: AppTextColorType.secondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Amount or Action Button
                  Row(
                    children: [
                      if (assetType == "add")
                        InkWell(
                          onTap:
                              () => Get.to(
                                () => FinarkeinConnectionScreen(),
                                transition: Transition.rightToLeft,
                              ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.linkColor,
                          ),
                        ),
                      // Show loading animation during initial load, then "Link now" for unlinked assets
                      if (!isLinked && assetType != "add")
                        (isAssetsLoading || _isRefreshing)
                            ? AnimatedAmount(
                              isLoading: true,
                              amount: "₹0",
                              isAmountVisible: true,
                              alignment: Alignment.centerRight,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                            : InkWell(
                              onTap:
                                  (assetType.toLowerCase() == "mutualfunds" ||
                                          assetType.toLowerCase() == "mf")
                                      ? () {
                                        _onTapLinkMutualFunds(context);
                                        // Check for service outage
                                        // final isMfcWorking =
                                        //     RemoteConfigService.to.isMfcWorking.value;
                                        // if (!isMfcWorking) {
                                        //   if (mounted && context.mounted) {
                                        //     ScaffoldMessenger.of(context).showSnackBar(
                                        //       SnackBar(
                                        //         content: Row(
                                        //           children: [
                                        //             const Icon(
                                        //               Icons.error_outline,
                                        //               color: Colors.white,
                                        //             ),
                                        //             const SizedBox(width: 12),
                                        //             Expanded(
                                        //               child: Column(
                                        //                 crossAxisAlignment:
                                        //                     CrossAxisAlignment.start,
                                        //                 mainAxisSize: MainAxisSize.min,
                                        //                 children: [
                                        //                   const Text(
                                        //                     "Service Unavailable",
                                        //                     style: TextStyle(
                                        //                       color: Colors.white,
                                        //                       fontWeight: FontWeight.w600,
                                        //                       fontSize: 16,
                                        //                     ),
                                        //                   ),
                                        //                   const SizedBox(height: 4),
                                        //                   Text(
                                        //                     "We are currently facing downtime with our mutual fund data provider. Please try again later.",
                                        //                     style: TextStyle(
                                        //                       color: Colors.white.withOpacity(0.9),
                                        //                       fontSize: 14,
                                        //                     ),
                                        //                   ),
                                        //                 ],
                                        //               ),
                                        //             ),
                                        //           ],
                                        //         ),
                                        //         backgroundColor: AppColors.error,
                                        //         behavior: SnackBarBehavior.floating,
                                        //         margin: const EdgeInsets.all(16),
                                        //         shape: RoundedRectangleBorder(
                                        //           borderRadius: BorderRadius.circular(8),
                                        //         ),
                                        //         duration: const Duration(seconds: 4),
                                        //       ),
                                        //     );
                                        //   }
                                        //   return;
                                        // }

                                        // // Clear any existing retry information for fresh start
                                        // MFOnboardingService.clearRetryInfo();
                                        // Get.to(
                                        //   // () => MutualFundHoldingsJourneyScreen(
                                        //   //   isInitialJourney: false,
                                        //   // ),
                                        //   () => ImportMf(),
                                        //   transition: Transition.rightToLeft,
                                        // );
                                      }
                                      : assetType.toLowerCase() ==
                                          "personalassets"
                                      ? () => Get.to(
                                        () =>
                                            isLinked
                                                ? AllPersonalAssetsScreen(
                                                  isFamilyMode: _isFamilyMode,
                                                )
                                                : PersonalAssetsScreen(
                                                  isFamilyMode: _isFamilyMode,
                                                ),
                                        transition: Transition.rightToLeft,
                                      )
                                      : () {
                                        AnalyticsService.to.logEvent(
                                          name:
                                              AnalyticsEvents
                                                  .dashboardUnlinkedCtaClicked,
                                          parameters: {
                                            AnalyticsParams.taskTitle:
                                                "Link now",
                                            'asset_type': assetType,
                                          },
                                        );
                                        _onTapLinkAllAssets(context);
                                      },
                              child: AppText(
                                "Link now",
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.medium,
                                colorType: AppTextColorType.link,
                                decoration: TextDecoration.none,
                              ),
                            ),
                      if (isLinked)
                        AnimatedAmount(
                          isLoading:
                              (isAssetsLoading || _isRefreshing) ||
                              _isRefreshing,
                          amount: formattedAmount,
                          isAmountVisible: isAmountVisible,
                          alignment: Alignment.centerRight,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      if (assetType != "add") const SizedBox(width: 12),
                      // Arrow icon
                      if (assetType != "add")
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.darkTextGray,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Divider
        if (showDivider)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 0.5,
            color: AppColors.darkButtonBorder,
          ),
      ],
    );
  }

  /// Skeleton placeholder for the Assets list while initial data is loading.
  /// Avoids showing literal "Loading..." text in production UI.
  Widget _buildModernAssetLoadingItem({bool showDivider = true}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedAmount(
                    isLoading: true,
                    isAmountVisible: true,
                    amount: "••••••••••••••",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              AnimatedAmount(
                isLoading: true,
                isAmountVisible: true,
                amount: "•••••••••",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.darkTextGray,
                size: 16,
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 0.5,
            color: AppColors.darkButtonBorder,
          ),
      ],
    );
  }
}

class _PinSetupBottomSheet extends StatefulWidget {
  final VoidCallback? onPinSetupComplete;

  const _PinSetupBottomSheet({this.onPinSetupComplete});

  @override
  _PinSetupBottomSheetState createState() => _PinSetupBottomSheetState();
}

class _PinSetupBottomSheetState extends State<_PinSetupBottomSheet> {
  String _otpCode = '';
  final ValueNotifier<int> _otpKey = ValueNotifier<int>(0);
  bool _isConfirmationStep = false;
  String _firstPin = '';

  void _resetPinFields() {
    setState(() {
      _isConfirmationStep = false;
      _firstPin = '';
      _otpKey.value++; // Force OTPField recreation
    });
  }

  void _setPin(String pin) async {
    try {
      if (pin.length == 6) {
        if (!_isConfirmationStep) {
          // First PIN entry
          _firstPin = pin;
          setState(() {
            _isConfirmationStep = true;
            _otpCode = ''; // Clear the OTP code for confirmation step
            _otpKey.value++; // Force OTPField recreation for confirmation
          });
          return; // Exit early, don't proceed to confirmation dialog
        } else {
          // Confirmation PIN entry
          if (pin == _firstPin) {
            // PIN confirmed, save it directly
            await _savePinAndProceed(pin);
          } else {
            setState(() {
              _isConfirmationStep = false;
              _firstPin = '';
              _otpCode = ''; // Clear the OTP code
            });
            _showPinMismatchDialog(context);
          }
        }
      } else {
        AppLogger.error('Invalid pin', tag: 'SetPin');
      }
    } catch (e) {
      AppLogger.error('SetPin Error', error: e, tag: 'SetPin');
    }
  }

  Future<void> _savePinAndProceed(String pin) async {
    try {
      // Save PIN to secure storage
      await SecureStorage.write(StorageKeys.PIN_KEY, pin);
      await SecureStorage.write(StorageKeys.IS_PIN_SET_KEY, 'true');

      // Close bottom sheet
      Navigator.of(context).pop();

      // Trigger the callback to show unlinked assets bottom sheet
      widget.onPinSetupComplete?.call();
    } catch (e) {
      AppLogger.error('Error saving PIN', error: e, tag: 'DashboardPinSetup');
    }
  }

  void _showPinMismatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "PIN Mismatch",
                    variant: AppTextVariant.headline5,
                    weight: AppTextWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppText(
                    "The PIN you entered do not match, Please try again.",
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    lineHeight: 1.5,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.darkInputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetPinFields();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    child: AppText(
                      "Try Again",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.primary,
                      weight: AppTextWeight.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _otpKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkTextGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Header with shield icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    AppText(
                      _isConfirmationStep
                          ? "Confirm your PIN to protect your account"
                          : "Set up your PIN to protect your account",
                      variant: AppTextVariant.headline5,
                      weight: AppTextWeight.bold,
                      textAlign: TextAlign.center,
                      lineHeight: 1.3,
                    ),
                    const SizedBox(height: 12),
                    // Description
                    AppText(
                      _isConfirmationStep
                          ? "Confirm your PIN to keep your account secure and ensure quick access every time you open the Pivot Money app."
                          : "Create a PIN to keep your account secure and ensure quick access every time you open the Pivot Money app.",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                      lineHeight: 1.5,
                    ),
                    const SizedBox(height: 40),
                    // PIN input label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        _isConfirmationStep
                            ? "Confirm 6 digit MPIN"
                            : "Enter 6 digit MPIN",
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // PIN input field
                    RepaintBoundary(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _otpKey,
                        builder:
                            (context, key, child) => OTPField(
                              key: ValueKey(key),
                              enableAutofill: false,
                              onOTPFilled: (pin) {
                                setState(() => _otpCode = pin);
                                _setPin(pin);
                              },
                              length: 6,
                              obscureText: true,
                            ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  ],
                ),
              ),
            ),
            // Set PIN button
            Container(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    16,
                top: 10,
              ),
              width: double.infinity,
              child: AppButton(
                text: _isConfirmationStep ? 'Confirm' : 'Proceed',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: () {
                  if (_otpCode.length == 6) {
                    _setPin(_otpCode);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dedicated KYC card removed; KYC CTA is now sourced from `unlinkedStateTasks` only.
