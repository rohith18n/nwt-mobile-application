import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/dark_input_field.dart';
import 'package:nwt_app/widgets/common/app_dropdown.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/sip_day_picker.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';

class SipDetailsWidget extends StatelessWidget {
  final TextEditingController startDateController;
  final String? selectedFrequency;
  final List<String> frequencies;
  final ValueChanged<String?> onFrequencyChanged;
  final VoidCallback onNext;

  const SipDetailsWidget({
    super.key,
    required this.startDateController,
    this.selectedFrequency,
    required this.frequencies,
    required this.onFrequencyChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    print('SIP Details Widget is being built');
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'SIP Details',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 24),
          AppDropdown(
            value: selectedFrequency,
            items: frequencies,
            labelText: 'SIP Frequency*',
            hintText: 'Monthly',
            onChanged: onFrequencyChanged,
            fillColor: Colors.transparent,
          ),
          const SizedBox(height: 24),
          DarkInputField(
            label: 'SIP Start Date*',
            controller: startDateController,
            hintText: '2-05-2025',
            readOnly: true,
            suffixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
            onTap: () {
              // Handle date picker
              _showDatePicker(context);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppText(
                'Next SIP on 2-06-2025',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.gray,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showSipInfoBottomSheet(context),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
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

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SipDayPicker(
            initialDay: int.tryParse(startDateController.text.split('-')[0]) ?? DateTime.now().day,
            onDaySelected: (day) {
              final now = DateTime.now();
              DateTime selectedDate = DateTime(now.year, now.month, day);
              // If selected day is in the past or today, move to next month (allow from tomorrow)
              if (selectedDate.isBefore(now)) {
                selectedDate = DateTime(now.year, now.month + 1, day);
              }
              startDateController.text =
                  '${selectedDate.day}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
            },
          ),
    );
  }

  void _showSipInfoBottomSheet(BuildContext context) {
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
              'WHY IS MY NEXT SIP AFTER 30 DAYS?',
              variant: AppTextVariant.headline4,
              weight: AppTextWeight.bold,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.darkInputBorder,
                ),
              ),
              child: AppText(
                'BSE and AMCs do not allow SIP start date to be within 30 days if Auto pay mandate is not set up',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.darkInputBorder,
                ),
              ),
              child: AppText(
                'We will help you set up an Auto pay mandate next',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardBG,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.darkInputBorder,
                ),
              ),
              child: AppText(
                'Finally, you will get an option to invest a SIP installment today',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.primary,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
