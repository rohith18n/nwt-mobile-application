import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/screens/bse_star/widgets/relation_selector.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class NomineeData {
  final String name;
  final String relation;
  final String dateOfBirth;
  final String aadhaar;
  final String email;
  final String mobile;
  final String shareAllocation;
  final bool sameAsApplicantAddress;

  NomineeData({
    required this.name,
    required this.relation,
    required this.dateOfBirth,
    required this.aadhaar,
    required this.email,
    required this.mobile,
    required this.shareAllocation,
    required this.sameAsApplicantAddress,
  });
}

class AddNomineeWidget extends StatelessWidget {
  final TextEditingController nomineeNameController;
  final TextEditingController nomineeDobController;
  final TextEditingController aadhaarController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController shareAllocationController;
  final String selectedRelation;
  final String selectedIdType;
  final bool sameAsApplicantAddress;
  final ValueChanged<String> onRelationChanged;
  final ValueChanged<String> onIdTypeChanged;
  final ValueChanged<bool> onAddressChanged;
  final VoidCallback onNext;

  const AddNomineeWidget({
    super.key,
    required this.nomineeNameController,
    required this.nomineeDobController,
    required this.aadhaarController,
    required this.emailController,
    required this.mobileController,
    required this.shareAllocationController,
    required this.selectedRelation,
    required this.selectedIdType,
    required this.sameAsApplicantAddress,
    required this.onRelationChanged,
    required this.onIdTypeChanged,
    required this.onAddressChanged,
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
            'Add a nominee for all products',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 8),
          AppText(
            'Please fill in the details of the person that you may want to add as a nominee',
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DarkInputField(
                    label: 'Name of nominee',
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
                    relations: ['Father', 'Mother', 'Husband', 'Wife', 'Son', 'Daughter', 'Brother', 'Sister'],
                    selectedRelation: selectedRelation,
                    onRelationChanged: onRelationChanged,
                  ),
                  const SizedBox(height: 24),
                  DarkInputField(
                    label: 'Nominee\'s Date of Birth',
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AppText(
                      selectedIdType.isEmpty ? 'Aadhar' : selectedIdType,
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DarkInputField(
                    label: 'Last 4 Digits of Aadhaar Number',
                    controller: aadhaarController,
                    hintText: 'XXXX-XXXX-XXXX',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  DarkInputField(
                    label: 'Nominee Email Id',
                    controller: emailController,
                    hintText: 'Enter nominee\'s email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  DarkInputField(
                    label: 'Mobile Number',
                    controller: mobileController,
                    hintText: 'Enter nominee\'s mobile number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  DarkInputField(
                    label: 'Share allocation (%)',
                    controller: shareAllocationController,
                    hintText: '100',
                    keyboardType: TextInputType.number,
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Complete Investment',
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
