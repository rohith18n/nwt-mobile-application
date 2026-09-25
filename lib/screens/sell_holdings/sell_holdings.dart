import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';
import 'package:nwt_app/constants/analytics.dart';
import 'widgets/fund_selection_widget.dart';
import 'widgets/sell_order_preview_widget.dart';

class SellHoldings extends StatefulWidget {
  const SellHoldings({super.key});

  @override
  State<SellHoldings> createState() => _SellHoldingsState();
}

class _SellHoldingsState extends State<SellHoldings> {
  int currentStep = 0;
  
  // Controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController unitsController = TextEditingController();
  
  // State variables
  String selectedFund = 'Franklin India Opportunities Fund';
  String folioNumber = '9214500367';
  String fundValue = '₹10,000.00';
  String totalUnits = '10.2';
  String withdrawAmount = '₹ 10,000.00';
  String withdrawUnits = '10.2';
  bool sellAllUnits = true;
  String totalGain = '+₹ 3,398.90 (+11.87%)';
  String exitLoad = '₹ 10.00';
  String ltcg = '+₹ 2,000.90';
  String stcg = '+₹ 1,398';
  
  // Order Preview variables
  String paymentStatus = 'Successful';
  String paymentMode = 'UPI';
  String bankName = 'Bank of Baroda';
  String triggerTime = '14 Oct 2025, 6:05 pm';
  String navDate = '14 Oct 2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            AnalyticsService.to.logEvent(name: AnalyticsEvents.sellHoldingsBackClicked);
            Navigator.pop(context);
          },
        ),
        title: AppText(
          _getScreenTitle(),
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
          colorType: AppTextColorType.white,
        ),
        centerTitle: true,
      ),
      body: _buildCurrentScreen(),
    );
  }

  String _getScreenTitle() {
    switch (currentStep) {
      case 0:
        return 'Sell Funds';
      case 1:
        return 'Order Preview';
      default:
        return 'Sell Holdings';
    }
  }

  Widget _buildCurrentScreen() {
    switch (currentStep) {
      case 0:
        return FundSelectionWidget(
          selectedFund: selectedFund,
          folioNumber: folioNumber,
          fundValue: fundValue,
          totalUnits: totalUnits,
          withdrawAmount: withdrawAmount,
          withdrawUnits: withdrawUnits,
          sellAllUnits: sellAllUnits,
          totalGain: totalGain,
          exitLoad: exitLoad,
          ltcg: ltcg,
          stcg: stcg,
          amountController: amountController,
          unitsController: unitsController,
          onSellAllUnitsChanged: (value) {
            setState(() {
              sellAllUnits = value;
            });
          },
          onAmountChanged: (value) {
            setState(() {
              withdrawAmount = value;
            });
          },
          onUnitsChanged: (value) {
            setState(() {
              withdrawUnits = value;
            });
          },
          onContinue: () {
            setState(() {
              currentStep = 1;
            });
          },
        );
      case 1:
        return SellOrderPreviewWidget(
          fundName: selectedFund,
          amount: withdrawAmount,
          units: withdrawUnits,
          paymentStatus: paymentStatus,
          paymentMode: paymentMode,
          bankName: bankName,
          triggerTime: triggerTime,
          navDate: navDate,
          folioNumber: folioNumber,
          onNext: () {
            // Handle completion - go back to main screen
            Navigator.pop(context);
          },
        );
      default:
        return FundSelectionWidget(
          selectedFund: selectedFund,
          folioNumber: folioNumber,
          fundValue: fundValue,
          totalUnits: totalUnits,
          withdrawAmount: withdrawAmount,
          withdrawUnits: withdrawUnits,
          sellAllUnits: sellAllUnits,
          totalGain: totalGain,
          exitLoad: exitLoad,
          ltcg: ltcg,
          stcg: stcg,
          amountController: amountController,
          unitsController: unitsController,
          onSellAllUnitsChanged: (value) {
            setState(() {
              sellAllUnits = value;
            });
          },
          onAmountChanged: (value) {
            setState(() {
              withdrawAmount = value;
            });
          },
          onUnitsChanged: (value) {
            setState(() {
              withdrawUnits = value;
            });
          },
          onContinue: () {
            Navigator.pop(context);
          },
        );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    unitsController.dispose();
    super.dispose();
  }
}