import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/screens/paper_trading/widget/paper_trading_history_card.dart';
import 'package:nwt_app/widgets/common/animated_error_message.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PaperTradingHistory extends StatefulWidget {
  const PaperTradingHistory({super.key});

  @override
  State<PaperTradingHistory> createState() => _PaperTradingHistoryState();
}

class _PaperTradingHistoryState extends State<PaperTradingHistory> {
  final String _errorMessage = '';
  final bool _isLoading = false;

  // Sample data for trade history
  final List<Map<String, dynamic>> _julyTrades = [
    {
      'symbol': 'Reliance',
      'logo': 'R',
      'quantity': 100,
      'invested': 100000.0,
      'current': 112000.0,
      'gain': 12000.0,
      'percentage': '12',
      'average': '₹1,000',
      'type': 'buy',
    },
    {
      'symbol': 'Tata Motors',
      'logo': 'T',
      'quantity': 100,
      'invested': 100000.0,
      'current': 118000.0,
      'gain': 12000.0,
      'percentage': '10',
      'average': '₹700',
      'type': 'buy',
    },
    {
      'symbol': 'TCS',
      'logo': 'T',
      'quantity': 100,
      'invested': 100000.0,
      'current': 108000.0,
      'gain': 10000.0,
      'percentage': '11',
      'average': '₹2,500',
      'type': 'sell',
    },
  ];

  final List<Map<String, dynamic>> _juneTrades = [];

  final List<Map<String, dynamic>> _mayTrades = [
    {
      'symbol': 'ICICI Bank',
      'logo': 'I',
      'quantity': 50,
      'invested': 100000.0,
      'current': 70000.0,
      'gain': -12000.0,
      'percentage': '-15.5',
      'average': '₹800',
      'type': 'sell',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
              "Paper Trading History",
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.semiBold,
            ),
            const Opacity(opacity: 0, child: Icon(Icons.chevron_left, size: 32)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.scaffoldHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),

                // July 2025 Accordion
                CustomAccordion(
                  title: "July 2025",
                  initiallyExpanded: true,
                  backgroundColor: AppColors.darkInputBackground,
                  child: Column(
                    spacing: 12.h,
                    children:
                        _julyTrades
                            .map(
                              (trade) => PaperTradingHistoryCard(
                                symbol: trade['symbol'],
                                logo: trade['logo'],
                                quantity: trade['quantity'].toString(),
                                invested: trade['invested'],
                                current: trade['current'],
                                gain: trade['gain'],
                                percentage: trade['percentage'],
                                gainPercentage: trade['percentage'],
                                average: trade['average'],
                                type: trade['type'],
                              ),
                            )
                            .toList(),
                  ),
                ),

                // June 2025 Accordion
                CustomAccordion(
                  title: "June 2025",
                  initiallyExpanded: false,
                  backgroundColor: AppColors.darkInputBackground,
                  child:
                      _juneTrades.isEmpty
                          ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: AppText(
                                "No trades in June 2025",
                                variant: AppTextVariant.bodyMedium,
                                colorType: AppTextColorType.secondary,
                              ),
                            ),
                          )
                          : Column(
                            children:
                                _juneTrades
                                    .map(
                                      (trade) => PaperTradingHistoryCard(
                                        symbol: trade['symbol'],
                                        logo: trade['logo'],
                                        quantity: trade['quantity'].toString(),
                                        invested: trade['invested'],
                                        current: trade['current'],
                                        gain: trade['gain'],
                                        percentage: trade['percentage'],
                                        gainPercentage: trade['percentage'],
                                        average: trade['average'],
                                        type: trade['type'],
                                      ),
                                    )
                                    .toList(),
                          ),
                ),

                // May 2025 Accordion
                CustomAccordion(
                  title: "May 2025",
                  initiallyExpanded: false,
                  backgroundColor: AppColors.darkInputBackground,
                  child: Column(
                    children:
                        _mayTrades
                            .map(
                              (trade) => PaperTradingHistoryCard(
                                symbol: trade['symbol'],
                                logo: trade['logo'],
                                quantity: trade['quantity'].toString(),
                                invested: trade['invested'],
                                current: trade['current'],
                                gain: trade['gain'],
                                percentage: trade['percentage'],
                                gainPercentage: trade['percentage'],
                                average: trade['average'],
                                type: trade['type'],
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedErrorMessage(errorMessage: _errorMessage),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Download Report',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    isDisabled: _isLoading,
                    onPressed: () {
                      if (!_isLoading) {
                        // _downloadReport();
                      }
                    },
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// This class is no longer used - replaced by PaperTradingHistoryCard
class TradeHistoryCard extends StatelessWidget {
  final String symbol;
  final String logo;
  final int quantity;
  final String invested;
  final String current;
  final String gain;
  final String percentage;
  final String average;
  final String type; // 'buy' or 'sell'

  const TradeHistoryCard({
    super.key,
    required this.symbol,
    required this.logo,
    required this.quantity,
    required this.invested,
    required this.current,
    required this.gain,
    required this.percentage,
    required this.average,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = !percentage.contains('-');
    final bool isBuy = type.toLowerCase() == 'buy';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          // Header with symbol and status
          Padding(
            padding: EdgeInsets.all(12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Logo circle
                    Container(
                      width: 32.h,
                      height: 32.h,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          logo,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Symbol and quantity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          symbol,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 14.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: 4.w),
                            AppText(
                              "$quantity",
                              variant: AppTextVariant.bodySmall,
                              colorType: AppTextColorType.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Status tag
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isBuy
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AppText(
                    "${isBuy ? 'Buy' : 'Sell'} Success",
                    variant: AppTextVariant.bodySmall,
                    weight: AppTextWeight.semiBold,
                    customColor:
                        isBuy ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
            child: Column(
              children: [
                // Invested and Current
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AppText(
                          "Invested: ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        AppText(
                          invested,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppText(
                          "Current: ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        AppText(
                          current,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Gain and Average
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AppText(
                          type.toLowerCase() == 'buy'
                              ? "Unrealized Gain: "
                              : "Realized Gain: ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        AppText(
                          gain,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isPositive
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AppText(
                            "${isPositive ? '+' : ''}$percentage%",
                            variant: AppTextVariant.bodySmall,
                            weight: AppTextWeight.semiBold,
                            customColor:
                                isPositive
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppText(
                          "Avg ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                        ),
                        AppText(
                          average,
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
