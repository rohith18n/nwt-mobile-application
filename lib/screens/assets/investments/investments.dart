import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:developer' as dev;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_realtime_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/fip_status_controller.dart';
import 'package:nwt_app/controllers/dashboard/total_networth_controller.dart';
import 'package:nwt_app/controllers/dashboard/dashboard_asset.dart';
import 'package:nwt_app/controllers/account_aggregators/aa_data_fetch_controller.dart';
import 'package:nwt_app/types/account_aggregators/aa_data_fetch_options.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/types/portfolio.dart';
import 'package:nwt_app/screens/assets/investments/widgets/etf_holding_card.dart';
import 'package:nwt_app/screens/assets/investments/widgets/holding_card.dart';
import 'package:nwt_app/screens/assets/investments/widgets/stock_holding_card.dart';
import 'package:nwt_app/controllers/mf_central/mf_central_status_controller.dart';
import 'package:nwt_app/screens/fetch-holdings/mf_fetching.dart';
import 'package:nwt_app/services/mf_central/mf_central_linked_accounts_service.dart';
import 'package:nwt_app/types/mf_central/mf_central_linked_account.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/widgets/common/service_outage_card.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/data_fetch_details_screen.dart';
import 'package:nwt_app/screens/mf_central/mf_central_detail_screen.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_instructions_screen.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/assets/investments/isin_service.dart';
import 'package:nwt_app/services/mf_onboarding/mf_onboarding_service.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/widgets/verification/universal_pan_verification_widget.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/graph_legend.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/widgets/status_card_swiper.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/screens/dashboard/widgets/unlinked_state_widgets.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';

class AssetInvestmentScreen extends StatefulWidget {
  const AssetInvestmentScreen({
    super.key,
    required this.isstacknavbar,
    this.initialCategory,
    this.forceStandardApis = false,
  });

  final bool isstacknavbar;
  final String? initialCategory;
  final bool forceStandardApis;

  @override
  State<AssetInvestmentScreen> createState() => _AssetInvestmentScreenState();
}

const categories = ["All", "Equity", "Mutual Funds", "ETF"];

class _AssetInvestmentScreenState extends State<AssetInvestmentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isAmountVisible = true;
  final RxString _searchQuery = ''.obs; // Reactive search query
  final RxMap<String, bool> _expandedBrokers =
      <String, bool>{}.obs; // Expand/collapse state for broker groups
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  // Removed animation controllers for progress bars
  bool showFullHeader = true;
  final InvestmentController investmentController = Get.put(
    InvestmentController(),
  );
  final PortfolioRealtimeController _realtimeController = Get.put(
    PortfolioRealtimeController(),
  );
  final userController = Get.find<UserController>();
  late RawAssetController rawAssetController;
  late FipStatusController _fipStatusController;
  Worker? _refreshWorker;

  bool isPortfolioLoading = true;
  bool isHoldingLoading = true;
  late AnimationController _refreshController;
  late String _selectedCategory;

  // FIP Status polling variables
  Timer? _fipPollingTimer;
  final Duration _fipPollingInterval = const Duration(seconds: 3);

  // ISIN service variables
  final IsinService _isinService = IsinService();
  DateTime? _latestIsinUpdatedDate;
  bool _isIsinDateLoading = false;
  bool _didAttemptFinarkeinResultSync = false;

  final AccountAggregatorRouter _accountAggregatorRouter =
      AccountAggregatorRouter();
  Future<List<Map<String, dynamic>>>? _mfCentralSwiperAccountsFuture;

  bool _hasAnyFinarkeinDataNow() {
    // Check 1: InvestmentController (Direct screen data)
    if (Get.isRegistered<InvestmentController>()) {
      final ctrl = Get.find<InvestmentController>();

      final portfolio = ctrl.portfolio;
      if (portfolio != null &&
          (portfolio.value > 0 || portfolio.invested > 0)) {
        return true;
      }

      final inv = ctrl.holdings?.data?.investments;
      if (inv != null &&
          (inv.mf.isNotEmpty || inv.stocks.isNotEmpty || inv.etf.isNotEmpty)) {
        return true;
      }

      // Check for MF Central holdings (V2 API)
      if (ctrl.mfCentralHoldings.isNotEmpty) {
        return true;
      }
    }

    // Check 2: TotalNetworthController (Standard API)
    if (Get.isRegistered<TotalNetworthController>()) {
      final data = Get.find<TotalNetworthController>().networthData.value?.data;
      if (data != null && data.totalNetWorth > 0) return true;
    }

    // Check 3: DashboardAssetController (Standard API)
    if (Get.isRegistered<DashboardAssetController>()) {
      final assets =
          Get.find<DashboardAssetController>().dashboardAssets.value?.data;
      if (assets != null && assets.any((a) => a.value > 0)) return true;
    }

    // Check 4: FinarkeinDataController (Legacy/Fallback)
    if (Get.isRegistered<FinarkeinDataController>()) {
      final finarkeinCtrl = Get.find<FinarkeinDataController>();
      final data = finarkeinCtrl.dataResponse.value?.data;
      if (data != null) {
        final networth = data.summary['networth'];
        if (networth != null && networth > 0) return true;
      }
    }

    // Check 5: RawAssetController (Legacy/Fallback)
    if (Get.isRegistered<RawAssetController>()) {
      final ctrl = Get.find<RawAssetController>();
      if (ctrl.equities.isNotEmpty ||
          ctrl.mutualFunds.isNotEmpty ||
          ctrl.etfs.isNotEmpty ||
          ctrl.banks.isNotEmpty) {
        return true;
      }
    }

    // Check 6: FipStatusController (Linked accounts)
    if (Get.isRegistered<FipStatusController>()) {
      final ctrl = Get.find<FipStatusController>();
      if (ctrl.accounts.isNotEmpty) return true;
    }

    return false;
  }

  bool _hasLinkedInvestments() {
    // Check AA data
    if (Get.isRegistered<AaDataFetchController>()) {
      final data = Get.find<AaDataFetchController>().fetchOptionsData.value;
      if (data != null && (data.equities.isNotEmpty || data.etf.isNotEmpty)) {
        return true;
      }
    }

    // Check MF Central data
    if (Get.isRegistered<MFCentralStatusController>()) {
      final ctrl = Get.find<MFCentralStatusController>();
      if (ctrl.status.value != 'none') return true;
    }

    return false;
  }

  List<Map<String, dynamic>> _getMergedAccountStatuses() {
    final List<Map<String, dynamic>> result = [];

    // Use only AaDataFetchController and MFCentralStatusController as sources of truth

    // 2. Add accounts from AaDataFetchController (Categorized)
    if (Get.isRegistered<AaDataFetchController>()) {
      final data = Get.find<AaDataFetchController>().fetchOptionsData.value;
      if (data != null) {
        // Map categorized lists to our swiper format
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
            // Avoid duplicates
            final exists = result.any(
              (acc) =>
                  acc['fipname'] == option.fipName &&
                  acc['maskedaccno'] == option.maskedAccNumber,
            );

            if (!exists) {
              result.add({
                'type':
                    categoryType, // Use the category type as the source of truth
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

    return result;
  }

  String _getFormattedLastFetchedTime(List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) return '';

    DateTime? mostRecent;
    for (final account in accounts) {
      final dynamic updatedAt =
          account['lastdatafetchedat'] ?? account['fetchstatusupdatedat'];
      if (updatedAt != null) {
        final DateTime? date =
            updatedAt is DateTime
                ? updatedAt
                : DateTime.tryParse(updatedAt.toString());
        if (date != null && (mostRecent == null || date.isAfter(mostRecent))) {
          mostRecent = date;
        }
      }
    }

    if (mostRecent == null) return _fipStatusController.lastFetchedTime;

    // Format as "3 Mar, 2:00 PM"
    final formatter = DateFormat('d MMM, h:mm a');
    return formatter.format(mostRecent.toLocal());
  }

  /// Fetch MF Central linked accounts grouped by AMC for swiper
  Future<List<Map<String, dynamic>>> _getMFCentralSwiperAccounts() async {
    final List<Map<String, dynamic>> accounts = [];

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

          // Get most recent last_updated by parsing the dates
          DateTime? mostRecentDate;
          String mostRecentUpdateRaw = '';

          for (final acc in accountsList) {
            if (acc.lastUpdated.isNotEmpty) {
              DateTime? currentDt;
              try {
                currentDt = DateFormat(
                  "dd MMM yyyy, hh:mm a",
                ).parse(acc.lastUpdated);
              } catch (e) {
                currentDt = DateTime.tryParse(acc.lastUpdated);
              }

              if (currentDt != null) {
                if (mostRecentDate == null ||
                    currentDt.isAfter(mostRecentDate)) {
                  mostRecentDate = currentDt;
                  mostRecentUpdateRaw = acc.lastUpdated;
                }
              }
            }
          }

          accounts.add({
            'type': 'MUTUAL_FUNDS',
            'fetchstatus': groupStatus,
            'fipname': amcName,
            'guid': 'mfcentral_${amcName.hashCode}',
            'fipid': 'MF_CENTRAL',
            'userguid': '',
            'activestatus': 'ACTIVE',
            'fetchstatusupdatedat': mostRecentDate,
            'balancedatetime': mostRecentDate,
            'lastdatafetchedat': mostRecentDate, // Pass DateTime object
            'lastdatafetchedat_raw': mostRecentUpdateRaw, // Fallback raw string
            'imageurl': '',
            'maskedaccno':
                '${accountsList.length} folio${accountsList.length > 1 ? 's' : ''}',
            'isMFCentralGroup': true,
            'amcName': amcName,
            'folioCount': accountsList.length,
          });
        }

        AppLogger.info(
          'Investments: Grouped ${response.data.length} MF Central accounts into ${groupedByAmc.length} AMC groups',
          tag: 'Investments',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching MF Central linked accounts for swiper',
        error: e,
        stackTrace: stackTrace,
        tag: 'Investments',
      );
    }

    return accounts;
  }

  /// Maps an FI type or Investment category to a Linked Accounts category name.
  String _mapToLinkedAccountCategory(String? type) {
    if (type == null || type.isEmpty || type == 'All') {
      return "Mutual Funds";
    }
    final upperType = type.toUpperCase().replaceAll('_', ' ');
    if (upperType.contains('EQUITY') ||
        upperType.contains('STOCK') ||
        upperType.contains('ETF')) {
      return "Equities & ETFs";
    } else if (upperType.contains('MUTUAL FUND') || upperType.contains('MF')) {
      return "Mutual Funds";
    } else if (upperType.contains('DEPOSIT') ||
        upperType.contains('SAVINGS') ||
        upperType.contains('BANK')) {
      return "Savings & Deposits";
    } else if (upperType.contains('INSURANCE')) {
      return "Insurance";
    } else if (upperType.contains('NPS')) {
      return "NPS";
    }
    return "Savings & Deposits";
  }

  /// Routes swiper card taps — MFC cards → MFCentralDetailScreen,
  /// all other cards → DataFetchDetailsScreen.
  void _onSwiperCardTap(Map<String, dynamic> cardData) {
    final fipname = (cardData['fipname'] as String? ?? '').toLowerCase();
    final type = cardData['type'] as String?;

    if (fipname.contains('mutual fund holdings')) {
      Get.to(
        () => const MFCentralDetailScreen(),
        transition: Transition.rightToLeft,
      );
    } else {
      Get.to(
        () => DataFetchDetailsScreen(
          initialCategory: _mapToLinkedAccountCategory(
            type ?? _selectedCategory,
          ),
        ),
        transition: Transition.rightToLeft,
      );
    }
  }

  bool _shouldShowUnlockCard() {
    final isFamilyMode =
        GetStorage().read(StorageKeys.FAMILY_MODE_KEY) ?? false;
    if (isFamilyMode) return false;

    // Show card if no data is found across any source
    return !_hasAnyFinarkeinDataNow();
  }

  Future<void> _onTapLinkAllAssets(BuildContext context) async {
    // Check validation status like in dashboard.dart
    final userController =
        Get.isRegistered<UserController>() ? Get.find<UserController>() : null;
    final phone =
        userController?.userData?.phonenumber ??
        userController?.userData?.secondaryphonenumber;
    final email = userController?.userData?.email;
    bool phoneVerified = phone != null;
    bool emailVerified = false;
    bool needsEmail = false;

    try {
      final validate = await ProfileService().getProfileValidate();
      if (validate != null && validate['success'] == true) {
        final data = validate['data'];
        phoneVerified = data['phone']?['status'] == 'verified';
        emailVerified = data['email']?['status'] == 'verified';
        final emailStatus = data['email']?['status'] as String?;
        final ctx = data['context'] as Map<String, dynamic>? ?? {};
        needsEmail =
            !emailVerified &&
            (ctx['needs_email'] == true || emailStatus == 'pending');
      }
    } catch (e) {
      AppLogger.error(
        'Error checking validation status: $e',
        tag: 'Investments',
      );
    }

    // Show PAN verification widget
    Get.to(
      () => UniversalPanVerificationWidget(
        showProgress: false,
        title: 'Link Assets',
        phoneNumber: phone,
        isPhoneValidated: phoneVerified,
        isEmailValidated: emailVerified,
        needsEmailVerification: needsEmail,
        email: email,
        onSuccess: (panData) async {
          final phoneNumber = panData['phone_number'] as String?;
          AppLogger.info(
            'PAN verified for Assets linking - Phone: $phoneNumber',
            tag: 'Investments',
          );
          await _accountAggregatorRouter.openConnection(
            context,
            phoneNumber: phoneNumber ?? phone ?? '',
            showConnectionScreen: false,
          );
        },
      ),
    );
  }

  InvestmentPortfolio _buildPortfolioFromProvider() {
    // Prioritize standard portfolio data if available from the API
    if (investmentController.portfolio != null) {
      return investmentController.portfolio!;
    }

    // Default empty portfolio if no data is available
    return InvestmentPortfolio(
      value: 0,
      invested: 0,
      gain: 0,
      latestbalancedatetime: DateTime.now().toIso8601String(),
      deltavalue: 0,
      deltapercentage: 0,
      coverage: Coverage(stocks: 0, mutualfunds: 0, etf: 0, fo: 0),
      etf_total: 0,
      mf_total: 0,
      stocks_total: 0,
    );
  }

  /// Restores amount visibility state from persistent storage
  void _restoreAmountVisibilityState() {
    final savedAmountVisibility =
        StorageService.read(StorageKeys.AMOUNT_VISIBILITY_KEY) ?? false;
    setState(() {
      _isAmountVisible = savedAmountVisibility;
    });
  }

  AppBar _buildAppbar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          !widget.isstacknavbar
              ? Semantics(
                label: 'Back',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    AnalyticsService.to.logEvent(
                      name: AnalyticsEvents.investmentsBackButtonClicked,
                      parameters: {
                        AnalyticsParams.screenName: 'investments_main',
                        AnalyticsParams.categoryName:
                            _selectedCategory.toLowerCase(),
                      },
                    );
                    BackNavigation.backOrHome();
                  },
                  child: ExcludeSemantics(
                    child: const Icon(Icons.chevron_left, size: 32),
                  ),
                ),
              )
              : SizedBox.shrink(),
          AppText(
            "My Investments",
            variant: AppTextVariant.headline2,
            weight: AppTextWeight.bold,
            customColor: Colors.white,
          ),
          const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
        ],
      ),
    );
  }

  Widget _buildHeader(InvestmentPortfolio? portfolio, Function onRefresh) {
    // Get the appropriate portfolio value based on selected category
    AppLogger.info("_buildHeader: portfolio: ${portfolio?.value}");

    // Check if RawAssetController data is ready for Finarkein users
    bool isDataReady() {
      final isFinarkein = userController.userData?.isFinarkeinAa == true;
      if (!isFinarkein) return true; // Non-Finarkein users use backend API

      if (!Get.isRegistered<RawAssetController>()) return false;
      final rawCtrl = Get.find<RawAssetController>();

      // Data is ready if we have summary OR any actual assets OR standard portfolio data
      return rawCtrl.summary.value.isNotEmpty ||
          rawCtrl.equities.isNotEmpty ||
          rawCtrl.mutualFunds.isNotEmpty ||
          rawCtrl.etfs.isNotEmpty ||
          investmentController.portfolio != null;
    }

    double getPortfolioValueForCategory() {
      if (portfolio == null || !isDataReady()) return 0.0;

      final eqCalc = _calculateEquityPortfolioFromHoldings();
      final mfCalc = _calculateMfPortfolioFromHoldings();
      final etfCalc = _calculateEtfPortfolioFromHoldings();

      final wsTotals = _realtimeController.totals.value;

      switch (_selectedCategory) {
        case 'Equity':
          return (wsTotals?.equityTotal != null && wsTotals!.equityTotal! > 0)
              ? wsTotals.equityTotal!
              : (eqCalc['total'] ?? 0.0);
        case 'Mutual Funds':
          return mfCalc['total'] ?? 0.0;
        case 'ETF':
          return (wsTotals?.etfTotal != null && wsTotals!.etfTotal! > 0)
              ? wsTotals.etfTotal!
              : (etfCalc['total'] ?? 0.0);
        default: // 'All'
          final eqVal = (wsTotals?.equityTotal != null && wsTotals!.equityTotal! > 0)
              ? wsTotals.equityTotal!
              : (eqCalc['total'] ?? 0.0);
          final etfVal = (wsTotals?.etfTotal != null && wsTotals!.etfTotal! > 0)
              ? wsTotals.etfTotal!
              : (etfCalc['total'] ?? 0.0);
          return eqVal + (mfCalc['total'] ?? 0.0) + etfVal;
      }
    }

    // Get the appropriate invested amount based on selected category
    double? getInvestedAmountForCategory() {
      if (portfolio == null || !isDataReady()) return null;

      final eqCalc = _calculateEquityPortfolioFromHoldings();
      final mfCalc = _calculateMfPortfolioFromHoldings();
      final etfCalc = _calculateEtfPortfolioFromHoldings();

      final wsTotals = _realtimeController.totals.value;

      switch (_selectedCategory) {
        case 'Equity':
          return eqCalc['invested'] ?? 0.0;
        case 'Mutual Funds':
          return mfCalc['invested'] ?? 0.0;
        case 'ETF':
          return etfCalc['invested'] ?? 0.0;
        default: // 'All'
          return (wsTotals?.invested != null && wsTotals!.invested! > 0)
              ? wsTotals.invested!
              : ((eqCalc['invested'] ?? 0.0) +
                  (mfCalc['invested'] ?? 0.0) +
                  (etfCalc['invested'] ?? 0.0));
      }
    }

    // Get the appropriate gain based on selected category
    double? getGainForCategory() {
      if (portfolio == null) return null;

      final eqCalc = _calculateEquityPortfolioFromHoldings();
      final mfCalc = _calculateMfPortfolioFromHoldings();
      final etfCalc = _calculateEtfPortfolioFromHoldings();

      final wsTotals = _realtimeController.totals.value;

      switch (_selectedCategory) {
        case 'Equity':
          if (wsTotals?.equityTotal != null && wsTotals!.equityTotal! > 0) {
            final eqInvested = eqCalc['invested'] ?? 0.0;
            return wsTotals.equityTotal! - eqInvested;
          }
          return eqCalc['gain'] ?? 0.0;
        case 'Mutual Funds':
          return mfCalc['gain'] ?? 0.0;
        case 'ETF':
          if (wsTotals?.etfTotal != null && wsTotals!.etfTotal! > 0) {
            final etfInvested = etfCalc['invested'] ?? 0.0;
            return wsTotals.etfTotal! - etfInvested;
          }
          return etfCalc['gain'] ?? 0.0;
        default: // 'All'
          final eqVal = (wsTotals?.equityTotal != null && wsTotals!.equityTotal! > 0)
              ? wsTotals.equityTotal!
              : (eqCalc['total'] ?? 0.0);
          final etfVal = (wsTotals?.etfTotal != null && wsTotals!.etfTotal! > 0)
              ? wsTotals.etfTotal!
              : (etfCalc['total'] ?? 0.0);
          final totalVal = eqVal + (mfCalc['total'] ?? 0.0) + etfVal;

          final totalInvested =
              (wsTotals?.invested != null && wsTotals!.invested! > 0)
                  ? wsTotals.invested!
                  : ((eqCalc['invested'] ?? 0.0) +
                      (mfCalc['invested'] ?? 0.0) +
                      (etfCalc['invested'] ?? 0.0));
          return totalVal - totalInvested;
      }
    }

    // Get the appropriate title based on selected category
    String getPortfolioTitle() {
      switch (_selectedCategory) {
        case 'Equity':
          return "Equity Portfolio Value";
        case 'Mutual Funds':
          return "Mutual Funds Portfolio Value";
        case 'ETF':
          return "ETF Portfolio Value";
        default: // 'All'
          return "Overall Portfolio Value";
      }
    }

    return Container(
      color: AppColors.darkBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Container(
              padding: EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkButtonBorder),
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Obx(() {
                // Access _searchQuery observable to avoid GetX error when no other observables are accessed
                final _ = _searchQuery.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              getPortfolioTitle(),
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.bold,
                              colorType: AppTextColorType.secondary,
                            ),
                            Semantics(
                              label:
                                  _selectedCategory == 'Mutual Funds'
                                      ? 'Re-initiate MF Central'
                                      : 'Refresh investments',
                              button: true,
                              child: GestureDetector(
                                onTap: () {
                                  AnalyticsService.to.logEvent(
                                    name:
                                        AnalyticsEvents
                                            .investmentsStatusButtonClicked,
                                    parameters: {
                                      AnalyticsParams.screenName:
                                          'investments_main',
                                      AnalyticsParams.categoryName:
                                          _selectedCategory.toLowerCase(),
                                    },
                                  );

                                  if (_selectedCategory == 'Mutual Funds') {
                                    // Re-initiate the full MF Central journey
                                    final pan =
                                        userController.userData?.pannumber ??
                                        '';
                                    final phone =
                                        userController.userData?.phonenumber ??
                                        userController
                                            .userData
                                            ?.secondaryphonenumber ??
                                        '';
                                    Get.to(
                                      () => MFCInstructionsScreen(
                                        panNumber: pan,
                                        phoneNumber: phone,
                                      ),
                                      transition: Transition.rightToLeft,
                                    );
                                  } else {
                                    // Navigate to linked accounts filtered by category
                                    Get.to(
                                      () => DataFetchDetailsScreen(
                                        initialCategory:
                                            _mapToLinkedAccountCategory(
                                              _selectedCategory,
                                            ),
                                      ),
                                      transition: Transition.rightToLeft,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkButtonBorder,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.darkButtonBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: ExcludeSemantics(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _selectedCategory == 'Mutual Funds'
                                              ? Icons.sync
                                              : Icons.refresh,
                                          size: 14,
                                          color:
                                              AppColors
                                                  .darkButtonPrimaryBackground,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText(
                                          _selectedCategory == 'Mutual Funds'
                                              ? "Re-initiate"
                                              : "Refresh",
                                          variant: AppTextVariant.tiny,
                                          weight: AppTextWeight.medium,
                                          colorType: AppTextColorType.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AnimatedAmount(
                                isMain: true,
                                isLoading: isPortfolioLoading || !isDataReady(),
                                isAmountVisible: _isAmountVisible,
                                amount: CurrencyFormatter.formatRupee(
                                  // portfolio?.value ?? 0,
                                  getPortfolioValueForCategory(),
                                ),
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkPrimary,
                                ),
                              ),
                            ),
                            Semantics(
                              label:
                                  _isAmountVisible
                                      ? 'Hide portfolio amounts'
                                      : 'Show portfolio amounts',
                              button: true,
                              toggled: _isAmountVisible,
                              child: GestureDetector(
                                onTap: () {
                                  final previousVisibility = _isAmountVisible;
                                  setState(() {
                                    _isAmountVisible = !_isAmountVisible;
                                    StorageService.write(
                                      StorageKeys.AMOUNT_VISIBILITY_KEY,
                                      _isAmountVisible,
                                    );
                                  });
                                  AnalyticsService.to.logEvent(
                                    name:
                                        AnalyticsEvents
                                            .investmentsAmountVisibilityToggled,
                                    parameters: {
                                      AnalyticsParams.screenName:
                                          'investments_main',
                                      AnalyticsParams.isVisible:
                                          _isAmountVisible.toString(),
                                      AnalyticsParams.previousVisibility:
                                          previousVisibility.toString(),
                                    },
                                  );
                                },
                                child: ExcludeSemantics(
                                  child: Icon(
                                    _isAmountVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.darkPrimary,
                                    size: 22.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppText(
                          portfolio?.latestbalancedatetime != null
                              ? "Last data fetched at ${portfolio!.latestbalancedatetime != null ? DateFormatter.formatToDateTimeWithAmPm(DateTime.parse(portfolio.latestbalancedatetime!)) : ""}"
                              : "No data fetched yet",
                          variant: AppTextVariant.tiny,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.secondary,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),

                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 10,
                    //     vertical: 8,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: ((portfolio?.deltavalue ?? 0) < 0
                    //             ? AppColors.error
                    //             : AppColors.success)
                    //         .withValues(alpha: 0.1),
                    //     borderRadius: BorderRadius.circular(6),
                    //   ),
                    //   child:
                    //       isPortfolioLoading
                    //           ? Shimmer.fromColors(
                    //             baseColor: AppColors.darkCardBG,
                    //             highlightColor: AppColors.darkButtonBorder,
                    //             child: Container(
                    //               width: 100,
                    //               height: 20,
                    //               decoration: BoxDecoration(
                    //                 color: AppColors.darkCardBG,
                    //                 borderRadius: BorderRadius.circular(4),
                    //               ),
                    //             ),
                    //           )
                    //           : AppText(
                    //             "${_isAmountVisible ? '${(portfolio?.deltavalue ?? 0) < 0 ? '' : '+'}${CurrencyFormatter.formatRupee(portfolio?.deltavalue ?? 0)}' : '••••••'} (${portfolio?.deltapercentage}%) Today",
                    //             variant: AppTextVariant.bodySmall,
                    //             weight: AppTextWeight.medium,
                    //             colorType:
                    //                 (portfolio?.deltavalue ?? 0) < 0
                    //                     ? AppTextColorType.error
                    //                     : AppTextColorType.success,
                    //           ),
                    // ),
                    SizedBox(height: 16),
                    ExcludeSemantics(
                      child: SizedBox(
                        width: double.infinity,
                        height: 8,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Minimum flex value to ensure visibility of small percentages
                            final int minFlex = 1;

                            // Get individual coverage values
                            final int stocksFlex =
                                (portfolio?.coverage.stocks ?? 0) > 0
                                    ? math.max(
                                      (portfolio?.coverage.stocks ?? 0).round(),
                                      minFlex,
                                    )
                                    : 0;
                            final int mfFlex =
                                (portfolio?.coverage.mutualfunds ?? 0) > 0
                                    ? math.max(
                                      (portfolio?.coverage.mutualfunds ?? 0)
                                          .round(),
                                      minFlex,
                                    )
                                    : 0;
                            final int etfFlex =
                                (portfolio?.coverage.etf ?? 0) > 0
                                    ? math.max(
                                      (portfolio?.coverage.etf ?? 0).round(),
                                      minFlex,
                                    )
                                    : 0;

                            // Determine which segments are visible for border radius
                            final bool hasStocks = stocksFlex > 0;
                            final bool hasEtf = etfFlex > 0;
                            final bool hasMF = mfFlex > 0;

                            return Row(
                              spacing: 8,
                              children: [
                                // Stocks bar
                                if (hasStocks)
                                  Expanded(
                                    flex: stocksFlex,
                                    child: Container(
                                      // Add small spacing between segments
                                      padding: EdgeInsets.only(
                                        right: hasMF || hasEtf ? 1 : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
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

                                // Mutual Funds bar
                                if (hasMF)
                                  Expanded(
                                    flex: mfFlex,
                                    child: Container(
                                      padding: EdgeInsets.only(
                                        left: hasStocks ? 1 : 0,
                                        right: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
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

                                // ETF bar
                                if (hasEtf)
                                  Expanded(
                                    flex: etfFlex,
                                    child: Container(
                                      padding: EdgeInsets.only(
                                        left: hasStocks || hasMF ? 1 : 0,
                                        right: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF48AEE4),
                                            Color(0xFF3A9499),
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
                        CategoryLegend(
                          category: "ETF",
                          color: Color(0xFF48AEE4),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_selectedCategory != 'All' &&
                        (((_selectedCategory != 'Equity' &&
                                    _selectedCategory != 'ETF') &&
                                (getInvestedAmountForCategory() ?? 0.0) !=
                                    0.0) ||
                            (getGainForCategory() ?? 0.0) != 0.0))
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.darkButtonBorder,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          spacing: 6,
                          children: [
                            if (_selectedCategory != 'Equity' &&
                                _selectedCategory != 'ETF' &&
                                (getInvestedAmountForCategory() ?? 0.0) != 0.0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AppText(
                                    "Invested",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.medium,
                                    colorType: AppTextColorType.primary,
                                  ),
                                  SizedBox(height: 3),
                                  AnimatedAmount(
                                    isLoading:
                                        isPortfolioLoading || !isDataReady(),
                                    amount:
                                        CurrencyFormatter.formatRupeeWithCommas(
                                          getInvestedAmountForCategory() ?? 0.0,
                                          decimals: 0,
                                        ),
                                    alignment: Alignment.centerRight,
                                    isAmountVisible: _isAmountVisible,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            if ((getGainForCategory() ?? 0.0) != 0.0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AppText(
                                    "Gain",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.medium,
                                    colorType: AppTextColorType.primary,
                                  ),
                                  SizedBox(height: 3),
                                  AnimatedAmount(
                                    isLoading:
                                        isPortfolioLoading || !isDataReady(),
                                    amount:
                                        "${(getGainForCategory() ?? 0.0) >= 0 ? '+' : '-'}${CurrencyFormatter.formatRupeeWithCommas(getGainForCategory() ?? 0.0, decimals: 2)}",
                                    alignment: Alignment.centerRight,
                                    isAmountVisible: _isAmountVisible,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          (getGainForCategory() ?? 0.0) >= 0
                                              ? AppColors.success
                                              : AppColors.error,
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
                        Semantics(
                          label: 'Speak to advisor for investment advice',
                          link: true,
                          child: InkWell(
                            onTap: () async {
                              AnalyticsService.to.logEvent(
                                name:
                                    AnalyticsEvents
                                        .investmentsSpeakToAdvisorClicked,
                                parameters: {
                                  AnalyticsParams.screenName:
                                      'investments_main',
                                  AnalyticsParams.sourceCategory:
                                      _selectedCategory.toLowerCase(),
                                },
                              );
                              SpeakToAdvisor.speakToAdvisor();
                            },
                            child: ExcludeSemantics(
                              child: AppText(
                                "Speak to advisor for Investment advise",
                                variant: AppTextVariant.bodyMedium,
                                colorType: AppTextColorType.link,
                                weight: AppTextWeight.medium,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLatestIsinUpdatedDate() async {
    try {
      final response = await _isinService.getLatestIsinUpdatedDate(
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              _isIsinDateLoading = isLoading;
            });
          }
        },
      );

      if (response?.success == true && response?.data != null) {
        final dateTime = response!.data!.dateTime;
        if (mounted && dateTime != null) {
          setState(() {
            _latestIsinUpdatedDate = dateTime;
          });
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching ISIN updated date',
        error: e,
        tag: 'Investments',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _realtimeController.connectClient('investments');
    _selectedCategory = widget.initialCategory ?? 'All';
    _restoreAmountVisibilityState();
    _mfCentralSwiperAccountsFuture = _getMFCentralSwiperAccounts();

    // Initialize FipStatusController
    _fipStatusController =
        Get.isRegistered<FipStatusController>()
            ? Get.find<FipStatusController>()
            : Get.put(FipStatusController(), permanent: true);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Removed progress bar animation initialization

    // Initialize RawAssetController for Finarkein users
    final isFinarkein = userController.userData?.isFinarkeinAa == true;
    if (isFinarkein) {
      if (!Get.isRegistered<RawAssetController>()) {
        rawAssetController = Get.put(RawAssetController());
      } else {
        rawAssetController = Get.find<RawAssetController>();
      }
      // Note: Data will be fetched in fetchPortfolio() to avoid race conditions
    }

    // Start the initial animation
    _animationController.forward();
    fetchPortfolio();

    // Re-fetch whenever the My Investments tab is tapped again
    _refreshWorker = ever(investmentController.refreshTrigger, (_) {
      if (mounted) fetchPortfolio();
    });

    // Log screen view
    AnalyticsService.to.logScreenView(screenName: 'investments_main');
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.investmentsScreenViewed,
      parameters: {
        AnalyticsParams.screenName: 'investments_main',
        AnalyticsParams.categoryName: _selectedCategory.toLowerCase(),
        AnalyticsParams.isAmountVisible: _isAmountVisible.toString(),
      },
    );
  }

  @override
  void dispose() {
    _realtimeController.disconnectClient('investments');
    _stopFipStatusPolling();
    _refreshWorker?.dispose();
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> fetchPortfolio({bool forceAaRefresh = false}) async {
    if (mounted) {
      setState(() {
        isPortfolioLoading = true;
        isHoldingLoading = true;
        _mfCentralSwiperAccountsFuture = _getMFCentralSwiperAccounts();
      });
    }

    _refreshController.reset();
    _refreshController.repeat();

    // 1. Fetch Portfolio + Holdings + V2 MF Central in parallel
    await Future.wait([
      investmentController.getPortfolio(
        onLoading: (isLoading) {
          if (mounted) setState(() => isPortfolioLoading = isLoading);
        },
      ),
      investmentController.getHoldings(
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              isHoldingLoading = isLoading;
              if (!isLoading) isPortfolioLoading = false;
            });
          }
        },
      ),
      // V2: MF Central holdings — runs alongside V1, no UI blocker
      investmentController.fetchMFCentralHoldings(),
    ]);

    // Force rebuild so mfCentralHoldings is reflected in _effectiveMf
    if (mounted) setState(() {});

    // 3. Refresh Swiper card data (FIP status and fetch options)
    final provider = getAccountAggregatorDataProvider();
    unawaited(
      provider.refreshDashboardData(fetchResults: false).then((response) {
        if (response != null && mounted) {
          setState(() {
            _fipStatusController.statusResponse.value = response;
          });
        }
      }),
    );

    if (Get.isRegistered<AaDataFetchController>()) {
      unawaited(AaDataFetchController.to.fetchDataFetchOptions(silent: true));
    }

    if (mounted) {
      setState(() {
        isPortfolioLoading = false;
        isHoldingLoading = false;
      });
      _refreshController.stop();
    }
  }

  void _startFipStatusPolling() async {
    if (widget.forceStandardApis) return;
    final isFinarkein = userController.userData?.isFinarkeinAa == true;

    // Fetch initial status
    await _fetchAccountListFromProvider();

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
    final accounts = _fipStatusController.accounts;
    if (accounts.isEmpty) return false;

    final isFinarkein = userController.userData?.isFinarkeinAa == true;

    if (isFinarkein) {
      // For Finarkein: Continue polling if any account is PROCESSING or PENDING
      // Stop when all are SUCCESS or FAILED
      return accounts.any((account) {
        final status = (account['fetchstatus'] as String?)?.toUpperCase() ?? '';
        return status == 'PROCESSING' || status == 'PENDING';
      });
    } else {
      // For non-Finarkein: Continue if any account is FETCHING
      return accounts.any((account) => account['fetchstatus'] == 'FETCHING');
    }
  }

  Future<void> _fetchAccountListFromProvider() async {
    try {
      // Use FipStatusController for all users
      await _fipStatusController.fetchFipStatus();

      if (_shouldStartFipPolling() && _fipPollingTimer == null) {
        _startFipPolling();
      } else if (!_shouldStartFipPolling() && _fipPollingTimer != null) {
        _stopFipStatusPolling();
      }
    } catch (e) {
      dev.log('Error fetching account list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppbar(),
      body: GetBuilder<InvestmentController>(
        builder: (investmentController) {
          return Obx(() {
            // Access observables to establish dependency for live updates
            _realtimeController.connectionState.value;
            _realtimeController.totals.value;
            _realtimeController.holdingsMap.length;

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.investmentsPullToRefresh,
                    parameters: {
                      AnalyticsParams.screenName: 'investments_main',
                      AnalyticsParams.categoryName:
                          _selectedCategory.toLowerCase(),
                    },
                  );
                  await fetchPortfolio(forceAaRefresh: true);
                },
                color: AppColors.darkPrimary,
                backgroundColor: AppColors.darkCardBG,
                displacement: 20.0,
                strokeWidth: 3.0,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child:
                      _shouldShowUnlockCard()
                          ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: UnlockDashboardCard(
                              onTap: () => _onTapLinkAllAssets(context),
                            ),
                          )
                          : Column(
                            children: [
                              _buildHeader(investmentController.portfolio, () {
                                fetchPortfolio(forceAaRefresh: true);
                              }),
                              if (!(GetStorage().read(
                                    StorageKeys.FAMILY_MODE_KEY,
                                  ) ??
                                  false))
                                Container(
                                  color: AppColors.darkBackground,
                                  child: FutureBuilder<
                                    List<Map<String, dynamic>>
                                  >(
                                    future: _mfCentralSwiperAccountsFuture,
                                    builder: (context, mfSnapshot) {
                                      final mfAccounts = mfSnapshot.data ?? [];
                                      return Obx(() {
                                        final aaAccounts =
                                            _getMergedAccountStatuses();
                                        // Filter out AA MF accounts - we only use MF Central for MF data
                                        final filteredAaAccounts =
                                            aaAccounts.where((a) {
                                              final type =
                                                  (a['type'] as String? ?? '')
                                                      .toUpperCase();
                                              return type != 'MUTUAL_FUNDS' &&
                                                  type != 'MUTUAL_FUND';
                                            }).toList();
                                        // Combine filtered AA accounts with MF Central grouped accounts
                                        final mergedAccounts = [
                                          ...filteredAaAccounts,
                                          ...mfAccounts,
                                        ];
                                        return StatusCardSwiper(
                                          lastFetchedTime:
                                              _getFormattedLastFetchedTime(
                                                mergedAccounts,
                                              ),
                                          category:
                                              _selectedCategory == 'All'
                                                  ? 'Investments'
                                                  : _selectedCategory,
                                          accounts: mergedAccounts,
                                          onCardTap: _onSwiperCardTap,
                                        );
                                      });
                                    },
                                  ),
                                ),

                              // Category filter chips
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    // spacing: 12,
                                    children: [
                                      const SizedBox(
                                        width:
                                            AppSizing.scaffoldHorizontalPadding,
                                      ),
                                      ...categories.map(
                                        (category) =>
                                            _buildCategoryChip(category),
                                      ),
                                      const SizedBox(
                                        width:
                                            AppSizing.scaffoldHorizontalPadding,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      AppSizing.scaffoldHorizontalPadding,
                                ),
                                child: AppInputField(
                                  controller: _searchController,
                                  prefix: Icon(
                                    CupertinoIcons.search,
                                    color: AppColors.darkTextMuted,
                                  ),
                                  hintText: "Search...",
                                  onTap: () {
                                    AnalyticsService.to.logEvent(
                                      name:
                                          AnalyticsEvents
                                              .investmentsSearchInitiated,
                                      parameters: {
                                        AnalyticsParams.screenName:
                                            'investments_main',
                                        AnalyticsParams.categoryName:
                                            _selectedCategory.toLowerCase(),
                                      },
                                    );
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery.value = value.toLowerCase();
                                    });
                                    if (value.length > 2) {
                                      AnalyticsService.to.logEvent(
                                        name:
                                            AnalyticsEvents
                                                .investmentsSearchQueryEntered,
                                        parameters: {
                                          AnalyticsParams.screenName:
                                              'investments_main',
                                          AnalyticsParams.categoryName:
                                              _selectedCategory.toLowerCase(),
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                              if (_selectedCategory != 'Mutual Funds') ...[
                                SizedBox(height: 8.h),

                                // Nominee Registered Details Section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        AppSizing.scaffoldHorizontalPadding,
                                  ),
                                  child: CustomAccordion(
                                    title: "Nominee Registered Details",
                                    backgroundColor: AppColors.darkCardBG,
                                    borderRadius: 15,
                                    child: Column(
                                      spacing: 12,
                                      children: [
                                        if (investmentController
                                                    .holdings
                                                    ?.data
                                                    ?.investments
                                                    .profiles !=
                                                null &&
                                            investmentController
                                                .holdings!
                                                .data!
                                                .investments
                                                .profiles
                                                .isNotEmpty)
                                          ...investmentController.holdings!.data!.investments.profiles.map((
                                            profile,
                                          ) {
                                            final isNomineeRegistered =
                                                profile.nominee == "REGISTERED";

                                            // Get icon based on profile type
                                            IconData getProfileIcon() {
                                              switch (profile.type
                                                  .toUpperCase()) {
                                                case 'EQUITIES':
                                                  return Icons.trending_up;
                                                case 'MUTUAL_FUNDS':
                                                  return Icons
                                                      .account_balance_wallet;
                                                case 'ETF':
                                                  return Icons.bar_chart;
                                                default:
                                                  return Icons.account_balance;
                                              }
                                            }

                                            return Container(
                                              padding: EdgeInsets.all(16.w),
                                              decoration: BoxDecoration(
                                                color: AppColors.darkBackground,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      AppColors
                                                          .darkButtonBorder,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Investment Type Icon (decorative)
                                                  ExcludeSemantics(
                                                    child: Container(
                                                      width: 40.w,
                                                      height: 40.w,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.info,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        getProfileIcon(),
                                                        color: Colors.white,
                                                        size: 20.sp,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12.w),

                                                  // Investment Details
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        AppText(
                                                          profile.fipname,
                                                          variant:
                                                              AppTextVariant
                                                                  .bodyMedium,
                                                          weight:
                                                              AppTextWeight
                                                                  .semiBold,
                                                        ),
                                                        SizedBox(height: 0.h),
                                                        AppText(
                                                          profile.type
                                                              .replaceAll(
                                                                '_',
                                                                ' ',
                                                              )
                                                              .split(' ')
                                                              .map(
                                                                (word) =>
                                                                    word.isNotEmpty
                                                                        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                                                        : '',
                                                              )
                                                              .join(' '),
                                                          variant:
                                                              AppTextVariant
                                                                  .bodySmall,
                                                          colorType:
                                                              AppTextColorType
                                                                  .secondary,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      AppText(
                                                        "Nominee: ",
                                                        variant:
                                                            AppTextVariant
                                                                .bodySmall,
                                                        colorType:
                                                            AppTextColorType
                                                                .secondary,
                                                      ),
                                                      AppText(
                                                        isNomineeRegistered
                                                            ? "Yes"
                                                            : "No",
                                                        variant:
                                                            AppTextVariant
                                                                .bodySmall,
                                                        weight:
                                                            AppTextWeight
                                                                .semiBold,
                                                        colorType:
                                                            isNomineeRegistered
                                                                ? AppTextColorType
                                                                    .success
                                                                : AppTextColorType
                                                                    .error,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          })
                                        else
                                          // No profiles found UI
                                          Container(
                                            padding: EdgeInsets.all(16.w),
                                            child: Center(
                                              child: AppText(
                                                "No investment profiles found",
                                                variant:
                                                    AppTextVariant.bodyMedium,
                                                colorType:
                                                    AppTextColorType.secondary,
                                              ),
                                            ),
                                          ),

                                        // Info message
                                        Container(
                                          padding: EdgeInsets.all(12.w),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.darkPrimary
                                                  .withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              ExcludeSemantics(
                                                child: Icon(
                                                  Icons.info_outline,
                                                  color: AppColors.info,
                                                  size: 16.sp,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    AppText(
                                                      "Go ahead and register a nominee if you haven't.",
                                                      variant:
                                                          AppTextVariant
                                                              .bodySmall,
                                                      colorType:
                                                          AppTextColorType
                                                              .primary,
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Semantics(
                                                      label:
                                                          'Speak to our advisor for nominee registration help',
                                                      link: true,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          AnalyticsService.to.logEvent(
                                                            name:
                                                                AnalyticsEvents
                                                                    .investmentsNomineeSpeakToAdvisorClicked,
                                                            parameters: {
                                                              AnalyticsParams
                                                                      .screenName:
                                                                  'investments_main',
                                                              AnalyticsParams
                                                                      .categoryName:
                                                                  _selectedCategory
                                                                      .toLowerCase(),
                                                            },
                                                          );
                                                          SpeakToAdvisor.speakToAdvisor();
                                                        },
                                                        child: ExcludeSemantics(
                                                          child: AppText(
                                                            "Speak to our advisor if you need help",
                                                            variant:
                                                                AppTextVariant
                                                                    .bodySmall,
                                                            colorType:
                                                                AppTextColorType
                                                                    .link,
                                                            weight:
                                                                AppTextWeight
                                                                    .semiBold,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              SizedBox(height: 8.h),

                              // Holdings list - Convert to Column with reactive Obx to support progressive batch loading
                              Builder(
                                builder: (context) {
                                  if (Get.isRegistered<RawAssetController>()) {
                                    return Obx(() {
                                      final raw =
                                          Get.find<RawAssetController>();
                                      // Access observables to register dependency
                                      raw.equities.length;
                                      raw.mutualFunds.length;
                                      raw.etfs.length;

                                      return Column(
                                        children: _buildInvestmentsList(
                                          investmentController,
                                        ),
                                      );
                                    });
                                  }

                                  return Column(
                                    children: _buildInvestmentsList(
                                      investmentController,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                ),
              ),
            );
          });
        },
      ),
      // bottomNavigationBar: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     if ((userController.userData?.istestaccount ?? false) == false)
      //       Container(
      //         padding: EdgeInsets.only(
      //           left: AppSizing.scaffoldHorizontalPadding,
      //           right: AppSizing.scaffoldHorizontalPadding,
      //           bottom: MediaQuery.of(context).padding.bottom + 16,
      //         ),
      //         margin: EdgeInsets.only(bottom: 8),
      //         child: SizedBox(
      //           width: double.infinity,
      //           child: AppButton(
      //             text: "Add Investments",
      //             onPressed: () {
      //               Get.to(() => ConnectionsScreen());
      //             },
      //           ),
      //         ),
      //       ),
      //   ],
      // ),
    );
  }

  // Helper method to build the investments list
  List<Widget> _buildInvestmentsList(
    InvestmentController investmentController,
  ) {
    // Show shimmer placeholders when loading
    if (isPortfolioLoading && investmentController.portfolio == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmerInvestmentCard(),
              ),
            ),
          ),
        ),
      ];
    }

    final investments = _filteredInvestments();

    if (investments.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: _buildNoHoldingsMessage(),
        ),
      ];
    }

    String getBrokerDisplayName(dynamic item) {
      String? brokerName;
      String? brokerId;
      String? fipName;
      String? fipid;

      if (item is Stock) {
        brokerName = item.brokername;
        brokerId = item.broker;
        fipName = item.fipname;
        fipid = item.fipid;
      } else if (item is Etf) {
        brokerName = item.brokername;
        brokerId = item.broker;
        fipName = item.fipname;
        fipid = item.fipid;
      }

      String name =
          (brokerName ?? brokerId ?? fipName ?? fipid ?? 'Other').trim();
      if (name.isEmpty || name.toLowerCase() == 'other') {
        return 'Other Brokers';
      }

      // Capitalize nicely if it's all uppercase except CDSL/NSDL
      final upper = name.toUpperCase();
      if (upper == 'CDSL' || upper == 'NSDL') {
        return upper;
      }

      if (name == upper) {
        return name[0] + name.substring(1).toLowerCase();
      }

      return name;
    }

    Widget buildBrokerGroupHeader(
      String displayName,
      int count,
      double totalValue,
      bool isExpanded,
    ) {
      return Padding(
        padding: const EdgeInsets.only(
          left: AppSizing.scaffoldHorizontalPadding,
          right: AppSizing.scaffoldHorizontalPadding,
          top: 16,
          bottom: 12,
        ),
        child: InkWell(
          onTap: () {
            _expandedBrokers[displayName] = !isExpanded;
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.darkPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppText(
                    displayName,
                    variant: AppTextVariant.bodyLarge,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppText(
                      '$count',
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.secondary,
                    ),
                  ),
                ],
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.darkTextMuted,
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> widgets = [];

    if (_selectedCategory == 'Equity' || _selectedCategory == 'ETF') {
      // 1. Group the investments by broker
      final Map<String, List<dynamic>> groupedInvestments = {};
      for (final investment in investments) {
        final displayName = getBrokerDisplayName(investment);
        if (!groupedInvestments.containsKey(displayName)) {
          groupedInvestments[displayName] = [];
        }
        groupedInvestments[displayName]!.add(investment);
      }

      // 2. Sum current value per group for sorting and display
      final Map<String, double> groupTotalValues = {};
      groupedInvestments.forEach((broker, items) {
        double sum = 0.0;
        for (final item in items) {
          if (item is Stock) {
            sum += item.currentMarketValue;
          } else if (item is Etf) {
            sum += item.currentMarketValue;
          }
        }
        groupTotalValues[broker] = sum;
      });

      // 3. Sort the group names by their total value desc
      final sortedBrokers =
          groupedInvestments.keys.toList()..sort(
            (a, b) => (groupTotalValues[b] ?? 0.0).compareTo(
              groupTotalValues[a] ?? 0.0,
            ),
          );

      // 4. Build headers and items for each broker group
      for (final broker in sortedBrokers) {
        final items = groupedInvestments[broker]!;
        final totalVal = groupTotalValues[broker] ?? 0.0;

        _expandedBrokers.putIfAbsent(broker, () => true);

        widgets.add(
          Obx(() {
            final isExpanded = _expandedBrokers[broker] ?? true;
            return buildBrokerGroupHeader(
              broker,
              items.length,
              totalVal,
              isExpanded,
            );
          }),
        );

        widgets.add(
          Obx(() {
            final isExpanded = _expandedBrokers[broker] ?? true;
            if (!isExpanded) {
              return const SizedBox.shrink();
            }
            return Column(
              children:
                  items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.scaffoldHorizontalPadding,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildInvestmentCard(item),
                      ),
                    );
                  }).toList(),
            );
          }),
        );
      }

      return widgets;
    }

    for (int index = 0; index < investments.length; index++) {
      final investment = investments[index];

      // Show the switch to direct banner before the first item
      if (index == 0 && _selectedCategory == 'Mutual Funds') {
        //   widgets.add(
        //     Padding(
        //       padding: const EdgeInsets.symmetric(
        //         horizontal: AppSizing.scaffoldHorizontalPadding,
        //       ),
        //       child: InkWell(
        //         onTap:
        //             () => Get.to(
        //               () => MutualFundSwitchScreen(),
        //               transition: Transition.rightToLeft,
        //             ),
        //         child: Container(
        //           decoration: BoxDecoration(
        //             borderRadius: BorderRadius.circular(12),
        //             border: Border.all(color: AppColors.darkButtonBorder),
        //             color: AppColors.darkCardBG,
        //           ),
        //           width: double.infinity,
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 12,
        //           ),
        //           child: Row(
        //             children: [
        //               SvgPicture.asset(
        //                 "assets/svgs/assets/investments/save.svg",
        //                 width: 50,
        //                 height: 50,
        //               ),
        //               const SizedBox(width: 20),
        //               Expanded(
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: [
        //                     const SizedBox(height: 8),
        //                     AppText(
        //                       'Switch to save up to 1.4%',
        //                       variant: AppTextVariant.bodyLarge,
        //                       weight: AppTextWeight.semiBold,
        //                       colorType: AppTextColorType.success,
        //                     ),
        //                     const SizedBox(height: 8),
        //                     AppText(
        //                       "Say goodbye to high commissions. Easily switch plans in less than 5 minute for free.",
        //                       variant: AppTextVariant.bodySmall,
        //                       colorType: AppTextColorType.primary,
        //                     ),
        //                     GestureDetector(
        //                       onTap: _showSwitchToDirectBottomSheet,
        //                       child: AppText(
        //                         'Know More',
        //                         variant: AppTextVariant.bodySmall,
        //                         weight: AppTextWeight.bold,
        //                         colorType: AppTextColorType.link,
        //                         decoration: TextDecoration.underline,
        //                         decorationColor: AppColors.linkColor,
        //                       ),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        //   );
        //   widgets.add(const SizedBox(height: 12));
        // }

        // Add price update notification widget
        // widgets.add(
        //   Builder(
        //     builder: (context) {
        //       // Log NAV date info shown event
        //       WidgetsBinding.instance.addPostFrameCallback((_) {
        //         AnalyticsService.to.logEvent(
        //           name: AnalyticsEvents.investmentsMfNavDateInfoShown,
        //           parameters: {
        //             AnalyticsParams.screenName: 'investments_main',
        //             AnalyticsParams.categoryName: 'mutual_funds',
        //             AnalyticsParams.mfNavDate: _getNavDateText(investments),
        //           },
        //         );
        //       });
        //       return Padding(
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: AppSizing.scaffoldHorizontalPadding,
        //         ),
        //         child: Container(
        //           decoration: BoxDecoration(
        //             borderRadius: BorderRadius.circular(12),
        //             border: Border.all(color: AppColors.darkButtonBorder),
        //             color: AppColors.darkCardBG,
        //           ),
        //           width: double.infinity,
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 12,
        //           ),
        //           child: Row(
        //             children: [
        //               Icon(
        //                 Icons.schedule,
        //                 color: AppColors.darkPrimary,
        //                 size: 24,
        //               ),
        //               const SizedBox(width: 12),
        //               Expanded(
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: [
        //                     AppText(
        //                       _getNavDateText(investments),
        //                       variant: AppTextVariant.bodyMedium,
        //                       weight: AppTextWeight.semiBold,
        //                       colorType: AppTextColorType.primary,
        //                     ),
        //                     const SizedBox(height: 4),
        //                     AppText(
        //                       "Mutual fund NAVs are updated daily after market close",
        //                       variant: AppTextVariant.bodySmall,
        //                       colorType: AppTextColorType.secondary,
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // );
        // widgets.add(const SizedBox(height: 12));

        // Check for service outage
        // final isMfcWorking = RemoteConfigService.to.isMfcWorking.value;

        // if (!isMfcWorking) {
        //   widgets.add(
        //     Builder(
        //       builder: (context) {
        //         // Log service outage shown event
        //         WidgetsBinding.instance.addPostFrameCallback((_) {
        //           AnalyticsService.to.logEvent(
        //             name: AnalyticsEvents.investmentsMfServiceOutageShown,
        //             parameters: {
        //               AnalyticsParams.screenName: 'investments_main',
        //               AnalyticsParams.categoryName: 'mutual_funds',
        //               AnalyticsParams.mfcServiceStatus: 'unavailable',
        //             },
        //           );
        //         });
        //         return Padding(
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: AppSizing.scaffoldHorizontalPadding,
        //           ),
        //           child: const ServiceOutageCard(),
        //         );
        //       },
        //     ),
        //   );
        // } else {
        //   widgets.add(
        //     Padding(
        //       padding: const EdgeInsets.symmetric(
        //         horizontal: AppSizing.scaffoldHorizontalPadding,
        //       ),
        //       child: InkWell(
        //         onTap: () {
        //           AnalyticsService.to.logEvent(
        //             name:
        //                 AnalyticsEvents.investmentsMfUpdateHoldingsCardClicked,
        //             parameters: {
        //               AnalyticsParams.screenName: 'investments_main',
        //               AnalyticsParams.categoryName: 'mutual_funds',
        //               AnalyticsParams.mfcServiceStatus: 'available',
        //             },
        //           );
        //           MFOnboardingService.clearRetryInfo();
        //           Get.to(
        //             () => MutualFundHoldingsJourneyScreen(
        //               isInitialJourney: false,
        //             ),
        //             transition: Transition.rightToLeft,
        //           );
        //         },
        //         child: Container(
        //           decoration: BoxDecoration(
        //             borderRadius: BorderRadius.circular(12),
        //             border: Border.all(color: AppColors.darkButtonBorder),
        //             color: AppColors.darkCardBG,
        //           ),
        //           width: double.infinity,
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 12,
        //           ),
        //           child: Row(
        //             children: [
        //               Image.asset(
        //                 "assets/svgs/assets/investments/mfc.png",
        //                 width: 50,
        //                 height: 50,
        //               ),
        //               const SizedBox(width: 20),
        //               Expanded(
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: [
        //                     const SizedBox(height: 8),
        //                     AppText(
        //                       'Update Your MF Holdings',
        //                       variant: AppTextVariant.bodyLarge,
        //                       weight: AppTextWeight.semiBold,
        //                       colorType: AppTextColorType.success,
        //                     ),
        //                     const SizedBox(height: 6),
        //                     AppText(
        //                       "Keep your mutual fund information current for accurate tracking.",
        //                       variant: AppTextVariant.bodySmall,
        //                       colorType: AppTextColorType.primary,
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        //   );
        // }

        // widgets.add(const SizedBox(height: 12));
      }

      if (index == 0 && _selectedCategory == 'Equity') {
        // widgets.add(
        //   Padding(
        //     padding: const EdgeInsets.symmetric(
        //       horizontal: AppSizing.scaffoldHorizontalPadding,
        //     ),
        //     child: InkWell(
        //       onTap:
        //           () => Get.to(
        //             () => PaperTradingPortfolio(),
        //             transition: Transition.rightToLeft,
        //           ),
        //       child: Container(
        //         decoration: BoxDecoration(
        //           borderRadius: BorderRadius.circular(12),
        //           border: Border.all(color: AppColors.darkButtonBorder),
        //           color: AppColors.darkCardBG,
        //         ),
        //         width: double.infinity,
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 16,
        //           vertical: 12,
        //         ),
        //         child: Row(
        //           children: [
        //             SvgPicture.asset(
        //               "assets/svgs/advisory/ai.svg",
        //               width: 40,
        //               height: 40,
        //             ),
        //             const SizedBox(width: 12),
        //             Expanded(
        //               child: Column(
        //                 crossAxisAlignment: CrossAxisAlignment.start,
        //                 children: [
        //                   AppText(
        //                     'Paper Trading Portfolio',
        //                     variant: AppTextVariant.bodyLarge,
        //                     weight: AppTextWeight.semiBold,
        //                     colorType: AppTextColorType.success,
        //                   ),
        //                   const SizedBox(height: 4),
        //                   AppText(
        //                     "Track your virtual investment performance",
        //                     variant: AppTextVariant.bodySmall,
        //                     colorType: AppTextColorType.primary,
        //                   ),
        //                 ],
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // );
        // widgets.add(const SizedBox(height: 12));

        // Add price update notification widget for stocks
        // widgets.add(
        //   Builder(
        //     builder: (context) {
        //       // Log equity price update info shown event
        //       WidgetsBinding.instance.addPostFrameCallback((_) {
        //         AnalyticsService.to.logEvent(
        //           name: AnalyticsEvents.investmentsEquityPriceUpdateInfoShown,
        //           parameters: {
        //             AnalyticsParams.screenName: 'investments_main',
        //             AnalyticsParams.categoryName: 'equity',
        //             AnalyticsParams.stockPriceUpdateTime: _getStockDateText(),
        //           },
        //         );
        //       });
        //       return Padding(
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: AppSizing.scaffoldHorizontalPadding,
        //         ),
        //         child: Container(
        //           decoration: BoxDecoration(
        //             borderRadius: BorderRadius.circular(12),
        //             border: Border.all(color: AppColors.darkButtonBorder),
        //             color: AppColors.darkCardBG,
        //           ),
        //           width: double.infinity,
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 12,
        //           ),
        //           child: Row(
        //             children: [
        //               Icon(
        //                 Icons.update,
        //                 color: AppColors.darkPrimary,
        //                 size: 24,
        //               ),
        //               const SizedBox(width: 12),
        //               Expanded(
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: [
        //                     AppText(
        //                       _getStockDateText(),
        //                       variant: AppTextVariant.bodyMedium,
        //                       weight: AppTextWeight.semiBold,
        //                       colorType: AppTextColorType.primary,
        //                     ),
        //                     const SizedBox(height: 4),
        //                     AppText(
        //                       _isIsinDateLoading
        //                           ? "Loading latest update time..."
        //                           : "Stock prices are updated every 10 mins during market hours",
        //                       variant: AppTextVariant.bodySmall,
        //                       colorType: AppTextColorType.secondary,
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // );
        // widgets.add(const SizedBox(height: 12));
      }

      // if (index == 0 && _selectedCategory == 'ETF') {
      //   // Add price update notification widget for ETF
      //   widgets.add(
      //     Builder(
      //       builder: (context) {
      //         // Log ETF price update info shown event
      //         WidgetsBinding.instance.addPostFrameCallback((_) {
      //           AnalyticsService.to.logEvent(
      //             name: AnalyticsEvents.investmentsEtfPriceUpdateInfoShown,
      //             parameters: {
      //               AnalyticsParams.screenName: 'investments_main',
      //               AnalyticsParams.categoryName: 'etf',
      //               AnalyticsParams.etfPriceUpdateTime: _getStockDateText(),
      //             },
      //           );
      //         });
      //         return Padding(
      //           padding: const EdgeInsets.symmetric(
      //             horizontal: AppSizing.scaffoldHorizontalPadding,
      //           ),
      //           child: Container(
      //             decoration: BoxDecoration(
      //               borderRadius: BorderRadius.circular(12),
      //               border: Border.all(color: AppColors.darkButtonBorder),
      //               color: AppColors.darkCardBG,
      //             ),
      //             width: double.infinity,
      //             padding: const EdgeInsets.symmetric(
      //               horizontal: 16,
      //               vertical: 12,
      //             ),
      //             child: Row(
      //               children: [
      //                 Icon(
      //                   Icons.update,
      //                   color: AppColors.darkPrimary,
      //                   size: 24,
      //                 ),
      //                 const SizedBox(width: 12),
      //                 Expanded(
      //                   child: Column(
      //                     crossAxisAlignment: CrossAxisAlignment.start,
      //                     children: [
      //                       AppText(
      //                         _getStockDateText(),
      //                         variant: AppTextVariant.bodyMedium,
      //                         weight: AppTextWeight.semiBold,
      //                         colorType: AppTextColorType.primary,
      //                       ),
      //                       const SizedBox(height: 4),
      //                       AppText(
      //                         _isIsinDateLoading
      //                             ? "Loading latest update time..."
      //                             : "ETF prices are updated every 10 mins during market hours",
      //                         variant: AppTextVariant.bodySmall,
      //                         colorType: AppTextColorType.secondary,
      //                       ),
      //                     ],
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         );
      //       },
      //     ),
      //   );
      //   widgets.add(const SizedBox(height: 12));
      // }

      // if (index == 0 && _selectedCategory == 'All') {
      //   widgets.add(
      //     Padding(
      //       padding: const EdgeInsets.symmetric(
      //         horizontal: AppSizing.scaffoldHorizontalPadding,
      //       ),
      //       child: InkWell(
      //         onTap:
      //             () => Get.to(
      //               () => TaxAdvisoryScreen(),
      //               transition: Transition.rightToLeft,
      //             ),
      //         child: Container(
      //           decoration: BoxDecoration(
      //             borderRadius: BorderRadius.circular(12),
      //             border: Border.all(color: AppColors.darkButtonBorder),
      //             color: AppColors.darkCardBG,
      //           ),
      //           width: double.infinity,
      //           padding: const EdgeInsets.symmetric(
      //             horizontal: 16,
      //             vertical: 12,
      //           ),
      //           child: Row(
      //             children: [
      //               SvgPicture.asset(
      //                 "assets/svgs/advisory/tax.svg",
      //                 width: 40,
      //                 height: 40,
      //               ),
      //               const SizedBox(width: 12),
      //               Expanded(
      //                 child: Column(
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: [
      //                     AppText(
      //                       'Tax Advisory',
      //                       variant: AppTextVariant.bodyLarge,
      //                       weight: AppTextWeight.semiBold,
      //                       colorType: AppTextColorType.success,
      //                     ),
      //                     const SizedBox(height: 4),
      //                     AppText(
      //                       "Review tax advice for your portfolio.",
      //                       variant: AppTextVariant.bodySmall,
      //                       colorType: AppTextColorType.primary,
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
      //     ),
      //   );
      //   widgets.add(const SizedBox(height: 12));
      // }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInvestmentCard(investment),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Stock> get _effectiveStocks {
    // 1. Prioritize standard holdings API (aa/dashboard/portfolio/all)
    List<Stock> stocks = [];
    final standardStocks =
        investmentController.holdings?.data?.investments.stocks;
    if (standardStocks != null && standardStocks.isNotEmpty) {
      stocks = standardStocks;
    } else {
      final isFinarkein = userController.userData?.isFinarkeinAa == true;

      // For Finarkein users, use RawAssetController to get all equities from API
      if (isFinarkein && Get.isRegistered<RawAssetController>()) {
        final rawController = Get.find<RawAssetController>();
        if (rawController.equities.isNotEmpty) {
          // Convert raw Map data to Stock models
          stocks =
              rawController.equities.map((rawStock) {
                return Stock.fromJson(rawStock);
              }).toList();
        }
      }

      if (stocks.isEmpty) {
        // Fallback to provider
        final list = getAccountAggregatorDataProvider().getStocks();
        if (list != null && list.isNotEmpty) stocks = list;
      }
    }

    if (stocks.isEmpty) return [];

    // Deduplicate and merge by ISIN + Broker without mutating original objects
    final Map<String, Stock> merged = {};
    for (final s in stocks) {
      final brokerKey = s.broker ?? '';
      final key = '${s.isin ?? s.name}|$brokerKey';
      final existing = merged[key];
      if (existing != null) {
        final newQuantity = existing.quantity + s.quantity;
        final newCurrentValue =
            existing.currentMarketValue + s.currentMarketValue;
        final newCostValue = (existing.costValue ?? 0) + (s.costValue ?? 0);
        final newGainLoss = (existing.gainLoss ?? 0) + (s.gainLoss ?? 0);

        merged[key] = existing.copyWith(
          quantity: newQuantity,
          currentMarketValue: newCurrentValue,
          costValue: newCostValue,
          gainLoss: newGainLoss,
          gainLossPercentage:
              newCostValue > 0 ? (newGainLoss / newCostValue) * 100 : 0,
          rate: existing.rate,
        );
      } else {
        merged[key] = s;
      }
    }

    // Apply live prices from WebSocket if available
    final liveHoldings = _realtimeController.holdingsMap;
    if (liveHoldings.isNotEmpty) {
      for (final entry in merged.entries) {
        final stock = entry.value;
        final isin = stock.isin;
        if (isin != null && liveHoldings.containsKey(isin)) {
          final liveHolding = liveHoldings[isin]!;
          final cost = stock.costValue ?? 0.0;
          final newMarketValue = liveHolding.marketValue;

          double newGainLoss = newMarketValue - cost;
          double newGainPct = cost > 0 ? (newGainLoss / cost) * 100 : 0.0;

          if (liveHolding.totalGain != null && liveHolding.totalGain != 0.0) {
            newGainLoss = liveHolding.totalGain!;
          }
          if (liveHolding.totalGainPct != null &&
              liveHolding.totalGainPct != 0.0) {
            newGainPct = liveHolding.totalGainPct!;
          }

          double? newAvgBuyPrice = stock.averageholdingprice;
          if (newAvgBuyPrice == null || newAvgBuyPrice == 0.0) {
            if (liveHolding.avgBuyPrice != null &&
                liveHolding.avgBuyPrice != 0.0) {
              newAvgBuyPrice = liveHolding.avgBuyPrice;
            }
          }

          double? newCostValue = stock.costValue;
          if (newCostValue == null || newCostValue == 0.0) {
            if (liveHolding.totalInvested != null &&
                liveHolding.totalInvested != 0.0) {
              newCostValue = liveHolding.totalInvested;
            }
          }

          double? newXirr = stock.xirr;
          if (newXirr == null || newXirr == 0.0) {
            if (liveHolding.cagrPct != null && liveHolding.cagrPct != 0.0) {
              newXirr = liveHolding.cagrPct;
            }
          }

          merged[entry.key] = stock.copyWith(
            rate: liveHolding.lastPrice,
            currentMarketValue: newMarketValue,
            gainLoss: newGainLoss,
            gainLossPercentage: newGainPct,
            deltaValue: liveHolding.dayGain,
            deltapercentage: liveHolding.dayGainPct,
            averageholdingprice: newAvgBuyPrice,
            costValue: newCostValue,
            xirr: newXirr,
          );
        }
      }
    }

    return merged.values.toList();
  }

  // Calculate Equity portfolio values from holdings data
  Map<String, double> _calculateEquityPortfolioFromHoldings() {
    final equityHoldings = _effectiveStocks;
    double total = 0.0;
    double invested = 0.0;
    double gain = 0.0;

    for (final stock in equityHoldings) {
      total += stock.currentMarketValue;
      invested += stock.costValue ?? 0.0;
      gain += stock.gainLoss ?? 0.0;
    }

    return {'total': total, 'invested': invested, 'gain': gain};
  }

  // Calculate ETF portfolio values from holdings data
  Map<String, double> _calculateEtfPortfolioFromHoldings() {
    final etfHoldings = _effectiveEtf;
    double total = 0.0;
    double invested = 0.0;
    double gain = 0.0;

    for (final etf in etfHoldings) {
      total += etf.currentMarketValue;
      invested += etf.investedvalue ?? 0.0;
      gain += etf.gainloss ?? 0.0;
    }

    return {'total': total, 'invested': invested, 'gain': gain};
  }

  // Calculate MF portfolio values from holdings data
  Map<String, double> _calculateMfPortfolioFromHoldings() {
    final mfHoldings = _effectiveMf;
    double total = 0.0;
    double invested = 0.0;
    double gain = 0.0;

    for (final mf in mfHoldings) {
      total += mf.currentmktvalue;
      invested += mf.costvalue;
      gain += mf.gainloss ?? 0.0;
    }

    return {'total': total, 'invested': invested, 'gain': gain};
  }

  List<Mf> get _effectiveMf {
    // Only use MF Central holdings for mutual funds data
    // Do NOT fall back to portfolio API or any other source
    final List<Mf> mfs = List<Mf>.from(investmentController.mfCentralHoldings);

    if (mfs.isEmpty) return [];

    // Deduplicate and merge by ISIN + Folio to keep different folios separate
    final Map<String, Mf> merged = {};
    for (final m in mfs) {
      // Use ISIN + Folio as key to distinguish different folios of the same fund
      final isinKey = m.isin.isEmpty ? m.name : m.isin;
      final folioKey = m.folio;
      final key = '$isinKey|$folioKey';

      final existing = merged[key];
      if (existing != null) {
        final newQuantity = existing.quantity + m.quantity;
        final newAvailableUnits = existing.availableunits + m.availableunits;
        final newCurrentValue = existing.currentmktvalue + m.currentmktvalue;
        final newCostValue = existing.costvalue + m.costvalue;
        final newGainLoss = (existing.gainloss ?? 0) + (m.gainloss ?? 0);

        merged[key] = existing.copyWith(
          quantity: newQuantity,
          availableunits: newAvailableUnits,
          currentmktvalue: newCurrentValue,
          costvalue: newCostValue,
          gainloss: newGainLoss,
          gainlosspercentage:
              newCostValue > 0 ? (newGainLoss / newCostValue) * 100 : 0,
        );
      } else {
        merged[key] = m;
      }
    }
    return merged.values.toList();
  }

  List<Etf> get _effectiveEtf {
    // 1. Prioritize standard holdings API (aa/dashboard/portfolio/all)
    List<Etf> etfs = [];
    final standardEtfs = investmentController.holdings?.data?.investments.etf;
    if (standardEtfs != null && standardEtfs.isNotEmpty) {
      etfs = standardEtfs;
    } else {
      final isFinarkein = userController.userData?.isFinarkeinAa == true;

      // For Finarkein users, use RawAssetController to get all ETFs from API
      if (isFinarkein && Get.isRegistered<RawAssetController>()) {
        final rawController = Get.find<RawAssetController>();

        if (rawController.etfs.isNotEmpty) {
          // Convert raw Map data to Etf models
          etfs =
              rawController.etfs.map((rawEtf) {
                return Etf.fromJson(rawEtf);
              }).toList();
        }
      }

      if (etfs.isEmpty) {
        // Fallback to provider
        final list = getAccountAggregatorDataProvider().getEtf();
        if (list != null && list.isNotEmpty) etfs = list;
      }
    }

    if (etfs.isEmpty) return [];

    // Deduplicate and merge by ISIN + Folio + Broker to keep different folios/brokers separate
    final Map<String, Etf> merged = {};
    for (final e in etfs) {
      // Use ISIN + Folio + Broker as key to distinguish different folios/brokers of the same ETF
      final isinKey = (e.isin?.isEmpty ?? true) ? e.name : e.isin!;
      final folioKey = e.foliono ?? '';
      final brokerKey = e.broker ?? '';
      final key = '$isinKey|$folioKey|$brokerKey';
      final existing = merged[key];
      if (existing != null) {
        final newUnits = existing.units + e.units;
        final newCurrentValue =
            existing.currentMarketValue + e.currentMarketValue;
        final newInvestedValue =
            (existing.investedvalue ?? 0) + (e.investedvalue ?? 0);
        final newGainLoss = (existing.gainloss ?? 0) + (e.gainloss ?? 0);

        merged[key] = existing.copyWith(
          units: newUnits,
          currentMarketValue: newCurrentValue,
          investedvalue: newInvestedValue,
          gainloss: newGainLoss,
          gainlosspercentage:
              newInvestedValue > 0 ? (newGainLoss / newInvestedValue) * 100 : 0,
        );
      } else {
        merged[key] = e;
      }
    }

    // Apply live prices from WebSocket if available
    final liveHoldings = _realtimeController.holdingsMap;
    if (liveHoldings.isNotEmpty) {
      for (final entry in merged.entries) {
        final etf = entry.value;
        final isin = etf.isin;
        if (isin != null && liveHoldings.containsKey(isin)) {
          final liveHolding = liveHoldings[isin]!;
          final cost = etf.investedvalue ?? 0.0;
          final newMarketValue = liveHolding.marketValue;

          double newGainLoss = newMarketValue - cost;
          double newGainPct = cost > 0 ? (newGainLoss / cost) * 100 : 0.0;

          if (liveHolding.totalGain != null && liveHolding.totalGain != 0.0) {
            newGainLoss = liveHolding.totalGain!;
          }
          if (liveHolding.totalGainPct != null &&
              liveHolding.totalGainPct != 0.0) {
            newGainPct = liveHolding.totalGainPct!;
          }

          double? newAvgBuyPrice = etf.averageholdingprice;
          if (newAvgBuyPrice == null || newAvgBuyPrice == 0.0) {
            if (liveHolding.avgBuyPrice != null &&
                liveHolding.avgBuyPrice != 0.0) {
              newAvgBuyPrice = liveHolding.avgBuyPrice;
            }
          }

          double? newInvestedValue = etf.investedvalue;
          if (newInvestedValue == null || newInvestedValue == 0.0) {
            if (liveHolding.totalInvested != null &&
                liveHolding.totalInvested != 0.0) {
              newInvestedValue = liveHolding.totalInvested;
            }
          }

          double? newXirr = etf.xirr;
          if (newXirr == null || newXirr == 0.0) {
            if (liveHolding.cagrPct != null && liveHolding.cagrPct != 0.0) {
              newXirr = liveHolding.cagrPct;
            }
          }

          merged[entry.key] = etf.copyWith(
            nav: liveHolding.lastPrice,
            currentmarketprice: liveHolding.lastPrice,
            currentMarketValue: newMarketValue,
            gainloss: newGainLoss,
            gainlosspercentage: newGainPct,
            deltavalue: liveHolding.dayGain,
            deltapercentage: liveHolding.dayGainPct,
            averageholdingprice: newAvgBuyPrice,
            investedvalue: newInvestedValue,
            xirr: newXirr,
          );
        }
      }
    }

    return merged.values.toList();
  }

  // Returns a list of investments based on the selected category and search query
  List<dynamic> _filteredInvestments() {
    final stocks = _effectiveStocks;
    final mf = _effectiveMf;
    final etf = _effectiveEtf;
    final hasAny = stocks.isNotEmpty || mf.isNotEmpty || etf.isNotEmpty;
    if (!hasAny) return [];

    // Handle different investment types based on selected category
    switch (_selectedCategory) {
      case 'Equity':
        var stocksList = stocks;

        // Apply search filter if query exists
        final query = _searchQuery.value.toLowerCase().trim();
        if (query.isNotEmpty) {
          stocksList =
              stocksList.where((stock) {
                final name = stock.name.toLowerCase();
                final isin = stock.isin?.toLowerCase() ?? '';

                return name.contains(query) || isin.contains(query);
              }).toList();
        }

        // Always sort by value high to low
        stocksList.sort(
          (a, b) => b.currentMarketValue.compareTo(a.currentMarketValue),
        );

        return stocksList;

      case 'ETF':
        var etfsList = etf;

        // Apply search filter if query exists
        final etfQuery = _searchQuery.value.toLowerCase().trim();
        if (etfQuery.isNotEmpty) {
          etfsList =
              etfsList.where((e) {
                final name = e.name.toLowerCase();
                final isin = e.isin?.toLowerCase() ?? '';
                final folioNo = e.foliono?.toLowerCase() ?? '';

                return name.contains(etfQuery) ||
                    isin.contains(etfQuery) ||
                    folioNo.contains(etfQuery);
              }).toList();
        }

        // Always sort by value high to low
        etfsList.sort(
          (a, b) => b.currentMarketValue.compareTo(a.currentMarketValue),
        );

        return etfsList;

      case 'Mutual Funds':
        var mutualFunds =
            mf.where((investment) => investment.type == Type.MF).toList();

        // Apply search filter if query exists
        final query = _searchQuery.value.toLowerCase().trim();
        if (query.isNotEmpty) {
          mutualFunds =
              mutualFunds.where((investment) {
                final name = investment.name.toLowerCase();
                final amc = investment.amc.toLowerCase();
                final assetType =
                    investment.assettype?.toString().toLowerCase() ?? '';

                return name.contains(query) ||
                    amc.contains(query) ||
                    assetType.contains(query);
              }).toList();
        }

        // Always sort by value high to low
        mutualFunds.sort(
          (a, b) => b.currentmktvalue.compareTo(a.currentmktvalue),
        );

        return mutualFunds;

      case 'Commodity':
        var commodities =
            mf
                .where(
                  (investment) =>
                      investment.assettype?.toString().toLowerCase().contains(
                        'commodity',
                      ) ??
                      false,
                )
                .toList();

        // Apply search filter
        final query = _searchQuery.value.toLowerCase().trim();
        if (query.isNotEmpty) {
          commodities =
              commodities.where((investment) {
                final name = investment.name.toLowerCase();
                final amc = investment.amc.toLowerCase();

                return name.contains(query) || amc.contains(query);
              }).toList();
        }

        return commodities;

      case 'F&O':
        var fAndO =
            mf
                .where(
                  (investment) =>
                      investment.assettype?.toString().toLowerCase().contains(
                        'f&o',
                      ) ??
                      false,
                )
                .toList();

        // Apply search filter
        final query = _searchQuery.value.toLowerCase().trim();
        if (query.isNotEmpty) {
          fAndO =
              fAndO.where((investment) {
                final name = investment.name.toLowerCase();
                final amc = investment.amc.toLowerCase();

                return name.contains(query) || amc.contains(query);
              }).toList();
        }

        return fAndO;

      default: // 'All' category
        // Combine all investment types
        var allInvestments = [...stocks, ...mf, ...etf];

        // Apply search filter
        final query = _searchQuery.value.toLowerCase().trim();
        if (query.isNotEmpty) {
          allInvestments =
              allInvestments.where((dynamic investment) {
                // First check the type before accessing properties
                if (investment is Mf) {
                  final name = investment.name.toLowerCase();
                  final amc = investment.amc.toLowerCase();
                  final assetType =
                      investment.assettype?.toString().toLowerCase() ?? '';
                  return name.contains(query) ||
                      amc.contains(query) ||
                      assetType.contains(query);
                } else if (investment is Stock) {
                  final name = investment.name.toLowerCase();
                  final isin = investment.isin?.toLowerCase() ?? '';
                  return name.contains(query) || isin.contains(query);
                } else if (investment is Etf) {
                  final name = investment.name.toLowerCase();
                  final isin = investment.isin?.toLowerCase() ?? '';
                  final folioNo = investment.foliono?.toLowerCase() ?? '';
                  return name.contains(query) ||
                      isin.contains(query) ||
                      folioNo.contains(query);
                }

                return false;
              }).toList();
        }

        // Always sort by value high to low
        allInvestments.sort((a, b) {
          double getVal(dynamic item) {
            if (item is Stock) return item.currentMarketValue;
            if (item is Mf) return item.currentmktvalue;
            if (item is Etf) return item.currentMarketValue;
            return 0.0;
          }

          return getVal(b).compareTo(getVal(a));
        });

        return allInvestments;
    }
  }

  // Build investment card based on investment type (Stock or Mf)
  Widget _buildInvestmentCard(dynamic investment) {
    if (investment is Stock) {
      return StockHoldingCard(
        isAmountVisible: _isAmountVisible,
        fundName: investment.name,
        costValue: investment.costValue,
        currentAmount: investment.currentMarketValue,
        gainloss: investment.gainLoss,
        gainlosspercentage: investment.gainLossPercentage,
        quantity: investment.quantity,
        rate: investment.rate, // Pass the rate (price per share)
        buydate: investment.buydate,
        delta: investment.delta,
        deltaValue: investment.deltaValue,
        icon: investment.icon,
        averageholdingprice: investment.averageholdingprice,
        navdate: investment.navdate,
        xirr: investment.xirr,
        deltapercentage: investment.deltapercentage,
        lasttransactiondate: investment.lasttransactiondate,
        isin: investment.isin, // Pass ISIN for transaction filtering
        count: investment.count,
        logourl: investment.logourl,
        forceStandardApis: widget.forceStandardApis,
      );
    } else if (investment is Etf) {
      return EtfHoldingCard(
        isAmountVisible: _isAmountVisible,
        fundName: investment.name,
        nav: investment.nav,
        units: investment.units,
        currentMarketValue: investment.currentMarketValue,
        folioNo: investment.foliono ?? '',
        deltapercentage: investment.deltapercentage,
        gainlosspercentage: investment.gainlosspercentage,
        deltavalue: investment.deltavalue,
        gainloss: investment.gainloss,
        investedvalue: investment.investedvalue,
        averageholdingprice: investment.averageholdingprice,
        currentmarketprice: investment.currentmarketprice,
        lasttransactiondate: investment.lasttransactiondate,
        xirr: investment.xirr,
        isin: investment.isin, // Pass ISIN for transaction filtering
        count: investment.count,
        logourl: investment.logourl,
        forceStandardApis: widget.forceStandardApis,
      );
    } else if (investment is Mf) {
      return HoldingCard(
        mf: investment,
        isAmountVisible: _isAmountVisible,
        icon: Icons.account_balance_outlined,
        forceStandardApis: widget.forceStandardApis,
      );
    } else {
      // Fallback for any other investment type
      // Create a dummy Mf object with default values
      final dummyMf = Mf(
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
        isin: '',
        name: 'Unknown Investment',
        idcwchangeallowed: false,
        schemeoption: '',
        schemetype: '',
        nav: 0.0,
        closingbalance: 0.0,
        currentmktvalue: 0.0,
        costvalue: 0.0,
        gainloss: 0.0,
        gainlosspercentage: 0.0,
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
      return HoldingCard(
        mf: dummyMf,
        isAmountVisible: _isAmountVisible,
        forceStandardApis: widget.forceStandardApis,
      );
    }
  }

  // ignore: unused_element
  void _showSwitchToDirectBottomSheet() {
    showModalBottomSheet(
      showDragHandle: true,
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkInputBackground,
      builder:
          (context) => Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.95,
                decoration: BoxDecoration(color: AppColors.darkInputBackground),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizing.scaffoldHorizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  'Mutual Fund Switch',
                                  variant: AppTextVariant.headline4,
                                  weight: AppTextWeight.bold,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/app/switch.png",
                                  height: 120,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppText(
                              "What is mutual fund switch?",
                              variant: AppTextVariant.bodyLarge,
                              weight: AppTextWeight.bold,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.darkCardBG,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(16),
                              child: AppText(
                                "Switching from regular to direct mutual funds means moving your investments from regular plans with distributor commissions to those without commission(direct fund plans)",
                                variant: AppTextVariant.bodySmall,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppText(
                              "Why you should switch to Direct plans ?",
                              variant: AppTextVariant.bodyLarge,
                              weight: AppTextWeight.bold,
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                _buildEnhancedBenefitItem(
                                  icon: Icons.trending_down,
                                  iconColor: Colors.blue,
                                  title: "Lower expense ratio",
                                  description:
                                      "0.5% to 1.5% lower costs than regular plans.",
                                ),
                                _buildEnhancedBenefitItem(
                                  icon: Icons.trending_up,
                                  iconColor: Colors.green,
                                  title: "Higher Returns",
                                  description:
                                      "Better long-term returns due to lower costs.",
                                ),
                                _buildEnhancedBenefitItem(
                                  icon: Icons.people,
                                  iconColor: Colors.purple,
                                  title: "Same fund manager",
                                  description:
                                      "Same fund & strategy, only cost differs.",
                                ),
                                _buildEnhancedBenefitItem(
                                  icon: Icons.visibility,
                                  iconColor: Colors.amber,
                                  title: "Full Transparency",
                                  description: "No hidden fees or commissions.",
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppText(
                              "How mutual fund switch works?",
                              variant: AppTextVariant.bodyLarge,
                              weight: AppTextWeight.bold,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.darkCardBG,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    "Switch plans in just 3 steps!",
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.bold,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildImprovedStepItem(
                                    number: "1",
                                    icon: Icons.description_outlined,
                                    text:
                                        "Review the direct plan summary showing all calculations and benefits.",
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 24),
                                    height: 24,
                                    width: 1,
                                    color: AppColors.darkPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  _buildImprovedStepItem(
                                    number: "2",
                                    icon: Icons.list_alt_outlined,
                                    text:
                                        "We'll list your regular funds that can switch to direct.",
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 24),
                                    height: 24,
                                    width: 1,
                                    color: AppColors.darkPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  _buildImprovedStepItem(
                                    number: "3",
                                    icon: Icons.touch_app_outlined,
                                    text:
                                        "Click 'Continue' to proceed with the switch.",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText(
                                      "Capital gains tax implications & exit load may apply if you've held the funds for less than the required period.",
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEnhancedBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.8),
                  iconColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.semiBold,
                  // Removed maxLines constraint to prevent clipping
                ),
                const SizedBox(height: 4),
                AppText(
                  description,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                  // Removed maxLines and overflow constraints to show full text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New improved step item that matches the design in the screenshot
  Widget _buildImprovedStepItem({
    required String number,
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AppText(
                text,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                lineHeight: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build shimmer placeholders for investment cards
  Widget _buildShimmerInvestmentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCardBG,
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.darkButtonBorder,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedAmount(
                  isLoading: true,
                  isAmountVisible: true,
                  amount: "••••••••••••••",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedAmount(
                      isLoading: true,
                      isAmountVisible: true,
                      amount: "••••••••",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    AnimatedAmount(
                      isLoading: true,
                      isAmountVisible: true,
                      amount: "••••••",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

    // Log no holdings shown event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.investmentsNoHoldingsShown,
        parameters: {
          AnalyticsParams.screenName: 'investments_main',
          AnalyticsParams.categoryName: _selectedCategory.toLowerCase(),
        },
      );
    });

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
            final previousCategory = _selectedCategory;
            setState(() {
              _selectedCategory = label;
            });

            // Log category selection event
            String eventName;
            switch (label) {
              case 'All':
                eventName = AnalyticsEvents.investmentsCategoryAllSelected;
                break;
              case 'Equity':
                eventName = AnalyticsEvents.investmentsCategoryEquitySelected;
                break;
              case 'Mutual Funds':
                eventName =
                    AnalyticsEvents.investmentsCategoryMutualFundsSelected;
                break;
              case 'ETF':
                eventName = AnalyticsEvents.investmentsCategoryEtfSelected;
                break;
              default:
                eventName = AnalyticsEvents.investmentsCategoryAllSelected;
            }

            final filteredInvestments = _filteredInvestments();
            AnalyticsService.to.logEvent(
              name: eventName,
              parameters: {
                AnalyticsParams.screenName: 'investments_main',
                AnalyticsParams.categoryName: label.toLowerCase(),
                AnalyticsParams.previousCategory:
                    previousCategory.toLowerCase(),
                AnalyticsParams.holdingsCount: filteredInvestments.length,
              },
            );
          },
        ),
        SizedBox(width: 12),
      ],
    );
  }

  String _getNavDateText(List<dynamic> investments) {
    if (investments.isNotEmpty && investments[0].navdate != null) {
      final navDate = investments[0].navdate as DateTime;
      final formattedDate = '${navDate.day}-${navDate.month}-${navDate.year}';
      return 'Prices Updated on $formattedDate';
    }
    return 'Prices Updated Yesterday';
  }

  String _getStockDateText() {
    if (_latestIsinUpdatedDate != null) {
      final date = _latestIsinUpdatedDate!;

      // Format day with suffix (1st, 2nd, 3rd, 4th, etc.)
      String getDaySuffix(int day) {
        if (day >= 11 && day <= 13) return 'th';
        switch (day % 10) {
          case 1:
            return 'st';
          case 2:
            return 'nd';
          case 3:
            return 'rd';
          default:
            return 'th';
        }
      }

      // Month names
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      // Format time (12-hour format with am/pm)
      final hour =
          date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = date.hour < 12 ? 'am' : 'pm';

      final formattedDate =
          '${date.day}${getDaySuffix(date.day)} ${months[date.month - 1]} ${date.year}: $hour:$minute$amPm';
      return 'Prices Updated on $formattedDate';
    }
    return 'Prices Updated Every 10 Minutes';
  }
}
