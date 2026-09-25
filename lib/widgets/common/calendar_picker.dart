import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/theme.dart';

// Enum for different date format types
enum DateFormatType {
  ddMMMyyyy, // DD/MM/YYYY
  ddMMyyyy, // DD-MM-YYYY
  yyyyMMdd, // YYYY-MM-DD
  MMddyyyy, // MM/DD/YYYY
  ddMMMyy, // DD/MM/YY
  yyyyddMM, // YYYY/DD/MM
}

// Helper class for date formatting
class DateFormatHelper {
  // Helper method to get DateFormat based on DateFormatType
  static DateFormat getDateFormat(DateFormatType formatType) {
    switch (formatType) {
      case DateFormatType.ddMMMyyyy:
        return DateFormat('dd/MM/yyyy');
      case DateFormatType.ddMMyyyy:
        return DateFormat('dd-MM-yyyy');
      case DateFormatType.yyyyMMdd:
        return DateFormat('yyyy-MM-dd');
      case DateFormatType.MMddyyyy:
        return DateFormat('MM/dd/yyyy');
      case DateFormatType.ddMMMyy:
        return DateFormat('dd/MM/yy');
      case DateFormatType.yyyyddMM:
        return DateFormat('yyyy/dd/MM');
    }
  }

  // Helper method to format date as string
  static String formatDate(DateTime date, DateFormatType formatType) {
    final formatter = getDateFormat(formatType);
    return formatter.format(date);
  }

  // Helper method to get format display string
  static String getFormatDisplayString(DateFormatType formatType) {
    switch (formatType) {
      case DateFormatType.ddMMMyyyy:
        return 'DD/MM/YYYY';
      case DateFormatType.ddMMyyyy:
        return 'DD-MM-YYYY';
      case DateFormatType.yyyyMMdd:
        return 'YYYY-MM-DD';
      case DateFormatType.MMddyyyy:
        return 'MM/DD/YYYY';
      case DateFormatType.ddMMMyy:
        return 'DD/MM/YY';
      case DateFormatType.yyyyddMM:
        return 'YYYY/DD/MM';
    }
  }
}

// Helper function to show the native date picker with platform-specific UI
Future<DateTime?> showAppCalendarPicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  DateFormatType dateFormat = DateFormatType.ddMMMyyyy,
  bool showFormattedDate = false,
  Function(String)? onFormattedDateSelected,
}) async {
  final DateTime? selectedDate =
      Platform.isIOS
          ? await _showCupertinoDatePicker(
            context,
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            title: title,
          )
          : await _showMaterialDatePicker(
            context,
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            title: title,
          );

  // Call formatted date callback if provided and date was selected
  if (selectedDate != null && onFormattedDateSelected != null) {
    final formattedDate = DateFormatHelper.formatDate(selectedDate, dateFormat);
    onFormattedDateSelected(formattedDate);
  }

  return selectedDate;
}

// Show Material Design date picker for Android
Future<DateTime?> _showMaterialDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) async {
  return await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
    helpText: title ?? 'Select Date',
    cancelText: 'Cancel',
    confirmText: 'OK',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            fillColor: AppColors.darkInputBackground,
            filled: true,
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(
                color: AppColors.darkInputBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(
                color: AppColors.darkInputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(color: AppColors.darkPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            hintStyle: TextStyle(
              color: AppColors.darkInputHintText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.darkPrimary,
            onPrimary: AppColors.darkBackground,
            surface: AppColors.darkBackground,
            onSurface: AppColors.darkTextPrimary,
            onSurfaceVariant: AppColors.darkTextSecondary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkPrimary,
              textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.darkCardBG,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.darkPrimary, width: 1.w),
              borderRadius: BorderRadius.circular(15.r),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

// Show Cupertino date picker for iOS
Future<DateTime?> _showCupertinoDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) async {
  DateTime now = DateTime.now();
  DateTime minDate = firstDate ?? DateTime(1900);
  DateTime maxDate = lastDate ?? DateTime(2100);
  DateTime tempDate = initialDate ?? now;

  // Ensure tempDate is within the valid range
  if (tempDate.isBefore(minDate)) {
    tempDate = minDate;
  } else if (tempDate.isAfter(maxDate)) {
    tempDate = maxDate;
  }

  return await showModalBottomSheet<DateTime?>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Header with Done button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  Text(
                    title ?? 'Select Date',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, tempDate),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            // Date Picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: minDate,
                maximumDate: maxDate,
                onDateTimeChanged: (DateTime newDate) {
                  tempDate = newDate;
                },
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Simple date picker button widget
class AppDatePickerButton extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;
  final String? title;
  final DateFormatType dateFormat;
  final String? placeholder;
  final Widget? icon;

  const AppDatePickerButton({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
    this.title,
    this.dateFormat = DateFormatType.ddMMMyyyy,
    this.placeholder = 'Select Date',
    this.icon,
  });

  @override
  State<AppDatePickerButton> createState() => _AppDatePickerButtonState();
}

class _AppDatePickerButtonState extends State<AppDatePickerButton> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _showDatePicker() async {
    final DateTime? date = await showAppCalendarPicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      title: widget.title,
      dateFormat: widget.dateFormat,
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      widget.onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textThemeColors = context.textThemeColors;

    return InkWell(
      onTap: _showDatePicker,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.darkInputBackground
                  : AppColors.lightInputPrimaryBackground,
          border: Border.all(
            color:
                isDarkMode
                    ? AppColors.darkInputBorder
                    : AppColors.lightInputPrimaryBorder,
            width: 1.w,
          ),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormatHelper.formatDate(
                      _selectedDate!,
                      widget.dateFormat,
                    )
                    : widget.placeholder ?? 'Select Date',
                style: TextStyle(
                  color:
                      _selectedDate != null
                          ? textThemeColors.primaryText
                          : textThemeColors.secondaryText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            widget.icon ??
                Icon(
                  Icons.calendar_today,
                  size: 20.sp,
                  color: textThemeColors.secondaryText,
                ),
          ],
        ),
      ),
    );
  }
}
