import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/data/categories/categories.types.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/assets/banks.dart';
import 'package:nwt_app/screens/assets/banks/types/banks.dart';
import 'package:nwt_app/screens/assets/banks/widgets/bank_card.dart';
import 'package:nwt_app/services/account_aggregators/account_aggregator_data_provider.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/empty_state.dart';
import 'package:nwt_app/widgets/common/loading.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

final List<Category> categories = [
  Category(id: 'all', name: 'All'),
  Category(id: 'TERM_DEPOSIT', name: 'Term Deposit'),
  Category(id: 'RECURRING_DEPOSIT', name: 'Recurring Deposit'),
  Category(id: 'DEPOSIT', name: 'Savings'),
];

class BankDepositsListScreen extends StatefulWidget {
  final bool forceStandardApis;
  const BankDepositsListScreen({super.key, this.forceStandardApis = true});

  @override
  State<BankDepositsListScreen> createState() => _BankDepositsListScreenState();
}

class _BankDepositsListScreenState extends State<BankDepositsListScreen>
    with TickerProviderStateMixin {
  Category _selectedCategory = categories.first;
  final BankController bankController = Get.find<BankController>();
  bool isBankSummaryLoading = false;
  late final AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    fetchBankSummary();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> fetchBankSummary() async {
    final provider = getAccountAggregatorDataProvider(
      forceStandard: widget.forceStandardApis,
    );
    final providerBanks = provider.getBanks() ?? <Bank>[];

    // Finarkein: deposits data comes from aa/data/result store.
    if (!widget.forceStandardApis && providerBanks.isEmpty) {
      // Try to hydrate the store if user came here before Dashboard.
      await provider.refreshDashboardData();
    }

    // Saafe/standard: use API summary.
    if (widget.forceStandardApis ||
        (provider.getBanks() ?? <Bank>[]).isNotEmpty) {
      if (widget.forceStandardApis && bankController.bankSummary?.data != null) {
        return;
      }
    }

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
    );
  }

  List<Bank> getFilteredBanks() {
    final providerBanks =
        getAccountAggregatorDataProvider(
          forceStandard: widget.forceStandardApis,
        ).getBanks() ??
        <Bank>[];
    final banks = providerBanks.isNotEmpty
        ? providerBanks
        : (bankController.bankSummary?.data?.banks ?? <Bank>[]);

    if (_selectedCategory.id == 'all') {
      return banks
          .where(
            (bank) =>
                bank.type == 'DEPOSIT' ||
                bank.type == 'TERM_DEPOSIT' ||
                bank.type == 'RECURRING_DEPOSIT',
          )
          .toList();
    } else {
      return banks.where((bank) => bank.type == _selectedCategory.id).toList();
    }
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
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            AppText(
              "Deposits",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            const SizedBox(height: 16),
            Expanded(
              child: GetBuilder<BankController>(
                builder: (controller) {
                  if (isBankSummaryLoading) {
                    return const Center(child: LoadingIndicator());
                  }

                  final filteredBanks = getFilteredBanks();

                  if (filteredBanks.isEmpty) {
                    return const Center(
                      child: EmptyState(
                        title: "No deposits found",
                        subtitle:
                            "You don't have any deposits in this category",
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.scaffoldHorizontalPadding,
                    ),
                    itemCount: filteredBanks.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bank = filteredBanks[index];
                      return _buildBankCard(bank);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(Bank bank) {
    final bool isDeposit =
        bank.type == 'DEPOSIT' ||
        bank.type == 'TERM_DEPOSIT' ||
        bank.type == 'RECURRING_DEPOSIT';

    // Format the balance and delta values
    final String formattedBalance = CurrencyFormatter.formatRupee(
      bank.currentvalue,
    );

    String deltaValue;
    bool isPositiveDelta;

    if (isDeposit) {
      // For deposit types, show delta percentage
      deltaValue = "${bank.deltapercentage.abs().toStringAsFixed(2)}%";
      isPositiveDelta = bank.deltavalue >= 0;
    } else {
      // For non-deposit types, show interest rate
      deltaValue =
          bank.interestrate != null
              ? "${bank.interestrate!.toStringAsFixed(2)}% p.a."
              : "N/A";
      isPositiveDelta = true; // Interest rates are always shown as positive
    }

    // Get appropriate icon based on account type
    IconData icon = _getIconForBankType(bank.type);

    return BankCard(
      type: bank.type!,
      icon: icon,
      bankName: bank.fipname,
      accountNumber: bank.maskedaccountid,
      balance: formattedBalance,
      // For non-deposit types, don't show delta value but show interest rate
      deltaValue: isDeposit ? deltaValue : "",
      isPositiveDelta: isPositiveDelta,
      bankGUID: bank.guid,
      forceStandardApis: widget.forceStandardApis,
    );
  }

  IconData _getIconForBankType(String? type) {
    switch (type) {
      case 'TERM_DEPOSIT':
        return Icons.account_balance;
      case 'RECURRING_DEPOSIT':
        return Icons.repeat;
      case 'DEPOSIT':
        return Icons.savings;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
