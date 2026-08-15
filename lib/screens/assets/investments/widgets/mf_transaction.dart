import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/transactions/investments/transactions.dart';
import 'package:nwt_app/screens/assets/investments/types/transaction.dart'
    as invtypes;
import 'package:intl/intl.dart';
import 'package:nwt_app/widgets/common/category_chip.dart';
import 'package:nwt_app/widgets/common/loading_widget.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';

class MfTransactionScreen extends StatefulWidget {
  final String? isinCode;
  final String? isinDescription;
  final String? folioNo;
  final bool forceStandardApis;

  const MfTransactionScreen({
    super.key,
    this.isinCode,
    this.isinDescription,
    this.folioNo,
    this.forceStandardApis = false,
  });

  @override
  State<MfTransactionScreen> createState() => _MfTransactionScreenState();
}

class _MfTransactionScreenState extends State<MfTransactionScreen> {
  final ScrollController _scrollController = ScrollController();
  final InvestmentTransactionController _controller = Get.put(
    InvestmentTransactionController(),
  );
  bool _pageLoading = false;

  // No filter needed - MF only
  // String _selectedFilter = 'ALL';
  // final List<String> _filterOptions = ['ALL', 'EQUITY', 'MUTUAL FUNDS', 'ETF'];

  @override
  void initState() {
    super.initState();
    // Initial fetch with ISIN and Folio for MF transactions
    _controller.getInvestmentTransactions(
      onLoading: (isLoading) {
        setState(() {
          _pageLoading = isLoading;
        });
      },
      refresh: true,
      isinCode: widget.isinCode,
      folioNo: widget.folioNo,
      forceStandardApis: widget.forceStandardApis,
    );

    // Infinite scroll
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      // Trigger only if list overflows (maxScrollExtent > 0) and near bottom
      if (pos.maxScrollExtent > 0 &&
          pos.pixels >= pos.maxScrollExtent - 200 &&
          _controller.hasMoreData &&
          !_controller.isLoadingMore) {
        _controller.loadMore(
          onLoading: (isLoading) {},
          forceStandardApis: widget.forceStandardApis,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Get MF transactions only
  List<invtypes.Investment> _getFilteredItems(invtypes.Data? transactions) {
    if (transactions == null) return [];

    // Only return MF transactions
    final filtered = transactions.mfs;

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date?.compareTo(a.date ?? DateTime.now()) ?? 0);
    return filtered;
  }

  // Group transactions by date and create list items with date headers
  List<Widget> _buildGroupedTransactionList(List<invtypes.Investment> items) {
    if (items.isEmpty) return [];

    final List<Widget> widgets = [];
    String? currentDateHeader;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final dateHeader = DateFormat(
        'd MMMM yyyy',
      ).format(item.date ?? DateTime.now());

      // Add date header if it's different from the previous one
      if (currentDateHeader != dateHeader) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 24)); // Space between date groups
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              header: true,
              child: AppText(
                dateHeader,
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
            ),
          ),
        );
        currentDateHeader = dateHeader;
      }

      // Add transaction card
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InvestmentTxnCard(
            name:
                (item.name != null && item.name!.isNotEmpty)
                    ? item.name!
                    : (widget.isinDescription ?? ''),

            amount:
                (item.txnamount != null && item.txnamount! > 0)
                    ? item.txnamount!
                    : (item.quantity ?? 0) * (item.currentMarketPrice ?? 0),
            category: item.category ?? '',
            type: item.type ?? '',
            qty: item.quantity ?? 0,
            price: item.avgBuyPrice ?? 0,
            date: item.date?.toString() ?? '',
            exchange: item.exchange ?? 0,
            rate: item.currentMarketPrice ?? 0,
            units: item.quantity ?? 0,
            totalGain: item.totalGainValue ?? 0,
            xirr: item.xirrPercent ?? 0,
            ltcg: item.ltcgValue ?? 0,
            stcg: item.stcgValue ?? 0,
            imageUrl: item.image_url,
            isin: item.isin,
            description: item.description,
            folio_no: item.folio_no,
            brokercode: item.brokercode,
            registrar: item.registrar,
          ),
        ),
      );
    }

    return widgets;
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
            const WhatsAppSupportButton(size: 20),
          ],
        ),
      ),
      body: SafeArea(
        child: GetBuilder<InvestmentTransactionController>(
          builder: (c) {
            // Filter and flatten categories based on selected filter
            final List<invtypes.Investment> items = _getFilteredItems(
              c.transactions,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.scaffoldHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter chips
                  // Center(
                  //   child: SizedBox(
                  //     height: 30,
                  //     child: ListView.separated(
                  //       scrollDirection: Axis.horizontal,
                  //       shrinkWrap: true,
                  //       itemCount: _filterOptions.length,
                  //       separatorBuilder: (_, __) => const SizedBox(width: 8),
                  //       itemBuilder: (context, index) {
                  //         final option = _filterOptions[index];
                  //         final isSelected = _selectedFilter == option;
                  //         return CategoryChip(
                  //           label: option,
                  //           isSelected: isSelected,
                  //           onTap: () {
                  //             setState(() {
                  //               _selectedFilter = option;
                  //             });
                  //           },
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  // AppText(
                  //   "Investment Transactions",
                  //   variant: AppTextVariant.headline6,
                  //   weight: AppTextWeight.bold,
                  //   colorType: AppTextColorType.primary,
                  // ),
                  // const SizedBox(height: 12),
                  if (_pageLoading && items.isEmpty)
                    const Center(child: LoadingWidget())
                  else if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.darkCardBG,
                                border: Border.all(
                                  color: AppColors.darkButtonBorder,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppText(
                              "No transactions yet",
                              variant: AppTextVariant.headline6,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                            const SizedBox(height: 6),
                            AppText(
                              "Your recent investment transactions will appear here.",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._buildGroupedTransactionList(items),
                            if (c.isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: LoadingWidget()),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InvestmentTxnCard extends StatefulWidget {
  final String name;
  final double amount;
  final String category;
  final String type;
  final double qty;
  final double price;
  final String date;
  final double exchange;
  final double rate;
  final double units;
  final double totalGain;
  final double xirr;
  final double ltcg;
  final double stcg;

  final String? imageUrl;
  final String? isin;
  final String? description;
  final String? folio_no;
  final String? brokercode;
  final String? registrar;
  final String? brokername;

  const _InvestmentTxnCard({
    required this.name,
    required this.amount,
    required this.category,
    required this.type,
    required this.qty,
    required this.price,
    required this.date,
    required this.exchange,
    required this.rate,
    required this.units,
    required this.totalGain,
    required this.xirr,
    required this.ltcg,
    required this.stcg,
    this.imageUrl,
    this.isin,
    this.description,
    this.folio_no,
    this.brokercode,
    this.registrar,
    this.brokername,
  });

  @override
  State<_InvestmentTxnCard> createState() => _InvestmentTxnCardState();
}

class _InvestmentTxnCardState extends State<_InvestmentTxnCard> {
  bool _expanded = false;
  final GlobalKey _localAccordionKey = GlobalKey();

  void _showSimpleBottomSheet(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
              vertical: 8,
            ),
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.headline4,
                  weight: AppTextWeight.bold,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 12),
                AppText(
                  description,
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.primary,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool hasInfoIcon = false,
    VoidCallback? onInfoIconTap,
  }) {
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppText(
                label,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.secondary,
              ),
              if (hasInfoIcon) ...[
                const SizedBox(width: 6),
                Semantics(
                  label: 'More info about $label',
                  button: true,
                  child: InkWell(
                    onTap: onInfoIconTap,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppText(
            value,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            customColor: valueColor ?? AppColors.darkTextPrimary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lookup holding for logo/name fallback
    final investmentController =
        Get.isRegistered<InvestmentController>()
            ? Get.find<InvestmentController>()
            : null;
    final holding = investmentController?.findHoldingByIsin(widget.isin);

    String effectiveName = widget.name;
    // Check if original name is empty, then fetch from holding or fallback
    if (effectiveName.isEmpty && holding != null) {
      String? holdingName;
      if (holding is Mf) holdingName = holding.name;
      if (holding is Stock) holdingName = holding.name;
      if (holding is Etf) holdingName = holding.name;

      if (holdingName != null && holdingName.isNotEmpty) {
        effectiveName = holdingName;
      }
    }

    String? effectiveImageUrl =
        (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ? widget.imageUrl
            : null;

    // Check if original logo is empty/null, then fetch from holding
    if (effectiveImageUrl == null && holding != null) {
      String? hLogo;
      if (holding is Mf) hLogo = holding.logo;
      if (holding is Stock) {
        hLogo = holding.icon ?? holding.logourl;
      }
      if (holding is Etf) hLogo = holding.logourl;

      if (hLogo != null && hLogo.isNotEmpty) {
        effectiveImageUrl = hLogo;
      }
    }

    // Build a summary label for the card
    final formattedAmt = CurrencyFormatter.formatRupeeWithCommas(widget.amount);
    final cardLabel =
        '${effectiveName.isNotEmpty ? effectiveName : 'Transaction'}, '
        '${widget.type.isNotEmpty ? '${widget.type}, ' : ''}'
        'transaction amount $formattedAmt';

    return Semantics(
      label: cardLabel,
      button: true,
      expanded: _expanded,
      hint:
          _expanded
              ? 'Double tap to collapse details'
              : 'Double tap to expand details',
      child: GestureDetector(
        onTap: () {
          // Toggle accordion expansion on card tap
          final st = _localAccordionKey.currentState;
          if (st != null) {
            (st as dynamic).toggle();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkButtonBorder),
          ),
          child: Column(
            children: [
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.scaffoldHorizontalPadding,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Avatar(
                        path: effectiveImageUrl ?? "",
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(12),
                        errorWidget: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.darkButtonBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              effectiveName.isNotEmpty
                                  ? effectiveName[0].toUpperCase()
                                  : '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppText(
                                    effectiveName,
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.semiBold,
                                    colorType: AppTextColorType.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      children: [
                                        AppText(
                                          "Txn Amount",
                                          variant: AppTextVariant.bodySmall,
                                          weight: AppTextWeight.medium,
                                          colorType: AppTextColorType.secondary,
                                        ),
                                        const SizedBox(height: 2),
                                        AppText(
                                          CurrencyFormatter.formatRupeeWithCommas(
                                            widget.amount,
                                          ),
                                          variant: AppTextVariant.bodyMedium,
                                          weight: AppTextWeight.semiBold,
                                          colorType: AppTextColorType.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedRotation(
                                      turns: _expanded ? 0.5 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.darkPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (widget.category != null) ...[
                              AppText(
                                widget.category,
                                variant: AppTextVariant.bodySmall,
                                weight: AppTextWeight.medium,
                                colorType: AppTextColorType.secondary,
                              ),
                            ],
                            if (widget.type != null) ...[
                              const SizedBox(height: 6),
                              AppText(
                                widget.type,
                                variant: AppTextVariant.bodySmall,
                                weight: AppTextWeight.medium,
                                colorType: AppTextColorType.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomAccordion(
                key: _localAccordionKey,
                title: "Details",
                backgroundColor: Colors.transparent,
                borderRadius: 0,
                padding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                showHeader: false,
                onChanged: (expanded) {
                  setState(() {
                    _expanded = expanded;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFF2B2F36)),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Average Price",
                      widget.category.toUpperCase().contains('MUTUAL')
                          ? CurrencyFormatter.formatRupeeWithCustomDecimals(
                              widget.price,
                              4,
                            )
                          : CurrencyFormatter.formatRupeeWithCommas(widget.price),
                      hasInfoIcon: true,
                      onInfoIconTap: () {
                        _showSimpleBottomSheet(
                          context,
                          "Average Price",
                          "The average price at which this transaction was executed. This helps calculate your overall gain/loss for the investment.",
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Date",
                      _formatTransactionDate(widget.date, widget.category),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      "Units",
                      widget.category.toUpperCase().contains('MUTUAL')
                          ? widget.units.toStringAsFixed(4)
                          : widget.units.toStringAsFixed(2),
                    ),

                    if (widget.totalGain != 0.0) ...[
                      const SizedBox(height: 12),

                      Container(height: 1, color: AppColors.darkInputHintText),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        "Total Gain",
                        "${widget.totalGain >= 0 ? '+' : ''}${CurrencyFormatter.formatRupeeWithCommas(widget.totalGain)}",
                        valueColor:
                            widget.totalGain >= 0
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    ],
                    if (widget.xirr != 0.0) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        "XIRR",
                        "${widget.xirr >= 0 ? '+' : ''}${widget.xirr.toStringAsFixed(2)}%",
                        valueColor:
                            widget.xirr >= 0
                                ? AppColors.success
                                : AppColors.error,
                        hasInfoIcon: true,
                        onInfoIconTap: () {
                          _showSimpleBottomSheet(
                            context,
                            "XIRR",
                            "XIRR calculates your overall return by considering the exact dates and amounts of all investments and withdrawals, whether done via SIP, lump sum, SWP, or any combination. It helps you see the true performance of your investment over time.",
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.folio_no != null &&
                        widget.folio_no!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(height: 1, color: AppColors.darkInputHintText),
                      const SizedBox(height: 12),
                      _buildDetailRow("Folio no", widget.folio_no!),
                      const SizedBox(height: 12),
                    ],
                    if (widget.brokername != null &&
                        widget.brokername!.isNotEmpty) ...[
                      _buildDetailRow("Broker Name", widget.brokername!),
                      const SizedBox(height: 12),
                    ],
                    if (widget.registrar != null &&
                        widget.registrar!.isNotEmpty) ...[
                      _buildDetailRow("Registrar", widget.registrar!),
                      // const SizedBox(height: 12),
                    ],
                    if (widget.description != null &&
                        widget.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(height: 1, color: AppColors.darkInputHintText),
                      const SizedBox(height: 12),
                      AppText(
                        widget.description!,
                        variant: AppTextVariant.bodyMedium,
                        weight: AppTextWeight.regular,
                        colorType: AppTextColorType.primary,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // const SizedBox(height: 12),
                    // LTCG and STCG in card layout
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: Container(
                    //           padding: const EdgeInsets.all(16),
                    //           decoration: BoxDecoration(
                    //             color: AppColors.darkButtonBorder,
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //           child: Column(
                    //             children: [
                    //               AppText(
                    //                 "LTCG",
                    //                 variant: AppTextVariant.bodySmall,
                    //                 weight: AppTextWeight.medium,
                    //                 colorType: AppTextColorType.secondary,
                    //               ),
                    //               const SizedBox(height: 4),
                    //               AppText(
                    //                 "${widget.ltcg >= 0 ? '+' : ''}${CurrencyFormatter.formatRupeeWithCommas(widget.ltcg)}",
                    //                 variant: AppTextVariant.bodyMedium,
                    //                 weight: AppTextWeight.semiBold,
                    //                 customColor: widget.ltcg >= 0 ? AppColors.success : AppColors.error,
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Container(
                    //           padding: const EdgeInsets.all(16),
                    //           decoration: BoxDecoration(
                    //             color: AppColors.darkButtonBorder,
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //           child: Column(
                    //             children: [
                    //               AppText(
                    //                 "STCG",
                    //                 variant: AppTextVariant.bodySmall,
                    //                 weight: AppTextWeight.medium,
                    //                 colorType: AppTextColorType.secondary,
                    //               ),
                    //               const SizedBox(height: 4),
                    //               AppText(
                    //                 "${widget.stcg >= 0 ? '+' : ''}${CurrencyFormatter.formatRupeeWithCommas(widget.stcg)}",
                    //                 variant: AppTextVariant.bodyMedium,
                    //                 weight: AppTextWeight.semiBold,
                    //                 customColor: widget.stcg >= 0 ? AppColors.success : AppColors.error,
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTransactionDate(String dateString, String type) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);

      // Show time for Equity and ETF, only date for Mutual Funds
      if (type.toUpperCase() == 'EQUITY' || type.toUpperCase() == 'ETF') {
        // Check if the time is meaningful (not just 00:00:00)
        if (parsedDate.hour != 0 ||
            parsedDate.minute != 0 ||
            parsedDate.second != 0) {
          return DateFormat('d MMMM yyyy, h:mm a').format(parsedDate);
        }
      }

      // Default: show only date
      return DateFormat('d MMMM yyyy').format(parsedDate);
    } catch (e) {
      // Fallback in case of parsing error
      return dateString;
    }
  }
}
