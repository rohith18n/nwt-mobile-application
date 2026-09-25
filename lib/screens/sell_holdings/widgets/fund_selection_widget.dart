import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/avatar.dart';

class FundSelectionWidget extends StatelessWidget {
  final String selectedFund;
  final String folioNumber;
  final String fundValue;
  final String totalUnits;
  final String withdrawAmount;
  final String withdrawUnits;
  final bool sellAllUnits;
  final String totalGain;
  final String exitLoad;
  final String ltcg;
  final String stcg;
  final TextEditingController amountController;
  final TextEditingController unitsController;
  final ValueChanged<bool> onSellAllUnitsChanged;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onUnitsChanged;
  final VoidCallback onContinue;

  const FundSelectionWidget({
    super.key,
    required this.selectedFund,
    required this.folioNumber,
    required this.fundValue,
    required this.totalUnits,
    required this.withdrawAmount,
    required this.withdrawUnits,
    required this.sellAllUnits,
    required this.totalGain,
    required this.exitLoad,
    required this.ltcg,
    required this.stcg,
    required this.amountController,
    required this.unitsController,
    required this.onSellAllUnitsChanged,
    required this.onAmountChanged,
    required this.onUnitsChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: AppText(
              'Redeem From',
              variant: AppTextVariant.headline6,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.white,
            ),
          ),
          const SizedBox(height: 24),
          // Fund Selection Card
          MergeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkButtonBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 12,
                            children: [
                              Avatar(
                                path: "",
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
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
                                      selectedFund[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AppText(
                                selectedFund,
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkButtonBorder,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4,
                                  children: [
                                    AppText(
                                      'Folio No.: $folioNumber',
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.gray,
                                    ),
                                    AppText(
                                      'Value: $fundValue',
                                      variant: AppTextVariant.bodySmall,
                                      colorType: AppTextColorType.gray,
                                    ),
                                  ],
                                ),
                                AppText(
                                  'Units: $totalUnits',
                                  variant: AppTextVariant.bodySmall,
                                  colorType: AppTextColorType.gray,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Semantics(
            header: true,
            child: AppText(
              'Withdraw Details',
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.gray,
            ),
          ),
          const SizedBox(height: 16),
          // Amount and Units Input
          Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Amount',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.gray,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          withdrawAmount,
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                          colorType: AppTextColorType.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MergeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBG,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Units',
                          variant: AppTextVariant.bodySmall,
                          colorType: AppTextColorType.gray,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          withdrawUnits,
                          variant: AppTextVariant.bodyLarge,
                          weight: AppTextWeight.bold,
                          colorType: AppTextColorType.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sell All Units Checkbox
          Semantics(
            selected: sellAllUnits,
            label: 'Sell All Units',
            button: true,
            onTap: () => onSellAllUnitsChanged(!sellAllUnits),
            child: GestureDetector(
              onTap: () => onSellAllUnitsChanged(!sellAllUnits),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBG,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'Sell All Units',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.medium,
                      colorType: AppTextColorType.white,
                    ),
                    ExcludeSemantics(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: sellAllUnits ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: sellAllUnits ? Colors.white : Colors.grey[600]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child:
                            sellAllUnits
                                ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.black,
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tax Information
          AppText(
            'You\'ve made the following gains on which taxes may be applicable',
            variant: AppTextVariant.bodySmall,
            colorType: AppTextColorType.gray,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTaxRow('Total gain', totalGain, const Color(0xFF00C853)),
                const SizedBox(height: 12),
                _buildTaxRow('Exit Load', exitLoad, Colors.white),
                const SizedBox(height: 16),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: MergeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkButtonBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              AppText(
                                'LTCG',
                                variant: AppTextVariant.bodySmall,
                                colorType: AppTextColorType.gray,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                ltcg,
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: MergeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkButtonBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              AppText(
                                'STCG',
                                variant: AppTextVariant.bodySmall,
                                colorType: AppTextColorType.gray,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                stcg,
                                variant: AppTextVariant.bodyMedium,
                                weight: AppTextWeight.semiBold,
                                colorType: AppTextColorType.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Warning Message
          Semantics(
            container: true,
            label: 'Important Information',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText(
                      'Sell orders once placed cannot be cancelled.',
                      variant: AppTextVariant.bodySmall,
                      colorType: AppTextColorType.gray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Continue',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodySmall,
          colorType: AppTextColorType.gray,
        ),
        AppText(
          value,
          variant: AppTextVariant.bodySmall,
          weight: AppTextWeight.semiBold,
          colorType:
              (valueColor == Colors.green ||
                      valueColor == const Color(0xFF00C853))
                  ? AppTextColorType.success
                  : AppTextColorType.white,
        ),
      ],
    );
  }
}
