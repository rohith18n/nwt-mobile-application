import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nwt_app/widgets/common/calendar_picker.dart';

/// Example widget showing how to use the new native date picker
class DatePickerExample extends StatefulWidget {
  const DatePickerExample({super.key});

  @override
  State<DatePickerExample> createState() => _DatePickerExampleState();
}

class _DatePickerExampleState extends State<DatePickerExample> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Picker Example'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Native Date Picker Examples',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Example 1: Date picker button
            Text(
              'Date Picker Button:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            AppDatePickerButton(
              initialDate: _selectedDate,
              placeholder: 'Select a date',
              title: 'Choose Date',
              dateFormat: DateFormatType.ddMMMyyyy,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            SizedBox(height: 24.h),
            
            // Example 2: Modal date picker
            Text(
              'Modal Date Picker:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () async {
                final date = await showAppCalendarPicker(
                  context: context,
                  title: 'Select Date',
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  dateFormat: DateFormatType.ddMMMyyyy,
                );
                
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: const Text('Open Date Picker'),
            ),
            SizedBox(height: 24.h),
            
            // Show selected date
            if (_selectedDate != null) ...[
              Text(
                'Selected Date:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  DateFormatHelper.formatDate(_selectedDate!, DateFormatType.ddMMMyyyy),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
