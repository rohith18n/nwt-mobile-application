import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/data/categories/categories.dart';
import 'package:nwt_app/constants/data/categories/categories.types.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/strings.dart';
import 'package:nwt_app/controllers/assets/banks.dart';
import 'package:nwt_app/controllers/transactions/banks/transactions.dart';
import 'package:nwt_app/screens/transactions/banks/types/transaction.dart';
import 'package:nwt_app/screens/transactions/banks/widgets/transaction_card.dart';
import 'package:nwt_app/services/support/support_contact_service.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/calendar_picker.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class Bank {
  final String id;
  final String name;
  final String accountNumber;
  final IconData icon;
  bool isSelected;
  bool isPrimary;

  Bank({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.icon,
    this.isSelected = false,
    this.isPrimary = false,
  });
}

class FilterCategories extends Category {
  bool isSelected;

  FilterCategories({
    required super.id,
    required super.name,
    super.parentId,
    this.isSelected = false,
  });

  // Helper to check if this is a main category
  bool get isMainCategory => parentId == null;
}

class BankTransactionListScreen extends StatefulWidget {
  const BankTransactionListScreen({
    super.key,
    this.bankGUID,
    this.forceStandardApis = false,
  });

  final String? bankGUID;
  final bool forceStandardApis;

  @override
  State<BankTransactionListScreen> createState() =>
      _BankTransactionListScreenState();
}

class _BankTransactionListScreenState extends State<BankTransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isTransactionsLoading = false;
  final BankTransactionController bankTransactionController = Get.put(
    BankTransactionController(),
  );
  final ScrollController _scrollController = ScrollController();

  // Pagination variables
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedDateRange = '30 days';
  double _minAmount = 0;
  double _maxAmount = 10000;
  bool _hasTransaction = false;
  double dataMaxAmount = 10000;

  // Apply filters and get transactions
  void getTransactions({bool refresh = false}) async {
    // Always reset pagination when applying filters or refreshing
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMoreData = true;
      });

      // Also reset in the controller to ensure consistency
      bankTransactionController.currentPage = 0;
      bankTransactionController.hasMoreData = true;
    }

    // Get selected bank GUIDs for filtering
    List<String>? selectedBankGUIDs;
    if (selectedBanks.isNotEmpty) {
      selectedBankGUIDs = selectedBanks.map((bank) => bank.id).toList();
    } else if (widget.bankGUID != null) {
      // If no banks selected in filter but we have a bankGUID from widget, use that
      selectedBankGUIDs = [widget.bankGUID!];
    }

    // Apply all filters
    final transactionResponse = await bankTransactionController
        .getBankTransactions(
          bankGUIDs: selectedBankGUIDs,
          // Always pass amount values if they've been changed from defaults
          amountMin: _minAmount > 0 ? _minAmount : null,
          amountMax: _maxAmount < 10000 ? _maxAmount : null,
          startDate: _startDate,
          endDate: _endDate,
          refresh: refresh,
          forceStandard: widget.forceStandardApis,
          onLoading: (isLoading) {
            if (mounted) {
              setState(() {
                isTransactionsLoading = isLoading;

                // Update _hasTransaction based on current transaction data
                if (!isLoading) {
                  final transactions =
                      bankTransactionController
                          .transactionData
                          ?.banktransations ??
                      [];
                  _hasTransaction = transactions.isNotEmpty;
                }

                // Update local pagination state based on controller
                if (!isLoading) {
                  _hasMoreData = bankTransactionController.hasMoreData;
                }
              });
            }
          },
        );

    dataMaxAmount = transactionResponse ?? 0;
  }

  @override
  void initState() {
    super.initState();
    getTransactions(refresh: true);

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Skip redundant bank summary fetch if data is already available
    if (bankController.bankSummary?.data != null) {
      _updateBanksList();
    }

    if (!widget.forceStandardApis || bankController.bankSummary?.data == null) {
      fetchBankData();
    }
  }

  // Fetch bank data for filtering
  void fetchBankData() {
    // If we already have data, populate the list immediately
    if (bankController.bankSummary?.data != null) {
      _updateBanksList();
    }

    bankController.getBankSummary(
      onLoading: (isLoading) {
        if (!isLoading) {
          // Update banks list when data is loaded
          _updateBanksList();
        }
      },
    );
  }

  void _scrollListener() {
    // Check if we're close to the bottom of the scroll view
    if (!_isLoadingMore &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      // Load more data when we're near the bottom
      _loadMoreTransactions();
    }
  }

  void _loadMoreTransactions() {
    if (_isLoadingMore || !_hasMoreData) {
      return; // Don't load more if already loading or no more data
    }

    // Update UI to show loading state and increment page
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    // Also update controller's page to ensure consistency
    bankTransactionController.currentPage = _currentPage;

    // Get selected bank GUIDs for filtering
    List<String>? selectedBankGUIDs;
    if (selectedBanks.isNotEmpty) {
      selectedBankGUIDs = selectedBanks.map((bank) => bank.id).toList();
    } else if (widget.bankGUID != null) {
      // If no banks selected in filter but we have a bankGUID from widget, use that
      selectedBankGUIDs = [widget.bankGUID!];
    }

    // Call the controller with the current page and all filters
    bankTransactionController.loadMoreTransactionsWithPage(
      bankGUIDs: selectedBankGUIDs,
      // Always pass amount values if they've been changed from defaults
      amountMin: _minAmount > 0 ? _minAmount : null,
      amountMax: _maxAmount < 10000 ? _maxAmount : null,
      startDate: _startDate,
      endDate: _endDate,
      page: _currentPage,
      forceStandard: widget.forceStandardApis,
      onLoading: (isLoading) {
        // Update UI when loading state changes
        if (mounted) {
          setState(() {
            _isLoadingMore = isLoading;

            // Update _hasTransaction based on current transaction data
            if (!isLoading) {
              final transactions =
                  bankTransactionController.transactionData?.banktransations ??
                  [];
              _hasTransaction = transactions.isNotEmpty;
            }

            // Update has more data status from controller
            if (!isLoading) {
              _hasMoreData = bankTransactionController.hasMoreData;
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Filter state variables

  // Categories list with hierarchical structure

  // Bank controller to fetch actual banks list
  final bankController = Get.put(BankController());

  // Store the actual bank list for selection state persistence
  final List<Bank> _banksList = [];

  // Get banks from controller and update _banksList
  void _updateBanksList() {
    if (bankController.bankSummary?.data?.banks != null) {
      // Store currently selected IDs to preserve them
      final selectedIds =
          _banksList.where((b) => b.isSelected).map((b) => b.id).toSet();

      // Clear the current list
      _banksList.clear();

      // Add banks from controller
      _banksList.addAll(
        bankController.bankSummary!.data!.banks.map((bankData) {
          // A bank is selected if it was previously selected OR
          // if it's the current bankGUID and nothing else was selected yet
          final bool isSelected =
              selectedIds.contains(bankData.guid) ||
              (selectedIds.isEmpty && bankData.guid == widget.bankGUID);

          return Bank(
            id: bankData.guid,
            name: bankData.fipname,
            accountNumber: bankData.maskedaccountid,
            icon: Icons.account_balance,
            isPrimary: bankData.isprimary,
            isSelected: isSelected,
          );
        }),
      );

      // Update UI
      if (mounted) setState(() {});
    }
  }

  final List<Category> _categories = categories;
  List<Bank> get selectedBanks =>
      _banksList.where((bank) => bank.isSelected).toList();

  // Store selected categories
  final List<FilterCategories> _selectedFilterCategories = [];

  List<FilterCategories> get selectedCategories => _selectedFilterCategories;

  Widget _buildBankChip(Bank bank, [StateSetter? setModalState]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkButtonBorder,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(bank.icon, size: 14, color: AppColors.darkTextMuted),
          const SizedBox(width: 4),
          AppText(
            bank.name,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              bank.isSelected = false;
              setState(() {});
              if (setModalState != null) {
                setModalState(() {});
              }
            },
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    FilterCategories category, [
    StateSetter? setModalState,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkButtonBorder,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            category.name,
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.primary,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterCategories.removeWhere(
                  (cat) => cat.id == category.id,
                );
              });
              if (setModalState != null) {
                setModalState(() {});
              }
            },
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showBankSelectionBottomSheet(
    BuildContext context,
    StateSetter setModalState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.darkInputBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        "Select Banks",
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.semiBold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _banksList.length,
                      separatorBuilder: (context, index) => const SizedBox(),
                      itemBuilder: (context, index) {
                        final bank = _banksList[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.darkButtonBorder,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              bank.icon,
                              color: AppColors.darkTextMuted,
                            ),
                          ),
                          title: AppText(
                            bank.name,
                            variant: AppTextVariant.bodyLarge,
                            weight: AppTextWeight.medium,
                          ),
                          subtitle: AppText(
                            bank.accountNumber,
                            variant: AppTextVariant.bodySmall,
                            colorType: AppTextColorType.secondary,
                          ),
                          trailing:
                              bank.isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : null,
                          onTap: () {
                            setBottomSheetState(() {
                              bank.isSelected = !bank.isSelected;
                            });
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: () => Navigator.pop(context),
                      variant: AppButtonVariant.primary,
                      text: "Done",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategorySelectionBottomSheet(
    BuildContext context,
    StateSetter setModalState,
  ) {
    // Create a temporary list to track selections during the bottom sheet session
    final List<FilterCategories> tempSelectedCategories = List.from(
      _selectedFilterCategories,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            // Group categories by their parent
            final Map<String?, List<Category>> groupedCategories = {};

            // Initialize with empty lists for each parent type
            groupedCategories[null] = [];

            // Group categories by parent
            for (final category in _categories) {
              if (!groupedCategories.containsKey(category.parentId)) {
                groupedCategories[category.parentId] = [];
              }
              groupedCategories[category.parentId]!.add(category);
            }

            // Get main categories (those without a parent)
            final mainCategories = groupedCategories[null] ?? [];

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      AppText(
                        "Select Categories",
                        variant: AppTextVariant.headline4,
                        weight: AppTextWeight.semiBold,
                      ),
                      Semantics(
                        label: 'Close',
                        button: true,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const ExcludeSemantics(
                            child: Icon(Icons.close, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: mainCategories.length,
                      itemBuilder: (context, index) {
                        final mainCategory = mainCategories[index];
                        final subCategories =
                            groupedCategories[mainCategory.id] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main category header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: AppText(
                                mainCategory.name,
                                variant: AppTextVariant.bodyLarge,
                                weight: AppTextWeight.semiBold,
                              ),
                            ),
                            // Subcategories
                            ...subCategories.map((subCategory) {
                              // Check if this category is selected
                              final isSelected = tempSelectedCategories.any(
                                (cat) => cat.id == subCategory.id,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.darkInputBackground,
                                ),
                                child: ListTile(
                                  title: AppText(
                                    subCategory.name,
                                    variant: AppTextVariant.bodyMedium,
                                  ),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                          : null,
                                  onTap: () {
                                    setBottomSheetState(() {
                                      // Find if this category is already selected
                                      final existingIndex =
                                          tempSelectedCategories.indexWhere(
                                            (cat) => cat.id == subCategory.id,
                                          );

                                      if (existingIndex >= 0) {
                                        // If already selected, remove it
                                        tempSelectedCategories.removeAt(
                                          existingIndex,
                                        );
                                      } else {
                                        // If not selected, add it
                                        tempSelectedCategories.add(
                                          FilterCategories(
                                            id: subCategory.id,
                                            name: subCategory.name,
                                            parentId: subCategory.parentId,
                                            isSelected: true,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: () {
                        // Update the actual selected categories list
                        setModalState(() {
                          _selectedFilterCategories.clear();
                          _selectedFilterCategories.addAll(
                            tempSelectedCategories,
                          );
                        });
                        Navigator.pop(context);
                      },
                      variant: AppButtonVariant.primary,
                      text: "Done",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openFilterBottomsheet(double maxAmount) {
    // Ensure _banksList is populated if it's empty but data is available in controller
    if (_banksList.isEmpty && bankController.bankSummary?.data?.banks != null) {
      _updateBanksList();
    }

    // Ensure _maxAmount doesn't exceed the actual data max amount
    if (_maxAmount > maxAmount) {
      _maxAmount = maxAmount;
    }

    // Initialize dates based on selected date range if not already set
    final now = DateTime.now();
    if (_selectedDateRange == "30 days") {
      _startDate = now.subtract(const Duration(days: 30));
    } else if (_selectedDateRange == "60 days") {
      _startDate = now.subtract(const Duration(days: 60));
    } else if (_selectedDateRange == "90 days") {
      _startDate = now.subtract(const Duration(days: 90));
    }
    _endDate = now;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Scaffold(
                backgroundColor: AppColors.darkBackground,
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
                          onTap: () => Navigator.pop(context),
                          child: const ExcludeSemantics(
                            child: Icon(Icons.chevron_left, size: 32),
                          ),
                        ),
                      ),
                      AppText(
                        "Filter",
                        variant: AppTextVariant.headline6,
                        weight: AppTextWeight.semiBold,
                      ),
                      const Opacity(
                        opacity: 0,
                        child: Icon(Icons.chevron_left, size: 32),
                      ),
                    ],
                  ),
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.scaffoldHorizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            AppText(
                              "Banks",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap:
                                  () => _showBankSelectionBottomSheet(
                                    context,
                                    setModalState,
                                  ),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                constraints: BoxConstraints(minHeight: 60),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.darkButtonBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (selectedBanks.isEmpty)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            "Select Banks",
                                            variant: AppTextVariant.bodyMedium,
                                            colorType: AppTextColorType.primary,
                                          ),
                                          const Icon(Icons.keyboard_arrow_down),
                                        ],
                                      ),
                                    if (selectedBanks.isNotEmpty) ...[
                                      // const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            selectedBanks
                                                .map(
                                                  (bank) => _buildBankChip(
                                                    bank,
                                                    setModalState,
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            AppText(
                              "Date Range",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                            ),
                            Row(
                              spacing: 12,
                              children: [
                                ChoiceChip(
                                  selected: _selectedDateRange == "30 days",
                                  showCheckmark: false,
                                  surfaceTintColor: AppColors.darkButtonBorder,
                                  backgroundColor: AppColors.darkButtonBorder,
                                  selectedColor: AppColors.darkButtonBorder,
                                  disabledColor: AppColors.darkButtonBorder,
                                  side: BorderSide(
                                    color:
                                        _selectedDateRange == "30 days"
                                            ? Colors.white
                                            : AppColors.darkButtonBorder,
                                    width:
                                        _selectedDateRange == "30 days"
                                            ? 1.5
                                            : 1.0,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      final now = DateTime.now();
                                      final startDate = now.subtract(
                                        const Duration(days: 30),
                                      );

                                      setModalState(() {
                                        _startDate = startDate;
                                        _endDate = now;
                                        _selectedDateRange = "30 days";
                                      });
                                    }
                                  },
                                  label: AppText(
                                    "30 days",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                  ),
                                ),
                                ChoiceChip(
                                  selected: _selectedDateRange == "60 days",
                                  showCheckmark: false,
                                  surfaceTintColor: AppColors.darkButtonBorder,
                                  backgroundColor: AppColors.darkButtonBorder,
                                  selectedColor: AppColors.darkButtonBorder,
                                  disabledColor: AppColors.darkButtonBorder,
                                  side: BorderSide(
                                    color:
                                        _selectedDateRange == "60 days"
                                            ? Colors.white
                                            : AppColors.darkButtonBorder,
                                    width:
                                        _selectedDateRange == "60 days"
                                            ? 1.5
                                            : 1.0,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      final now = DateTime.now();
                                      final startDate = now.subtract(
                                        const Duration(days: 60),
                                      );

                                      setModalState(() {
                                        _startDate = startDate;
                                        _endDate = now;
                                        _selectedDateRange = "60 days";
                                      });
                                    }
                                  },
                                  label: AppText(
                                    "60 days",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                  ),
                                ),
                                ChoiceChip(
                                  selected: _selectedDateRange == "90 days",
                                  showCheckmark: false,
                                  surfaceTintColor: AppColors.darkButtonBorder,
                                  backgroundColor: AppColors.darkButtonBorder,
                                  selectedColor: AppColors.darkButtonBorder,
                                  disabledColor: AppColors.darkButtonBorder,
                                  side: BorderSide(
                                    color:
                                        _selectedDateRange == "90 days"
                                            ? Colors.white
                                            : AppColors.darkButtonBorder,
                                    width:
                                        _selectedDateRange == "90 days"
                                            ? 1.5
                                            : 1.0,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      final now = DateTime.now();
                                      final startDate = now.subtract(
                                        const Duration(days: 90),
                                      );

                                      setModalState(() {
                                        _startDate = startDate;
                                        _endDate = now;
                                        _selectedDateRange = "90 days";
                                      });
                                    }
                                  },
                                  label: AppText(
                                    "90 days",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.semiBold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppText(
                              "Select Date",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: AppInputField(
                                    controller: TextEditingController(
                                      text:
                                          _startDate == null
                                              ? ""
                                              : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}",
                                    ),
                                    hintText: "Start Date",
                                    readOnly: true,
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showAppCalendarPicker(
                                            context: context,
                                            initialDate:
                                                _startDate ?? DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            title: "Select Start Date",
                                          );
                                      if (picked != null) {
                                        setModalState(() {
                                          _startDate = picked;
                                          _selectedDateRange =
                                              null; // Clear preset when custom date is selected
                                        });
                                      }
                                    },
                                    suffix: Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppInputField(
                                    controller: TextEditingController(
                                      text:
                                          _endDate == null
                                              ? ""
                                              : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
                                    ),
                                    hintText: "End Date",
                                    readOnly: true,
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showAppCalendarPicker(
                                            context: context,
                                            initialDate:
                                                _endDate ?? DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            title: "Select End Date",
                                          );
                                      if (picked != null) {
                                        setModalState(() {
                                          _endDate = picked;
                                          _selectedDateRange =
                                              null; // Clear preset when custom date is selected
                                        });
                                      }
                                    },
                                    suffix: Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bank Selection
                            const SizedBox(height: 20),

                            // AppText(
                            //   "Categories",
                            //   variant: AppTextVariant.bodyMedium,
                            //   weight: AppTextWeight.semiBold,
                            // ),
                            // const SizedBox(height: 8),
                            // GestureDetector(
                            //   onTap:
                            //       () => _showCategorySelectionBottomSheet(
                            //         context,
                            //         setModalState,
                            //       ),
                            //   child: Container(
                            //     width: MediaQuery.of(context).size.width,
                            //     constraints: BoxConstraints(minHeight: 60),
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 12,
                            //       vertical: 12,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       border: Border.all(
                            //         color: AppColors.darkButtonBorder,
                            //       ),
                            //       borderRadius: BorderRadius.circular(8),
                            //     ),
                            //     child: Column(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         if (selectedCategories.isEmpty)
                            //           Row(
                            //             mainAxisAlignment:
                            //                 MainAxisAlignment.spaceBetween,
                            //             crossAxisAlignment:
                            //                 CrossAxisAlignment.start,
                            //             children: [
                            //               AppText(
                            //                 "Select Categories",
                            //                 variant: AppTextVariant.bodyMedium,
                            //                 colorType: AppTextColorType.primary,
                            //               ),
                            //               const Icon(Icons.keyboard_arrow_down),
                            //             ],
                            //           ),
                            //         if (selectedCategories.isNotEmpty) ...[
                            //           Wrap(
                            //             spacing: 8,
                            //             runSpacing: 8,
                            //             children:
                            //                 selectedCategories
                            //                     .map(
                            //                       (category) =>
                            //                           _buildCategoryChip(
                            //                             category,
                            //                             setModalState,
                            //                           ),
                            //                     )
                            //                     .toList(),
                            //           ),
                            //         ],
                            //       ],
                            //     ),
                            //   ),
                            // ),

                            // const SizedBox(height: 24),

                            // Amount Range
                            AppText(
                              "Amount Range",
                              variant: AppTextVariant.bodyLarge,
                              weight: AppTextWeight.semiBold,
                            ),
                            const SizedBox(height: 12),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                rangeValueIndicatorShape:
                                    const PaddleRangeSliderValueIndicatorShape(),
                                valueIndicatorColor: Colors.white,
                                valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                                showValueIndicator: ShowValueIndicator.always,
                              ),
                              child: RangeSlider(
                                values: RangeValues(_minAmount, _maxAmount),
                                min: 0,
                                max: dataMaxAmount,
                                divisions: 100,
                                labels: RangeLabels(
                                  CurrencyFormatter.formatRupee(_minAmount),
                                  CurrencyFormatter.formatRupee(_maxAmount),
                                ),
                                onChanged: (RangeValues values) {
                                  setModalState(() {
                                    _minAmount = values.start;
                                    _maxAmount = values.end;
                                  });
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  CurrencyFormatter.formatRupee(0),
                                  variant: AppTextVariant.bodyMedium,
                                ),
                                AppText(
                                  CurrencyFormatter.formatRupee(dataMaxAmount),
                                  variant: AppTextVariant.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                        right: AppSizing.scaffoldHorizontalPadding,
                        left: AppSizing.scaffoldHorizontalPadding,
                        bottom: AppSizing.scaffoldHorizontalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkInputBackground,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              onPressed: () {
                                // Apply filters and refresh transactions
                                setState(() {
                                  // Reset pagination when applying new filters
                                  _currentPage = 0;
                                  _hasMoreData = true;
                                });

                                // Reset controller pagination state
                                bankTransactionController.currentPage = 0;
                                bankTransactionController.hasMoreData = true;

                                // Close the filter sheet
                                Navigator.pop(context);

                                // Fetch transactions with the applied filters
                                getTransactions(refresh: true);
                              },
                              variant: AppButtonVariant.primary,
                              text: "Apply",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Check if any filters are currently active
  bool get _hasActiveFilters {
    // Check if any banks are selected
    if (selectedBanks.isNotEmpty) return true;

    // Check if any categories are selected
    if (selectedCategories.isNotEmpty) return true;

    // Check if amount range is modified from defaults
    if (_minAmount > 0 || _maxAmount < 10000) return true;

    // Check if date range is set (not null)
    if (_startDate != null || _endDate != null) return true;

    return false;
  }

  // Sort transactions by date (newest first)
  List<Banktransation> _sortTransactionsByDate(
    List<Banktransation>? transactions,
  ) {
    if (transactions == null || transactions.isEmpty) {
      return [];
    }

    // Create a copy of the list to avoid modifying the original
    final sortedTransactions = List<Banktransation>.from(transactions);

    // Sort transactions by date (newest first)
    sortedTransactions.sort(
      (a, b) => b.transactiontimestamp.compareTo(a.transactiontimestamp),
    );

    return sortedTransactions;
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
                onTap: () => Navigator.pop(context),
                child: const ExcludeSemantics(
                  child: Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            AppText(
              "Transactions",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WhatsAppSupportButton(
                  size: 20,
                  color: AppColors.darkPrimary,
                ),
                if (_hasTransaction) ...[
                  const SizedBox(width: 12),
                  Opacity(
                    opacity: _hasTransaction ? 1.0 : 0.0,
                    child: Semantics(
                      label: 'Filter transactions',
                      button: true,
                      child: GestureDetector(
                        onTap:
                            _hasTransaction
                                ? () => openFilterBottomsheet(dataMaxAmount)
                                : null,
                        child: ExcludeSemantics(
                          child: Stack(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color:
                                    _hasActiveFilters ? AppColors.info : null,
                              ),
                              if (_hasActiveFilters)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.info,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GetBuilder<BankTransactionController>(
          builder: (bankTransactionController) {
            // Get transactions and sort them by date (newest first)
            final transactions =
                bankTransactionController.transactionData?.banktransations ??
                [];
            final sortedTransactions = _sortTransactionsByDate(transactions);

            // Update _hasTransaction immediately based on current data
            // This ensures filter icon is visible on initial load if transactions exist
            if (transactions.isNotEmpty && !_hasTransaction) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasTransaction = true;
                  });
                }
              });
            }

            // Calculate item count - add 1 for loading indicator if more data is available
            final itemCount =
                sortedTransactions.length +
                (_isLoadingMore || _hasMoreData ? 1 : 0);

            return Column(
              children: [
                // Padding(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: AppSizing.scaffoldHorizontalPadding,
                //     vertical: 8,
                //   ),
                //   child: AppInputField(
                //     controller: _searchController,
                //     hintText: "Search transactions",
                //     prefix: const Icon(
                //       Icons.search,
                //       color: AppColors.darkTextMuted,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "We fetch financial information from your bank, but sometimes it's incomplete or inaccurate. ",
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.medium,
                        colorType: AppTextColorType.primary,
                      ),
                      FutureBuilder<String>(
                        future: SupportContactService.getEffectiveContactType(
                          SupportContext.generalSupport,
                        ),
                        builder: (context, snapshot) {
                          final contactType =
                              snapshot.data ??
                              SupportContactService.contactTypeEmail;

                          return RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: Semantics(
                                    button: true,
                                    link: true,
                                    label:
                                        contactType ==
                                                SupportContactService
                                                    .contactTypeEmail
                                            ? AppStrings.contactUs
                                            : AppStrings.whatsApp,
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          await SupportContactService.contactSupport(
                                            context:
                                                SupportContext.generalSupport,
                                          );
                                        } catch (e) {
                                          AppLogger.error(
                                            'Unhandled error in contact support: $e',
                                            tag: 'BankTxnList',
                                          );
                                        }
                                      },
                                      child: ExcludeSemantics(
                                        child: Text(
                                          contactType ==
                                                  SupportContactService
                                                      .contactTypeEmail
                                              ? AppStrings.contactUs
                                              : AppStrings.whatsApp,
                                          style: TextStyle(
                                            color: AppColors.linkColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(text: AppStrings.forAnyIssues),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (isTransactionsLoading && transactions.isEmpty)
                  const Expanded(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (!isTransactionsLoading && transactions.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: AppColors.darkTextMuted.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppText(
                            'No transactions found',
                            variant: AppTextVariant.bodyLarge,
                            weight: AppTextWeight.medium,
                            colorType: AppTextColorType.secondary,
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            'Your transactions will appear here',
                            variant: AppTextVariant.bodySmall,
                            colorType: AppTextColorType.muted,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: AppSizing.scaffoldHorizontalPadding,
                        right: AppSizing.scaffoldHorizontalPadding,
                        bottom: 20,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom when loading more data
                        if (index == sortedTransactions.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: SizedBox(),
                              // Column(
                              //   children: [
                              //     const CupertinoActivityIndicator(),
                              //     const SizedBox(height: 8),
                              //     AppText(
                              //       'Loading more transactions...',
                              //       variant: AppTextVariant.bodySmall,
                              //       colorType: AppTextColorType.muted,
                              //     ),
                              //   ],
                              // ),
                            ),
                          );
                        }

                        // Show transaction card
                        final transaction = sortedTransactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BankTransactionCardWidget(
                            transaction: transaction,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
