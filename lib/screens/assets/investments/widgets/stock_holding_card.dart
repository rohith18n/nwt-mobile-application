import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/assets/investments/widgets/transaction.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/avatar.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/delta_indicator.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/services/assets/investments/investments.dart';
import 'package:nwt_app/controllers/assets/investments.dart';
import 'package:nwt_app/controllers/portfolio/portfolio_realtime_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

// Chart data class for Syncfusion chart
class ChartData {
  final DateTime date;
  final double value;

  ChartData(this.date, this.value);
}

// Using DeltaType from constants/enums.dart

class StockHoldingCard extends StatefulWidget {
  final String fundName;
  final double? costValue;
  final double currentAmount;
  final double? gainloss;
  final double? gainlosspercentage;
  final double quantity;
  final double? rate; // Added rate parameter
  final bool? isAmountVisible;
  final String? buydate;
  final double? delta;
  final double? deltaValue;
  final double? averageholdingprice;
  final String? navdate;
  final String? icon;
  final double? xirr;
  final double? deltapercentage;
  final String? lasttransactiondate;
  final String? isin; // Added ISIN parameter
  final int? count;
  final String? logourl;
  final bool forceStandardApis;

  const StockHoldingCard({
    super.key,
    required this.fundName,
    this.costValue,
    required this.currentAmount,
    this.gainloss,
    this.gainlosspercentage,
    required this.quantity,
    required this.rate,
    this.isAmountVisible = true,
    this.buydate,
    this.delta,
    this.deltaValue,
    this.averageholdingprice,
    this.navdate,
    this.icon,
    this.xirr,
    this.deltapercentage,
    this.lasttransactiondate,
    this.isin,
    this.count,
    this.logourl,
    this.forceStandardApis = false,
  });

  @override
  State<StockHoldingCard> createState() => _StockHoldingCardState();
}

class _StockHoldingCardState extends State<StockHoldingCard> {
  // Control chart animation
  late TooltipBehavior _tooltipBehavior;
  final bool _isInitialRender = true;
  final GlobalKey _accordionKey = GlobalKey();
  bool _isAccordionExpanded = false;

  // Editable average holding price
  double _editableAveragePrice = 0.0;
  late final TextEditingController _inlinePriceController;

  // Service instance
  final InvestmentService _investmentService = InvestmentService();
  bool _isEditingPrice = false;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: false);
    _editableAveragePrice = widget.averageholdingprice ?? 0;
    _inlinePriceController = TextEditingController(
      text:
          _editableAveragePrice > 0
              ? _editableAveragePrice.toStringAsFixed(2)
              : "",
    );
  }

  @override
  void didUpdateWidget(covariant StockHoldingCard oldWidget) {
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
        category: "EQUITY",
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

  Widget _buildDeltaIndicator(double deltaValue, DeltaType deltaType) {
    return SizedBox(
      width: 72,
      child: DeltaIndicator(
        deltaValue: deltaValue,
        deltaType: deltaType,
        textVariant: AppTextVariant.bodySmall,
        textWeight: AppTextWeight.medium,
        capValue: true,
      ),
    );
  }

  Widget _buildExpandedContent() {
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
              _editableAveragePrice > 0
                  ? _buildDetailRow(
                    "Avg. buy price",
                    CurrencyFormatter.formatRupeeWithDecimals(
                      _editableAveragePrice,
                    ),
                    hasInfoIcon: true,
                    hasEditIcon: true,
                    onInfoIconTap: () {
                      AnalyticsService.to.logEvent(
                        name:
                            AnalyticsEvents
                                .investmentsStockHoldingAvgBuyPriceInfoClicked,
                        parameters: {
                          AnalyticsParams.investmentType: 'stock',
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
                        name:
                            AnalyticsEvents
                                .investmentsStockHoldingAvgBuyPriceEditClicked,
                        parameters: {
                          AnalyticsParams.investmentType: 'equity',
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
                                        .investmentsStockHoldingAvgBuyPriceInfoClicked,
                                parameters: {
                                  AnalyticsParams.investmentType: 'stock',
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
              if (widget.costValue != null && widget.costValue != 0.0) ...[
                _buildDetailRow(
                  "Invested value",
                  CurrencyFormatter.formatRupeeWithDecimals(widget.costValue!),
                  // islocked: true,
                ),
                // const SizedBox(height: 12),
                //Container(height: 1, color: AppColors.darkInputHintText),
              ],

              // const SizedBox(height: 12),
              // _buildDetailRow("Quantity", widget.quantity.toStringAsFixed(2)),
              if (widget.rate != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  "Today's price",
                  CurrencyFormatter.formatRupeeWithCommas(widget.rate!),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.lasttransactiondate != null &&
                  widget.lasttransactiondate!.isNotEmpty) ...[
                _buildDetailRow(
                  "Last Transaction Date",
                  DateFormatter.formatToApiDate(
                    DateTime.parse(widget.lasttransactiondate!),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.xirr != null) ...[
                // Container(height: 1, color: AppColors.darkInputHintText),
                // const SizedBox(height: 12),
                _buildDetailRow(
                  "CAGR",
                  "${widget.xirr!.toStringAsFixed(2)}%",
                  valueColor:
                      widget.xirr! >= 0 ? AppColors.success : AppColors.error,
                  onInfoIconTap: () {
                    AnalyticsService.to.logEvent(
                      name:
                          AnalyticsEvents
                              .investmentsStockHoldingXirrInfoClicked,
                      parameters: {
                        AnalyticsParams.investmentType: 'stock',
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
              // Today - show only if deltaValue is not null
              if (widget.deltaValue != null) ...[
                _buildDetailRow(
                  "Today's gain",
                  CurrencyFormatter.formatRupeeWithCommas(widget.deltaValue!),
                  valueColor:
                      widget.deltaValue! >= 0
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
              // Tax Benefits Section
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
            ],
          ),
        ),
        // const SizedBox(height: 16),

        // const SizedBox(height: 16),

        // Transactions Button
        GestureDetector(
          onTap: () {
            AnalyticsService.to.logEvent(
              name: AnalyticsEvents.investmentsStockHoldingTransactionsClicked,
              parameters: {
                AnalyticsParams.investmentType: 'stock',
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
                    // AppText(
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

  DeltaType _getDeltaType(double percentage) {
    if (percentage > 0) return DeltaType.positive;
    if (percentage < 0) return DeltaType.negative;
    return DeltaType.neutral;
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
                    borderSide: BorderSide(color: AppColors.darkInputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.darkInputBorder),
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
                onPressed: () async {
                  if (widget.isin == null || widget.isin!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to reset: ISIN not available'),
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
                    Get.find<InvestmentController>().triggerRefresh();
                    Get.find<PortfolioRealtimeController>().disconnect();
                    Get.find<PortfolioRealtimeController>().connect();

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
              onPressed: () {
                AnalyticsService.to.logEvent(
                  name:
                      AnalyticsEvents
                          .investmentsStockHoldingAvgBuyPriceEditCancelled,
                  parameters: {
                    AnalyticsParams.investmentType: 'equity',
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
              onPressed: () async {
                final newPrice = double.tryParse(controller.text);
                if (newPrice != null && newPrice > 0) {
                  // Validate ISIN is available
                  if (widget.isin == null || widget.isin!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to update: ISIN not available'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  // Call the API to update average buy price
                  final response = await _investmentService.editAverageBuyPrice(
                    category: "EQUITY",
                    value: newPrice,
                    isin: widget.isin!,
                    onLoading: (isLoading) {
                      setState(() {
                        _isEditingPrice = isLoading;
                      });
                    },
                  );

                  if (response?.statusCode == 200) {
                    final oldPrice = widget.averageholdingprice ?? 0;
                    final priceChangePercentage =
                        oldPrice > 0
                            ? ((newPrice - oldPrice) / oldPrice * 100)
                            : 0.0;

                    AnalyticsService.to.logEvent(
                      name:
                          AnalyticsEvents
                              .investmentsStockHoldingAvgBuyPriceEditSaved,
                      parameters: {
                        AnalyticsParams.investmentType: 'equity',
                        AnalyticsParams.isinCode: widget.isin ?? '',
                        AnalyticsParams.fundName: widget.fundName,
                        AnalyticsParams.oldPrice: oldPrice.toString(),
                        AnalyticsParams.newPrice: newPrice.toString(),
                        AnalyticsParams.priceChangePercentage:
                            priceChangePercentage.toString(),
                      },
                    );

                    setState(() {
                      _editableAveragePrice = newPrice;
                      _inlinePriceController.text = newPrice.toStringAsFixed(2);
                    });
                    Navigator.of(context).pop();

                    // Refresh holdings
                    Get.find<InvestmentController>().triggerRefresh();
                    Get.find<PortfolioRealtimeController>().disconnect();
                    Get.find<PortfolioRealtimeController>().connect();

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
  }

  // Method removed as it's now handled by DeltaIndicator widget
  Widget _buildHeaderContent() {
    return Padding(
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
                //backgroundColor: Colors.white,
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
                child: InkWell(
                  // onTap:
                  //     () => Get.to(
                  //       () => InsightsScreen(isincode: mf.isin),
                  //       transition: Transition.rightToLeft,
                  //     ),
                  child: AppText(
                    widget.fundName,
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.semiBold,
                    colorType: AppTextColorType.primary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // const SizedBox(width: 12),
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.end,
              //   children: [
              //        AppText(
              //       "${(widget.gainloss ?? 0.0) >= 0 ? '+' : '-'}${CurrencyFormatter.formatRupeeWithCommas(widget.deltapercentage ?? 0.0)} Today",
              //       variant: AppTextVariant.bodySmall,
              //       weight: AppTextWeight.medium,
              //       colorType:
              //           (widget.gainloss ?? 0.0) >= 0
              //               ? AppTextColorType.success
              //               : AppTextColorType.error,
              //     ),
              //   ],
              // ),
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
                    amount: CurrencyFormatter.formatRupee(widget.currentAmount),
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
                    // amount: widget.quantity.toStringAsFixed(2),
                    amount: CurrencyFormatter.formatNumberWithCommas(
                      widget.quantity,
                      decimals: 0,
                    ),
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
                    turns: _isAccordionExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.darkPrimary,
                    ),
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
          name: AnalyticsEvents.investmentsStockHoldingCardClicked,
          parameters: {
            AnalyticsParams.investmentType: 'stock',
            AnalyticsParams.isinCode: widget.isin ?? '',
            AnalyticsParams.fundName: widget.fundName,
            AnalyticsParams.marketValue: widget.currentAmount.toString(),
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
            // Container(
            //   height: 1,
            //   color: AppColors.darkButtonBorder,
            //   margin: const EdgeInsets.symmetric(horizontal: 16),
            // ),
            CustomAccordion(
              key: _accordionKey,
              title: "Details",
              backgroundColor: Colors.transparent,
              borderRadius: 0,
              padding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              showHeader: false,
              onChanged: (expanded) {
                setState(() {
                  _isAccordionExpanded = expanded;
                });
              },
              child: _buildExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }
}
