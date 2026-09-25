import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/controllers/account_aggregators/aa_data_fetch_controller.dart';
import 'package:nwt_app/types/account_aggregators/aa_data_fetch_options.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_instructions_screen.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/utils/analytics_drop_off_detector.dart';

class DataFetchDetailsScreen extends StatefulWidget {
  final String? initialCategory;
  const DataFetchDetailsScreen({super.key, this.initialCategory});

  @override
  State<DataFetchDetailsScreen> createState() => _DataFetchDetailsScreenState();
}

class _DataFetchDetailsScreenState extends State<DataFetchDetailsScreen> 
    with DropOffTrackingMixin {
  final controller = Get.find<AaDataFetchController>();
  late final RxString selectedCategory;
  final Map<String, GlobalKey> _categoryKeys = {};
  Worker? _categoryWorker;
  late final ScrollController _scrollController;

  @override
  String get screenName => 'data_fetch_details';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    selectedCategory = (widget.initialCategory ?? "Savings & Deposits").obs;

    // Listen for category changes to scroll into view
    _categoryWorker = ever(selectedCategory, (String category) {
      _scrollToCategory(category);
    });

    // Refresh data when entering the screen
    controller.fetchDataFetchOptions(silent: true);

    // Ensure initial category is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCategory(selectedCategory.value);
    });
  }

  @override
  void dispose() {
    _categoryWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String category) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _categoryKeys[category];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          alignment: 0.5, // Center the item
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            tooltip: 'Back',
            style: IconButton.styleFrom(
              side: BorderSide.none,
              backgroundColor: Colors.transparent,
            ),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: AppText(
          "Linked Accounts",
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        actions: [
          const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
      ),
      body: Obx(() {
        final isLoadingInitial =
            controller.isLoading.value &&
            controller.fetchOptionsData.value == null;
        if (isLoadingInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.fetchOptionsData.value;
        final options = data?.fetchOptions ?? [];

        if (options.isEmpty && !controller.isLoading.value) {
          return RefreshIndicator(
            onRefresh: () => controller.fetchDataFetchOptions(),
            color: AppColors.darkButtonPrimaryBackground,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.folder_open_outlined,
                              size: 80,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppText(
                            "No data providers found",
                            variant: AppTextVariant.headline6,
                            weight: AppTextWeight.semiBold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          AppText(
                            "Your linked accounts and their real-time fetch status will appear here once you've connected them.",
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.secondary,
                            textAlign: TextAlign.center,
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

        final categorizedData = {
          "Savings & Deposits": data?.deposit ?? [],
          "Mutual Funds": data?.mutualFunds ?? [],
          "Equities & ETFs": data?.equitiesEtf ?? [],
          "Insurance": data?.insurance ?? [],
          "NPS": data?.nps ?? [],
          "Others": data?.others ?? [],
        };

        final availableCategories =
            categorizedData.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((e) => e.key)
                .toList();

        // Safety check for selected category
        if (!availableCategories.contains(selectedCategory.value) &&
            availableCategories.isNotEmpty) {
          selectedCategory.value = availableCategories.first;
        }

        final currentOptions = categorizedData[selectedCategory.value] ?? [];

        return RefreshIndicator(
          onRefresh: () => controller.fetchDataFetchOptions(),
          color: AppColors.darkButtonPrimaryBackground,
          child: CustomScrollView(
            key: const PageStorageKey('data_fetch_details_scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (availableCategories.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    availableCategories: availableCategories,
                    selectedCategory: selectedCategory,
                    categoryKeys: _categoryKeys,
                    // We remove onAfterBuild because the 'ever' worker already handles category scroll
                  ),
                ),

              // Global Refresh All button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                    vertical: 12,
                  ),
                  child: Obx(() {
                    final isRefreshing =
                        controller.isRefreshingAll.value;
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isRefreshing
                            ? null
                            : () async {
                                // Track refresh initiation
                                AnalyticsService.to.logEvent(
                                  name: AnalyticsEvents.accountRefreshClicked,
                                  parameters: {
                                    'screen_name': screenName,
                                    'category': selectedCategory.value,
                                    'action_type': selectedCategory.value == 'Mutual Funds' ? 'mf_central' : 'normal_refresh',
                                  },
                                );

                                // Check if on Mutual Funds tab - trigger MF Central flow
                                if (selectedCategory.value == 'Mutual Funds') {
                                  AppLogger.info(
                                    'Refresh All on Mutual Funds tab - triggering MF Central flow',
                                    tag: 'DataFetchDetails',
                                  );
                                  
                                  // Track MF Central initiation
                                  AnalyticsService.to.logEvent(
                                    name: 'mf_central_trigger_initiated',
                                    parameters: {
                                      'screen_name': screenName,
                                      'trigger_source': 'refresh_all_button',
                                    },
                                  );
                                  
                                  // Navigate to MF Central instructions screen
                                  Get.to(
                                    () => const MFCInstructionsScreen(),
                                    transition: Transition.rightToLeft,
                                  );
                                  return;
                                }
                                
                                // For other tabs, do normal refresh
                                try {
                                  await controller.refreshAll();
                                  await controller.fetchDataFetchOptions();
                                  
                                  // Track successful refresh
                                  AnalyticsService.to.logEvent(
                                    name: 'account_refresh_completed',
                                    parameters: {
                                      'screen_name': screenName,
                                      'category': selectedCategory.value,
                                      'success': true,
                                    },
                                  );
                                } catch (e) {
                                  // Track refresh failure
                                  AnalyticsService.to.logEvent(
                                    name: 'account_refresh_failed',
                                    parameters: {
                                      'screen_name': screenName,
                                      'category': selectedCategory.value,
                                      'error': e.toString(),
                                    },
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          isRefreshing
                              ? (selectedCategory.value == 'Mutual Funds'
                                  ? 'Updating mutual funds...'
                                  : 'Refreshing all accounts...')
                              : (selectedCategory.value == 'Mutual Funds'
                                  ? 'Update Mutual Funds'
                                  : 'Refresh All Accounts'),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final option = currentOptions[index];
                    return _buildFipCard(option);
                  }, childCount: currentOptions.length),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAdhocCountCard() {
    return Obx(() {
      final adhocRemaining = controller.manualAdhocRemaining.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    adhocRemaining.toString(),
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                    colorType: AppTextColorType.primary,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    "Refreshes remaining this month",
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    "You can perform on-demand refreshes every month across all your linked accounts to get the latest data.",
                    variant: AppTextVariant.tiny,
                    colorType: AppTextColorType.secondary,
                    weight: AppTextWeight.regular,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildRefreshAction(),
          ],
        ),
      );
    });
  }

  Widget _buildRefreshAction() {
    final adhocRemaining = controller.manualAdhocRemaining.value;
    final isRefreshing = controller.isRefreshingAll.value;
    final seconds = controller.timerSeconds.value;

    if (adhocRemaining <= 0 && !isRefreshing) {
      return const SizedBox.shrink();
    }

    if (isRefreshing) {
      final minutes = seconds ~/ 60;
      final remSeconds = seconds % 60;
      final timeStr = "$minutes:${remSeconds.toString().padLeft(2, '0')}";

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText(
            "Refreshing all accounts",
            variant: AppTextVariant.tiny,
            weight: AppTextWeight.semiBold,
            customColor: AppColors.darkButtonPrimaryBackground,
          ),
          AppText(
            "Estimated: $timeStr",
            variant: AppTextVariant.tiny,
            weight: AppTextWeight.bold,
            customColor: AppColors.darkButtonPrimaryBackground,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.darkButtonPrimaryBackground,
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: 'Refresh all accounts',
      button: true,
      child: GestureDetector(
        onTap: () => controller.refreshAll(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkButtonPrimaryBackground.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const ExcludeSemantics(
            child: Icon(
              Icons.refresh_sharp,
              size: 20,
              color: AppColors.darkButtonPrimaryBackground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFipCard(AaFetchOption option) {
    final statusLabel = _statusLabel(option.status);
    final isMFCentral = option.fipId == 'MF_CENTRAL';
    return Semantics(
      label:
          '${option.fipName}, status: $statusLabel'
          '${(option.unmaskedAccNumber != null && option.unmaskedAccNumber!.isNotEmpty) ? ", account ending ${option.unmaskedAccNumber!}" : (option.maskedAccNumber != null && option.maskedAccNumber!.isNotEmpty ? ", account ${option.maskedAccNumber!}" : "")}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardBG,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkButtonBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: AppText(
                      option.fipName,
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: ExcludeSemantics(
                    child: Center(child: _buildStatusBadge(option.status)),
                  ),
                ),
                // Refresh icon for non-MF Central accounts
                if (!isMFCentral) ...[
                  const SizedBox(width: 8),
                  Obx(() {
                    final isRefreshing =
                        controller.refreshingAccounts[option.id] ?? false;
                    return SizedBox(
                      width: 32,
                      height: 32,
                      child: isRefreshing
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.darkPrimary,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: AppColors.darkPrimary,
                                size: 18,
                              ),
                              onPressed: () => controller.refreshAccount(option.id),
                              tooltip: 'Refresh',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                    );
                  }),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if ((option.unmaskedAccNumber != null &&
                    option.unmaskedAccNumber!.isNotEmpty) ||
                (option.maskedAccNumber != null &&
                    option.maskedAccNumber!.isNotEmpty)) ...[
              ExcludeSemantics(
                child: _buildInfoRow(
                  isMFCentral ? "Folio Number" : "Account Number",
                  (option.unmaskedAccNumber != null &&
                          option.unmaskedAccNumber!.isNotEmpty)
                      ? option.unmaskedAccNumber!
                      : option.maskedAccNumber!,
                ),
              ),
              const SizedBox(height: 8),
            ],
            ExcludeSemantics(
              child: _buildInfoRow(
                "Last Updated",
                _getLastUpdatedText(option),
              ),
            ),
            // Only show refresh/remaining for non-MF Central accounts
            if (!isMFCentral)
              Obx(() {
                final isRefreshing =
                    controller.refreshingAccounts[option.id] ?? false;
                final isPending = [
                  'pending',
                  'fetching',
                  'processing',
                  'in_progress',
                ].contains(option.status.toLowerCase());

                final bool isExhausted =
                    (option.adhocRemainingCount <= 0 ||
                        (option.quota?.canFetch == false)) &&
                    !isRefreshing &&
                    !isPending;

                // Hide "Out of refreshes" message
                if (isExhausted) {
                  return const SizedBox.shrink();
                }

                // Show refreshes remaining for non-exhausted accounts
                if (option.adhocRemainingCount > 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      ExcludeSemantics(
                        child: _buildInfoRow(
                          "Refreshes Remaining",
                          "${option.adhocRemainingCount}",
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        return 'Success';
      case 'failed':
      case 'error':
        return 'Failed';
      case 'fetching':
      case 'pending':
      case 'processing':
      case 'in_progress':
        return 'Pending';
      default:
        return status;
    }
  }

  /// Get last updated text - shows raw string for MF Central, formatted for AA
  String _getLastUpdatedText(AaFetchOption option) {
    // Check if this is MF Central data
    if (option.fipId == 'MF_CENTRAL') {
      // Get raw lastUpdated from controller
      final rawDate = controller.mfCentralLastUpdatedRaw[option.id];
      if (rawDate != null && rawDate.isNotEmpty) {
        return rawDate; // Return as-is: "10 May 2026, 06:09 PM"
      }
      return "Never";
    }
    
    // For AA data, use formatted DateTime
    if (option.lastFetchedTime != null) {
      return DateFormatter.formatToDateTimeWithAmPm(option.lastFetchedTime!);
    }
    return "Never";
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayStatus = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        color = AppColors.success;
        break;
      case 'failed':
      case 'error':
        color = AppColors.error;
        break;
      case 'fetching':
      case 'pending':
      case 'processing':
      case 'in_progress':
        color = Colors.orange;
        if (status.toLowerCase() == 'in_progress') {
          displayStatus = 'PENDING';
        }
        break;
      default:
        color = AppColors.darkTextMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: AppText(
        displayStatus,
        variant: AppTextVariant.tiny,
        weight: AppTextWeight.bold,
        customColor: color,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isId = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppText(
            isId ? value : value,
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.medium,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> availableCategories;
  final RxString selectedCategory;
  final Map<String, GlobalKey> categoryKeys;

  _CategoryHeaderDelegate({
    required this.availableCategories,
    required this.selectedCategory,
    required this.categoryKeys,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.darkBackground,
      padding: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
        vertical: 12,
      ),
      child: SizedBox(
        height: 44,
        child: Builder(
          builder: (context) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableCategories.length,
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                final key = categoryKeys.putIfAbsent(
                  category,
                  () => GlobalKey(debugLabel: 'category_$category'),
                );
                return Obx(() {
                  final isSelected = selectedCategory.value == category;
                  return Container(
                    key: key,
                    child: Semantics(
                      label: category,
                      button: true,
                      selected: isSelected,
                      child: GestureDetector(
                        onTap: () => selectedCategory.value = category,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.darkButtonPrimaryBackground
                                    : AppColors.darkCardBG,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.darkButtonPrimaryBackground
                                      : AppColors.darkButtonBorder,
                            ),
                          ),
                          child: Center(
                            child: ExcludeSemantics(
                              child: AppText(
                                category,
                                variant: AppTextVariant.bodySmall,
                                weight:
                                    isSelected
                                        ? AppTextWeight.semiBold
                                        : AppTextWeight.medium,
                                customColor:
                                    !isSelected
                                        ? Colors.white
                                        : AppColors.darkButtonBorder,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 68;

  @override
  double get minExtent => 68;

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.availableCategories != availableCategories ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.categoryKeys != categoryKeys;
  }
}
