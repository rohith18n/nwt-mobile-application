import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class HoldingDetailsWidget extends StatelessWidget {
  final String? selectedHoldingMode;
  final List<String> holdingModes;
  final ValueChanged<String?> onHoldingModeChanged;
  final VoidCallback onNext;

  const HoldingDetailsWidget({
    super.key,
    this.selectedHoldingMode,
    required this.holdingModes,
    required this.onHoldingModeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Holding Details',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 24),
          AppDropdown(
            value: selectedHoldingMode,
            items: holdingModes,
            labelText: 'Holding Mode*',
            hintText: 'Anyone or Survivor',
            onChanged: onHoldingModeChanged,
            fillColor: Colors.transparent,
          ),
          const SizedBox(height: 24),
          // Information card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[600]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Anyone or Survivor Holding',
                  variant: AppTextVariant.bodyMedium,
                  weight: AppTextWeight.semiBold,
                  colorType: AppTextColorType.white,
                ),
                const SizedBox(height: 8),
                AppText(
                  'In either or survivor mode of holding, if one holder dies, the surviving holder gains full control of the account automatically, ensuring a seamless transition and immediate access to funds without the need for legal procedures.',
                  variant: AppTextVariant.bodySmall,
                  colorType: AppTextColorType.gray,
                  maxLines: null,
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Next',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
