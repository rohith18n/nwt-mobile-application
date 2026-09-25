import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/banks/widgets/bank_card.dart';
import 'package:nwt_app/screens/family_finance/types/assets/family_finance_assets_banks.dart';
import 'package:nwt_app/services/family_finance/assets/family_finance_assets_banks.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/app_input_field.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/empty_state.dart';
import 'package:nwt_app/widgets/common/loading.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class FamilyFinanceBanksScreen extends StatefulWidget {
  const FamilyFinanceBanksScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<FamilyFinanceBanksScreen> createState() =>
      _FamilyFinanceBanksScreenState();
}

class _FamilyFinanceBanksScreenState extends State<FamilyFinanceBanksScreen>
    with SingleTickerProviderStateMixin {
  bool _isAmountVisible = true;
  bool _isLoading = false;
  String _searchQuery = '';
  late AnimationController _refreshController;
  final TextEditingController _searchController = TextEditingController();
  final FamilyFinanceAssetsBanksService _bankService =
      FamilyFinanceAssetsBanksService();

  FamilyFinanceBanksResponse? _banksResponse;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _searchController.addListener(_onSearchChanged);
    _fetchFamilyBanks();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _fetchFamilyBanks() async {
    try {
      final response = await _bankService.getFamilyFinanceBanks(
        familyId: widget.familyId,
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
          if (isLoading) {
            _refreshController.repeat();
          } else {
            _refreshController.stop();
            _refreshController.reset();
          }
        },
      );

      setState(() {
        _banksResponse = response;
      });
    } catch (e) {
      AppLogger.error(
        'Error fetching family banks: $e',
        tag: 'FamilyFinanceBanksScreen',
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: EmptyState(
        icon: Icons.account_balance_outlined,
        title: 'No bank accounts found',
        subtitle: 'No family bank accounts are available.',
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(),
          SizedBox(height: 16.h),
          AppText(
            "Loading family bank accounts...",
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(FamilyFinanceBankAccount bank) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: BankCard(
        redirect: false,
        type: bank.type,
        bankGUID: bank.guid,
        icon: Icons.account_balance,
        bankName: bank.fipname,
        accountNumber: bank.maskedaccountid,
        balance: CurrencyFormatter.formatRupee(bank.currentvalue),
        deltaValue: "${bank.delta.toStringAsFixed(2)}%",
        isPositiveDelta: bank.delta >= 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total bank balance
    double totalBalance = 0;
    Map<String, List<FamilyFinanceBankAccount>> memberBanks = {};
    List<Member> filteredMembers = [];

    if (_banksResponse?.data != null) {
      // Group banks by member and calculate total balance
      for (final member in _banksResponse!.data!.members) {
        if (member.assets.deposit.data.isNotEmpty) {
          List<FamilyFinanceBankAccount> memberFilteredBanks = [];

          for (final bank in member.assets.deposit.data) {
            if (_searchQuery.isEmpty ||
                bank.fipname.toLowerCase().contains(_searchQuery) ||
                bank.maskedaccountid.toLowerCase().contains(_searchQuery)) {
              memberFilteredBanks.add(bank);
            }
            totalBalance += bank.currentvalue;
          }

          if (memberFilteredBanks.isNotEmpty) {
            memberBanks["${member.firstname} ${member.lastname}"] =
                memberFilteredBanks;
            filteredMembers.add(member);
          }
        }
      }
    }

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
              "Family Banks",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                  ),
                  child: Column(
                    children: [
                      // Total balance card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.darkCardBG, Color(0xFF727272)],
                            end: Alignment.topLeft,
                            begin: Alignment.bottomRight,
                          ).withOpacity(0.3),
                          border: Border.all(color: AppColors.darkButtonBorder),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 20.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          "Total family bank balance",
                                          variant: AppTextVariant.bodyMedium,
                                          weight: AppTextWeight.bold,
                                          colorType: AppTextColorType.secondary,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            AnimatedAmount(
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
                                          ],
                                        ),
                                        if (_banksResponse?.data != null)
                                          AppText(
                                            "${memberBanks.values.expand((banks) => banks).length} bank ${memberBanks.values.expand((banks) => banks).length == 1 ? 'account' : 'accounts'}",
                                            variant: AppTextVariant.tiny,
                                            weight: AppTextWeight.semiBold,
                                            colorType:
                                                AppTextColorType.secondary,
                                          ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isAmountVisible = !_isAmountVisible;
                                        });
                                      },
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
                                  ],
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Search field
                      AppInputField(
                        controller: _searchController,
                        prefix: Icon(
                          CupertinoIcons.search,
                          color: AppColors.darkTextMuted,
                        ),
                        hintText: "Search by bank name or account...",
                      ),

                      SizedBox(height: 16.h),

                      // Bank accounts grouped by family member
                      memberBanks.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                            onRefresh: _fetchFamilyBanks,
                            child: Column(
                              children: [
                                ...memberBanks.entries.map((entry) {
                                  final memberName = entry.key;
                                  final banks = entry.value;

                                  return CustomAccordion(
                                    title: memberName,
                                    initiallyExpanded: false,
                                    child: Column(
                                      children: [
                                        ...banks.map(
                                          (bank) => _buildBankCard(bank),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                // Add bottom padding for better scrolling experience
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
