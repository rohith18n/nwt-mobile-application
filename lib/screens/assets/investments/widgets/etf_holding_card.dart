import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/investments/widgets/transaction.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/assets/investments/investments.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_realtime_controller.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/widgets/avatar.dart';

enum DeltaType { positive, negative, neutral }

class EtfHoldingCard extends StatefulWidget {
  final String fundName;
  final double nav;
  final double units;
  final double currentMarketValue;
  final String folioNo;
  final IconData? icon;
  final bool? isAmountVisible;
  final double? deltapercentage;
  final double? gainlosspercentage;
  final double? deltavalue;
  final double? gainloss;
  final double? investedvalue;
  final double? averageholdingprice;
  final double? currentmarketprice;
  final String? lasttransactiondate;
  final double? xirr;
  final String? isin; // Added ISIN parameter
  final int? count;
  final String? logourl;
  final bool forceStandardApis;

  const EtfHoldingCard({
    super.key,
    required this.fundName,
    required this.nav,
    required this.units,
    required this.currentMarketValue,
    required this.folioNo,
    this.icon = Icons.bar_chart_rounded,
    this.isAmountVisible = true,
    this.deltapercentage,
    this.gainlosspercentage,
    this.deltavalue,
    this.gainloss,
    this.investedvalue,
    this.averageholdingprice,
    this.currentmarketprice,
    this.lasttransactiondate,
    this.xirr,
    this.isin,
    this.count,
    this.logourl,
    this.forceStandardApis = false,
  });

  @override
  State<EtfHoldingCard> createState() => _EtfHoldingCardState();
}

class _EtfHoldingCardState extends State<EtfHoldingCard> {
  final GlobalKey _accordionKey = GlobalKey();
  final ValueNotifier<bool> _isAccordionExpanded = ValueNotifier<bool>(false);

  // Editable average holding price
  double _editableAveragePrice = 0.0;
  late final TextEditingController _inlinePriceController;

  // Service instance
  final InvestmentService _investmentService = InvestmentService();
  bool _isEditingPrice = false;

  @override
  void initState() {
    super.initState();
    _editableAveragePrice = widget.averageholdingprice ?? 0;
    _inlinePriceController = TextEditingController(
      text:
          _editableAveragePrice > 0
              ? _editableAveragePrice.toStringAsFixed(2)
              : "",
    );
  }

  @override
  void didUpdateWidget(covariant EtfHoldingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.averageholdingprice != oldWidget.averageholdingprice) {
      setState(() {
        _editableAveragePrice = widget.averageholdingprice ?? 0;
        _inlinePriceController.text =
            _editableAveragePrice > 0
                ? _editableAveragePrice.toStringAsFixed(2)
                : "";
      });
    }
  }

  @override
  void dispose() {
    _inlinePriceController.dispose();
    _isAccordionExpanded.dispose();
    super.dispose();
  }

  Future<void> _saveInlinePrice(String text) async {
    final newPrice = double.tryParse(text);
    if (newPrice != null && newPrice > 0) {
      if (widget.isin == null || widget.isin!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update: ISIN not available'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final response = await _investmentService.editAverageBuyPrice(
        category: "ETF",
        value: newPrice,
        isin: widget.isin!,
        onLoading: (isLoading) {
          setState(() {
            _isEditingPrice = isLoading;
          });
        },
      );

      if (response?.statusCode == 200) {
        setState(() {
          _editableAveragePrice = newPrice;
          _inlinePriceController.text = newPrice.toStringAsFixed(2);
        });
        Get.find<InvestmentController>().triggerRefresh();
        Get.find<PortfolioRealtimeController>().disconnect();
        Get.find<PortfolioRealtimeController>().connect();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (response?.message != null && response!.message.isNotEmpty)
                  ? response.message
                  : 'Average buy price updated to ₹${newPrice.toStringAsFixed(2)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (response?.message != null && response!.message.isNotEmpty)
                  ? response.message
                  : 'Failed to update average buy price',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool hasInfoIcon = false,
    bool hasEditIcon = false,
    bool islocked = false,
    VoidCallback? onInfoIconTap,
    VoidCallback? onEditIconTap,
  }) {
    final Widget rightSideWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        islocked
            ? Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.darkTextSecondary,
            )
            : AppText(
              value,
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              customColor: valueColor ?? AppColors.darkTextPrimary,
            ),
        if (hasEditIcon) ...[
          const SizedBox(width: 6),
          Icon(Icons.edit_outlined, size: 14, color: Colors.white),
        ],
      ],
    );

    final Widget interactiveRightSide =
        onEditIconTap != null
            ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEditIconTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 0.0,
                    top: 6.0,
                    bottom: 6.0,
                  ),
                  child: rightSideWidget,
                ),
              ),
            )
            : rightSideWidget;

    return Row(
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
              InkWell(
                onTap: onInfoIconTap,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        interactiveRightSide,
      ],
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
              //   "NAV",
              //   CurrencyFormatter.formatRupee(nav),
              // ),
              // const SizedBox(height: 12),
              _editableAveragePrice > 0
                  ? _buildDetailRow(
                    "Avg. buy price",
                    CurrencyFormatter.formatRupee(_editableAveragePrice),
                    hasInfoIcon: true,
                    hasEditIcon: true,
                    onInfoIconTap: () {
                      AnalyticsService.to.logEvent(
                        name:
                            AnalyticsEvents
                                .investmentsEtfHoldingAvgBuyPriceInfoClicked,
                        parameters: {
                          AnalyticsParams.investmentType: 'etf',
                          AnalyticsParams.isinCode: widget.isin ?? '',
                          AnalyticsParams.fundName: widget.fundName,
                        },
                      );
                      _showSimpleBottomSheet(
                        context,
                        "Avg. buy price",
                        "The buy price is approximate as we do not get accurate prices from Account Aggregator.",
                      );
                    },
                    onEditIconTap: () {
                      AnalyticsService.to.logEvent(
                        name: AnalyticsEvents.holdingCardEditClicked,
                        parameters: {
                          'field': 'avg_buy_price',
                          'fund_name': widget.fundName,
                          'investment_type': 'etf',
                          AnalyticsParams.isinCode: widget.isin ?? '',
                        },
                      );
                      AnalyticsService.to.logEvent(
                        name:
                            AnalyticsEvents
                                .investmentsEtfHoldingAvgBuyPriceEditClicked,
                        parameters: {
                          AnalyticsParams.investmentType: 'etf',
                          AnalyticsParams.isinCode: widget.isin ?? '',
                          AnalyticsParams.fundName: widget.fundName,
                          AnalyticsParams.oldPrice:
                              _editableAveragePrice.toString(),
                        },
                      );
                      _showEditPriceDialog();
                    },
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AppText(
                            "Avg. buy price",
                            variant: AppTextVariant.bodyMedium,
                            weight: AppTextWeight.medium,
                            colorType: AppTextColorType.secondary,
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              AnalyticsService.to.logEvent(
                                name:
                                    AnalyticsEvents
                                        .investmentsEtfHoldingAvgBuyPriceInfoClicked,
                                parameters: {
                                  AnalyticsParams.investmentType: 'etf',
                                  AnalyticsParams.isinCode: widget.isin ?? '',
                                  AnalyticsParams.fundName: widget.fundName,
                                },
                              );
                              _showSimpleBottomSheet(
                                context,
                                "Avg. buy price",
                                "The buy price is approximate as we do not get accurate prices from Account Aggregator.",
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.info_outline,
                                size: 14,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 32,
                            child: TextField(
                              onTapOutside: (event) {
                                FocusScope.of(context).unfocus();
                              },
                              controller: _inlinePriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Price',
                                hintStyle: TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 12,
                                ),
                                prefixText: '',
                                prefixStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkInputBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkInputBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.info),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isEditingPrice
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.info,
                                  ),
                                ),
                              )
                              : GestureDetector(
                                onTap:
                                    () => _saveInlinePrice(
                                      _inlinePriceController.text,
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AppText(
                                    "Save",
                                    variant: AppTextVariant.bodySmall,
                                    weight: AppTextWeight.bold,
                                    customColor: AppColors.success,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
              const SizedBox(height: 12),

              if (widget.investedvalue != null &&
                  widget.investedvalue != 0.0) ...[
                _buildDetailRow(
                  "Invested Value",
                  CurrencyFormatter.formatRupee(widget.investedvalue!),
                ),
                const SizedBox(height: 12),
                //Container(height: 1, color: AppColors.darkInputHintText),
              ],
              // const SizedBox(height: 12),
              _buildDetailRow(
                "Today's price",
                CurrencyFormatter.formatRupeeWithCustomDecimals(widget.nav, 2),
              ),
              const SizedBox(height: 12),

              if (widget.lasttransactiondate != null &&
                  widget.lasttransactiondate!.isNotEmpty) ...[
                _buildDetailRow(
                  "Last Transaction Date",
                  widget.lasttransactiondate!,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.xirr != null) ...[
                //   Container(height: 1, color: AppColors.darkInputHintText),
                // const SizedBox(height: 12),
                _buildDetailRow(
                  "CAGR",
                  "${widget.xirr!.toStringAsFixed(2)}%",
                  valueColor:
                      widget.xirr! >= 0 ? AppColors.success : AppColors.error,
                  onInfoIconTap: () {
                    AnalyticsService.to.logEvent(
                      name:
                          AnalyticsEvents.investmentsEtfHoldingXirrInfoClicked,
                      parameters: {
                        AnalyticsParams.investmentType: 'etf',
                        AnalyticsParams.isinCode: widget.isin ?? '',
                        AnalyticsParams.fundName: widget.fundName,
                      },
                    );
                    _showSimpleBottomSheet(
                      context,
                      "CAGR",
                      "CAGR (Compounded Annual Growth Rate) represents the annualized rate of return for your investment over time, assuming it grew at a steady rate.",
                    );
                  },
                  hasInfoIcon: true,
                ),
                const SizedBox(height: 12),
              ],
              // Today - show only if deltavalue is not null
              if (widget.deltavalue != null) ...[
                _buildDetailRow(
                  "Today's gain",
                  CurrencyFormatter.formatRupeeWithCommas(widget.deltavalue!),
                  valueColor:
                      widget.deltavalue! >= 0
                          ? AppColors.success
                          : AppColors.error,
                ),
                const SizedBox(height: 12),
              ],

              // Total gain - show only if gainloss is not null
              if (widget.gainloss != null && widget.gainloss != 0.0) ...[
                _buildDetailRow(
                  "Total gain",
                  CurrencyFormatter.formatRupeeWithCommas(widget.gainloss!),
                  valueColor:
                      widget.gainloss! >= 0
                          ? AppColors.success
                          : AppColors.error,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            AnalyticsService.to.logEvent(
              name: AnalyticsEvents.investmentsEtfHoldingTransactionsClicked,
              parameters: {
                AnalyticsParams.investmentType: 'etf',
                AnalyticsParams.isinCode: widget.isin ?? '',
                AnalyticsParams.fundName: widget.fundName,
                AnalyticsParams.transactionCount:
                    (widget.count ?? 0).toString(),
              },
            );
            Get.to(
              () => TransactionScreen(
                isinCode: widget.isin,
                forceStandardApis: true,
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
                    AppText(
                      "${widget.count ?? 0} total",
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.secondary,
                    ),
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
      ],
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
                path: widget.logourl ?? "",
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                //  backgroundColor: Colors.white,
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
                      widget.fundName.isNotEmpty
                          ? widget.fundName[0].toUpperCase()
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
                child: AppText(
                  widget.fundName,
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.primary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                    amount: CurrencyFormatter.formatRupee(
                      widget.currentMarketValue,
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
          // Performance Row
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
                    amount: widget.units.toString(),
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
                  // Show Today percentage only if deltapercentage is not null
                  if (widget.deltapercentage != null) ...[
                    AppText(
                      "${widget.deltapercentage! >= 0 ? '+' : ''}${widget.deltapercentage!.toStringAsFixed(2)}% Today",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.medium,
                      colorType:
                          widget.deltapercentage! >= 0
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
                          // Show Total percentage only if gainlosspercentage is not null
                          if (widget.gainlosspercentage != null &&
                              widget.gainlosspercentage != 0.0) ...[
                            AppText(
                              "${widget.gainlosspercentage! >= 0 ? '+' : ''}${widget.gainlosspercentage!.toStringAsFixed(2)}% Total",
                              variant: AppTextVariant.bodySmall,
                              weight: AppTextWeight.medium,
                              colorType:
                                  widget.gainlosspercentage! >= 0
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
    return GestureDetector(
      onTap: () {
        AnalyticsService.to.logEvent(
          name: AnalyticsEvents.investmentsEtfHoldingCardClicked,
          parameters: {
            AnalyticsParams.investmentType: 'etf',
            AnalyticsParams.isinCode: widget.isin ?? '',
            AnalyticsParams.fundName: widget.fundName,
            AnalyticsParams.marketValue: widget.currentMarketValue.toString(),
            AnalyticsParams.gainLossPercentage:
                (widget.gainlosspercentage ?? 0).toString(),
            AnalyticsParams.transactionCount: (widget.count ?? 0).toString(),
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
            _buildHeaderContent(),
            CustomAccordion(
              key: _accordionKey,
              title: "Details",
              backgroundColor: Colors.transparent,
              borderRadius: 0,
              padding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              showHeader: false,
              onChanged: (expanded) => _isAccordionExpanded.value = expanded,
              child: _buildExpandedContent(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPriceDialog() {
    final TextEditingController controller = TextEditingController(
      text:
          _editableAveragePrice > 0
              ? _editableAveragePrice.toStringAsFixed(2)
              : "",
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.darkCardBG,
              title: AppText(
                'Edit Average Buy Price',
                variant: AppTextVariant.headline5,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    'Enter the correct average buy price for ${widget.fundName}',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Average Buy Price',
                      labelStyle: TextStyle(color: AppColors.darkTextSecondary),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.darkInputBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.darkInputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.info),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (widget.averageholdingprice != null)
                  TextButton(
                    onPressed:
                        _isEditingPrice
                            ? null
                            : () async {
                              if (widget.isin == null || widget.isin!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to reset: ISIN not available',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              // Call the delete API
                              final response = await _investmentService
                                  .deleteAverageBuyPrice(
                                    isin: widget.isin!,
                                    onLoading: (isLoading) {
                                      setDialogState(() {
                                        _isEditingPrice = isLoading;
                                      });
                                      setState(() {
                                        _isEditingPrice = isLoading;
                                      });
                                    },
                                  );

                              if (response?.statusCode == 200) {
                                setState(() {
                                  _editableAveragePrice = 0.0;
                                  _inlinePriceController.text = "";
                                });
                                Navigator.of(context).pop();

                                // Refresh holdings
                                Get.find<InvestmentController>()
                                    .triggerRefresh();
                                Get.find<PortfolioRealtimeController>()
                                    .disconnect();
                                Get.find<PortfolioRealtimeController>()
                                    .connect();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      (response?.message != null &&
                                              response!.message.isNotEmpty)
                                          ? response.message
                                          : 'Average buy price reset successfully',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      (response?.message != null &&
                                              response!.message.isNotEmpty)
                                          ? response.message
                                          : 'Failed to reset average buy price',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                    child: AppText(
                      'Reset',
                      variant: AppTextVariant.bodyMedium,
                      customColor: AppColors.error,
                    ),
                  ),
                TextButton(
                  onPressed:
                      _isEditingPrice
                          ? null
                          : () {
                            AnalyticsService.to.logEvent(
                              name:
                                  AnalyticsEvents
                                      .investmentsEtfHoldingAvgBuyPriceEditCancelled,
                              parameters: {
                                AnalyticsParams.investmentType: 'etf',
                                AnalyticsParams.isinCode: widget.isin ?? '',
                                AnalyticsParams.fundName: widget.fundName,
                              },
                            );
                            Navigator.of(context).pop();
                          },
                  child: AppText(
                    'Cancel',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                  ),
                ),
                AppButton(
                  customHeight: 40,
                  text: 'Save',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                  isLoading: _isEditingPrice,
                  onPressed:
                      _isEditingPrice
                          ? null
                          : () async {
                            final newPrice = double.tryParse(controller.text);
                            if (newPrice != null && newPrice > 0) {
                              // Validate ISIN is available
                              if (widget.isin == null || widget.isin!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to update: ISIN not available',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              // Call the API to update average buy price with ETF category
                              final response = await _investmentService
                                  .editAverageBuyPrice(
                                    category: "ETF",
                                    value: newPrice,
                                    isin: widget.isin!,
                                    onLoading: (isLoading) {
                                      setDialogState(() {
                                        _isEditingPrice = isLoading;
                                      });
                                      setState(() {
                                        _isEditingPrice = isLoading;
                                      });
                                    },
                                  );

                              if (response?.statusCode == 200) {
                                final oldPrice =
                                    widget.averageholdingprice ?? 0;
                                final priceChangePercentage =
                                    oldPrice > 0
                                        ? ((newPrice - oldPrice) /
                                            oldPrice *
                                            100)
                                        : 0.0;

                                AnalyticsService.to.logEvent(
                                  name:
                                      AnalyticsEvents
                                          .investmentsEtfHoldingAvgBuyPriceEditSaved,
                                  parameters: {
                                    AnalyticsParams.investmentType: 'etf',
                                    AnalyticsParams.isinCode: widget.isin ?? '',
                                    AnalyticsParams.fundName: widget.fundName,
                                    AnalyticsParams.oldPrice:
                                        oldPrice.toString(),
                                    AnalyticsParams.newPrice:
                                        newPrice.toString(),
                                    AnalyticsParams.priceChangePercentage:
                                        priceChangePercentage.toString(),
                                  },
                                );

                                setState(() {
                                  _editableAveragePrice = newPrice;
                                  _inlinePriceController.text = newPrice
                                      .toStringAsFixed(2);
                                });
                                Navigator.of(context).pop();

                                // Refresh holdings
                                Get.find<InvestmentController>()
                                    .triggerRefresh();
                                Get.find<PortfolioRealtimeController>()
                                    .disconnect();
                                Get.find<PortfolioRealtimeController>()
                                    .connect();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      (response?.message != null &&
                                              response!.message.isNotEmpty)
                                          ? response.message
                                          : 'Average buy price updated to ₹${newPrice.toStringAsFixed(2)}',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                // Show API error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      (response?.message != null &&
                                              response!.message.isNotEmpty)
                                          ? response.message
                                          : 'Failed to update average buy price',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } else {
                              // Show validation error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid price'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
}
