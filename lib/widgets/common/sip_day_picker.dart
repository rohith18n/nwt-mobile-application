import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';

class SipDayPicker extends StatefulWidget {
  final int initialDay;
  final Function(int) onDaySelected;

  const SipDayPicker({
    super.key,
    required this.initialDay,
    required this.onDaySelected,
  });

  @override
  State<SipDayPicker> createState() => _SipDayPickerState();
}

class _SipDayPickerState extends State<SipDayPicker> {
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDay;
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _calculateNextSipDate() {
    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, selectedDay);
    // Usually SIP registration takes ~5-15 days.
    if (startDate.isBefore(now.add(const Duration(days: 0)))) {
      startDate = DateTime(now.year, now.month + 1, selectedDay);
    }
    return '${startDate.day}${_getDaySuffix(startDate.day)} ${DateFormat('MMMM').format(startDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.darkCardBG,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'Choose SIP instalment date',
            variant: AppTextVariant.headline5,
            weight: AppTextWeight.bold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 30, // As per image
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSelected = selectedDay == day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDay = day;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: AppText(
                    '$day',
                    variant: AppTextVariant.bodyLarge,
                    weight:
                        isSelected ? AppTextWeight.bold : AppTextWeight.medium,
                    customColor: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                'SIP instalment on ${_calculateNextSipDate()}',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.gray,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Update',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: () {
                widget.onDaySelected(selectedDay);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
