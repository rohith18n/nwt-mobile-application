import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';

class EnhancedAboutYouScreen extends StatelessWidget {
  final TextEditingController fatherNameController;
  final TextEditingController motherNameController;
  final TextEditingController spouseNameController;
  final String selectedGender;
  final String selectedMaritalStatus;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onMaritalStatusChanged;

  const EnhancedAboutYouScreen({
    super.key,
    required this.fatherNameController,
    required this.motherNameController,
    required this.spouseNameController,
    required this.selectedGender,
    required this.selectedMaritalStatus,
    required this.onGenderChanged,
    required this.onMaritalStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'For investment',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'We need your bank details for investment purposes.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            // Handle "Why do you need my PAN Number?" tap
          },
          child: AppText(
            'Why do you need my PAN Number?',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.link,
          ),
        ),
        const SizedBox(height: 32),
        AppText(
          'Gender',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'Female',
          isSelected: selectedGender == 'Female',
          onTap: () => onGenderChanged('Female'),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'Male',
          isSelected: selectedGender == 'Male',
          onTap: () => onGenderChanged('Male'),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'Others',
          isSelected: selectedGender == 'Others',
          onTap: () => onGenderChanged('Others'),
        ),
        const SizedBox(height: 24),
        AppText(
          'Marital Status',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'Single',
          isSelected: selectedMaritalStatus == 'Single',
          onTap: () => onMaritalStatusChanged('Single'),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'Married',
          isSelected: selectedMaritalStatus == 'Married',
          onTap: () => onMaritalStatusChanged('Married'),
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Father\'s name as per PAN',
          controller: fatherNameController,
          hintText: 'Enter your Father\'s name',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Mother\'s name',
          controller: motherNameController,
          hintText: 'Enter your Mother\'s name',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Spouse\'s name',
          controller: spouseNameController,
          hintText: 'Enter your Spouse\'s name',
        ),
      ],
    );
  }
}
