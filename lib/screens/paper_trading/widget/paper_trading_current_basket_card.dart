import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/utils/currency_formatter.dart';
import 'package:nwt_app/widgets/common/animated_amount.dart';
import 'package:nwt_app/widgets/common/delta_indicator.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class PaperTradingCurrentBasketCard extends StatelessWidget {
  final String symbol;
  final String logo;
  final String quantity;
  final double invested;
  final double current;
  final double gain;
  final String percentage;
  final double price;
  final double changeAmount;
  final String changePercentage;
  final double purchasePrice;
  final String gainPercentage;
  final IconData? icon;
  final bool? isAmountVisible;

  const PaperTradingCurrentBasketCard({
    super.key,
    required this.symbol,
    required this.logo,
    required this.quantity,
    required this.invested,
    required this.current,
    required this.gain,
    required this.percentage,
    required this.price,
    required this.changeAmount,
    required this.changePercentage,
    required this.purchasePrice,
    required this.gainPercentage,
    this.icon = Icons.account_balance_outlined,
    this.isAmountVisible = true,
  });

  String _capPercentage(String percentage) {
    final value = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    if (value > 100) return '100%';
    if (value < -100) return '-100%';
    return percentage;
  }

  DeltaType _getDeltaType(String percentage) {
    final value = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    if (value > 0) return DeltaType.positive;
    if (value < 0) return DeltaType.negative;
    return DeltaType.neutral;
  }

  Widget _buildDeltaIndicator(String delta, DeltaType deltaType) {
    // Convert the delta string to a double value
    double deltaValue = double.tryParse(delta.replaceAll('%', '')) ?? 0.0;

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

  @override
  Widget build(BuildContext context) {
    final deltaType = _getDeltaType(gainPercentage);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkButtonBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkButtonBorder,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 20, color: AppColors.darkTextMuted),
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      symbol,
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.primary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppText(
                      "₹${purchasePrice.toStringAsFixed(0)}",
                      variant: AppTextVariant.bodySmall,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.secondary,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.darkButtonBorder,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(width: 1, color: AppColors.darkButtonBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AppText(
                          "Invested: ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                        AnimatedAmount(
                          isAmountVisible: isAmountVisible ?? true,
                          amount: CurrencyFormatter.formatRupee(invested),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppText(
                          "Current: ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                        AnimatedAmount(
                          isAmountVisible: isAmountVisible ?? true,
                          amount: CurrencyFormatter.formatRupee(current),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppText(
                              "Gain: ",
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.semiBold,
                              colorType: AppTextColorType.primary,
                            ),
                            AnimatedAmount(
                              isAmountVisible: isAmountVisible ?? true,
                              amount: CurrencyFormatter.formatRupee(gain),
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        _buildDeltaIndicator(
                          _capPercentage("$gainPercentage"),
                          deltaType,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppText(
                          "Avg: ",
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.semiBold,
                          colorType: AppTextColorType.primary,
                        ),
                        AnimatedAmount(
                          isAmountVisible: isAmountVisible ?? true,
                          amount: "₹${purchasePrice.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkPrimary,
                          ),
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
