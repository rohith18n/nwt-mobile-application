import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:intl/intl.dart';

class DarkInputField extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final bool isDateField;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? dateFormat;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? errorText;
  final String? helperText;
  final FocusNode? focusNode;

  const DarkInputField({
    super.key,
    this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.isDateField = false,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
    this.textCapitalization,
    this.inputFormatters,
    this.validator,
    this.errorText,
    this.helperText,
    this.focusNode,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime effectiveLastDate = lastDate ?? DateTime.now();
    final DateTime effectiveFirstDate = firstDate ?? DateTime(1900);

    // Set initialDate to lastDate if lastDate is before today, otherwise use today
    final DateTime initialDate =
        effectiveLastDate.isBefore(DateTime.now())
            ? effectiveLastDate
            : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat(
        dateFormat ?? 'dd/MM/yyyy',
      ).format(picked);
      controller.text = formattedDate;
      if (onChanged != null) {
        onChanged!(formattedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          AppText(
            label!,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType: AppTextColorType.white,
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            onChanged: onChanged,
            onTap: (isDateField && !readOnly && enabled)
                ? () => _selectDate(context)
                : (enabled ? onTap : null),
            readOnly: isDateField ? true : readOnly,
            enableInteractiveSelection: !isDateField && !readOnly,
            textCapitalization: textCapitalization ?? TextCapitalization.none,
            inputFormatters: inputFormatters,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon:
                  isDateField
                      ? const Icon(
                        Icons.calendar_today,
                        color: Colors.grey,
                        size: 20,
                      )
                      : suffixIcon,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AppText(
              errorText!,
              variant: AppTextVariant.bodySmall,
              customColor: Colors.redAccent,
              weight: AppTextWeight.medium,
            ),
          ),
        ],
      ],
    );
  }
}
