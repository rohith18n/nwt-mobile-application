import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/screens/assets/investments/widgets/holding_card.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class MFCentralDetailScreen extends StatefulWidget {
  const MFCentralDetailScreen({super.key});

  @override
  State<MFCentralDetailScreen> createState() => _MFCentralDetailScreenState();
}

class _MFCentralDetailScreenState extends State<MFCentralDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late InvestmentController _investmentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Register the controller if not already present (e.g. navigating from
    // dashboard without having opened the investments screen first).
    _investmentController = Get.isRegistered<InvestmentController>()
        ? Get.find<InvestmentController>()
        : Get.put(InvestmentController());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _investmentController.fetchMFCentralHoldings(),
      _investmentController.fetchMFCentralTransactions(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: AppText(
          'Mutual Fund Holdings',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        centerTitle: true,
        actions: const [
          WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.info,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.darkTextSecondary,
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Holdings'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHoldingsTab(),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  // ── Holdings Tab ──────────────────────────────────────────────────────────

  Widget _buildHoldingsTab() {
    final holdings = _investmentController.mfCentralHoldings;

    if (holdings.isEmpty) {
      return _emptyState(
        icon: Icons.account_balance_wallet_outlined,
        message: 'No active holdings found',
      );
    }

    // Use pre-computed summary from API when available
    final summary      = _investmentController.mfPortfolioSummary;
    final totalValue   = double.tryParse(
            summary?['total_current_value']?.toString() ?? '') ??
        holdings.fold<double>(0, (s, h) => s + h.currentmktvalue);
    final totalInvested = double.tryParse(
            summary?['total_invested']?.toString() ?? '') ??
        holdings.fold<double>(0, (s, h) => s + h.costvalue);
    final totalGain    = double.tryParse(
            summary?['total_pnl']?.toString() ?? '') ??
        (totalValue - totalInvested);
    final gainPct      = double.tryParse(
            summary?['total_pnl_pct']?.toString() ?? '') ??
        (totalInvested > 0 ? (totalGain / totalInvested) * 100 : 0.0);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.info,
      child: CustomScrollView(
        slivers: [
          // Summary header
          SliverToBoxAdapter(
            child: _buildSummaryHeader(
              totalValue: totalValue,
              totalInvested: totalInvested,
              totalGain: totalGain,
              gainPct: gainPct,
            ),
          ),

          // Holdings list
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding.w,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: HoldingCard(
                    mf: holdings[index],
                    isAmountVisible: true,
                    forceStandardApis: true,
                  ),
                ),
                childCount: holdings.length,
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader({
    required double totalValue,
    required double totalInvested,
    required double totalGain,
    required double gainPct,
  }) {
    final isGain = totalGain >= 0;
    final gainColor = isGain ? AppColors.success : AppColors.error;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding.w,
        vertical: 16.h,
      ),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.darkInputBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Portfolio Overview',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.secondary,
          ),
          SizedBox(height: 8.h),
          AppText(
            CurrencyFormatter.formatRupee(totalValue.toInt()),
            variant: AppTextVariant.headline3,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.primary,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _summaryChip(
                label: 'Invested',
                value: CurrencyFormatter.formatRupee(totalInvested.toInt()),
              ),
              SizedBox(width: 16.w),
              _summaryChip(
                label: 'Returns',
                value:
                    '${isGain ? '+' : ''}${CurrencyFormatter.formatRupee(totalGain.toInt())} '
                    '(${isGain ? '+' : ''}${gainPct.toStringAsFixed(2)}%)',
                valueColor: gainColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.caption,
          colorType: AppTextColorType.muted,
        ),
        SizedBox(height: 2.h),
        AppText(
          value,
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.semiBold,
          customColor: valueColor,
          colorType: AppTextColorType.primary,
        ),
      ],
    );
  }

  // ── Transactions Tab ──────────────────────────────────────────────────────

  Widget _buildTransactionsTab() {
    final txns = _investmentController.mfCentralTransactions;

    if (txns.isEmpty) {
      return _emptyState(
        icon: Icons.receipt_long_outlined,
        message: 'No transactions found',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.info,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding.w,
          vertical: 16.h,
        ),
        itemCount: txns.length,
        separatorBuilder: (_, __) => Divider(
          color: AppColors.darkInputBorder,
          height: 1,
        ),
        itemBuilder: (context, i) => _buildTransactionTile(txns[i]),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> txn) {
    final name        = (txn['name'] ?? '').toString();
    final type        = (txn['type'] ?? '').toString();
    final dateStr     = (txn['date'] ?? '').toString();
    final amount      = (txn['txnamount'] as num?)?.toDouble() ?? 0.0;
    final qty         = (txn['quantity'] as num?)?.toDouble() ?? 0.0;
    final folio       = (txn['folio_no'] ?? '').toString();

    final isCredit    = amount >= 0;
    final amtColor    = isCredit ? AppColors.success : AppColors.error;

    String formattedDate = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      formattedDate = DateFormat('d MMM yyyy').format(parsed);
    } catch (_) {}

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.error)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amtColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  name,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                  maxLines: 2,
                ),
                SizedBox(height: 4.h),
                AppText(
                  type,
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.secondary,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    AppText(
                      formattedDate,
                      variant: AppTextVariant.caption,
                      colorType: AppTextColorType.muted,
                    ),
                    if (folio.isNotEmpty) ...[
                      AppText(
                        '  •  Folio $folio',
                        variant: AppTextVariant.caption,
                        colorType: AppTextColorType.muted,
                      ),
                    ],
                  ],
                ),
                if (qty != 0) ...[
                  SizedBox(height: 2.h),
                  AppText(
                    'Units: ${qty.abs().toStringAsFixed(3)}',
                    variant: AppTextVariant.caption,
                    colorType: AppTextColorType.muted,
                  ),
                ],
              ],
            ),
          ),

          // Amount
          if (amount != 0)
            AppText(
              '${isCredit ? '+' : ''}${CurrencyFormatter.formatRupee(amount.abs().toInt())}',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.bold,
              customColor: amtColor,
            ),
        ],
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56.sp, color: AppColors.darkTextSecondary),
          SizedBox(height: 16.h),
          AppText(
            message,
            variant: AppTextVariant.bodyLarge,
            colorType: AppTextColorType.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
