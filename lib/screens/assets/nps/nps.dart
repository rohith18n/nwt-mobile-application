import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/account_aggregators/fip_status_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/assets/nps/types/nps.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/data_fetch_details_screen.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/account_aggregators/raw_asset_service.dart';
import 'package:nwt_app/services/assets/nps/nps.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/widgets/status_card_swiper.dart';
import 'package:nwt_app/widgets/common/loading_widget.dart';

class NPSScreen extends StatefulWidget {
  final bool forceStandardApis;
  const NPSScreen({super.key, this.forceStandardApis = false});

  @override
  State<NPSScreen> createState() => _NPSScreenState();
}

class _NPSScreenState extends State<NPSScreen> {
  final _fipStatusController = Get.find<FipStatusController>();
  bool _isAmountVisible = false;
  int _selectedTierIndex = 0; // 0 means Tier 1 is selected by default
  bool _isLoading = false;
  NpsRespone? _npsData;

  // FIP Status polling variables
  Timer? _fipPollingTimer;
  final Duration _fipPollingInterval = const Duration(seconds: 3);
  List<Map<String, dynamic>> _fipAccounts = [];

  @override
  void initState() {
    super.initState();
    // Restore amount visibility state from storage
    _restoreAmountVisibilityState();
    _fetchNPSData();
    _startFipStatusPolling();
  }

  Future<void> _fetchNPSData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!widget.forceStandardApis) {
        // Use RawAssetService to get NPS data with transactions
        final rawAssetService = RawAssetService();
        final npsRows = await rawAssetService.getAllNPS();

        if (npsRows.isNotEmpty) {
          final synthetic = _npsDataFromStoreRows(npsRows);
          if (mounted)
            setState(() {
              _npsData = synthetic;
              _isLoading = false;
            });
          return;
        }
      }
    } catch (e) {
      print('Error fetching NPS from RawAssetService: $e');
    }

    if (!widget.forceStandardApis) {
      // Fallback to old method if RawAssetService fails
      final provider = getAccountAggregatorDataProvider();
      final npsRows = provider.getNpsRows();
      if (npsRows != null && npsRows.isNotEmpty) {
        final synthetic = _npsDataFromStoreRows(npsRows);
        if (mounted)
          setState(() {
            _npsData = synthetic;
            _isLoading = false;
          });
        return;
      }
    }

    final npsService = NPSService();
    final response = await npsService.getNPSData(
      onLoading: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _npsData = response;
      });
    }
  }

  /// Build minimal NpsRespone from Finarkein data/result nps rows for display.
  NpsRespone _npsDataFromStoreRows(List<Map<String, dynamic>> rows) {
    final funds =
        rows.map((row) {
          final value =
              double.tryParse(
                (row['value'] ??
                        row['currentValue'] ??
                        row['currentvalue'] ??
                        '0')
                    .toString(),
              ) ??
              0.0;
          final units =
              double.tryParse(
                (row['totalunits'] ?? row['units'] ?? row['quantity'] ?? '0')
                    .toString(),
              ) ??
              0.0;
          final nav = double.tryParse((row['nav'] ?? '1').toString()) ?? 1.0;
          return Fund(
            schemename:
                (row['schemename'] ??
                        row['issuerName'] ??
                        row['issuer_name'] ??
                        'NPS')
                    .toString(),
            units: units,
            nav: nav,
            value: value,
            deltapercentage:
                double.tryParse((row['deltapercentage'] ?? '0').toString()) ??
                0.0,
            deltavalue:
                double.tryParse((row['deltavalue'] ?? '0').toString()) ?? 0.0,
          );
        }).toList();
    final totalholdings = funds.fold<double>(0, (s, f) => s + f.value);
    final tier1 = Tier(value: totalholdings, schemetype: 'NPS', funds: funds);
    final tier2 = Tier(value: 0, schemetype: null, funds: []);
    final data = NPSData(
      totalholdings: totalholdings,
      tier1: tier1,
      tier2: tier2,
      profiles: [],
    );
    return NpsRespone(statusCode: 200, message: 'OK', data: data);
  }

  @override
  void dispose() {
    _stopFipStatusPolling();
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

  void _startFipStatusPolling() async {
    if (widget.forceStandardApis) return;
    final provider = getAccountAggregatorDataProvider();
    if (!provider.shouldPollAccountStatus()) return;
    await _fetchAccountListFromProvider();
    _startFipPolling();
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
    return _fipAccounts.any((account) => account['fetchstatus'] == 'FETCHING');
  }

  Future<void> _fetchAccountListFromProvider() async {
    try {
      final provider = getAccountAggregatorDataProvider();
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
        if (_shouldStartFipPolling() && _fipPollingTimer == null) {
          _startFipPolling();
        } else if (!_shouldStartFipPolling() && _fipPollingTimer != null) {
          _stopFipStatusPolling();
        }
      }
    } catch (e) {
      dev.log('Error fetching account list: $e');
    }
  }

  final userController = Get.find<UserController>();

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
            Semantics(
              header: true,
              child: AppText(
                "NPS",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
            Row(
              children: [
                const WhatsAppSupportButton(
                  size: 20,
                  color: AppColors.darkPrimary,
                ),
                Semantics(
                  label: 'NPS information',
                  hint: 'Opens NPS terms glossary',
                  button: true,
                  child: GestureDetector(
                    onTap: () => _showInfoBottomSheet(context),
                    child: const ExcludeSemantics(
                      child: Icon(Icons.info_outline_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            children: [
              // Holdings summary card - fixed at top
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "Your Holdings",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.bold,
                          colorType: AppTextColorType.secondary,
                        ),
                        Semantics(
                          label: 'Refresh NPS data',
                          button: true,
                          child: GestureDetector(
                            onTap: () {
                              Get.to(
                                () => const DataFetchDetailsScreen(initialCategory: "NPS"),
                                transition: Transition.rightToLeft,
                              );
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
                                      Icons.refresh,
                                      size: 14,
                                      color:
                                          AppColors.darkButtonPrimaryBackground,
                                    ),
                                    const SizedBox(width: 4),
                                    AppText(
                                      "Refresh",
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedAmount(
                              isLoading: _isLoading && _npsData == null,
                              isAmountVisible: _isAmountVisible,
                              amount: CurrencyFormatter.formatRupee(
                                _npsData?.data?.totalholdings ?? 0,
                              ),
                              style: TextStyle(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkPrimary,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            // Delta value indicator
                          ],
                        ),
                        Semantics(
                          label:
                              _isAmountVisible
                                  ? 'Hide NPS amounts'
                                  : 'Show NPS amounts',
                          button: true,
                          toggled: _isAmountVisible,
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
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    color:
                                        _isAmountVisible
                                            ? AppColors.darkPrimary
                                            : AppColors.darkTextMuted,
                                    size: 22.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tier selection row - fixed below holdings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Only show Tier 1 if scheme type is not empty
                  if (_npsData != null &&
                      _npsData!.data != null &&
                      _npsData!.data!.tier1.schemetype != null &&
                      _npsData!.data!.tier1.schemetype!.isNotEmpty)
                    _buildTierContainer(
                      index: 0,
                      title: 'Tier 1',
                      subtitle: _npsData!.data!.tier1.schemetype!
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map(
                            (word) =>
                                word.isNotEmpty
                                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                    : '',
                          )
                          .join(' '),
                      amount: _npsData!.data!.tier1.value,
                    ),

                  // Add spacing only if both tiers are shown
                  if (_npsData != null &&
                      _npsData!.data != null &&
                      _npsData!.data!.tier1.schemetype != null &&
                      _npsData!.data!.tier1.schemetype!.isNotEmpty &&
                      _npsData!.data!.tier2.schemetype != null &&
                      _npsData!.data!.tier2.schemetype!.isNotEmpty)
                    const SizedBox(width: 12),

                  // Only show Tier 2 if scheme type is not empty
                  if (_npsData != null &&
                      _npsData!.data != null &&
                      _npsData!.data!.tier2.schemetype != null &&
                      _npsData!.data!.tier2.schemetype!.isNotEmpty)
                    _buildTierContainer(
                      index: 1,
                      title: 'Tier 2',
                      subtitle: _npsData!.data!.tier2.schemetype!
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map(
                            (word) =>
                                word.isNotEmpty
                                    ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                    : '',
                          )
                          .join(' '),
                      amount: _npsData!.data!.tier2.value,
                    ),
                ],
              ),

              Container(
                color: AppColors.darkBackground,
                width: double.infinity,
                child: Obx(
                  () => StatusCardSwiper(
                    lastFetchedTime: _fipStatusController.lastFetchedTime,
                    category: 'NPS',
                    horizontalPadding: 0,
                    accounts: _fipStatusController.accounts,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              CustomAccordion(
                title: "Nominee Registered Details",
                backgroundColor: AppColors.darkCardBG,
                borderRadius: 15,
                child: Column(
                  spacing: 12,
                  children: [
                    // Nominee Registered Details Section
                    if (_isLoading && _npsData == null)
                      // Initial loading UI for nominee section
                      Container(
                        padding: EdgeInsets.all(16.w),
                        height: 100.h,
                        child: const Center(
                          child: LoadingWidget(size: 40),
                        ),
                      )
                    else if (_npsData?.data?.profiles != null &&
                        _npsData!.data!.profiles.isNotEmpty)
                      ..._npsData!.data!.profiles.map((profile) {
                        final isNomineeRegistered =
                            profile.nominee == "REGISTERED";

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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // NPS Icon (decorative)
                              ExcludeSemantics(
                                child: Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),

                              // NPS Details
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      profile.fipname,
                                      variant: AppTextVariant.bodyMedium,
                                      weight: AppTextWeight.semiBold,
                                    ),
                                    SizedBox(height: 0.h),
                                    AppText(
                                      "NPS Account",
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.secondary,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  AppText(
                                    "Nominee: ",
                                    variant: AppTextVariant.bodySmall,
                                    colorType: AppTextColorType.secondary,
                                  ),
                                  AppText(
                                    isNomineeRegistered ? "Yes" : "No",
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
                      })
                    else
                      // No profiles found UI
                      Container(
                        padding: EdgeInsets.all(16.w),
                        child: Center(
                          child: AppText(
                            "No NPS profiles found",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                          ),
                        ),
                      ),

                    // Info message
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.darkPrimary.withValues(alpha: 0.3),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Go ahead and register a nominee if you haven't.",
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.primary,
                                ),
                                SizedBox(height: 4.h),
                                Semantics(
                                  label:
                                      'Speak to our advisor for NPS nominee registration help',
                                  link: true,
                                  child: GestureDetector(
                                    onTap: () {
                                      SpeakToAdvisor.speakToAdvisor();
                                    },
                                    child: ExcludeSemantics(
                                      child: AppText(
                                        "Speak to our advisor if you need help",
                                        variant: AppTextVariant.bodySmall,
                                        colorType: AppTextColorType.link,
                                        weight: AppTextWeight.semiBold,
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

              const SizedBox(height: 8),

              // Scrollable content area
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: LoadingWidget(),
                          ),
                        )
                        : _npsData == null
                        ? _buildNoNPSFoundMessage()
                        : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tier 1 Funds
                              if (_selectedTierIndex == 0) ...[
                                ..._npsData!.data!.tier1.funds.map(
                                  (fund) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _NPSCard(
                                      fund: fund,
                                      onTap: () {
                                        // Handle tap on pension fund card
                                        debugPrint(
                                          'Tapped on ${fund.schemename}',
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],

                              // Tier 2 Funds
                              if (_selectedTierIndex == 1) ...[
                                ..._npsData!.data!.tier2.funds.map(
                                  (fund) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _NPSCard(
                                      fund: fund,
                                      onTap: () {
                                        // Handle tap on pension fund card
                                        debugPrint(
                                          'Tapped on ${fund.schemename}',
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              // Add bottom padding for better scrolling experience
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar:
      //     (userController.userData?.istestaccount ?? false) == false
      //         ? Container(
      //           width: double.infinity,
      //           padding: const EdgeInsets.symmetric(
      //             horizontal: AppSizing.scaffoldHorizontalPadding,
      //           ),
      //           margin: EdgeInsets.only(
      //             bottom: MediaQuery.of(context).padding.bottom + 16,
      //           ),
      //           child: Row(
      //             children: [
      //               Expanded(
      //                 child: AppButton(
      //                   text: 'Track NPS',
      //                   variant: AppButtonVariant.primary,
      //                   size: AppButtonSize.large,
      //                   isLoading: false,
      //                   onPressed: () {},
      //                 ),
      //               ),
      //             ],
      //           ),
      //         )
      //         : null,
    );
  }

  /// Helper method to build consistent text displays
  Widget _buildInfoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Montserrat'),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.darkPrimary,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.darkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build delta indicator
  Widget _buildDeltaIndicator(double deltaValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            deltaValue >= 0
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText(
        deltaValue >= 0
            ? "+ ${deltaValue.abs().toStringAsFixed(1)}%"
            : "- ${deltaValue.abs().toStringAsFixed(1)}%",
        variant: AppTextVariant.bodySmall,
        weight: AppTextWeight.medium,
        colorType:
            deltaValue >= 0 ? AppTextColorType.success : AppTextColorType.error,
      ),
    );
  }

  /// A private widget to display pension fund information within the NPS screen
  Widget _NPSCard({required Fund fund, VoidCallback? onTap}) {
    return Semantics(
      label:
          '${fund.schemename}, value ${CurrencyFormatter.formatRupee(fund.value)}, ${fund.units} units at NAV ${fund.nav}',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkInputBorder),
          ),
          width: double.infinity,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  fund.schemename,
                  variant: AppTextVariant.bodyLarge,
                  weight: AppTextWeight.medium,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildInfoText('Units', fund.units.toString()),
                          _buildInfoText('NAV', fund.nav.toString()),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildInfoText(
                            'Value',
                            CurrencyFormatter.formatRupee(fund.value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierContainer({
    required int index,
    required String title,
    required String subtitle,
    required num amount,
  }) {
    final bool isSelected = _selectedTierIndex == index;

    // Define colors based on selection state
    final backgroundColor =
        isSelected ? AppColors.darkPrimary : AppColors.darkCardBG;
    final borderColor =
        isSelected ? AppColors.darkPrimary : AppColors.darkButtonBorder;
    final shadowColor =
        isSelected
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.2);

    return Expanded(
      child: Semantics(
        label:
            '$title, ${CurrencyFormatter.formatRupee(amount)}${subtitle.isNotEmpty && subtitle.toUpperCase() != 'NA' ? ', $subtitle' : ''}',
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (!isSelected) {
                _selectedTierIndex = index;
              }
            });
          },
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        title,
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.semiBold,
                        colorType:
                            isSelected
                                ? AppTextColorType.black
                                : AppTextColorType.primary,
                      ),
                      // Only show the subtitle container if it's not 'NA'
                      if (subtitle.isNotEmpty && subtitle.toUpperCase() != 'NA')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.darkButtonBorder.withOpacity(
                                      0.5,
                                    ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppText(
                            subtitle,
                            variant: AppTextVariant.tiny,
                            weight: AppTextWeight.semiBold,
                            colorType:
                                isSelected
                                    ? AppTextColorType.black
                                    : AppTextColorType.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    CurrencyFormatter.formatRupee(amount),
                    variant: AppTextVariant.headline3,
                    weight: AppTextWeight.bold,
                    colorType:
                        isSelected
                            ? AppTextColorType.black
                            : AppTextColorType.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a message to display when no NPS data is found
  Widget _buildNoNPSFoundMessage() {
    // Use LayoutBuilder to get the available height
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // Take the full available height
          height: constraints.maxHeight,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppColors.darkTextMuted,
                  ),
                ),
                const SizedBox(height: 16),
                AppText(
                  'No NPS found',
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: AppText(
                    'You don\'t have any NPS accounts linked yet.',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "NPS Terms",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  const SizedBox(height: 12),
                  _buildNPSTermCard(
                    title: "Moderate",
                    description:
                        'The Moderate option in NPS is a Life Cycle Fund with a 50% equity cap until age 35, which decreases with age.',
                  ),
                  _buildNPSTermCard(
                    title: "Conservative",
                    description:
                        'The Conservative caps equity at 25% until age 35, then reduces it to 5% by age 55, prioritizing safer investments like bonds.',
                  ),
                  _buildNPSTermCard(
                    title: "Aggressive",
                    description:
                        'The Aggressive NPS option invests 75% in equity until age 35, then reduces equity by 4% each year, moving to safer assets like bonds.',
                  ),
                  _buildNPSTermCard(
                    title: "Corporate",
                    description:
                        'Corporate NPS is tailored for employer-employee collaboration, offering joint contributions and tax benefits.',
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Helper method to build NPS term cards with consistent styling
  Widget _buildNPSTermCard({
    required String title,
    required String description,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          AppText(
            title,
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.bold,
          ),
          AppText(
            description,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.regular,
          ),
        ],
      ),
    );
  }
}
