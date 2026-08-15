import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/widgets/mf_transaction.dart';
import 'package:nwt_app/screens/insights/insights.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/delta_indicator.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

class HoldingCard extends StatefulWidget {
  final Mf mf;
  final IconData? icon;
  final bool? isAmountVisible;
  final bool forceStandardApis;

  const HoldingCard({
    super.key,
    required this.mf,
    this.icon = Icons.account_balance_outlined,
    this.isAmountVisible = true,
    this.forceStandardApis = false,
  });

  @override
  State<HoldingCard> createState() => _HoldingCardState();
}

class _HoldingCardState extends State<HoldingCard> {
  final GlobalKey _accordionKey = GlobalKey();
  final ValueNotifier<bool> _isAccordionExpanded = ValueNotifier<bool>(false);

  @override
  void initState() {
    AppLogger.info(
      "Mode of Holding: ${widget.mf.modeofholding}",
      tag: "HoldingCard",
    );
    super.initState();
  }

  @override
  void dispose() {
    _isAccordionExpanded.dispose();
    super.dispose();
  }

  DeltaType _getDeltaType(double percentage) {
    if (percentage > 0) return DeltaType.positive;
    if (percentage < 0) return DeltaType.negative;
    return DeltaType.neutral;
  }

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

  Widget _buildDeltaIndicator(double deltaValue, DeltaType deltaType) {
    return SizedBox(
      width: 72,
      child: Center(
        child: DeltaIndicator(
          deltaValue: deltaValue,
          deltaType: deltaType,
          textVariant: AppTextVariant.bodySmall,
          textWeight: AppTextWeight.medium,
          capValue: true,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // _buildDetailRow(
              //   "SWP amount",
              //   mf.swapamount == null
              //       ? "-"
              //       : CurrencyFormatter.formatRupeeWithDecimals(mf.swapamount!),
              // ),
              // const SizedBox(height: 12),
              // _buildDetailRow("Frequency", mf.frequency ?? "-"),
              // const SizedBox(height: 12),
              // _buildDetailRow(
              //   "Installments",
              //   (mf.installments == null || mf.installments!.isEmpty)
              //       ? "-"
              //       : mf.installments!,
              // ),
              // const SizedBox(height: 12),
              // _buildDetailRow(
              //   "Next Installments",
              //   (mf.nextinstallments == null || mf.nextinstallments!.isEmpty)
              //       ? "-"
              //       : mf.nextinstallments!,
              // ),
              // const SizedBox(height: 12),
              // Container(height: 1, color: AppColors.darkInputHintText),
              const SizedBox(height: 12),
              _buildDetailRow(
                "NAV",
                CurrencyFormatter.formatRupeeWithCustomDecimals(
                  widget.mf.nav,
                  4,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.mf.lasttrxndate != null &&
                  widget.mf.lasttrxndate!.isNotEmpty &&
                  widget.mf.lasttrxndate != "-") ...[
                _buildDetailRow(
                  "Last Transaction Date",
                  widget.mf.lasttrxndate!,
                ),
                const SizedBox(height: 12),
              ],

              if (widget.mf.holdingavgprice != null) ...[
                _buildDetailRow(
                  "Avg. buy price",
                  CurrencyFormatter.formatRupeeWithCustomDecimals(
                    widget.mf.holdingavgprice!,
                    4,
                  ),
                  onInfoIconTap: () {
                    AnalyticsService.to.logEvent(
                      name:
                          AnalyticsEvents
                              .investmentsMfHoldingAvgBuyPriceInfoClicked,
                      parameters: {
                        AnalyticsParams.investmentType: 'mutual_fund',
                        AnalyticsParams.isinCode: widget.mf.isin,
                        AnalyticsParams.fundName: widget.mf.name,
                      },
                    );
                    _showSimpleBottomSheet(
                      context,
                      "Avg. buy price",
                      "Account Aggregator sometimes does not provide accurate purchase prices. This reflects your average cost calculated from available transaction data.",
                    );
                  },
                  onEditIconTap: () {
                    AnalyticsService.to.logEvent(
                      name: AnalyticsEvents.holdingCardEditClicked,
                      parameters: {
                        'field': 'avg_buy_price',
                        'fund_name': widget.mf.name,
                        AnalyticsParams.isinCode: widget.mf.isin,
                      },
                    );
                    // Actual edit logic could be added here later
                  },
                  hasInfoIcon: true,
                  hasEditIcon: false,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.mf.costvalue != 0.0) ...[
                _buildDetailRow(
                  "Invested value",
                  CurrencyFormatter.formatRupeeWithDecimals(
                    widget.mf.costvalue,
                  ),
                ),
                //   const SizedBox(height: 12),
              ],
              if (widget.mf.xirrvalue != null) ...[
                const SizedBox(height: 12),

                Builder(
                  builder: (context) {
                    AppLogger.info(
                      'MF XIRR Display Check - Fund: ${widget.mf.name}, ISIN: ${widget.mf.isin}, xirrvalue: ${widget.mf.xirrvalue}, isNull: ${widget.mf.xirrvalue == null}',
                      tag: 'xirr',
                    );
                    return _buildDetailRow(
                      "XIRR",
                      widget.mf.xirrvalue == null
                          ? "-"
                          : "${widget.mf.xirrvalue?.toStringAsFixed(2)}%",
                      valueColor:
                          widget.mf.xirrvalue == null
                              ? null
                              : (widget.mf.xirrvalue ?? 0.0) >= 0
                              ? AppColors.success
                              : AppColors.error,
                      onInfoIconTap: () {
                        AnalyticsService.to.logEvent(
                          name:
                              AnalyticsEvents
                                  .investmentsMfHoldingXirrInfoClicked,
                          parameters: {
                            AnalyticsParams.investmentType: 'mutual_fund',
                            AnalyticsParams.isinCode: widget.mf.isin,
                            AnalyticsParams.fundName: widget.mf.name,
                          },
                        );
                        _showSimpleBottomSheet(
                          context,
                          "XIRR",
                          "XIRR calculates your overall return by considering the exact dates and amounts of all investments and withdrawals, whether done via SIP, lump sum, SWP, or any combination. It helps you see the true performance of your mutual fund over time.",
                        );
                      },
                      hasInfoIcon: true,
                    );
                  },
                ),
              ],
              if (widget.mf.modeofholding != null &&
                  widget.mf.modeofholding!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow("Mode of Holding", widget.mf.modeofholding!),
              ],
              if (widget.mf.lienunits != null && widget.mf.lienunits! > 0) ...[
                _buildDetailRow(
                  "Lien Units",
                  widget.mf.lienunits!.toStringAsFixed(4),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 12),
              if (widget.mf.deltavalue != null) ...[
                //  Container(height: 1, color: AppColors.darkInputHintText),
                //const SizedBox(height: 12),
                _buildDetailRow(
                  "Today's gain",
                  CurrencyFormatter.formatRupeeWithCommas(
                    widget.mf.deltavalue!,
                  ),
                  valueColor:
                      (widget.mf.deltavalue! >= 0)
                          ? AppColors.success
                          : AppColors.error,
                ),
                const SizedBox(height: 12),
              ],

              // Total gain - show only if gainloss is not null
              if (widget.mf.gainloss != null && widget.mf.gainloss != 0.0) ...[
                _buildDetailRow(
                  "Total gain",
                  CurrencyFormatter.formatRupeeWithCommas(widget.mf.gainloss!),
                  valueColor:
                      (widget.mf.gainloss ?? 0.0) >= 0
                          ? AppColors.success
                          : AppColors.error,
                ),
                const SizedBox(height: 12),
              ],
              // const SizedBox(height: 12),
              if (widget.mf.nomineestatus != null &&
                  widget.mf.nomineestatus!.isNotEmpty) ...[
                _buildDetailRow(
                  "Nominee status",
                  widget.mf.nomineestatus == 'Y'
                      ? 'Yes'
                      : widget.mf.nomineestatus == 'N'
                      ? 'No'
                      : widget.mf.nomineestatus!,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.mf.isdemat != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Demat",
                  widget.mf.isdemat == true
                      ? 'Yes'
                      : widget.mf.isdemat == false
                      ? 'No'
                      : widget.mf.isdemat.toString(),
                ),
              ],
              if (widget.mf.brokername != null &&
                  widget.mf.brokername!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow("Broker Name", widget.mf.brokername!),
              ],
              // const SizedBox(height: 12),
              // Container(height: 1, color: AppColors.darkInputHintText),
              // const SizedBox(height: 12),
              // _buildDetailRow(
              //   "XIRR",
              //   mf.xirrvalue == null
              //       ? "-"
              //       : "${mf.xirrvalue?.toStringAsFixed(2)}%",
              //   valueColor:
              //       mf.xirrvalue == null
              //           ? null
              //           : (mf.xirrvalue ?? 0.0) >= 0
              //           ? AppColors.success
              //           : AppColors.error,
              //   onInfoIconTap: () {
              //     _showSimpleBottomSheet(
              //       context,
              //       "XIRR",
              //       "XIRR calculates your overall return by considering the exact dates and amounts of all investments and withdrawals, whether done via SIP, lump sum, SWP, or any combination. It helps you see the true performance of your mutual fund over time.",
              //     );
              //   },
              //   hasInfoIcon: true,
              // ),
            ],
          ),
        ),
        // Container(height: 1, color: AppColors.darkInputHintText),
        // const SizedBox(height: 16),
        // // Tax Benefits Section
        // Row(
        //   children: [
        //     Expanded(
        //       child: Container(
        //         padding: const EdgeInsets.all(16),
        //         decoration: BoxDecoration(
        //           color: AppColors.darkButtonBorder,
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         child: Column(
        //           children: [
        //             AppText(
        //               "LTCG",
        //               variant: AppTextVariant.bodySmall,
        //               weight: AppTextWeight.medium,
        //               colorType: AppTextColorType.secondary,
        //             ),
        //             const SizedBox(height: 4),
        //             AppText(
        //               "+₹ 2,000.90",
        //               variant: AppTextVariant.bodyMedium,
        //               weight: AppTextWeight.semiBold,
        //               colorType: AppTextColorType.success,
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: Container(
        //         padding: const EdgeInsets.all(16),
        //         decoration: BoxDecoration(
        //           color: AppColors.darkButtonBorder,
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         child: Column(
        //           children: [
        //             AppText(
        //               "STCG",
        //               variant: AppTextVariant.bodySmall,
        //               weight: AppTextWeight.medium,
        //               colorType: AppTextColorType.secondary,
        //             ),
        //             const SizedBox(height: 4),
        //             AppText(
        //               "+₹ 1,398",
        //               variant: AppTextVariant.bodyMedium,
        //               weight: AppTextWeight.semiBold,
        //               colorType: AppTextColorType.success,
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ],
        // ),

        // const SizedBox(height: 16),

        // Transactions Button
        Semantics(
          label:
              widget.mf.count != null && widget.mf.count! > 0
                  ? 'Transactions, ${widget.mf.count} total'
                  : 'Transactions',
          button: true,
          hint: 'Opens transaction history for ${widget.mf.name}',
          child: GestureDetector(
            onTap: () {
              AnalyticsService.to.logEvent(
                name: AnalyticsEvents.investmentsMfHoldingTransactionsClicked,
                parameters: {
                  AnalyticsParams.investmentType: 'mutual_fund',
                  AnalyticsParams.isinCode: widget.mf.isin,
                  AnalyticsParams.fundName: widget.mf.name,
                  AnalyticsParams.transactionCount:
                      (widget.mf.count ?? 0).toString(),
                },
              );
              Get.to(
                () => MfTransactionScreen(
                  isinCode: widget.mf.isin,
                  isinDescription: widget.mf.name,
                  folioNo: widget.mf.folio,
                  forceStandardApis: widget.forceStandardApis,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.darkButtonBorder,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      "Transactions",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                    ),
                    Row(
                      children: [
                        if (widget.mf.count != null &&
                            widget.mf.count! > 0) ...[
                          AppText(
                            "${widget.mf.count ?? 0} total",
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.medium,
                            colorType: AppTextColorType.secondary,
                          ),
                        ],
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.darkTextSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool hasEditIcon = false,
    bool hasInfoIcon = false,
    VoidCallback? onInfoIconTap,
    VoidCallback? onEditIconTap,
  }) {
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: AppText(
                    value,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    customColor: valueColor ?? AppColors.darkTextPrimary,
                    textAlign: TextAlign.end,
                  ),
                ),
                if (hasEditIcon) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Edit $label',
                    button: true,
                    child: InkWell(
                      onTap: onEditIconTap,
                      child: ExcludeSemantics(
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Padding(
      // padding: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fund Name Row
          Row(
            children: [
              Avatar(
                path: widget.mf.logo ?? "",
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                // backgroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                errorWidget: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.darkButtonBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.mf.name.isNotEmpty
                          ? widget.mf.name[0].toUpperCase()
                          : '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: '${widget.mf.name}, view fund insights',
                  button: true,
                  hint: 'Opens fund insights',
                  // child: InkWell(
                  //   onTap: () {
                  //     AnalyticsService.to.logEvent(
                  //       name: AnalyticsEvents.investmentsMfHoldingFundNameClicked,
                  //       parameters: {
                  //         AnalyticsParams.investmentType: 'mutual_fund',
                  //         AnalyticsParams.isinCode: widget.mf.isin,
                  //         AnalyticsParams.fundName: widget.mf.name,
                  //       },
                  //     );
                  //     Get.to(
                  //       () => InsightsScreen(isincode: widget.mf.isin),
                  //       transition: Transition.rightToLeft,
                  //     );
                  //   },
                  child: ExcludeSemantics(
                    child: AppText(
                      widget.mf.name,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ),
                ),
              ),
              Column(
                children: [
                  AppText(
                    "Market Value",
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.secondary,
                  ),
                  const SizedBox(height: 4),
                  AnimatedAmount(
                    isAmountVisible: widget.isAmountVisible ?? true,
                    amount: CurrencyFormatter.formatRupeeWithDecimals(
                      widget.mf.currentmktvalue,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Market Value and Performance Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.darkTextSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  AnimatedAmount(
                    isAmountVisible: widget.isAmountVisible ?? true,
                    amount: widget.mf.quantity.toStringAsFixed(4),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.mf.deltapercentage != null) ...[
                    AppText(
                      "${widget.mf.deltapercentage! >= 0 ? '+' : ''}${widget.mf.deltapercentage!.toStringAsFixed(2)}% Today",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType:
                          widget.mf.deltapercentage! >= 0
                              ? AppTextColorType.success
                              : AppTextColorType.error,
                    ),
                    const SizedBox(width: 8),
                  ],
                  ValueListenableBuilder<bool>(
                    valueListenable: _isAccordionExpanded,
                    builder: (context, expanded, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.mf.gainlosspercentage != null &&
                              widget.mf.gainlosspercentage != 0.0) ...[
                            AppText(
                              "${widget.mf.gainlosspercentage! >= 0 ? '+' : ''}${widget.mf.gainlosspercentage!.toStringAsFixed(2)}% Total",
                              variant: AppTextVariant.bodySmall,
                              weight: AppTextWeight.medium,
                              colorType:
                                  widget.mf.gainlosspercentage! >= 0
                                      ? AppTextColorType.success
                                      : AppTextColorType.error,
                            ),
                            const SizedBox(width: 4),
                          ],
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.darkPrimary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isAccordionExpanded,
      builder: (context, expanded, _) {
        final marketValue = CurrencyFormatter.formatRupeeWithDecimals(
          widget.mf.currentmktvalue,
        );
        final gainLossPct =
            widget.mf.gainlosspercentage != null
                ? '${widget.mf.gainlosspercentage! >= 0 ? '+' : ''}${widget.mf.gainlosspercentage!.toStringAsFixed(2)}% total gain'
                : '';
        final semanticLabel =
            '${widget.mf.name}, market value $marketValue${gainLossPct.isNotEmpty ? ', $gainLossPct' : ''}';

        return Semantics(
          label: semanticLabel,
          button: true,
          expanded: expanded,
          hint:
              expanded
                  ? 'Double tap to collapse details'
                  : 'Double tap to expand details',
          child: GestureDetector(
            onTap: () {
              AnalyticsService.to.logEvent(
                name: AnalyticsEvents.investmentsMfHoldingCardClicked,
                parameters: {
                  AnalyticsParams.investmentType: 'mutual_fund',
                  AnalyticsParams.isinCode: widget.mf.isin,
                  AnalyticsParams.fundName: widget.mf.name,
                  AnalyticsParams.marketValue:
                      widget.mf.currentmktvalue.toString(),
                  AnalyticsParams.gainLossPercentage:
                      widget.mf.gainlosspercentage.toString(),
                  AnalyticsParams.transactionCount:
                      (widget.mf.count ?? 0).toString(),
                },
              );
              // Toggle accordion expansion on card tap
              final st = _accordionKey.currentState;
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
                  ExcludeSemantics(child: _buildHeaderContent()),
                  CustomAccordion(
                    key: _accordionKey,
                    title: "Details",
                    backgroundColor: Colors.transparent,
                    borderRadius: 0,
                    padding: EdgeInsets.zero,
                    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    showHeader: false,
                    onChanged:
                        (expanded) => _isAccordionExpanded.value = expanded,
                    child: _buildExpandedContent(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
