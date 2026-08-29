import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/dark_radio_tile.dart';
import 'package:nwt_app/widgets/common/occupation_dropdown.dart';
import 'package:nwt_app/screens/bse_star/widgets/dynamic_relation_selector.dart';
import 'package:nwt_app/screens/bse_star/types/occupation_option.dart';

class SecondHolderScreen extends StatelessWidget {
  final TextEditingController nomineeNameController;
  final TextEditingController nomineeDobController;
  final TextEditingController fatherNameController;
  final TextEditingController aadhaarController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController panController;
  final String selectedRelation;
  final String selectedRelationId;
  final String selectedIdType;
  final String? selectedOccupationId;
  final String selectedGender;
  final bool isNRI;
  final bool sameAsApplicantAddress;
  final ValueChanged<String> onRelationChanged;
  final ValueChanged<String> onRelationIdChanged;
  final ValueChanged<String> onIdTypeChanged;
  final Function(Datum) onOccupationSelected;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<bool> onNRIChanged;
  final ValueChanged<bool> onAddressChanged;

  const SecondHolderScreen({
    super.key,
    required this.nomineeNameController,
    required this.nomineeDobController,
    required this.fatherNameController,
    required this.aadhaarController,
    required this.emailController,
    required this.mobileController,
    required this.panController,
    required this.selectedRelation,
    required this.selectedRelationId,
    required this.selectedIdType,
    this.selectedOccupationId,
    required this.selectedGender,
    required this.isNRI,
    required this.sameAsApplicantAddress,
    required this.onRelationChanged,
    required this.onRelationIdChanged,
    required this.onIdTypeChanged,
    required this.onOccupationSelected,
    required this.onGenderChanged,
    required this.onNRIChanged,
    required this.onAddressChanged,
  });

  void _showSecondHolderInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBG,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
          vertical: 8,
        ),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'DIFFERENCE BETWEEN NOMINEE AND SECONDARY JOINT HOLDER',
              variant: AppTextVariant.headline4,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 12),
            AppText(
              'Nominee = Temporary caretaker who must follow succession laws\nJoint Holder = Co-owner with permanent rights',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.primary,
              weight: AppTextWeight.medium,
            ),
            const SizedBox(height: 16),
            AppText(
              'Nominee:',
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 8),
            AppText(
              '• Acts as a trustee or caretaker of your investments after your death\n• Has NO ownership rights while you\'re alive\n• Must hand over assets to your legal heirs as per Hindu Succession Act, Indian Succession Act, or your will\n• Simply holds assets temporarily until legal heirs complete the claim process\n• Think of them as a "key holder" - not an owner\n• Common practice: Parents nominate children, spouses nominate each other',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 16),
            AppText(
              'Secondary Joint Holder:',
              variant: AppTextVariant.bodyLarge,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 8),
            AppText(
              '• Has ACTUAL ownership rights from day one\n• Can operate the account and trade (based on mode: Either or Survivor, Joint, etc.)\n• Automatically becomes sole owner upon your death - assets transfer instantly\n• Bypasses legal heirs, succession laws, and even your will\n• True co-ownership with equal or defined rights\n• Common in demat accounts and mutual fund folios',
              variant: AppTextVariant.bodyMedium,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 16),
            AppText(
              'Choose wisely - this decision impacts your family\'s financial future and can prevent disputes.',
              variant: AppTextVariant.bodyMedium,
              weight: AppTextWeight.semiBold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Add a Secondary Holder',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSecondHolderInfoBottomSheet(context),
          child: AppText(
            'Please fill in the details of the person that you may want to add as a secondary holder.',
            variant: AppTextVariant.bodyMedium,
            colorType: AppTextColorType.gray,
            weight: AppTextWeight.medium,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showSecondHolderInfoBottomSheet(context),
          child: AppText(
            'Know the difference between nominee and secondary joint holder',
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.medium,
            colorType: AppTextColorType.link,
          ),
        ),
        const SizedBox(height: 32),
        DarkInputField(
          label: 'Name of Secondary Holder',
          controller: nomineeNameController,
          hintText: 'Name of the holder',
        ),
        const SizedBox(height: 24),
        AppText(
          'Relation',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 12),
        DynamicRelationSelector(
          selectedRelationName: selectedRelation,
          selectedRelationId: selectedRelationId,
          onRelationNameChanged: onRelationChanged,
          onRelationIdChanged: onRelationIdChanged,
        ),
        const SizedBox(height: 24),
        AppText(
          'Gender',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
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
          'Residency Status',
          variant: AppTextVariant.bodyMedium,
          weight: AppTextWeight.medium,
          colorType: AppTextColorType.white,
        ),
        const SizedBox(height: 12),
        DarkRadioTile(
          title: 'Indian Resident',
          isSelected: !isNRI,
          onTap: () => onNRIChanged(false),
        ),
        const SizedBox(height: 8),
        DarkRadioTile(
          title: 'NRI (Non-Resident Indian)',
          isSelected: isNRI,
          onTap: () => onNRIChanged(true),
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Secondary Holder\'s Date of Birth',
          controller: nomineeDobController,
          hintText: 'YYYY-MM-DD',
          isDateField: true,
          lastDate: DateTime(
            DateTime.now().year - 18,
            DateTime.now().month,
            DateTime.now().day,
          ),
          dateFormat: 'yyyy-MM-dd',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Father Name',
          controller: fatherNameController,
          hintText: 'Father\'s Full Name',
        ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'PAN',
          controller: panController,
          hintText: 'Please enter the PAN of secondary holder',
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.deny(
              RegExp(r'[^A-Z0-9]'),
            ),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.isEmpty) return newValue;
              
              final text = newValue.text.toUpperCase();
              final position = text.length;
              
              // Validate based on position
              if (position <= 5) {
                // First 5 chars must be letters
                if (!RegExp(r'^[A-Z]{1,5}$').hasMatch(text)) {
                  return oldValue;
                }
              } else if (position <= 9) {
                // After first 5 letters, next 4 must be numbers
                if (!RegExp(
                  r'^[A-Z]{5}[0-9]{1,4}$',
                ).hasMatch(text)) {
                  return oldValue;
                }
              } else {
                // Last char must be letter
                if (!RegExp(
                  r'^[A-Z]{5}[0-9]{4}[A-Z]$',
                ).hasMatch(text)) {
                  return oldValue;
                }
              }
              
              return TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: text.length),
              );
            }),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return null; // PAN is optional for second holder
            }
            if (value.length != 10 ||
                !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value)) {
              return 'Please enter a valid PAN (e.g., ABCDE1234F)';
            }
            return null;
          },
        ),
        // AppText(
        //   'ID Type',
        //   variant: AppTextVariant.bodyMedium,
        //   weight: AppTextWeight.medium,
        //   colorType: AppTextColorType.white,
        // ),
        // const SizedBox(height: 12),
        // Container(
        //   width: double.infinity,
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //   decoration: BoxDecoration(
        //     border: Border.all(color: Colors.grey[700]!),
        //     borderRadius: BorderRadius.circular(14),
        //   ),
        //   child: AppText(
        //     selectedIdType.isEmpty ? 'Aadhar' : selectedIdType,
        //     variant: AppTextVariant.bodyMedium,
        //     colorType: AppTextColorType.white,
        //   ),
        // ),
        // const SizedBox(height: 24),
        // DarkInputField(
        //   label: 'Last 4 Digits of Aadhaar Number',
        //   controller: aadhaarController,
        //   hintText: 'XXXX-XXXX-XXXX',
        //   keyboardType: TextInputType.number,
        // ),
        const SizedBox(height: 24),
        DarkInputField(
          label: 'Secondary Holder Email ID',
          controller: emailController,
          hintText: 'Enter Secondary Holder\'s email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        
        DarkInputField(
          label: 'Mobile Number',
          controller: mobileController,
          hintText: 'Enter Secondary Holder\'s mobile number',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 24),
        OccupationDropdown(
          selectedOccupationId: selectedOccupationId,
          onOccupationSelected: onOccupationSelected,
          label: 'Occupation',
          hintText: 'Select Occupation',
        ),
       
        // const SizedBox(height: 12),
        // GestureDetector(
        //   onTap: () => onAddressChanged(!sameAsApplicantAddress),
        //   child: Container(
        //     padding: const EdgeInsets.all(16),
        //     decoration: BoxDecoration(
        //       border: Border.all(color: Colors.grey[700]!),
        //       borderRadius: BorderRadius.circular(14),
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         AppText(
        //           'Same as applicant',
        //           variant: AppTextVariant.bodyMedium,
        //           colorType: AppTextColorType.white,
        //         ),
        //         Container(
        //           width: 20,
        //           height: 20,
        //           decoration: BoxDecoration(
        //             color: sameAsApplicantAddress ? Colors.white : Colors.transparent,
        //             border: Border.all(color: Colors.grey[600]!),
        //             borderRadius: BorderRadius.circular(4),
        //           ),
        //           child: sameAsApplicantAddress
        //               ? const Icon(
        //                   Icons.check,
        //                   size: 14,
        //                   color: Colors.black,
        //                 )
        //               : null,
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
     
      ],
    );
  }
}
