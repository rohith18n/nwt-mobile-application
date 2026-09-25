import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/types/fip_status.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/services/remote_config/remote_config_service.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/common/service_outage_card.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';
import 'package:nwt_app/screens/connections/finarkein_connection_screen.dart';

class FinarkeinDataFetch extends StatefulWidget {
  const FinarkeinDataFetch({super.key});

  @override
  State<FinarkeinDataFetch> createState() => _FinarkeinDataFetchState();
}

class _FinarkeinDataFetchState extends State<FinarkeinDataFetch>
    with WidgetsBindingObserver {
  // Controller instances
  final UserController _userController = Get.find<UserController>();
  final AccountAggregatorRouter _accountAggregatorRouter =
      AccountAggregatorRouter();

  // Store FIP status data
  final Rx<FipStatusResponse?> _fipStatusResponse = Rx<FipStatusResponse?>(
    null,
  );

  // Loading states
  final RxBool _isLoading = false.obs; // For general loading (initial load)
  final RxBool _isManualRefreshing = false.obs; // For manual refresh button
  bool _initialDataLoaded = false;

  // Adhoc remaining count
  final RxDouble _adhocRemaining = 0.0.obs;

  // Polling timer
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 3);
  bool _isPageVisible = true;
  DateTime? _loadingStartTime;
  DateTime? _pollingStartTime;

  // Callback for accounts data changes
  Function(List<Map<String, dynamic>>)? onAccountsChanged;

  // Tab selection state
  final RxInt _selectedTabIndex = 0.obs; // 0 for Accounts, 1 for Mutual Funds

  // Maps for account types and icons
  final Map<String, List<String>> _accountTypeMap = {
    'Banks': ['DEPOSIT', 'TERM_DEPOSIT', 'RECURRING_DEPOSIT'],
    'Investments': ['EQUITIES', 'ETF'], // Removed MUTUAL_FUNDS and SIP
    'Insurance': ['GENERAL_INSURANCE', 'LIFE_INSURANCE', 'INSURANCE_POLICIES'],
    'NPS': ['NPS'],
    'Mutual Funds': [
      'MUTUAL_FUNDS',
      'SIP',
    ], // Separate category for mutual funds
  };

  final Map<String, IconData> _typeIconMap = {
    'Banks': Icons.account_balance_outlined,
    'Investments': Icons.trending_up_outlined,
    'Insurance': Icons.shield_outlined,
    'NPS': Icons.account_balance_wallet_outlined,
    'Mutual Funds': Icons.donut_small_outlined,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  // Load data from FIP status service
  void _loadData() async {
    if (_userController.userData == null) return;

    dev.log(
      'Loading Finarkein FIP status data for user: ${_userController.userData!.guid}',
    );

    _loadingStartTime = DateTime.now();
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dataFetchStatusLoadingStarted,
      parameters: {AnalyticsParams.screenName: 'finarkein_data_fetch_status'},
    );

    _isLoading.value = true;
    final provider = getAccountAggregatorDataProvider();
    _adhocRemaining.value = await provider.fetchAdhocRemaining();
    final response = await provider.fetchAccountList();

    dev.log(
      'FinarkeinDataFetch: fetchAccountList returned: ${response != null}',
    );
    if (response != null) {
      dev.log(
        'FinarkeinDataFetch: response.FIPStatusData length: ${response.FIPStatusData?.length}',
      );
      if (response.FIPStatusData != null) {
        for (final d in response.FIPStatusData!) {
          dev.log(
            'FinarkeinDataFetch: Account: ${d.fipname} Type: ${d.type} Status: ${d.fetchstatus}',
          );
        }
      }
      _fipStatusResponse.value = response;
    } else {
      dev.log('FinarkeinDataFetch: response is null');
    }

    _initialDataLoaded = true;
    _isLoading.value = false;
    // Finarkein might not need aggressive polling if not in active fetch, but we keep it for consistency
    _startPolling();
  }

  void _startPolling() {
    if (!_isPageVisible) return;
    if (!getAccountAggregatorDataProvider().shouldPollAccountStatus()) return;

    // Check if any account has 'fetching' status before starting polling
    if (!_shouldStartPolling()) {
      dev.log('No accounts with fetching status, skipping polling');
      return;
    }

    _stopPolling(); // Stop any existing timer
    _pollingStartTime = DateTime.now();

    final fetchingCount = _getFetchingAccountsCount();
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dataFetchStatusPollingStarted,
      parameters: {
        AnalyticsParams.pollingIntervalSeconds:
            _pollingInterval.inSeconds.toString(),
        AnalyticsParams.accountsFetchingCount: fetchingCount.toString(),
      },
    );

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted && _isPageVisible && _shouldStartPolling()) {
        _fetchAccountListFromProvider();
      } else {
        dev.log('Stopping polling - conditions not met');
        timer.cancel();
        _pollingTimer = null;
      }
    });
    dev.log(
      'Started FIP status polling every ${_pollingInterval.inSeconds} seconds',
    );
  }

  // Get count of accounts in fetching status
  int _getFetchingAccountsCount() {
    final response = _fipStatusResponse.value;
    if (response == null || response.FIPStatusData == null) return 0;
    return response.FIPStatusData!
        .where((account) => account.fetchstatus == 'FETCHING')
        .length;
  }

  // Stop polling
  void _stopPolling() {
    if (_pollingTimer != null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;

      if (_pollingStartTime != null) {
        final duration = DateTime.now().difference(_pollingStartTime!);
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.dataFetchStatusPollingStopped,
          parameters: {
            AnalyticsParams.pollingDurationSeconds:
                duration.inSeconds.toString(),
          },
        );
        _pollingStartTime = null;
      }
    }
    dev.log('Stopped FIP status polling');
  }

  // Check if polling should start/continue based on account statuses
  bool _shouldStartPolling() {
    final response = _fipStatusResponse.value;
    if (response == null || response.FIPStatusData == null) return false;

    // Check if any account has 'fetching' status
    for (final account in response.FIPStatusData!) {
      if (account.fetchstatus == 'FETCHING') {
        return true;
      }
    }
    return false;
  }

  Future<void> _fetchAccountListFromProvider() async {
    try {
      final provider = getAccountAggregatorDataProvider();
      final response = await provider.fetchAccountList();
      if (response != null) {
        _fipStatusResponse.value = response;
        _initialDataLoaded = true;
        if (_loadingStartTime != null) {
          final duration = DateTime.now().difference(_loadingStartTime!);
          AnalyticsService.to.logEvent(
            name: AnalyticsEvents.dataFetchStatusLoadingCompleted,
            parameters: {
              AnalyticsParams.loadingDurationSeconds:
                  duration.inSeconds.toString(),
              AnalyticsParams.accountsCount:
                  (response.FIPStatusData?.length ?? 0).toString(),
            },
          );
          _loadingStartTime = null;
        }
        if (_shouldStartPolling() && _pollingTimer == null) {
          _startPolling();
        } else if (!_shouldStartPolling() && _pollingTimer != null) {
          _stopPolling();
        }
      }
    } catch (e) {
      dev.log('Error fetching account list: $e');
      if (_loadingStartTime != null) {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.dataFetchStatusLoadingFailed,
          parameters: {
            AnalyticsParams.errorMessage: e.toString(),
            AnalyticsParams.errorType: 'api_error',
          },
        );
        _loadingStartTime = null;
      }
    }
  }

  // Manually refresh data
  void _triggerRefresh() async {
    final remainingBefore = _adhocRemaining.value;

    // Log refresh initiated
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dataFetchStatusManualRefreshInitiated,
      parameters: {
        AnalyticsParams.adhocRemaining: remainingBefore.toInt().toString(),
        AnalyticsParams.tabSelected:
            _selectedTabIndex.value == 0 ? 'accounts' : 'mutual_funds',
      },
    );

    // Immediately update the UI to reflect the refresh action
    _isManualRefreshing.value = true;

    // Optimistically update the remaining count in the UI
    if (_adhocRemaining.value > 0) {
      _adhocRemaining.value--;
      // Force a UI update
      await Future.delayed(Duration.zero);
    }

    try {
      final provider = getAccountAggregatorDataProvider();
      final remainingRefreshes = await provider.triggerDataFetch();
      if (remainingRefreshes != null) {
        _adhocRemaining.value = remainingRefreshes;
      }
      await _fetchAccountListFromProvider();

      // Log refresh success
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dataFetchStatusManualRefreshSuccess,
        parameters: {
          AnalyticsParams.adhocRemaining:
              (remainingRefreshes?.toInt() ?? 0).toString(),
        },
      );
    } catch (e) {
      // If there's an error, revert the optimistic update
      if (_adhocRemaining.value >= 0) {
        _adhocRemaining.value++;
      }

      // Show error to user
      String msg = "Refresh failed. Please try again.";
      if (e.toString().contains("Fetch limit exhausted")) {
        msg = "Monthly refresh limit reached for this account.";
      } else if (e.toString().toLowerCase().contains("network")) {
        msg = "Network error. Please check your connection.";
      }

      Get.snackbar(
        "Update Failed",
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );

      // Log refresh failed
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dataFetchStatusManualRefreshFailed,
        parameters: {
          AnalyticsParams.errorMessage: e.toString(),
          AnalyticsParams.errorCode: 'refresh_failed',
          AnalyticsParams.adhocRemaining: remainingBefore.toInt().toString(),
        },
      );
    } finally {
      _isManualRefreshing.value = false;
    }
  }

  @override
  void dispose() {
    // Stop polling when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    print('Dispose used');
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isPageVisible) {
          _startPolling();
          dev.log('App resumed - restarting polling');
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopPolling();
        dev.log('App paused/inactive - stopping polling');
        break;
      default:
        break;
    }
  }

  // Helper method to get status color based on fetch status
  AppTextColorType _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppTextColorType.success;
      case 'failed':
        return AppTextColorType.error;
      default:
        return AppTextColorType.secondary;
    }
  }

  // Format the date for display
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not fetched yet';
    }

    try {
      final DateTime date = DateTime.parse(dateString);
      final lastFetchDateTime = DateFormatter.formatToDateTimeWithAmPm(date);
      return 'Updated $lastFetchDateTime';
    } catch (e) {
      return 'Update time unknown';
    }
  }

  // Capitalize first letter of a string and make rest lowercase
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
              onTap: () {
                AnalyticsService.to.logEvent(
                  name: AnalyticsEvents.dataFetchStatusBackButtonClicked,
                  parameters: {
                    AnalyticsParams.screenName: 'finarkein_data_fetch_status',
                    AnalyticsParams.tabSelected:
                        _selectedTabIndex.value == 0
                            ? 'accounts'
                            : 'mutual_funds',
                  },
                );
                Get.offAll(() => StackedNavbar(selectedIdx: 0));
              },
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Data Fetch Status",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            Opacity(
              opacity: 0,
              child: GestureDetector(
                onTap: () {
                  AnalyticsService.to.logEvent(
                    name: AnalyticsEvents.dataFetchStatusInfoIconClicked,
                    parameters: {
                      AnalyticsParams.screenName: 'finarkein_data_fetch_status',
                    },
                  );
                  _showInfoBottomSheet(context);
                },
                child: const Icon(Icons.info_outline_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
      body: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              children: [
                // Tab Toggle hidden
                // _buildTabToggle(),
                // const SizedBox(height: 20),

                // Dynamic content based on selected tab
                Obx(() => Column(children: _buildTabContent())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build content based on selected tab
  List<Widget> _buildTabContent() {
    if (_selectedTabIndex.value == 0) {
      // Accounts tab - show manual refresh, last fetch, and all accounts

      // Don't show manual refresh container during initial loading
      if (_isLoading.value && !_initialDataLoaded) {
        return _buildAccountSections(); // This returns the loading indicator
      }

      final accountSections = _buildAccountSections();
      if (accountSections.isEmpty) {
        // Show only Link Now button if no accounts are available (hide manual refresh and last fetch)
        return [_buildLinkNowButton(isAccountsTab: true)];
      }
      return [
        _buildManualRefreshContainer(),
        const SizedBox(height: 20),
        _buildLastFetchContainer(),
        const SizedBox(height: 20),
        ...accountSections,
      ];
    } else {
      // Mutual Funds tab - show MF specific cards and mutual funds

      // Don't show MF cards during initial loading
      if (_isLoading.value && !_initialDataLoaded) {
        return _buildAccountSections(); // This returns the loading indicator
      }

      final mutualFundSections = _buildAccountSections();
      if (mutualFundSections.isEmpty) {
        return [_buildLinkNowButton(isAccountsTab: false)];
      }

      // Finarkein specific MF logic here usually simpler as it's unified
      // But keeping structure for consistency

      List<Widget> widgets = [];
      widgets.addAll(mutualFundSections);
      return widgets;
    }
  }

  // Build manual refresh container
  Widget _buildManualRefreshContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkCardBG,
        border: Border.all(color: AppColors.darkButtonBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  "Manual Refresh",
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 6),
                Obx(
                  () =>
                      _adhocRemaining.value <= 0
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: AppText(
                                    "No refreshes available this month",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.medium,
                                    colorType: AppTextColorType.error,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: AppColors.darkPrimary.withOpacity(0.8),
                                fontSize: 14.sp,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(text: "You have "),
                                TextSpan(
                                  text: _adhocRemaining.value.toStringAsFixed(
                                    0,
                                  ),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: " refreshes remaining"),
                              ],
                            ),
                          ),
                ),
                const SizedBox(height: 6),
                AppText(
                  "15 on-demand updates each month",
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.regular,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
          ),
          Obx(
            () => Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    _adhocRemaining.value <= 0
                        ? AppColors.darkButtonBorder.withOpacity(0.5)
                        : AppColors.darkPrimary.withOpacity(0.1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap:
                      _adhocRemaining.value <= 0
                          ? () {
                            // Log disabled button click
                            AnalyticsService.to.logEvent(
                              name:
                                  AnalyticsEvents
                                      .dataFetchStatusManualRefreshDisabledClicked,
                              parameters: {AnalyticsParams.adhocRemaining: '0'},
                            );
                          }
                          : () => _triggerRefresh(),
                  child: Center(
                    child:
                        _isManualRefreshing.value
                            ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.darkPrimary,
                              ),
                            )
                            : Icon(
                              Icons.refresh_rounded,
                              color:
                                  _adhocRemaining.value <= 0
                                      ? Colors.grey
                                      : AppColors.darkPrimary,
                              size: 24,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build last fetch container
  Widget _buildLastFetchContainer() {
    // Log last fetch viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dataFetchStatusLastFetchViewed,
        parameters: {AnalyticsParams.tabSelected: 'accounts'},
      );
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkCardBG,
        border: Border.all(color: AppColors.darkButtonBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final data = _fipStatusResponse.value?.FIPStatusData;
                  if (data == null || data.isEmpty) {
                    return AppText(
                      "No fetch history yet",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    );
                  }

                  // Pick the latest successful balance datetime across accounts
                  DateTime? latest;
                  for (final d in data) {
                    if (d.fetchstatus.toUpperCase() == 'SUCCESS') {
                      if (latest == null || d.balancedatetime.isAfter(latest)) {
                        latest = d.balancedatetime;
                      }
                    }
                  }

                  // If no SUCCESS entries found, fall back to the latest balancedatetime of any status
                  latest ??= data
                      .map((d) => d.balancedatetime)
                      .reduce((a, b) => a.isAfter(b) ? a : b);

                  final DateTime latestResolved = latest;
                  final relative = DateFormatter.formatToRelativeTime(
                    latestResolved,
                  );
                  final absolute = DateFormatter.formatToDateTimeWithAmPm(
                    latestResolved,
                  );

                  return AppText(
                    "Last successful fetch was $relative on $absolute",
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.regular,
                    colorType: AppTextColorType.primary,
                  );
                }),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white24, // subtle light line
                ),
                const SizedBox(height: 8),
                AppText(
                  "Source: Finarkein (Account Aggregator)",
                  variant: AppTextVariant.caption,
                  weight: AppTextWeight.regular,
                  colorType: AppTextColorType.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Link Now button for empty states
  Widget _buildLinkNowButton({bool isAccountsTab = false}) {
    // Check for service outage on Mutual Funds tab
    if (!isAccountsTab) {
      final isMfcWorking = RemoteConfigService.to.isMfcWorking.value;
      if (!isMfcWorking) {
        return const Column(
          children: [
            SizedBox(height: 16),
            ServiceOutageCard(),
            SizedBox(height: 16),
          ],
        );
      }
    }
    final String title =
        isAccountsTab ? "No Accounts linked yet" : "No Mutual Funds linked yet";
    final String subtitle =
        isAccountsTab
            ? "Connect your bank and investment accounts to track your finances"
            : "Connect your mutual fund accounts to track your investments";

    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              AppText(
                title,
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.semiBold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 12),
              AppText(
                subtitle,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.regular,
                colorType: AppTextColorType.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.darkPrimary,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!isAccountsTab) {
                        // Mutual Funds tab - Navigate to MF Holdings Journey for Finarkein
                        // reusing MutualFundHoldingsJourneyScreen if compatible, otherwise use ConnectionScreen
                        AnalyticsService.to.logEvent(
                          name:
                              AnalyticsEvents
                                  .dataFetchStatusLinkNowMutualFundsClicked,
                          parameters: {
                            AnalyticsParams.tabContext: 'mutual_funds',
                            AnalyticsParams.destinationScreen:
                                'mutual_fund_holdings_journey',
                          },
                        );
                        // For Finarkein, usually single journey handles all.
                        // But let's assume we redirect to standard connection
                        Get.to(
                          () => FinarkeinConnectionScreen(),
                          transition: Transition.rightToLeft,
                        );
                      } else {
                        AnalyticsService.to.logEvent(
                          name:
                              AnalyticsEvents
                                  .dataFetchStatusLinkNowAccountsClicked,
                          parameters: {
                            AnalyticsParams.tabContext: 'accounts',
                            AnalyticsParams.destinationScreen:
                                'finarkein_connection',
                          },
                        );
                        _accountAggregatorRouter.openConnection(context);
                      }
                    },
                    child: Center(
                      child: AppText(
                        "Link Now",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType: AppTextColorType.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // Build account sections grouped by type
  List<Widget> _buildAccountSections() {
    // Show loading indicator if initial data is still loading
    if (_isLoading.value && !_initialDataLoaded) {
      return [
        const SizedBox(height: 40),
        Center(child: CircularProgressIndicator(color: AppColors.darkPrimary)),
        const SizedBox(height: 20),
        Center(
          child: AppText(
            "Loading accounts data...",
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.secondary,
          ),
        ),
      ];
    }

    // Show no data message if FIP status data is empty
    final fipData = _fipStatusResponse.value?.FIPStatusData;
    if (fipData == null || fipData.isEmpty) {
      // For both tabs, return empty list so Link Now button shows
      return [];
    }

    // Group accounts by type
    final Map<String, List<Datum>> groupedAccounts = {};

    for (final account in fipData) {
      final String type = account.type.toUpperCase();
      String category = 'Other';

      // Use the account type map to categorize accounts
      bool found = false;
      for (final entry in _accountTypeMap.entries) {
        if (entry.value.contains(type)) {
          category = entry.key;
          found = true;
          break;
        }
      }

      // If not found in map, try to infer from type string
      if (!found) {
        if (type.contains('INSURANCE'))
          category = 'Insurance';
        else if (type.contains('FUND') || type.contains('SIP'))
          category = 'Mutual Funds';
        else if (type.contains('EQUITY') ||
            type.contains('ETF') ||
            type.contains('STOCK'))
          category = 'Investments';
        else if (type.contains('DEPOSIT') || type.contains('BANK'))
          category = 'Banks';
        else if (type.contains('NPS'))
          category = 'NPS';
      }

      // Filter based on selected tab
      if (_selectedTabIndex.value == 1) {
        // Mutual Funds tab - only show mutual funds and SIPs
        if (category != 'Mutual Funds') {
          continue; // Skip non-mutual fund accounts
        }
      } else {
        // Accounts tab - exclude mutual funds and SIPs
        if (category == 'Mutual Funds') {
          continue; // Skip mutual fund accounts
        }
      }

      if (!groupedAccounts.containsKey(category)) {
        groupedAccounts[category] = [];
      }

      groupedAccounts[category]!.add(account);
    }

    // Build sections for each category
    final List<Widget> sections = [];

    groupedAccounts.forEach((category, accounts) {
      // Skip empty categories
      if (accounts.isEmpty) return;

      // Get icon for this category
      final IconData icon =
          _typeIconMap[category] ?? Icons.account_balance_outlined;

      // Only show category headers for Accounts tab (not for Mutual Funds tab)
      if (_selectedTabIndex.value == 0) {
        sections.add(const SizedBox(height: 14));

        // Category header
        sections.add(
          Row(
            children: [
              AppText(
                category,
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
            ],
          ),
        );

        // Add spacing after category header
        sections.add(const SizedBox(height: 12));
      } else {
        // For Mutual Funds tab, just add top spacing for first item
        if (sections.isEmpty) {
          sections.add(const SizedBox(height: 14));
        }
      }

      // Add account cards for this category
      for (final account in accounts) {
        final String name = account.fipname;
        final String status = account.fetchstatus;
        final DateTime? dateUpdated = account.balancedatetime;

        sections.add(
          _buildFetchStatusCard(
            icon: icon,
            name: name,
            status: status,
            statusColor: _getStatusColor(status),
            lastFetched: _formatDate(dateUpdated?.toIso8601String()),
            imageUrl: account.imageurl,
            accountType: account.type,
            fipName: account.fipname,
          ),
        );
        sections.add(const SizedBox(height: 12));
      }
    });

    return sections;
  }

  // Helper method to build fetch status cards
  Widget _buildFetchStatusCard({
    required IconData icon,
    required String name,
    required String status,
    required AppTextColorType statusColor,
    required String lastFetched,
    String? imageUrl,
    String? accountType,
    String? fipName,
  }) {
    // Log account card viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.to.logEvent(
        name: AnalyticsEvents.dataFetchStatusAccountCardViewed,
        parameters: {
          AnalyticsParams.accountType: accountType ?? 'unknown',
          AnalyticsParams.accountStatus: status,
          AnalyticsParams.fipName: fipName ?? name,
          AnalyticsParams.lastFetchDate: lastFetched,
          AnalyticsParams.tabSelected:
              _selectedTabIndex.value == 0 ? 'accounts' : 'mutual_funds',
        },
      );
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCardBG,
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  spacing: 10,
                  children: [
                    // Icon(icon, color: AppColors.darkPrimary),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.darkButtonBorder,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkButtonBorder),
                      ),
                      child:
                          imageUrl != null && imageUrl.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl,
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(icon, size: 18);
                                  },
                                ),
                              )
                              : Icon(icon, size: 18),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            name,
                            variant: AppTextVariant.bodyLarge,
                            weight: AppTextWeight.semiBold,
                            colorType: AppTextColorType.primary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          AppText(
                            lastFetched,
                            variant: AppTextVariant.label,
                            weight: AppTextWeight.regular,
                            colorType: AppTextColorType.gray,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppText(
                status.toLowerCase() == 'fetching'
                    ? 'Progress'
                    : _capitalizeFirstLetter(status),
                variant: AppTextVariant.bodySmall,
                weight: AppTextWeight.semiBold,
                colorType: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to show info bottom sheet
  void _showInfoBottomSheet(BuildContext context) {
    AnalyticsService.to.logEvent(
      name: AnalyticsEvents.dataFetchStatusInfoBottomSheetOpened,
      parameters: {AnalyticsParams.screenName: 'finarkein_data_fetch_status'},
    );

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            AnalyticsService.to.logEvent(
              name: AnalyticsEvents.dataFetchStatusInfoBottomSheetClosed,
              parameters: {
                AnalyticsParams.screenName: 'finarkein_data_fetch_status',
              },
            );
            return true;
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 5,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Data Update",
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.bold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AppText(
                      "Your investment data is updated based on the type of account and the data provider's refresh schedule. Here's what you need to know:",
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary by Asset Type
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          "Here’s a quick summary by asset type:",
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bank Deposits
                  _buildInfoSection(
                    title: "Bank Deposits",
                    icon: Icons.account_balance,
                    iconColor: Colors.lightBlue,
                    items: [
                      _buildInfoItem(
                        title: "Savings Accounts: ",
                        desc: "Fetched via Finarkein AA.",
                        subDesc:
                            "May reflect yesterday's balance if not reported by 11:30 AM",
                        subIcon: Icons.access_time,
                        subIconColor: Colors.amber,
                      ),
                      _buildInfoItem(
                        title: "Term Deposits: ",
                        desc: "Fetched via Finarkein AA.",
                        subDesc:
                            "Usually up-to-date unless very recently opened or closed",
                        subIcon: Icons.check_circle,
                        subIconColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Market Investments
                  _buildInfoSection(
                    title: "Market Investments",
                    icon: Icons.show_chart,
                    iconColor: Colors.green,
                    items: [
                      _buildInfoItem(
                        title: "Equities: ",
                        desc: "Fetched via Finarkein AA.",
                        subDesc:
                            "Shown after T+1; today's trades will appear tomorrow",
                        subIcon: Icons.circle,
                        subIconColor: Colors.white,
                      ),
                      _buildInfoItem(
                        title: "ETFs: ",
                        desc: "Fetched via Finarkein AA.",
                        subDesc:
                            "Similar to equities, updates after settlement (T+1)",
                        subIcon: Icons.circle,
                        subIconColor: Colors.white,
                      ),
                      _buildInfoItem(
                        title: "Mutual Funds: ",
                        desc: "Fetched via Finarkein AA / MFC.",
                        subDesc:
                            "NAV is real-time; transactions may take 1-2 days",
                        subIcon: Icons.warning,
                        subIconColor: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Insurance
                  _buildInfoSection(
                    title: "Insurance",
                    icon: Icons.shield_outlined,
                    iconColor: Colors.purpleAccent,
                    items: [
                      _buildInfoItem(
                        title: "Policies: ",
                        desc: "Fetched via Finarkein AA.",
                        subDesc:
                            "Updates may depend on insurer reporting frequency",
                        subIcon: Icons.check_circle,
                        subIconColor: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              AppText(
                title,
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String desc,
    required String subDesc,
    required IconData subIcon,
    required Color subIconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: desc,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      subIcon,
                      color: subIconColor,
                      size: 10,
                    ), // Reduced size to match logic
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        subDesc,
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.secondary,
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
}
