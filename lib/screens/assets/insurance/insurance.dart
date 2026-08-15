import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/data/categories/categories.types.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/storage_keys.dart';
import 'package:nwt_app/controllers/account_aggregators/fip_status_controller.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_router.dart';
import 'package:nwt_app/services/global_storage.dart';
import 'package:nwt_app/screens/assets/insurance/insurance_details.dart';
import 'package:nwt_app/screens/assets/insurance/types/insurance.dart';
import 'package:nwt_app/screens/assets/insurance/widgets/insurance_card.dart';
import 'package:nwt_app/screens/connections/connections.dart';
import 'package:nwt_app/screens/saafe_data_fetch_status/data_fetch_details_screen.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/services/assets/insurance/insurance.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/speak_to_advisor.dart';
import 'package:nwt_app/utils/back_navigation.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/empty_state.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/widgets/common/loading.dart';
import 'package:nwt_app/widgets/status_card_swiper.dart';

class InsuranceListScreen extends StatefulWidget {
  final bool forceStandardApis;
  const InsuranceListScreen({super.key, this.forceStandardApis = false});

  @override
  State<InsuranceListScreen> createState() => _InsuranceListScreenState();
}

final List<Category> categories = [
  Category(id: 'all', name: 'All'),
  Category(id: 'LIFE_INSURANCE', name: 'Life Insurance'),
  Category(id: 'GENERAL_INSURANCE', name: 'General Insurance'),
  Category(id: 'INSURANCE_POLICIES', name: 'Other Insurance'),
];

class _InsuranceListScreenState extends State<InsuranceListScreen> {
  final userController = Get.find<UserController>();
  final _fipStatusController = Get.find<FipStatusController>();
  final TextEditingController _searchController = TextEditingController();

  final RxString _searchQuery = ''.obs;
  bool _isAmountVisible = false;

  // FIP Status polling variables
  Timer? _fipPollingTimer;
  final Duration _fipPollingInterval = const Duration(seconds: 3);
  List<Map<String, dynamic>> _fipAccounts = [];
  Category _selectedCategory = categories.first;

  final InsuranceService _insuranceService = InsuranceService();
  Rx<InsuranceResponse?> insuranceResponse = Rx<InsuranceResponse?>(null);
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _restoreAmountVisibilityState();
    fetchInsuranceSummary();
    _startFipStatusPolling();
  }

  /// Restores amount visibility state from persistent storage
  void _restoreAmountVisibilityState() {
    final savedAmountVisibility =
        StorageService.read(StorageKeys.AMOUNT_VISIBILITY_KEY) ?? false;
    setState(() {
      _isAmountVisible = savedAmountVisibility;
    });
  }

  Future<void> fetchInsuranceSummary() async {
    if (!widget.forceStandardApis) {
      final provider = getAccountAggregatorDataProvider();
      if (provider.getInsurance() != null) {
        isLoading.value = false;
        return;
      }
    }
    final response = await _insuranceService.getInsuranceSummary(
      onLoading: (loading) {
        isLoading.value = loading;
      },
    );
    insuranceResponse.value = response;
  }

  Future<void> _refreshData() async {
    // Refresh insurance data
    await fetchInsuranceSummary();

    // Refresh FIP status
    await _fetchAccountListFromProvider();

    // Restart FIP polling if needed
    if (_shouldStartFipPolling() && _fipPollingTimer == null) {
      _startFipPolling();
    }
  }

  @override
  void dispose() {
    _stopFipStatusPolling();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Semantics(
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
        centerTitle: true,
        title: Semantics(
          header: true,
          child: AppText(
            "Insurance",
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
        ),
        actions: [
          const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.darkPrimary,
          backgroundColor: AppColors.darkCardBG,
          displacement: 20.0,
          strokeWidth: 3.0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.darkButtonBorder),
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Your Coverage",
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.bold,
                                  colorType: AppTextColorType.secondary,
                                ),
                              ],
                            ),
                            Semantics(
                              label: 'Refresh insurance data',
                              button: true,
                              child: GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => const DataFetchDetailsScreen(initialCategory: "Insurance"),
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
                                              AppColors
                                                  .darkButtonPrimaryBackground,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText(
                                          "Refresh",
                                          variant: AppTextVariant.bodySmall,
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

                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(() {
                              final providerInsurance =
                                  getAccountAggregatorDataProvider()
                                      .getInsurance() ??
                                  <Insurance>[];
                              final totalCoverage =
                                  providerInsurance.isNotEmpty
                                      ? providerInsurance.fold<double>(
                                        0,
                                        (s, i) => s + i.sumassured,
                                      )
                                      : (insuranceResponse
                                              .value
                                              ?.data
                                              ?.totalCoverage ??
                                          0);
                              return AnimatedAmount(
                                isLoading: isLoading.value && insuranceResponse.value == null,
                                isAmountVisible: _isAmountVisible,
                                amount: CurrencyFormatter.formatRupee(
                                  totalCoverage,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }),
                            Semantics(
                              label:
                                  _isAmountVisible
                                      ? 'Hide insurance amounts'
                                      : 'Show insurance amounts',
                              button: true,
                              toggled: _isAmountVisible,
                              child: InkWell(
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
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      _isAmountVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color:
                                          AppColors.darkButtonPrimaryBackground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                    vertical: 12,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(245, 200, 66, 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color.fromRGBO(255, 140, 0, 1),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFFD54F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppText(
                              "INSURANCE INFORMATION",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.bold,
                              colorType: AppTextColorType.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    "We get your policy details from your insurance company, but they may not share complete information. If you don't see all your policies here, please ",
                              ),
                              TextSpan(
                                text: 'Contact us',
                                style: TextStyle(
                                  color: AppColors.linkColor,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        SpeakToAdvisor.speakToAdvisor();
                                      },
                                semanticsLabel:
                                    'Contact us, opens advisor chat',
                              ),
                              const TextSpan(
                                text: " with your insurer's name.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: AppColors.darkBackground,
                  child: Obx(
                    () => StatusCardSwiper(
                      lastFetchedTime: _fipStatusController.lastFetchedTime,
                      category: 'Insurance',
                      accounts: _fipStatusController.accounts,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                    vertical: 12,
                  ),
                  child: Obx(
                    () => AppInputField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchQuery.value = value;
                        setState(() {}); // Ensure UI updates on search change
                      },
                      prefix: const Icon(
                        CupertinoIcons.search,
                        color: AppColors.darkTextMuted,
                      ),
                      suffix:
                          _searchQuery.value.isNotEmpty
                              ? Semantics(
                                label: 'Clear search',
                                button: true,
                                child: InkWell(
                                  onTap: () {
                                    _searchController.clear();
                                    _searchQuery.value = '';
                                    setState(
                                      () {},
                                    ); // Ensure UI updates on clear
                                  },
                                  child: const ExcludeSemantics(
                                    child: Icon(
                                      Icons.clear,
                                      color: AppColors.darkTextMuted,
                                    ),
                                  ),
                                ),
                              )
                              : null,
                      hintText: "Search...",
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding,
                    ),
                    itemBuilder: (context, index) {
                      return CategoryChip(
                        label: categories[index].name,
                        isSelected: _selectedCategory == categories[index],
                        onTap: () {
                          setState(() {
                            _selectedCategory = categories[index];
                          });
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(width: 8);
                    },
                    itemCount: categories.length,
                  ),
                ),
                // Insurance list content
                Obx(() {
                  final providerInsurance =
                      widget.forceStandardApis
                          ? <Insurance>[]
                          : (getAccountAggregatorDataProvider()
                                  .getInsurance() ??
                              <Insurance>[]);
                  final useFinarkeinInsurance = providerInsurance.isNotEmpty;
                  if (!useFinarkeinInsurance && isLoading.value) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: const Center(child: LoadingIndicator()),
                    );
                  }

                  final insuranceData = insuranceResponse.value?.data;
                  final items =
                      useFinarkeinInsurance
                          ? providerInsurance
                          : (insuranceData?.items ?? []);

                  final filteredItems =
                      items.where((insurance) {
                        final matchesSearch =
                            _searchQuery.value.isEmpty ||
                            insurance.policyname.toLowerCase().contains(
                              _searchQuery.value.toLowerCase(),
                            ) ||
                            insurance.policynumber.toLowerCase().contains(
                              _searchQuery.value.toLowerCase(),
                            );

                        final matchesCategory =
                            _selectedCategory.id == 'all' ||
                            insurance.type.contains(_selectedCategory.id);

                        return matchesSearch && matchesCategory;
                      }).toList();

                  if (filteredItems.isEmpty) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: EmptyState(
                          icon: Icons.policy_outlined,
                          title: "No insurance policies found",
                          subtitle:
                              "We couldn't find any insurance policies matching your criteria",
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        ...filteredItems.map(
                          (insurance) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Semantics(
                              label:
                                  '${insurance.policyname.isNotEmpty ? insurance.policyname : (insurance.subcategory ?? 'Insurance policy')}, Policy number ${insurance.policynumber}, Sum assured ${CurrencyFormatter.formatRupee(insurance.sumassured)}',
                              button: true,
                              hint: 'Double tap to view policy details',
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to details screen with insurance data
                                  Get.to(
                                    () => InsuranceDetailsScreen(
                                      accountguid: insurance.accountguid,
                                      companyLogo: 'assets/app/pivot.money.png',
                                      policyName: insurance.policyname,
                                      policyNumber: insurance.policynumber,
                                      sumAssured: insurance.sumassured,
                                      policyType: insurance.type,
                                      subcategory: insurance.subcategory,
                                      insuranceData:
                                          insurance, // Pass the full insurance data
                                    ),
                                  );
                                },
                                child: ExcludeSemantics(
                                  child: InsuranceCard(
                                    companyLogo: 'assets/app/pivot.money.png',
                                    policyName: insurance.policyname,
                                    policyNumber: insurance.policynumber,
                                    amount: insurance.sumassured,
                                    isAmountVisible: _isAmountVisible,
                                    subcategory: insurance.subcategory,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          (userController.userData?.istestaccount ?? false) == false
              ? Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                ),
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: "Add Insurance",
                    onPressed: () {
                      //    Get.to(() => ConnectionsScreen());
                      AccountAggregatorRouter().openConnection(context);
                    },
                  ),
                ),
              )
              : null,
    );
  }
}
