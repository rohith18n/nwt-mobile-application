import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';
import 'package:nwt_app/screens/bse_star/types/tax_status.dart';

class AboutYouScreen extends StatelessWidget {
  final TextEditingController fatherNameController;
  final TextEditingController motherNameController;
  final TextEditingController spouseNameController;
  final String selectedGender;
  final String selectedMaritalStatus;
  final TaxStatus? selectedTaxStatus;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onMaritalStatusChanged;
  final ValueChanged<TaxStatus> onTaxStatusChanged;

  const AboutYouScreen({
    super.key,
    required this.fatherNameController,
    required this.motherNameController,
    required this.spouseNameController,
    required this.selectedGender,
    required this.selectedMaritalStatus,
    required this.selectedTaxStatus,
    required this.onGenderChanged,
    required this.onMaritalStatusChanged,
    required this.onTaxStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'About you',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'We will use this information to tailor your experience and services throughout the app.',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),

        const SizedBox(height: 32),
        AppText(
          'Tax Status',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'NRE',
          isSelected: selectedTaxStatus == TaxStatus.nre,
          onTap: () => onTaxStatusChanged(TaxStatus.nre),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'NRO',
          isSelected: selectedTaxStatus == TaxStatus.nro,
          onTap: () => onTaxStatusChanged(TaxStatus.nro),
        ),
        const SizedBox(height: 24),
        AppText(
          'Gender',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'Female',
          isSelected: selectedGender == 'F',
          onTap: () => onGenderChanged('F'),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'Male',
          isSelected: selectedGender == 'M',
          onTap: () => onGenderChanged('M'),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'Others',
          isSelected: selectedGender == 'O',
          onTap: () => onGenderChanged('O'),
        ),
        const SizedBox(height: 24),
        AppText(
          'Marital Status',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          customColor: Colors.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'Single',
          isSelected: selectedMaritalStatus == 'S',
          onTap: () => onMaritalStatusChanged('S'),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'Married',
          isSelected: selectedMaritalStatus == 'M',
          onTap: () => onMaritalStatusChanged('M'),
        ),

        // if (selectedMaritalStatus == 'M') ...[
        //   const SizedBox(height: 24),
        //   DarkInputField(
        //     label: 'Spouse\'s name',
        //     controller: spouseNameController,
        //     hintText: 'Enter your spouse\'s name',
        //   ),
        // ],
        // const SizedBox(height: 24),
        // DarkInputField(
        //   label: 'Father\'s name as per PAN',
        //   controller: fatherNameController,
        //   hintText: 'Enter your Father\'s name',
        // ),
        // const SizedBox(height: 24),
        // DarkInputField(
        //   label: 'Mother\'s name',
        //   controller: motherNameController,
        //   hintText: 'Enter your Mother\'s name',
        // ),
      ],
    );
  }
}
