import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class ChooseFolioWidget extends StatelessWidget {
  final TextEditingController folioController;
  final String? selectedFolioOption;
  final List<String> folioOptions;
  final ValueChanged<String?> onFolioOptionChanged;
  final VoidCallback onNext;

  const ChooseFolioWidget({
    super.key,
    required this.folioController,
    this.selectedFolioOption,
    required this.folioOptions,
    required this.onFolioOptionChanged,
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
            'Choose your folio',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 24),
          DarkInputField(
            label: 'Folio Number*',
            controller: folioController,
            hintText: 'Folio Number',
          ),
          const SizedBox(height: 24),
          DarkRadioTile(
            title: 'Create New',
            isSelected: selectedFolioOption == 'Create New',
            onTap: () => onFolioOptionChanged('Create New'),
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