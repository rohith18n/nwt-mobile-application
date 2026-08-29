import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/screens/bse_star/widgets/relation_selector.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class FirstNomineeWidget extends StatelessWidget {
  final TextEditingController nomineeNameController;
  final TextEditingController nomineeDobController;
  final TextEditingController aadhaarController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController pinCodeController;
  final String selectedRelation;
  final String selectedIdType;
  final bool sameAsApplicantAddress;
  final ValueChanged<String> onRelationChanged;
  final ValueChanged<String?> onIdTypeChanged;
  final ValueChanged<bool> onAddressChanged;
  final VoidCallback onAddAnotherNominee;
  final VoidCallback onNext;

  const FirstNomineeWidget({
    super.key,
    required this.nomineeNameController,
    required this.nomineeDobController,
    required this.aadhaarController,
    required this.emailController,
    required this.mobileController,
    required this.pinCodeController,
    required this.selectedRelation,
    required this.selectedIdType,
    required this.sameAsApplicantAddress,
    required this.onRelationChanged,
    required this.onIdTypeChanged,
    required this.onAddressChanged,
    required this.onAddAnotherNominee,
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
          const SizedBox(height: 8),
          Row(
            children: [
              AppText(
                'First Nominee',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.white,
              ),
              AppText(
                '*',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.error,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DarkInputField(
                    label: '',
                    controller: nomineeNameController,
                    hintText: 'Name of the nominee',
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Relation',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 12),
                  RelationSelector(
                    relations: ['Father', 'Mother', 'Husband', 'Wife', 'Sibling'],
                    selectedRelation: selectedRelation,
                    onRelationChanged: onRelationChanged,
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Nominee\'s Date of Birth',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 8),
                  DarkInputField(
                    label: '',
                    controller: nomineeDobController,
                    hintText: 'DD / MM / YYYY',
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'ID Type',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 8),
                  AppDropdown(
                    value: selectedIdType.isEmpty ? 'Aadhar' : selectedIdType,
                    items: const ['Aadhar', 'PAN', 'Passport'],
                    hintText: 'Aadhar',
                    onChanged: onIdTypeChanged,
                    fillColor: Colors.transparent,
                    showLabel: false,
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Last 4 Digits of Aadhaar Number',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 8),
                  DarkInputField(
                    label: '',
                    controller: aadhaarController,
                    hintText: 'XXXX-XXXX-XXXX',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Nominee Email Id',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 8),
                  DarkInputField(
                    label: '',
                    controller: emailController,
                    hintText: 'Enter nominee\'s email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Mobile Number',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 8),
                  DarkInputField( 
                    label: '',
                    controller: mobileController,
                    hintText: '+91 Enter your mobile number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Nominee Address',
                    variant: AppTextVariant.bodyMedium,
                    weight: AppTextWeight.medium,
                    colorType: AppTextColorType.white,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => onAddressChanged(!sameAsApplicantAddress),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Same as applicant',
                            variant: AppTextVariant.bodyMedium,
                            colorType: AppTextColorType.white,
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: sameAsApplicantAddress ? Colors.white : Colors.transparent,
                              border: Border.all(color: Colors.grey[600]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: sameAsApplicantAddress
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DarkInputField(
                    label: '',
                    controller: pinCodeController,
                    hintText: 'PIN CODE',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: onAddAnotherNominee,
                    child: AppText(
                      'ADD ANOTHER NOMINEE',
                      variant: AppTextVariant.bodyMedium,
                      weight: AppTextWeight.semiBold,
                      colorType: AppTextColorType.link,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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
