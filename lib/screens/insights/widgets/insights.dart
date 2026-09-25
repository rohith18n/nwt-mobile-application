import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/screens/assets/investments/types/holdings.dart';
import 'package:nwt_app/screens/insights/types/insights.dart';
import 'package:nwt_app/screens/insights/widgets/asset_allocation_widget.dart';
import 'package:nwt_app/screens/insights/widgets/dividend_history_widget.dart';
import 'package:nwt_app/screens/insights/widgets/fund_details_widget.dart';
import 'package:nwt_app/screens/insights/widgets/holding_details.dart';
import 'package:nwt_app/screens/insights/widgets/insights_graph.dart';
import 'package:nwt_app/screens/insights/widgets/riskometer_widget.dart';
import 'package:nwt_app/screens/insights/widgets/sector_allocation_widget.dart';
import 'package:nwt_app/screens/insights/widgets/top_holdings_widget.dart';
import 'package:nwt_app/services/insights/insights.dart';
import 'package:nwt_app/utils/date_formatter.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class MutualFundsInsightWidget extends StatefulWidget {
  final InsightsSummary? insightData;
  final Function(String period)? onPeriodSelected;
  final Mf? holding;
  final String isin;
  final bool showAbsoluteReturns;
  final String selectedPeriod;

  const MutualFundsInsightWidget({
    super.key,
    this.holding,
    this.insightData,
    this.onPeriodSelected,
    required this.isin,
    this.showAbsoluteReturns = false,
    this.selectedPeriod = '3M',
  });

  @override
  State<MutualFundsInsightWidget> createState() =>
      _MutualFundsInsightWidgetState();
}

class _MutualFundsInsightWidgetState extends State<MutualFundsInsightWidget> {
  final InsightsService _insightsService = InsightsService();

  void _onPeriodSelected(String period, double returnValue) {
    if (widget.onPeriodSelected != null) {
      widget.onPeriodSelected!(period);
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return widget.insightData == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: InsightsGraphWidget(
                riskLevel: widget.insightData!.riskometer.name,
                fundName: widget.insightData!.fundname,
                fundType: widget.insightData!.fundtype,
                navValue: widget.insightData!.nav,
                returnPercentage: widget.insightData!.navdelta,
                showAbsoluteReturns: widget.showAbsoluteReturns,
                selectedPeriod: widget.selectedPeriod,
                onPeriodSelected: _onPeriodSelected,
                oneMonthData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .oneMonth ??
                    [],
                threeMonthData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .threeMonths ??
                    [],
                sixMonthData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .sixMonths ??
                    [],
                oneYearData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .oneYear ??
                    [],
                threeYearData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .threeYears ??
                    [],
                fiveYearData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .fiveYears ??
                    [],
                tenYearData:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .tenYears ??
                    [],
                all:
                    widget
                        .insightData
                        ?.mfreturnandsipreturn
                        .mfreturnandsipreturnReturn
                        .all ??
                    [],
                sipOneMonthData: [],
                sipThreeMonthData: [],
                sipSixMonthData: [],
                sipOneYearData: [],
                sipThreeYearData: [],
                sipFiveYearData: [],
                sipTenYearData: [],
                sipAll: [],
              ),
            ),
            if (widget.holding != null)
              HoldingDetails(
                investedAmount: widget.holding!.costvalue,
                currentAmount: widget.holding!.currentmktvalue,
                gain: widget.holding!.gainloss ?? 0.0,
                gainPercentage: widget.holding!.gainlosspercentage ?? 0.0,
                investedSince: DateFormatter.formatToApiDate(
                  widget.holding!.createdat,
                ),
                lasttrxndate: widget.holding!.lasttrxndate ?? '',
                folioNo: widget.holding!.folio,
                quantity: widget.holding!.quantity,
              ),
            if (widget.insightData!.objective != null)
              CustomAccordion(
                initiallyExpanded: true,
                title: "Fund Objective",
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AppText(
                    widget.insightData!.objective ?? "",
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.regular,
                  ),
                ),
              ),
            FundDetailsWidget(
              expenseRatio: '${widget.insightData!.funddetail.expenseratio}%',
              minsip: widget.insightData!.sipdetail.minimumsip,
              minInvestment: widget.insightData!.sipdetail.minimumlumpsum,
              investmentStyle: widget.insightData!.funddetail.investmentstyle,
              fundManager:
                  widget.insightData!.funddetail.fundmanager.isNotEmpty
                      ? widget.insightData!.funddetail.fundmanager[0].name
                      : '',
              aum: widget.insightData!.funddetail.aum,
              exitLoad: widget.insightData!.funddetail.exitload,
            ),
            AssetAllocationWidget(
              assetItems: [
                AssetItem(
                  name: 'Equity',
                  percentage: widget.insightData!.assetallocation.equity,
                  color: const Color(0xFF36D399),
                ),
                AssetItem(
                  name: 'Debt',
                  percentage: widget.insightData!.assetallocation.debt,
                  color: const Color(0xFF8B5CF6),
                ),
                AssetItem(
                  name: 'Hybrid',
                  percentage: widget.insightData!.assetallocation.hybrid,
                  color: const Color(0xFFFFC000),
                ),
              ],
            ),
            widget.insightData!.sectorallocation.sectors.isNotEmpty
                ? SectorAllocationWidget.fromSectorallocation(
                  widget.insightData!.sectorallocation,
                )
                : const SizedBox(),
            widget.insightData!.dividendhistory.isNotEmpty
                ? DividendHistoryWidget(
                  dividendItems:
                      widget.insightData!.dividendhistory
                          .map(
                            (dividend) => DividendItem(
                              recordDate:
                                  "${dividend.recorddate.day} ${_getMonthName(dividend.recorddate.month)} ${dividend.recorddate.year}",
                              dividend: dividend.dividend.toString(),
                            ),
                          )
                          .toList(),
                )
                : const SizedBox(),
            if (widget.insightData!.topHoldings.isNotEmpty)
              TopHoldingsWidget(
                holdingItems:
                    widget.insightData!.topHoldings
                        .map(
                          (holding) => HoldingItem(
                            name: holding.name,
                            logoUrl: holding.name,
                            percentage: holding.value,
                            logoBackground: AppColors.darkInputBorder,
                          ),
                        )
                        .toList(),
              ),
            RiskometerWidget(
              riskLevel: widget.insightData!.riskometer.name,
              riskValue: 30,
            ),
            const SizedBox(height: 100),
          ],
        );
  }
}
