import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

enum AppInputFieldSize { small, medium, large }

enum AppInputFieldType { text, number, email, password, phone, decimal }

class AppInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final AppInputFieldSize size;
  final AppInputFieldType type;
  final bool showLabel;
  final AutovalidateMode autovalidateMode;
  final int? maxLength;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final Color? fillColor;

  const AppInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.prefix,
    this.suffix,
    this.size = AppInputFieldSize.large,
    this.type = AppInputFieldType.text,
    this.showLabel = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.enabled = true,
    this.fillColor,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _obscureText;
  late TextInputType _keyboardType;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _keyboardType = _getKeyboardType();
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) return widget.keyboardType!;

    switch (widget.type) {
      case AppInputFieldType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case AppInputFieldType.number:
        return TextInputType.number;
      case AppInputFieldType.email:
        return TextInputType.emailAddress;
      case AppInputFieldType.phone:
        return TextInputType.phone;
      case AppInputFieldType.password:
      case AppInputFieldType.text:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (widget.inputFormatters != null) {
      formatters.addAll(widget.inputFormatters!);
      return formatters;
    }

    switch (widget.type) {
      case AppInputFieldType.number:
        formatters.add(
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        );
        break;
      case AppInputFieldType.phone:
        formatters.add(FilteringTextInputFormatter.digitsOnly);
        if (widget.maxLength == null) {
          formatters.add(LengthLimitingTextInputFormatter(10));
        }
        break;
      default:
        break;
    }

    if (widget.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    }

    return formatters;
  }

  EdgeInsetsGeometry _getContentPadding() {
    if (widget.contentPadding != null) return widget.contentPadding!;

    switch (widget.size) {
      case AppInputFieldSize.small:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 16);
      case AppInputFieldSize.large:
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 16);
      case AppInputFieldSize.medium:
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 16);
    }
  }

  Widget? _buildSuffix() {
    if (widget.suffix != null) return widget.suffix;

    if (widget.type == AppInputFieldType.password) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        child: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey,
          size: 20,
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.labelText != null) ...[
          AppText(
            widget.labelText!,
            variant: AppTextVariant.bodyMedium,
            weight: AppTextWeight.semiBold,
            colorType:
                isDarkMode
                    ? AppTextColorType.primary
                    : AppTextColorType.secondary,
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscureText,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          keyboardType: _keyboardType,
          inputFormatters: _getInputFormatters(),
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          maxLines: widget.maxLines,
          textCapitalization: widget.textCapitalization,
          autovalidateMode: widget.autovalidateMode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefix,
            suffixIcon: _buildSuffix(),
            contentPadding: _getContentPadding(),
            fillColor: widget.fillColor,
            filled: widget.fillColor != null,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
