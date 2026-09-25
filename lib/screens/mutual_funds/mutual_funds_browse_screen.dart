import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/mutual_funds/mf_browse_controller.dart';
import 'package:nwt_app/services/mutual_funds/mf_browse_service.dart';
import 'package:nwt_app/services/profile/investment_readiness_service.dart';
import 'package:nwt_app/services/auth/profile_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/widgets/common/custom_snackbar.dart';
import 'package:nwt_app/screens/bse_v2_final/bse_v2_final_journey.dart';
import 'package:nwt_app/screens/orders/create_order_v1_screen.dart';
import 'package:nwt_app/services/orders/investment_flow.dart';

class MutualFundsBrowseScreen extends StatefulWidget {
  const MutualFundsBrowseScreen({super.key});

  @override
  State<MutualFundsBrowseScreen> createState() =>
      _MutualFundsBrowseScreenState();
}

class _MutualFundsBrowseScreenState extends State<MutualFundsBrowseScreen> {
  final MFBrowseService _service = MFBrowseService();
  final InvestmentReadinessService _readinessService =
      InvestmentReadinessService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  // Filter state
  String? _selectedPlanType;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedSchemeOption;
  int? _selectedBudget;
  bool _showFilters = false;

  // Temporary filter state for buttons
  String? _tempPlanType;
  String? _tempCategory;
  String? _tempSubCategory;
  String? _tempSchemeOption;
  int? _tempBudget;

  // Data state
  List<dynamic> _schemes = [];
  Map<String, dynamic>? _filterOptions;
  bool _isLoading = false;
  bool _isPaginating = false;
  int _currentPage = 0;
  bool _hasMore = false;
  int? _totalCount;

  // Concurrency and memoization to prevent duplicate calls
  bool _isFetching = false;
  String? _lastRequestKey;

  final int _pageSize = 30;
  final ScrollController _scrollController = ScrollController();
  int _requestSequence = 0;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _loadSchemes(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isPaginating) {
        _loadMore();
      }
    }
  }

  Future<void> _loadFilterOptions() async {
    // Try to get from controller first
    if (Get.isRegistered<MFBrowseController>()) {
      final controller = Get.find<MFBrowseController>();
      if (controller.filterOptions.isNotEmpty) {
        if (mounted) {
          setState(() {
            _filterOptions = controller.filterOptions;
          });
        }
        return;
      }
    }

    // Fallback if controller is not ready or empty
    final result = await _service.fetchMutualFundsBrowseFilterOptions();
    if (result != null && result['success'] == true) {
      if (mounted) {
        setState(() {
          _filterOptions = result['data'];
        });
      }
      // Sync back to controller if it exists
      if (Get.isRegistered<MFBrowseController>()) {
        Get.find<MFBrowseController>().filterOptions.value =
            result['data'] ?? {};
      }
    }
  }

  Future<void> _loadSchemes({bool reset = false}) async {
    if (reset) {
      // 🚀 PERFORMANCE OPTIMIZATION: Check if data is already pre-fetched in the controller
      if (_searchController.text.isEmpty &&
          _selectedPlanType == null &&
          _selectedCategory == null &&
          _selectedSubCategory == null &&
          _selectedSchemeOption == null &&
          _selectedBudget == null) {
        if (Get.isRegistered<MFBrowseController>()) {
          final controller = Get.find<MFBrowseController>();
          if (controller.initialSchemes.isNotEmpty) {
            if (mounted) {
              setState(() {
                _schemes = List.from(controller.initialSchemes);
                _totalCount = controller.totalCount.value;
                _hasMore = controller.initialSchemes.length >= _pageSize;
                _currentPage = 0;
                _isLoading = false;
              });
            }
            AppLogger.info(
              '🚀 Using pre-fetched MF schemes from controller',
              tag: 'MutualFundsBrowse',
            );
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = true;
          _currentPage = 0;
          _schemes = [];
        });
      }
    }

    // 🚀 DUPLICATE CALL PREVENTION
    // Create a unique key for the current request parameters
    final currentRequestKey =
        '${_searchController.text.trim()}|$_selectedPlanType|$_selectedCategory|$_selectedSubCategory|$_selectedSchemeOption|$_selectedBudget|$_currentPage';

    // If we are already fetching this exact data, skip
    if (reset && _lastRequestKey == currentRequestKey) {
      AppLogger.info(
        '🚫 Skipping redundant fetch for: $currentRequestKey',
        tag: 'MutualFundsBrowse',
      );
      return;
    }

    // For pagination, we skip if already fetching
    if (!reset && _isFetching) {
      AppLogger.info(
        '⏳ Already fetching next page, skipping...',
        tag: 'MutualFundsBrowse',
      );
      return;
    }

    _isFetching = true;
    _lastRequestKey = currentRequestKey;
    final int thisRequestId = ++_requestSequence;

    if (_searchController.text.trim().isNotEmpty) {
      AppLogger.info(
        '🔍 Searching for: "${_searchController.text.trim()}"',
        tag: 'MutualFundsBrowse',
      );
    }

    dynamic result;
    try {
      result = await _service.fetchSchemes(
        start: _currentPage * _pageSize,
        length: _pageSize,
        query: _searchController.text.trim(),
        planType: _selectedPlanType,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        schemeOption: _selectedSchemeOption,
        budget: _selectedBudget,
        includeTotal: _currentPage == 0,
      );

      // Consider success if explicitly true OR if we received valid data
      final bool isSuccess =
          result != null &&
          (result['success'] == true || result['data'] != null);

      if (isSuccess) {
        // 🚀 LATEST REQUEST VALIDATION
        // Only update state if this is the result of the MOST RECENT request
        if (thisRequestId != _requestSequence) {
          AppLogger.info(
            '🗑️ Discarding stale response for request $thisRequestId (Latest is $_requestSequence)',
            tag: 'MutualFundsBrowse',
          );
          return;
        }

        final data = result['data'];
        if (mounted) {
          setState(() {
            if (reset) {
              _schemes = data['schemes'] ?? [];
            } else {
              _schemes.addAll(data['schemes'] ?? []);
            }
            _hasMore = data['has_more'] ?? false;
            if (data['total_count'] != null) {
              _totalCount = data['total_count'];
            }
            _isLoading = false;
            _isPaginating = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isPaginating = false;
          });
          AppSnackBar.showError(context, 'Failed to load mutual funds');
        }
      }
    } catch (e) {
      AppLogger.error(
        '❌ Error loading schemes',
        error: e,
        tag: 'MutualFundsBrowse',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPaginating = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _loadMore() async {
    if (mounted) {
      setState(() {
        _isPaginating = true;
        _currentPage++;
      });
    }
    await _loadSchemes();
  }

  void _applyFilters() {
    if (mounted) {
      setState(() {
        _selectedPlanType = _tempPlanType;
        _selectedCategory = _tempCategory;
        _selectedSubCategory = _tempSubCategory;
        _selectedSchemeOption = _tempSchemeOption;
        _selectedBudget = _tempBudget;
        _showFilters = false; // Close filter section after applying
      });
    }
    _loadSchemes(reset: true);
  }

  void _clearFilters() {
    if (mounted) {
      setState(() {
        _selectedPlanType = null;
        _selectedCategory = null;
        _selectedSubCategory = null;
        _selectedSchemeOption = null;
        _selectedBudget = null;

        _tempPlanType = null;
        _tempCategory = null;
        _tempSubCategory = null;
        _tempSchemeOption = null;
        _tempBudget = null;

        _searchController.clear();
        _showFilters = false;
      });
    }
    _loadSchemes(reset: true);
  }

  /// Resets only temporary selections (does not apply or close)
  void _resetTempFilters() {
    if (mounted) {
      setState(() {
        _tempPlanType = null;
        _tempCategory = null;
        _tempSubCategory = null;
        _tempSchemeOption = null;
        _tempBudget = null;
      });
    }
  }

  /// Syncs temporary state with active state (called when opening filters)
  void _syncTempFilters() {
    setState(() {
      _tempPlanType = _selectedPlanType;
      _tempCategory = _selectedCategory;
      _tempSubCategory = _selectedSubCategory;
      _tempSchemeOption = _selectedSchemeOption;
      _tempBudget = _selectedBudget;
    });
  }

  /// Smart invest handler - checks if user can skip onboarding steps
  Future<void> _handleInvestTap(Map<String, dynamic> scheme) async {
    await InvestmentFlow.startInvestmentJourney(
      name: scheme['name'] ?? '',
      isin: scheme['scheme_isin'] ?? '',
      schemeCode: scheme['scheme_code'] ?? '',
      nav: scheme['current_nav']?.toDouble(),
      minAmount: scheme['minimum_amount']?.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.darkBackground,
              elevation: 0,
              floating: true,
              pinned: false,
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              title: Semantics(
                header: true,
                child: const AppText(
                  'All Mutual Funds',
                  variant: AppTextVariant.headline5,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
              ),
              actions: [
                const WhatsAppSupportButton(size: 20, color: Colors.white),
              ],
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(
                  AppSizing.scaffoldHorizontalPadding,
                ),
                child: Semantics(
                  textField: true,
                  label: 'Search mutual funds',
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or AMC name',
                      hintStyle: TextStyle(color: AppColors.darkTextSecondary),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.darkTextSecondary,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                tooltip: 'Clear search',
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.darkTextSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadSchemes(reset: true);
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: AppColors.darkCardBG,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.darkButtonBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.darkButtonBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.darkButtonPrimaryBackground,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      // Immediate build to update clear icon visibility
                      setState(() {});

                      // Debounce search to avoid overwhelming the API
                      _searchTimer?.cancel();
                      _searchTimer = Timer(
                        const Duration(milliseconds: 500),
                        () {
                          _loadSchemes(reset: true);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Filter toggle button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                  vertical: 8,
                ),
                child: Semantics(
                  button: true,
                  label:
                      _showFilters
                          ? 'Hide Filters (Expanded)'
                          : 'Show Filters (Collapsed)',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFilters = !_showFilters;
                        if (_showFilters) {
                          _syncTempFilters();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _showFilters
                                ? AppColors.darkButtonPrimaryBackground
                                    .withOpacity(0.1)
                                : AppColors.darkCardBG,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _showFilters
                                  ? AppColors.darkButtonPrimaryBackground
                                  : AppColors.darkButtonBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.tune,
                                  color:
                                      _showFilters
                                          ? AppColors
                                              .darkButtonPrimaryBackground
                                          : Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppText(
                                _showFilters ? 'Hide Filters' : 'Show Filters',
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.medium,
                                customColor:
                                    _showFilters
                                        ? AppColors.darkButtonPrimaryBackground
                                        : Colors.white,
                              ),
                              if (_hasActiveFilters() && !_showFilters) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.darkButtonPrimaryBackground,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: AppText(
                                    _getActiveFilterCount().toString(),
                                    variant: AppTextVariant.caption,
                                    weight: AppTextWeight.bold,
                                    customColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          ExcludeSemantics(
                            child: Icon(
                              _showFilters
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color:
                                  _showFilters
                                      ? AppColors.darkButtonPrimaryBackground
                                      : AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Tax Residency Info Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonPrimaryBackground.withOpacity(
                      0.05,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.darkButtonPrimaryBackground.withOpacity(
                        0.2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.darkButtonPrimaryBackground,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: AppText(
                          'Mutual Funds available for you, tailored for your tax residency.',
                          variant: AppTextVariant.bodySmall,
                          customColor: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Filters section
            if (_showFilters) SliverToBoxAdapter(child: _buildFiltersSection()),

            // Results count
            if (_totalCount != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        'Total funds: $_totalCount',
                        variant: AppTextVariant.bodySmall,
                        colorType: AppTextColorType.secondary,
                      ),
                      if (_hasActiveFilters())
                        TextButton(
                          onPressed: _clearFilters,
                          child: const AppText(
                            'Clear all',
                            variant: AppTextVariant.bodySmall,
                            customColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Schemes list
            _isLoading
                ? _buildLoadingState()
                : _schemes.isEmpty
                ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
                : _buildSchemesList(),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedPlanType != null ||
        _selectedCategory != null ||
        _selectedSubCategory != null ||
        _selectedSchemeOption != null ||
        _selectedBudget != null ||
        _searchController.text.isNotEmpty;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedPlanType != null) count++;
    if (_selectedCategory != null) count++;
    if (_selectedSubCategory != null) count++;
    if (_selectedSchemeOption != null) count++;
    if (_selectedBudget != null) count++;
    return count;
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Type
          Semantics(
            header: true,
            child: const AppText(
              'PLAN TYPE',
              variant: AppTextVariant.caption,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All Plans', null, _tempPlanType, (val) {
                setState(() => _tempPlanType = val);
              }),
              _buildFilterChip('Direct', 'direct', _tempPlanType, (val) {
                setState(() => _tempPlanType = val);
              }),
              _buildFilterChip('Regular', 'regular', _tempPlanType, (val) {
                setState(() => _tempPlanType = val);
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Category
          Semantics(
            header: true,
            child: const AppText(
              'CATEGORY',
              variant: AppTextVariant.caption,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', null, _tempCategory, (val) {
                setState(() {
                  _tempCategory = val;
                  _tempSubCategory = null; // Reset sub-category
                });
              }),
              ...(_filterOptions?['categories'] as List<dynamic>? ?? [])
                  .map<Widget>((cat) {
                    return _buildFilterChip(
                      cat.toString(),
                      cat.toString(),
                      _tempCategory,
                      (val) {
                        setState(() {
                          _tempCategory = val;
                          _tempSubCategory = null;
                        });
                      },
                    );
                  }),
            ],
          ),
          const SizedBox(height: 16),

          // Scheme Option
          Semantics(
            header: true,
            child: const AppText(
              'SCHEME OPTION',
              variant: AppTextVariant.caption,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', null, _tempSchemeOption, (val) {
                setState(() => _tempSchemeOption = val);
              }),
              _buildFilterChip('Growth', 'Growth', _tempSchemeOption, (val) {
                setState(() => _tempSchemeOption = val);
              }),
              _buildFilterChip(
                'IDCW Payout',
                'IDCW Payout',
                _tempSchemeOption,
                (val) {
                  setState(() => _tempSchemeOption = val);
                },
              ),
              _buildFilterChip(
                'IDCW Reinvestment',
                'IDCW Reinvestment',
                _tempSchemeOption,
                (val) {
                  setState(() => _tempSchemeOption = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget
          Semantics(
            header: true,
            child: const AppText(
              'MIN. INVESTMENT (BUDGET)',
              variant: AppTextVariant.caption,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Any', null, _tempBudget, (val) {
                setState(() => _tempBudget = val);
              }),
              _buildFilterChip('≤ ₹100', 100, _tempBudget, (val) {
                setState(() => _tempBudget = val);
              }),
              _buildFilterChip('≤ ₹500', 500, _tempBudget, (val) {
                setState(() => _tempBudget = val);
              }),
              _buildFilterChip('≤ ₹1,000', 1000, _tempBudget, (val) {
                setState(() => _tempBudget = val);
              }),
              _buildFilterChip('≤ ₹5,000', 5000, _tempBudget, (val) {
                setState(() => _tempBudget = val);
              }),
              _buildFilterChip('≤ ₹10,000', 10000, _tempBudget, (val) {
                setState(() => _tempBudget = val);
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Apply and Reset Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetTempFilters,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const AppText(
                    'Reset',
                    variant: AppTextVariant.bodyMedium,
                    customColor: Colors.red,
                    weight: AppTextWeight.semiBold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkButtonPrimaryBackground,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const AppText(
                    'Apply',
                    variant: AppTextVariant.bodyMedium,
                    customColor: Colors.black,
                    weight: AppTextWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip<T>(
    String label,
    T? value,
    T? selectedValue,
    Function(T?) onTap,
  ) {
    final isSelected = value == selectedValue;
    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.darkButtonPrimaryBackground
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.darkButtonPrimaryBackground
                      : AppColors.darkButtonBorder,
            ),
          ),
          child: ExcludeSemantics(
            child: AppText(
              label,
              variant: AppTextVariant.bodySmall,
              weight: isSelected ? AppTextWeight.bold : AppTextWeight.medium,
              customColor: isSelected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchemesList() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < _schemes.length) {
            return _buildSchemeCard(_schemes[index]);
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
        }, childCount: _schemes.length + (_isPaginating ? 1 : 0)),
      ),
    );
  }

  Widget _buildSchemeCard(dynamic scheme) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => BseV2FinalJourney(
            fundName: scheme['name'] ?? '',
            isin: scheme['scheme_isin'] ?? '',
            schemeCode: scheme['scheme_code'] ?? '',
            nav: scheme['current_nav']?.toDouble(),
            minAmount: scheme['minimum_amount']?.toDouble(),
          ),
          transition: Transition.rightToLeft,
        );
      },
      child: Semantics(
        container: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkButtonBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fund name with plan badge
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            scheme['name'] ?? 'N/A',
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.semiBold,
                            colorType: AppTextColorType.primary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (scheme['plan_type'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  scheme['plan_type']?.toLowerCase() == 'direct'
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              scheme['plan_type']?.toUpperCase() ?? '',
                              variant: AppTextVariant.caption,
                              weight: AppTextWeight.bold,
                              customColor:
                                  scheme['plan_type']?.toLowerCase() == 'direct'
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Metrics
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'Min. Amount',
                                variant: AppTextVariant.bodySmall,
                                colorType: AppTextColorType.secondary,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                scheme['minimum_amount'] != null
                                    ? '₹${scheme['minimum_amount']}'
                                    : 'N/A',
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'Current NAV',
                                variant: AppTextVariant.bodySmall,
                                colorType: AppTextColorType.secondary,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                scheme['current_nav'] != null
                                    ? '₹${scheme['current_nav']?.toStringAsFixed(2)}'
                                    : 'N/A',
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'Category',
                                variant: AppTextVariant.bodySmall,
                                colorType: AppTextColorType.secondary,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                scheme['category'] ?? 'N/A',
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.primary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Invest button
              Semantics(
                button: true,
                label: 'Invest Now in ${scheme['name'] ?? 'Fund'}',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleInvestTap(scheme),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkButtonPrimaryBackground,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Invest Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkButtonBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        height: 40,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }, childCount: 5),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.darkTextSecondary),
          const SizedBox(height: 16),
          const AppText(
            'No mutual funds found',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(height: 8),
          const AppText(
            'Try adjusting your filters',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.secondary,
          ),
        ],
      ),
    );
  }
}
