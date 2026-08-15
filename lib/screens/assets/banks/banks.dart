import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/assets/banks.dart';
import 'package:nwt_app/controllers/account_aggregators/fip_status_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/aa_data_fetch_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/finarkein_data_controller.dart';
import 'package:nwt_app/controllers/account_aggregators/raw_asset_controller.dart';
import 'package:nwt_app/screens/assets/banks/deposits/list.dart';
import 'package:nwt_app/screens/assets/banks/types/banks.dart';
import 'package:nwt_app/screens/assets/banks/widgets/bank_card.dart';
import 'package:nwt_app/screens/connections/connections.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/data_fetch_details_screen.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_status_service.dart';
import 'package:nwt_app/screens/transactions/banks/list.dart' hide Bank;
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/empty_state.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/widgets/common/loading_widget.dart';
import 'package:nwt_app/widgets/status_card_swiper.dart';

class AssetBankScreen extends StatefulWidget {
  final bool forceStandardApis;
  const AssetBankScreen({super.key, this.forceStandardApis = true});

  @override
  State<AssetBankScreen> createState() => _AssetBankScreenState();
}

class _AssetBankScreenState extends State<AssetBankScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _refreshController;
  final bankController = Get.put(BankController());
  final _fipStatusController = Get.find<FipStatusController>();
  final userController = Get.find<UserController>();
  late RawAssetController rawAssetController;
  bool isBankSummaryLoading = false;
  bool _isAmountVisible = true;
  String _searchQuery = '';

  // FIP Status polling variables
  Timer? _fipPollingTimer;
  final Duration _fipPollingInterval = const Duration(seconds: 3);
  List<Map<String, dynamic>> _fipAccounts = [];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Restore amount visibility state from storage
    _restoreAmountVisibilityState();

    // Initialize RawAssetController for Finarkein users
    final isFinarkein =
        !widget.forceStandardApis &&
        userController.userData?.isFinarkeinAa == true;
    if (isFinarkein) {
      if (!Get.isRegistered<RawAssetController>()) {
        rawAssetController = Get.put(RawAssetController());
      } else {
        rawAssetController = Get.find<RawAssetController>();
      }
      // Fetch raw asset data
      rawAssetController.fetchAllAssets();
    }

    if (!widget.forceStandardApis) {
      _startFipStatusPolling();
    }
    fetchBankSummary();
  }

  @override
  void dispose() {
    _stopFipStatusPolling();
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  /// Restores amount visibility state from persistent storage
  void _restoreAmountVisibilityState() {
    final savedAmountVisibility =
        StorageService.read(StorageKeys.AMOUNT_VISIBILITY_KEY) ?? false;
    setState(() {
      _isAmountVisible = savedAmountVisibility;
    });
  }

  /// Get banks from RawAssetController for Finarkein users, fallback to provider
  List<Bank> get _effectiveBanks {
    final isFinarkein =
        !widget.forceStandardApis &&
        userController.userData?.isFinarkeinAa == true;

    // For Finarkein users, use RawAssetController to get all banks from API
    if (isFinarkein && Get.isRegistered<RawAssetController>()) {
      final rawController = Get.find<RawAssetController>();
      if (rawController.banks.isNotEmpty) {
        // Convert raw Map data to Bank models
        return rawController.banks.map((rawBank) {
          return Bank.fromJson(rawBank);
        }).toList();
      }
    }

    // Fallback to provider or holdings API
    final list =
        getAccountAggregatorDataProvider(
          forceStandard: widget.forceStandardApis,
        ).getBanks();
    if (list != null && list.isNotEmpty) return list;
    return bankController.bankSummary?.data?.banks ?? [];
  }

  Future<void> fetchBankSummary() async {
    final provider = getAccountAggregatorDataProvider(
      forceStandard: widget.forceStandardApis,
    );

    // If Finarkein user, trigger the global data fetch to update the store
    if (!widget.forceStandardApis &&
        userController.userData?.isFinarkeinAa == true) {
      if (!Get.isRegistered<FinarkeinDataController>()) {
        Get.put(FinarkeinDataController());
      }
      FinarkeinDataController.to.fetchFinarkeinData();
    }

    if (!widget.forceStandardApis && provider.getBanks() != null) return;
    bankController.getBankSummary(
      onLoading: (isLoading) {
        if (mounted) {
          setState(() {
            isBankSummaryLoading = isLoading;
          });
          if (isLoading) {
            _refreshController.repeat();
          } else {
            _refreshController.stop();
            _refreshController.reset();
          }
        }
      },
      forceStandard: widget.forceStandardApis,
    );
  }

  void _startFipStatusPolling() async {
    final isFinarkein =
        !widget.forceStandardApis &&
        userController.userData?.isFinarkeinAa == true;

    // Fetch initial status
    await _fetchAccountListFromProvider();

    if (isFinarkein) {
      // For Finarkein users, always start polling to show real-time status updates
      _startFipPolling();
    } else {
      // For non-Finarkein users, use existing logic
      final provider = getAccountAggregatorDataProvider(
        forceStandard: widget.forceStandardApis,
      );
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
    if (_fipAccounts.isEmpty) return false;

    final isFinarkein =
        !widget.forceStandardApis &&
        userController.userData?.isFinarkeinAa == true;

    if (isFinarkein) {
      // For Finarkein: Continue polling if any account is PROCESSING or PENDING
      // Stop when all are SUCCESS or FAILED
      return _fipAccounts.any((account) {
        final status = (account['fetchstatus'] as String?)?.toUpperCase() ?? '';
        return status == 'PROCESSING' || status == 'PENDING';
      });
    } else {
      // For non-Finarkein: Continue if any account is FETCHING
      return _fipAccounts.any(
        (account) => account['fetchstatus'] == 'FETCHING',
      );
    }
  }

  Future<void> _fetchAccountListFromProvider() async {
    try {
      final isFinarkein =
          !widget.forceStandardApis &&
          userController.userData?.isFinarkeinAa == true;

      if (isFinarkein) {
        // Use Finarkein-specific status service
        final finarkeinStatusService = FinarkeinStatusService();
        final response = await finarkeinStatusService.getFinarkeinStatus(
          onLoading: (isLoading) {
            // Loading state handled by existing logic
          },
        );
        if ((response.statusCode == 200 || response.statusCode == 201) &&
            response.FIPStatusData != null &&
            mounted) {
          setState(() {
            _fipAccounts =
                response.FIPStatusData!
                    .map(
                      (datum) => {
                        'guid': datum.guid,
                        'fetchstatus': datum.fetchstatus,
                        'fipname': datum.fipname,
                        'type': datum.type,
                        'userguid': datum.userguid,
                        'activestatus': datum.activestatus,
                        'fetchstatusupdatedat': datum.fetchstatusupdatedat,
                        'balancedatetime': datum.balancedatetime,
                      },
                    )
                    .toList();
          });
        }
      } else {
        // Use standard account aggregator provider for non-Finarkein users
        final provider = getAccountAggregatorDataProvider(
          forceStandard: widget.forceStandardApis,
        );
        final response = await provider.fetchAccountList();
        if (response != null && response.FIPStatusData != null && mounted) {
          setState(() {
            _fipAccounts =
                response.FIPStatusData!
                    .map(
                      (datum) => {
                        'guid': datum.guid,
                        'fetchstatus': datum.fetchstatus,
                        'fipname': datum.fipname,
                        'type': datum.type,
                      },
                    )
                    .toList();
          });
        }
      }

      if (_shouldStartFipPolling() && _fipPollingTimer == null) {
        _startFipPolling();
      } else if (!_shouldStartFipPolling() && _fipPollingTimer != null) {
        _stopFipStatusPolling();
      }
    } catch (e) {
      dev.log('Error fetching FIP status: $e');
    }
  }

  List<Map<String, dynamic>> _getMergedAccounts() {
    final List<Map<String, dynamic>> merged = [];

    final bankTypes = [
      'SAVINGS',
      'DEPOSIT',
      'CURRENT',
      'TERM_DEPOSIT',
      'RECURRING_DEPOSIT',
    ];

    // 1. Add real-time accounts from AaDataFetchController (Priority)
    if (Get.isRegistered<AaDataFetchController>()) {
      final fetchOptionsData =
          Get.find<AaDataFetchController>().fetchOptionsData.value;
      final bankAccounts = fetchOptionsData?.deposit ?? [];

      for (final option in bankAccounts) {
        final String type = (option.accountType ?? '').toUpperCase();
        // Even within deposit list, ensure it's a bank type
        if (!bankTypes.contains(type)) {
          continue;
        }

        merged.add({
          'type': type,
          'fetchstatus': option.status.toUpperCase(),
          'fipname': option.fipName,
          'guid': option.id,
          'maskedaccno': option.maskedAccNumber,
          'lastdatafetchedat': option.lastFetchedTime,
          'fetchstatusupdatedat': option.fetchStatusUpdatedAt,
          'lastdatafetchedat_raw':
              Get.find<AaDataFetchController>().mfCentralLastUpdatedRaw[option
                  .id],
        });
      }
    }

    // 2. Add accounts from FipStatusController only if they don't already exist
    for (final account in _fipStatusController.accounts) {
      final type = (account['type'] as String? ?? '').toUpperCase();
      // Skip if not a bank type
      if (!bankTypes.contains(type)) {
        continue;
      }

      final exists = merged.any(
        (acc) =>
            acc['fipname'] == account['fipname'] &&
            (acc['maskedaccno'] == account['maskedaccno'] ||
                acc['guid'] == account['guid']),
      );

      if (!exists) {
        merged.add(account);
      }
    }

    return merged;
  }

  /// Builds a message to display when no bank accounts are found
  Widget _buildNoAccountsMessage() {
    // Don't show message if still loading
    if (isBankSummaryLoading) {
      return const SizedBox(); // Empty widget when loading
    }

    // Use LayoutBuilder to get the available height
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // Take the full available height
          height: MediaQuery.of(context).size.height / 2,
          width: double.infinity,
          child: Center(
            child: EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'No bank accounts found',
              subtitle: 'You don\'t have any bank accounts linked yet.',
            ),
          ),
        );
      },
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
            Semantics(
              label: 'Back',
              button: true,
              child: GestureDetector(
                onTap: () {
                  BackNavigation.backOrHome();
                },
                child: const ExcludeSemantics(
                  child: Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            AppText(
              "Banks",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: AppSizing.scaffoldHorizontalPadding,
            right: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              // Total balance card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  border: Border.all(color: AppColors.darkButtonBorder),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GetBuilder<BankController>(
                      builder: (controller) {
                        final providerBanks = _effectiveBanks;
                        final useFinarkeinBanks = providerBanks.isNotEmpty;

                        // For Finarkein users, use summary.totalbankamount
                        double totalBalance = 0;
                        if (useFinarkeinBanks &&
                            !widget.forceStandardApis &&
                            userController.userData?.isFinarkeinAa == true &&
                            Get.isRegistered<FinarkeinDataController>()) {
                          final ctrl = Get.find<FinarkeinDataController>();
                          final summary =
                              ctrl.dataResponse.value?.data?.summary;
                          totalBalance = summary?['totalbankamount'] ?? 0.0;
                        } else if (useFinarkeinBanks) {
                          // Fallback: sum individual banks
                          totalBalance = providerBanks.fold<double>(
                            0,
                            (sum, b) => sum + (b.currentvalue),
                          );
                        } else {
                          // Non-Finarkein users
                          totalBalance =
                              controller.bankSummary?.data?.totalbalance ?? 0;
                        }
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  "Total balance",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.secondary,
                                ),
                                Semantics(
                                  label: 'Refresh Data Fetch Status',
                                  button: true,
                                  child: GestureDetector(
                                    onTap: () {
                                      Get.to(
                                        () => const DataFetchDetailsScreen(),
                                        transition: Transition.rightToLeft,
                                      );
                                    },
                                    child: ExcludeSemantics(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkButtonBorder,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: AppColors.darkButtonBorder,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.refresh,
                                              size: 14,
                                              color:
                                                  AppColors
                                                      .darkButtonPrimaryBackground,
                                            ),
                                            const SizedBox(width: 4),
                                            AppText(
                                              "Refresh",
                                              variant: AppTextVariant.tiny,
                                              weight: AppTextWeight.medium,
                                              colorType:
                                                  AppTextColorType.primary,
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: AnimatedAmount(
                                              isMain: true,
                                              isLoading:
                                                  useFinarkeinBanks
                                                      ? false
                                                      : isBankSummaryLoading,
                                              isAmountVisible: _isAmountVisible,
                                              amount:
                                                  CurrencyFormatter.formatRupee(
                                                    totalBalance,
                                                  ),
                                              style: TextStyle(
                                                fontSize: 36.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.darkPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      AppText(
                                        useFinarkeinBanks
                                            ? "Data from linked accounts"
                                            : (controller
                                                        .bankSummary
                                                        ?.data
                                                        ?.latestbalancedatetime !=
                                                    null
                                                ? "Last data fetched at ${controller.bankSummary!.data!.latestbalancedatetime != null ? DateFormatter.formatToDateTimeWithAmPm(DateTime.parse(controller.bankSummary!.data!.latestbalancedatetime!)) : ""}"
                                                : "No data fetched yet"),
                                        variant: AppTextVariant.tiny,
                                        weight: AppTextWeight.semiBold,
                                        colorType: AppTextColorType.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label:
                                      _isAmountVisible
                                          ? 'Hide Total Balance'
                                          : 'Show Total Balance',
                                  button: true,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAmountVisible = !_isAmountVisible;
                                      });
                                      // Save amount visibility state to storage
                                      StorageService.write(
                                        StorageKeys.AMOUNT_VISIBILITY_KEY,
                                        _isAmountVisible,
                                      );
                                    },
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        _isAmountVisible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color:
                                            _isAmountVisible
                                                ? AppColors.darkPrimary
                                                : AppColors.darkTextMuted,
                                        size: 22.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            if (!useFinarkeinBanks &&
                                controller.bankSummary?.data?.deltavalue !=
                                    null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          controller
                                                      .bankSummary!
                                                      .data!
                                                      .deltavalue! >=
                                                  0
                                              ? AppColors.success.withValues(
                                                alpha: 0.1,
                                              )
                                              : AppColors.error.withValues(
                                                alpha: 0.1,
                                              ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: AppText(
                                      "${controller.bankSummary!.data!.deltavalue! >= 0 ? '+' : ''}"
                                      "${CurrencyFormatter.formatRupeeWithDecimals(controller.bankSummary!.data!.deltavalue ?? 0.0)} "
                                      "(${controller.bankSummary!.data!.deltapercentage}%) Today",
                                      variant: AppTextVariant.bodySmall,
                                      weight: AppTextWeight.semiBold,
                                      colorType:
                                          controller
                                                      .bankSummary!
                                                      .data!
                                                      .deltavalue! >=
                                                  0
                                              ? AppTextColorType.success
                                              : AppTextColorType.error,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Transactions card
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Track your Transactions',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to transaction list without bank ID
                          Get.to(
                            () => BankTransactionListScreen(
                              forceStandardApis: widget.forceStandardApis,
                            ),
                          );
                        },
                        child: ExcludeSemantics(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkCardBG,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.darkButtonBorder,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(15.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/svgs/assets/banks/money-transfer.svg',
                                          height: 30,
                                          width: 30,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Track your ",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "Transactions ",
                                                  style: TextStyle(
                                                    color: AppColors.info,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Semantics(
                      label: 'Check Deposit Activity',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to transaction list without bank ID
                          Get.to(
                            () => const BankDepositsListScreen(
                              forceStandardApis: true,
                            ),
                          );
                        },
                        child: ExcludeSemantics(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkCardBG,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.darkButtonBorder,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(15.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/svgs/assets/banks/deposit-activity.svg',
                                          height: 30,
                                          width: 30,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Check ",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "Deposit ",
                                                  style: TextStyle(
                                                    color: AppColors.info,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "Activity",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Montserrat',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                color: AppColors.darkBackground,
                child: Obx(
                  () => StatusCardSwiper(
                    lastFetchedTime: _fipStatusController.lastFetchedTime,
                    category: 'banks',
                    horizontalPadding: 0,
                    accounts: _getMergedAccounts(),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Search field
              AppInputField(
                controller: _searchController,
                prefix: Icon(
                  CupertinoIcons.search,
                  color: AppColors.darkTextMuted,
                ),
                hintText: "Search...",
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),

              SizedBox(height: 4.h),

              // Bank list or no accounts message
              GetBuilder<BankController>(
                builder: (controller) {
                  final providerBanks = _effectiveBanks;
                  final useFinarkeinBanks = providerBanks.isNotEmpty;
                  final sourceBanks =
                      useFinarkeinBanks
                          ? providerBanks
                          : (controller.bankSummary?.data?.banks ?? <Bank>[]);
                  if (!useFinarkeinBanks &&
                      controller.bankSummary?.data == null) {
                    return const Center(child: LoadingWidget());
                  }

                  // Filter banks based on search query (DEPOSIT type for API data; Finarkein banks are already deposit)
                  final filteredBanks =
                      sourceBanks
                          .where(
                            (bank) =>
                                useFinarkeinBanks || (bank.type == "DEPOSIT"),
                          )
                          .where((bank) {
                            if (_searchQuery.isEmpty) return true;
                            final bankName = (bank.fipname).toLowerCase();
                            final accountNumber =
                                (bank.maskedaccountid).toLowerCase();
                            return bankName.contains(_searchQuery) ||
                                accountNumber.contains(_searchQuery);
                          })
                          .toList();

                  // Check if filtered banks list is empty
                  if (filteredBanks.isEmpty) {
                    return _buildNoAccountsMessage();
                  }

                  // If we have banks, show them in a scrollable list
                  return Column(
                    children: [
                      // Nominee Registered Details Section
                      GetBuilder<BankController>(
                        builder: (controller) {
                          final providerBanksList = _effectiveBanks;
                          final useFinarkein = providerBanksList.isNotEmpty;
                          final depositBanks =
                              useFinarkein
                                  ? providerBanksList
                                  : (controller.bankSummary?.data?.banks ??
                                          <Bank>[])
                                      .where((bank) => bank.type == "DEPOSIT")
                                      .toList();
                          if (!useFinarkein &&
                              controller.bankSummary?.data == null) {
                            return const SizedBox();
                          }

                          if (depositBanks.isEmpty) {
                            return const SizedBox();
                          }

                          return CustomAccordion(
                            title: "Nominee Registered Details",
                            backgroundColor: AppColors.darkCardBG,
                            borderRadius: 15,
                            child: Column(
                              spacing: 12,
                              children: [
                                ...depositBanks.asMap().entries.map((entry) {
                                  final bank = entry.value;
                                  final isNomineeRegistered =
                                      bank.profile.nominee == "REGISTERED";

                                  return Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.darkButtonBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Bank Icon
                                        Container(
                                          width: 40.w,
                                          height: 40.w,
                                          decoration: BoxDecoration(
                                            color: AppColors.info,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.account_balance,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),

                                        // Bank Details
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AppText(
                                                bank.fipname,
                                                variant:
                                                    AppTextVariant.bodyMedium,
                                                weight: AppTextWeight.semiBold,
                                              ),
                                              SizedBox(height: 0.h),
                                              AppText(
                                                bank.maskedaccountid,
                                                variant:
                                                    AppTextVariant.bodySmall,
                                                colorType:
                                                    AppTextColorType.secondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            AppText(
                                              "Nominee: ",
                                              variant: AppTextVariant.bodySmall,
                                              colorType:
                                                  AppTextColorType.secondary,
                                            ),
                                            AppText(
                                              isNomineeRegistered
                                                  ? "Yes"
                                                  : "No",
                                              variant: AppTextVariant.bodySmall,
                                              weight: AppTextWeight.semiBold,
                                              colorType:
                                                  isNomineeRegistered
                                                      ? AppTextColorType.success
                                                      : AppTextColorType.error,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                // Info message
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.darkPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppColors.info,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              "Go ahead and register a nominee if you haven't.",
                                              variant: AppTextVariant.bodySmall,
                                              colorType:
                                                  AppTextColorType.primary,
                                            ),
                                            SizedBox(height: 4.h),
                                            GestureDetector(
                                              onTap: () async {
                                                SpeakToAdvisor.speakToAdvisor();
                                              },
                                              child: AppText(
                                                "Speak to our advisor if you need help",
                                                variant:
                                                    AppTextVariant.bodySmall,
                                                colorType:
                                                    AppTextColorType.link,
                                                weight: AppTextWeight.semiBold,
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
                          );
                        },
                      ),

                      SizedBox(height: 4.h),

                      // Bank Cards List
                      ...filteredBanks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final bank = entry.value;
                        final isLastItem = index == filteredBanks.length - 1;

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: isLastItem ? 0 : 12.h,
                          ),
                          child: BankCard(
                            type: bank.type ?? 'DEPOSIT',
                            bankGUID: bank.guid,
                            icon: Icons.account_balance,
                            bankName: bank.fipname,
                            accountNumber: bank.maskedaccountid,
                            balance: CurrencyFormatter.formatRupee(
                              bank.currentvalue,
                            ),
                            deltaValue: "${bank.deltapercentage}%",
                            isPositiveDelta: bank.deltavalue >= 0,
                            isAmountVisible: _isAmountVisible,
                            balanceDateTime: bank.balancedatetime,
                            forceStandardApis: widget.forceStandardApis,
                          ),
                        );
                      }),

                      SizedBox(height: 16.h),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          (userController.userData?.istestaccount ?? false) == false
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                ),
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Add Banks',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        isLoading: false,
                        onPressed: () {
                          AccountAggregatorRouter().openConnection(context);
                        },
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
