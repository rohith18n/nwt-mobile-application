import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/orders/order_v1_controller.dart';
import 'package:nwt_app/controllers/search/global_search.dart';
import 'package:nwt_app/screens/insights/insights.dart';
import 'package:nwt_app/screens/orders/payment_processing_v1_screen.dart';
import 'package:nwt_app/services/search/search_history.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/services/orders/investment_flow.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  // Tab options
  final List<Map<String, String>> tabOptions = [
    {'name': 'All', 'type': ''},
    {'name': 'Stocks', 'type': 'stocks'},
    {'name': 'Mutual Funds', 'type': 'mutual_fund'},
    {'name': 'ETF', 'type': 'etf'},
    {'name': 'Commodities', 'type': 'commodities'},
  ];

  // Search controller
  final GlobalSearchController _searchController = Get.put(
    GlobalSearchController(),
  );
  final SearchHistoryService _searchHistoryService =
      Get.find<SearchHistoryService>();
  final TextEditingController _textController = TextEditingController();
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString selectedTab = 'All'.obs;

  // Cache for search results to prevent repeated fetches
  final Map<String, dynamic> _searchCache = {};
  final Map<String, dynamic> _trendingCache = {};

  // Debounce for search
  Worker? _debounceWorker;

  @override
  void initState() {
    super.initState();
    selectedTab.value = 'All';
    _setupDebounce();

    // Only fetch trending data if not already cached
    if (!_trendingCache.containsKey('')) {
      _getTrending();
    }
  }

  @override
  void dispose() {
    _debounceWorker?.dispose();
    _textController.dispose();

    // Clear cache when component is disposed to prevent memory leaks
    // Uncomment if you want to clear cache on dispose
    // _searchCache.clear();
    // _trendingCache.clear();

    super.dispose();
  }

  void _setupDebounce() {
    // Create a debounce worker that waits 500ms after typing stops before searching
    _debounceWorker = debounce(_searchQuery, (value) {
      final normalizedValue = value.toString().trim();
      if (normalizedValue.isNotEmpty) {
        _performSearch(normalizedValue);
      } else {
        // Clear search results when query is empty
        _searchController.clearSearchResults();
        _isLoading.value = false;
      }
    }, time: const Duration(milliseconds: 500));
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    final String type =
        selectedTab.value == 'All'
            ? ''
            : tabOptions.firstWhere(
                  (tab) => tab['name'] == selectedTab.value,
                  orElse: () => {'type': ''},
                )['type'] ??
                '';

    // Create a cache key using query and type
    final normalizedQuery = query.trim().toLowerCase();
    final String cacheKey = '${normalizedQuery}_$type';

    // Check if we have cached results for this query and type
    if (_searchCache.containsKey(cacheKey)) {
      // Use cached results
      _searchController.setSearchResultsFromCache(_searchCache[cacheKey]);
      _isLoading.value = false;
      return;
    }

    // Set loading state
    _isLoading.value = true;

    _searchController.search(
      query: query,
      type: type,
      limit: 15,
      onLoading: (isLoading) {
        _isLoading.value = isLoading;
      },
      onSuccess: (results) {
        // Cache the results
        _searchCache[cacheKey] = results;
      },
    );
  }

  void _getTrending() {
    // Get the current tab type
    String type = '';
    if (selectedTab.value != 'All') {
      type =
          tabOptions.firstWhere(
            (tab) => tab['name'] == selectedTab.value,
            orElse: () => {'type': ''},
          )['type'] ??
          '';
    }

    // Check if we have cached trending data for this type
    if (_trendingCache.containsKey(type)) {
      // Use cached trending data
      _searchController.setTrendingFromCache(_trendingCache[type]);
      return;
    }

    // Set loading state
    _isLoading.value = true;

    _searchController.getTrending(
      type: type,
      onLoading: (isLoading) {
        _isLoading.value = isLoading;
      },
      onSuccess: (trendingData) {
        // Cache the trending data
        _trendingCache[type] = trendingData;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow keyboard to push content up
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.darkCardBG,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: const Icon(Icons.chevron_left, size: 32),
                    ),
                  ),
                  suffixIcon: Obx(
                    () =>
                        _searchQuery.value.isNotEmpty
                            ? GestureDetector(
                              onTap: () {
                                _textController.clear();
                                _searchQuery.value = '';
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Icon(
                                  Icons.clear,
                                  color: AppColors.darkTextMuted,
                                  size: 20,
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  fillColor: AppColors.darkCardBG,
                  filled: true,
                  hintText: "Ask Pivot AI or search for Mutual Funds",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  final trimmedValue = value.trim();
                  // Set loading immediately if the query changed significantly
                  if (trimmedValue != _searchQuery.value.trim()) {
                    if (trimmedValue.isNotEmpty) {
                      _isLoading.value = true;
                    } else {
                      _searchController.clearSearchResults();
                    }
                  }
                  _searchQuery.value = value;
                },
              ),
            ),
            const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
            const SizedBox(width: 8),
          ],
        ),
      ),
      backgroundColor: AppColors.darkBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Obx(() => _buildContent()),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the main content based on search state
  Widget _buildContent() {
    if (_searchQuery.value.trim().isNotEmpty) {
      return _buildSearchResults();
    } else if (_searchHistoryService.searchHistory.isNotEmpty) {
      return _buildHistoryAndTrending();
    } else {
      return _buildInitialState();
    }
  }

  /// Builds the initial state when there's no search query and no history
  Widget _buildInitialState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.blue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const AppText(
                "Start searching",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AppText(
                  "Search by name, ISIN, code, AMC...",
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildSuggestionsSection(),
        _buildTrendingItems(),
      ],
    );
  }

  /// Builds the layout when both history and trending are shown
  Widget _buildHistoryAndTrending() {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentSearchesSection(),
        _buildSuggestionsSection(),
        _buildTrendingItems(),
      ],
    );
  }

  /// Builds the recent searches section with header and clear button
  Widget _buildRecentSearchesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      child: Column(
        children: [
          _buildRecentSearchesHeader(),
          const SizedBox(height: 12),
          _buildSearchHistory(),
        ],
      ),
    );
  }

  /// Builds the header row for recent searches
  Widget _buildRecentSearchesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: AppColors.darkTextGray),
            const SizedBox(width: 8),
            AppText(
              "Recent Searches",
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.medium,
              colorType: AppTextColorType.primary,
            ),
          ],
        ),
        _buildClearAllButton(),
      ],
    );
  }

  /// Builds the clear all button
  Widget _buildClearAllButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: _searchHistoryService.clearHistory,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 14,
                color: AppColors.darkTextMuted,
              ),
              const SizedBox(width: 4),
              AppText(
                "Clear All",
                variant: AppTextVariant.bodySmall,
                colorType: AppTextColorType.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the suggestions section
  Widget _buildSuggestionsSection() {
    return GetBuilder<GlobalSearchController>(
      builder: (controller) {
        // Get suggestions from trending data (using suggestion field from API)
        final suggestions = controller.suggestions;

        // Hide entire section if no suggestions
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuggestionsHeader(),
            const SizedBox(height: 12),
            _buildSuggestionsContent(suggestions, 10),
          ],
        );
      },
    );
  }

  /// Builds the suggestions header
  Widget _buildSuggestionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'SUGGESTIONS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[300],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the suggestions content with chips
  Widget _buildSuggestionsContent(List<String> suggestions, int maxItems) {
    // Split items into rows of 4 items each for better layout (same as trending)
    final List<List<String>> rows = [];
    for (int i = 0; i < suggestions.length; i += maxItems) {
      rows.add(
        suggestions.sublist(
          i,
          i + maxItems > suggestions.length ? suggestions.length : i + maxItems,
        ),
      );
    }

    return SizedBox(
      height: rows.length * 60.0, // Dynamic height based on rows
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map((row) => _buildSuggestionsRow(row)).toList(),
        ),
      ),
    );
  }

  /// Builds a row of suggestion chips (similar to trending row)
  Widget _buildSuggestionsRow(List<String> rowItems) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          spacing: 12,
          children:
              rowItems
                  .map((suggestion) => _buildSuggestionChip(suggestion))
                  .toList(),
        ),
      ),
    );
  }

  /// Builds individual suggestion chip
  Widget _buildSuggestionChip(String suggestion) {
    return InkWell(
      onTap: () => _onSuggestionTap(suggestion),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: Colors.blue,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                suggestion,
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles suggestion tap
  void _onSuggestionTap(String suggestion) {
    // Add to search history (suggestions don't have ISIN)
    _searchHistoryService.addStringToHistory(suggestion);

    // Set search query and perform search
    _textController.text = suggestion;
    _searchQuery.value = suggestion;
    _isLoading.value = true; // Set loading immediately
    _performSearch(suggestion);
  }

  // Build individual tab option
  Widget _buildTabOption(String label) {
    return Obx(() {
      final isSelected = selectedTab.value == label;
      return GestureDetector(
        onTap: () {
          // Prevent multiple taps while loading
          if (!_isLoading.value) {
            selectedTab.value = label;
            // If there's a search query, re-fetch results with the new tab type
            if (_searchQuery.value.trim().isNotEmpty) {
              _performSearch(_searchQuery.value);
            } else {
              // If no search query, fetch trending for this type
              _getTrending();
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.transparent
                      : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: AppText(
            label,
            variant: AppTextVariant.bodySmall,
            weight: AppTextWeight.medium,
            colorType:
                isSelected
                    ? AppTextColorType.tertiary
                    : AppTextColorType.primary,
          ),
        ),
      );
    });
  }

  // Build shimmer loading effect for search results
  Widget _buildSearchResultsShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCardBG,
      highlightColor: AppColors.darkInputBackground,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
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
    );
  }

  // Format asset type for display
  String _formatAssetType(String assetType) {
    final lowerType = assetType.toLowerCase();
    switch (lowerType) {
      case 'mutual_fund':
        return 'MF';
      case 'etf':
        return 'ETF';
      case 'equity':
        return 'EQUITY';
      case 'debt':
        return 'DEBT';
      case 'precious metals':
        return 'METAL';
      case 'hybrid':
        return 'HYBRID';
      default:
        return assetType;
    }
  }

  // Method to get initials from asset name
  String _getInitials(String assetName) {
    final words = assetName.trim().split(' ');
    if (words.isEmpty) return 'MF';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return words
        .take(1)
        .map((word) => word.substring(0, 1).toUpperCase())
        .join();
  }

  Widget _buildSearchResults() {
    return GetBuilder<GlobalSearchController>(
      builder: (controller) {
        return Obx(() {
          if (_isLoading.value) {
            return _buildSearchResultsShimmer();
          }

          if (controller.searchResults.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: AppColors.darkTextMuted,
                    ),
                    const SizedBox(height: 16),
                    const AppText(
                      "No results found",
                      variant: AppTextVariant.bodyLarge,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      "Try a different search term or category",
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.muted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.searchResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = controller.searchResults[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final name = result.assetname;
                      final isin = result.isincode;
                      final schemeCode = result.assetguid;
                      final icon = result.icon;
                      final minAmount = result.minimumAmount;

                      _searchHistoryService.addToHistory({
                        "name": name,
                        "isin": isin,
                        "scheme_code": schemeCode,
                        "icon_url": icon,
                        "minimum_amount": minAmount,
                      });

                      if (schemeCode.isNotEmpty) {
                        _navigateToInvest(
                          name: name,
                          isin: isin,
                          schemeCode: schemeCode,
                          icon: icon,
                          minAmount: minAmount,
                        );
                      }
                      /*
                      else if (isin.isNotEmpty) {
                        Get.to(() => InsightsScreen(isincode: isin));
                      }
                      */
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Fund icon/avatar
                          result.icon != null && result.icon!.isNotEmpty
                              ? Avatar(
                                path: result.icon!,
                                width: 40,
                                height: 40,
                                borderRadius: BorderRadius.circular(8),
                                errorWidget: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCardBG,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getInitials(result.assetname),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "Montserrat",
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.darkCardBG,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(result.assetname),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "Montserrat",
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  result.assetname,
                                  variant: AppTextVariant.bodyMedium,
                                  weight: AppTextWeight.medium,
                                  colorType: AppTextColorType.primary,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  _formatAssetType(result.assettype),
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (result.assettype.toLowerCase().contains('mutual'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkButtonPrimaryBackground
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.darkButtonPrimaryBackground
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: AppText(
                                'INVEST',
                                variant: AppTextVariant.caption,
                                weight: AppTextWeight.bold,
                                customColor:
                                    AppColors.darkButtonPrimaryBackground,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistoryService.searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount:
          _searchHistoryService.searchHistory.length > 5
              ? 5
              : _searchHistoryService.searchHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final historyItem = _searchHistoryService.searchHistory[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                AppLogger.info(
                  'History item tapped: ${historyItem.name} (ISIN: ${historyItem.isin})',
                  tag: 'GlobalSearch',
                );
                if (historyItem.hasIsin && historyItem.schemeCode != null) {
                  // Navigate directly to invest screen if ISIN and SchemeCode are available
                  _navigateToInvest(
                    name: historyItem.name,
                    isin: historyItem.isin!,
                    schemeCode: historyItem.schemeCode!,
                    icon: historyItem.iconUrl,
                    minAmount: historyItem.minimumAmount,
                  );
                }
                /*
                else if (historyItem.hasIsin) {
                  // Fallback to insights if only ISIN available
                  Get.to(() => InsightsScreen(isincode: historyItem.isin!));
                } 
                */
                else {
                  // Fallback to search if no ISIN available
                  _textController.text = historyItem.name;
                  _searchQuery.value = historyItem.name;
                  _isLoading.value = true;
                  _performSearch(historyItem.name);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  spacing: 12,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            historyItem.hasIsin
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        historyItem.hasIsin ? Icons.insights : Icons.history,
                        size: 16,
                        color: historyItem.hasIsin ? Colors.blue : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            historyItem.displayName,
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.primary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (historyItem.hasIsin) ...[
                            const SizedBox(height: 2),
                            AppText(
                              'Tap to view insights',
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.muted,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.darkTextMuted,
                      ),
                      onPressed: () {
                        // Remove this specific item from history
                        _searchHistoryService.removeFromHistory(historyItem);
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingItems() {
    return GetBuilder<GlobalSearchController>(
      builder: (controller) {
        // Hide entire section if no trending data
        if (controller.trendingData.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 8),
            _buildTrendingContent(controller.trendingData),
          ],
        );
      },
    );
  }

  /// Builds the trending content with dynamic rows
  Widget _buildTrendingContent(List<dynamic> trendingData) {
    // Split items into rows of 4 items each for better layout
    final List<List<dynamic>> rows = [];
    for (int i = 0; i < trendingData.length; i += 4) {
      rows.add(
        trendingData.sublist(
          i,
          i + 4 > trendingData.length ? trendingData.length : i + 4,
        ),
      );
    }

    return SizedBox(
      height: rows.length * 60.0, // Dynamic height based on rows
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map((row) => _buildTrendingRow(row)).toList(),
        ),
      ),
    );
  }

  Widget _buildTrendingRow(List<dynamic> rowItems) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          spacing: 12,
          children:
              rowItems.map((item) {
                // Handle both TrendingResult objects and Map<String, String>
                String name;
                String type;
                String? isin;
                String? schemeCode;

                if (item is Map<String, String>) {
                  // Static data fallback
                  name = item["name"]!;
                  type = item["type"]!;
                } else {
                  // TrendingResult object from API
                  name = item.assetname;
                  type = item.assettype;
                  isin = item.isin;
                  schemeCode = item.assetguid;
                }

                return _buildTrendingChip(
                  name,
                  type,
                  isin: isin,
                  schemeCode: schemeCode,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'TRENDING SEARCHES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[300],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingChip(
    String name,
    String type, {
    String? isin,
    String? schemeCode,
  }) {
    return InkWell(
      onTap:
          () => _onTrendingItemTap(name, type, isin: isin, schemeCode: schemeCode),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: Colors.green.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                color: Colors.green,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle tap events
  void _onTrendingItemTap(
    String name,
    String type, {
    String? isin,
    String? schemeCode,
  }) {
    // For trending items, we navigate to invest if it's a mutual fund
    if (isin != null &&
        isin.isNotEmpty &&
        type.toLowerCase().contains('mutual')) {
      if (schemeCode != null && schemeCode.isNotEmpty) {
        _navigateToInvest(name: name, isin: isin, schemeCode: schemeCode);
      }
    } else if (isin != null && isin.isNotEmpty) {
      // Get.to(() => InsightsScreen(isincode: isin));
    } else {
      _textController.text = name;
      _searchQuery.value = name;
      _performSearch(name);
    }
  }

  Future<void> _navigateToInvest({
    required String name,
    required String isin,
    required String schemeCode,
    String? icon,
    double? minAmount,
  }) async {
    // Check if a payment is already being processed
    if (Get.isRegistered<OrderV1Controller>()) {
      final orderController = Get.find<OrderV1Controller>();
      if (orderController.isPolling.value &&
          orderController.activeOrderData.value != null) {
        Get.to(
          () => PaymentProcessingV1Screen(
            orderData: orderController.activeOrderData.value!,
            isSip: orderController.activeIsSip.value,
            isRedirected: true,
          ),
          transition: Transition.rightToLeft,
        );
        return;
      }
    }

    // Ensure OrderV1Controller is initialized
    final orderController =
        Get.isRegistered<OrderV1Controller>()
            ? Get.find<OrderV1Controller>()
            : Get.put(OrderV1Controller());

    // Fetch accounts if not already loaded
    if (orderController.accounts.isEmpty &&
        !orderController.isLoadingAccounts.value) {
      await orderController.fetchAccounts();
    }

    // Set first account as default if none selected
    if (orderController.selectedAccount.value == null &&
        orderController.accounts.isNotEmpty) {
      orderController.selectedAccount.value = orderController.accounts.first;
    }

    // Check folios for the selected account
    if (orderController.selectedAccount.value != null && isin.isNotEmpty) {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );
      await orderController.checkFolios(isin);
      Get.back();
    }

    // Start centralized investment journey
    await InvestmentFlow.startInvestmentJourney(
      name: name,
      isin: isin,
      schemeCode: schemeCode,
      fundLogo: icon,
      minAmount: minAmount,
    );
  }
}
