import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/country_dropdown.dart';
import 'package:nwt_app/widgets/common/occupation_dropdown.dart';
import 'package:nwt_app/models/country.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';

class PANConfirmationScreen extends StatelessWidget {
  final TextEditingController panController;
  final TextEditingController nameController;
  final TextEditingController dobController;
  final TextEditingController fatherNameController;
  final TextEditingController emailController;
  final String? selectedCountryCode;
  final String? selectedOccupationId;
  final Function(Country) onCountrySelected;
  final Function(Datum) onOccupationSelected;
  final bool isPanDataFromAPI;
  final bool isNameDataFromAPI;

  const PANConfirmationScreen({
    super.key,
    required this.panController,
    required this.nameController,
    required this.dobController,
    required this.fatherNameController,
    required this.emailController,
    this.selectedCountryCode,
    this.selectedOccupationId,
    required this.onCountrySelected,
    required this.onOccupationSelected,
    this.isPanDataFromAPI = false,
    this.isNameDataFromAPI = false,
  });

  Widget _buildInfoItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppText(
              number,
              variant: AppTextVariant.bodySmall,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                variant: AppTextVariant.bodyMedium,
                weight: AppTextWeight.bold,
                colorType: AppTextColorType.primary,
              ),
              const SizedBox(height: 4),
              AppText(
                description,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWhyPanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkCardBG,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Why PAN",
                    variant: AppTextVariant.headline4,
                    weight: AppTextWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              _buildInfoItem(
                number: "1",
                title: "Unique Investor Identifier:",
                description:
                    "PAN serves as a unique identifier for all financial investments, including mutual funds, across Asset Management Companies (AMCs) and platforms.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "2",
                title: "Centralized Investment Data:",
                description:
                    "All mutual fund transactions — whether made through a distributor, direct platform, or online aggregator — are recorded against your PAN by Registrar and Transfer Agents (RTAs) such as CAMS and KFintech.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "3",
                title: "Accurate Portfolio Aggregation:",
                description:
                    "Using your PAN, we can securely request data from RTAs to retrieve your mutual fund holdings from all sources, enabling a consolidated and up-to-date view of your portfolio.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "4",
                title: "No Access to Sensitive Data Without Consent:",
                description:
                    "We use PAN only to initiate the data fetch request via official and secure APIs. Your consent is mandatory, and we do not store or misuse your information.",
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                number: "5",
                title: "Compliance with Regulatory Requirements:",
                description:
                    "PAN-based verification is required as per SEBI regulations to ensure data accuracy, investor protection, and traceability.",
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'PAN is required to invest',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          customColor: Colors.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'Kindly confirm your PAN and date of birth',
          variant: AppTextVariant.bodyMedium,
          colorType: AppTextColorType.gray,
          weight: AppTextWeight.medium,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showWhyPanBottomSheet(context),
          child: AppText(
            'Why do you need my PAN Number?',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.link,
            weight: AppTextWeight.medium,
          ),
        ),
        const SizedBox(height: 32),
        DarkInputField(
          label: 'PAN Number',
          controller: panController,
          hintText: 'AAAAA6578L',
          readOnly: isPanDataFromAPI,
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Name as on PAN',
          controller: nameController,
          hintText: 'Full Name',
          readOnly: isNameDataFromAPI,
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Date of Birth',
          controller: dobController,
          hintText: 'YYYY-MM-DD',
          isDateField: true,
          dateFormat: 'yyyy-MM-dd',
          lastDate: DateTime(
            DateTime.now().year - 18,
            DateTime.now().month,
            DateTime.now().day,
          ),
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Father Name',
          controller: fatherNameController,
          hintText: 'Father\'s Full Name',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Email',
          controller: emailController,
          hintText: 'example@gmail.com',
        ),
        const SizedBox(height: 24),
        CountryDropdown(
          selectedCountryCode: selectedCountryCode,
          onCountrySelected: onCountrySelected,
          label: 'Country of Residence',
          hintText: 'Select Country',
        ),
        const SizedBox(height: 24),
        OccupationDropdown(
          selectedOccupationId: selectedOccupationId,
          onOccupationSelected: onOccupationSelected,
          label: 'Occupation',
          hintText: 'Select Occupation',
        ),
      ],
    );
  }

}
