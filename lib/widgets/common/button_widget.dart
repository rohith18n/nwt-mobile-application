import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppButtonVariant { primary, secondary, outlined, text, destructive }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isFullWidth;
  final bool isDisabled;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? customBorderRadius;
  final EdgeInsets? customPadding;
  final bool isLoading;
  final Color? loadingIndicatorColor;
  final double? customHeight;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isFullWidth = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.customBorderRadius,
    this.customPadding,
    this.isLoading = false,
    this.loadingIndicatorColor,
    this.customHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get button styles based on variant
    final buttonStyle = _getButtonStyle(context);

    // Get padding based on size
    final buttonPadding = customPadding ?? _getButtonPadding();

    // Get border radius
    final borderRadius = customBorderRadius ?? 15.0;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: SizedBox(
        height: customHeight ?? 60.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonStyle.backgroundColor,
            foregroundColor: buttonStyle.textColor,
            disabledBackgroundColor:
                isDarkMode
                    ? const Color(0xFF242424)
                    : buttonStyle.backgroundColor.withOpacity(0.1),
            disabledForegroundColor:
                isDarkMode
                    ? Colors.white
                    : buttonStyle.textColor.withOpacity(0.38),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(
                color:
                    isDisabled
                        ? (isDarkMode
                            ? const Color(0xFF242424)
                            : buttonStyle.borderColor.withOpacity(0.1))
                        : buttonStyle.borderColor,
                width:
                    buttonStyle.variant == AppButtonVariant.outlined
                        ? 2.0.w
                        : 0.5.w,
              ),
            ),
            elevation: buttonStyle.variant == AppButtonVariant.text ? 0 : 0,
          ),
          onPressed: isDisabled ? null : (isLoading ? null : onPressed),
          child:
              isLoading
                  ? _buildLoadingIndicator(context)
                  : _buildButtonContent(buttonStyle, isDarkMode),
        ),
      ),
    );
  }

  // Build loading indicator
  Widget _buildLoadingIndicator(BuildContext context) {
    final double size = _getLoaderSize();
    final buttonStyle = _getButtonStyle(context);

    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0.w,
        color: loadingIndicatorColor ?? buttonStyle.backgroundColor,
        strokeCap: StrokeCap.round,
      ),
    );
  }

  // Build button content (text and icons)
  Widget _buildButtonContent(_ButtonStyle buttonStyle, bool isDarkMode) {
    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: _getIconSize()),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: _getTextSize(),
              ),
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          SizedBox(width: 8.w),
          Icon(trailingIcon, size: _getIconSize()),
        ],
      ],
    );
  }

  // Get loader size based on button size
  double _getLoaderSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16.0.w;
      case AppButtonSize.medium:
        return 14.0.w;
      case AppButtonSize.large:
        return 22.0.w;
    }
  }

  // Get button padding based on size
  EdgeInsets _getButtonPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 8.0.h);
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h);
      case AppButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h);
    }
  }

  // Get text size based on button size
  double _getTextSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14.0.sp;
      case AppButtonSize.medium:
        return 16.0.sp;
      case AppButtonSize.large:
        return 16.0.sp;
    }
  }

  // Get icon size based on button size
  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16.0.sp;
      case AppButtonSize.medium:
        return 20.0.sp;
      case AppButtonSize.large:
        return 24.0.sp;
    }
  }

  // Get button style based on variant and theme
  _ButtonStyle _getButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (isDarkMode) {
      // Dark theme styles
      switch (variant) {
        case AppButtonVariant.primary:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: AppColors.darkButtonPrimaryBackground,
            textColor: AppColors.darkButtonPrimaryText,
            borderColor: AppColors.darkButtonPrimaryBorder,
          );
        case AppButtonVariant.secondary:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.transparent,
            textColor: Colors.white,
            borderColor: Colors.white.withAlpha(51),
          );
        case AppButtonVariant.outlined:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.transparent,
            textColor: AppColors.darkButtonPrimaryBackground,
            borderColor: AppColors.darkButtonPrimaryBackground,
          );
        case AppButtonVariant.text:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.transparent,
            textColor: AppColors.darkButtonPrimaryBackground,
            borderColor: Colors.transparent,
          );
        case AppButtonVariant.destructive:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.red.shade800,
            textColor: Colors.white,
            borderColor: Colors.red.shade800,
          );
      }
    } else {
      // Light theme styles
      final colors = _getLightThemeColors(context);
      switch (variant) {
        case AppButtonVariant.primary:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: colors.primary,
            textColor: Colors.white,
            borderColor: colors.primary,
          );
        case AppButtonVariant.secondary:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            borderColor: colors.border,
          );
        case AppButtonVariant.outlined:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.transparent,
            textColor: colors.primary,
            borderColor: colors.primary,
          );
        case AppButtonVariant.text:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.transparent,
            textColor: colors.primary,
            borderColor: Colors.transparent,
          );
        case AppButtonVariant.destructive:
          return _ButtonStyle(
            variant: variant,
            backgroundColor: Colors.red.shade600,
            textColor: Colors.white,
            borderColor: Colors.red.shade600,
          );
      }
    }
  }

  // Light theme color helper
  _ThemeColors _getLightThemeColors(BuildContext context) {
    final theme = Theme.of(context);

    return _ThemeColors(
      primary:
          theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
          Colors.black,
      text:
          theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ??
          Colors.white,
      border:
          theme.elevatedButtonTheme.style?.side?.resolve({})?.color ??
          const Color.fromRGBO(197, 201, 208, 1),
    );
  }
}

// Helper class for button styles
class _ButtonStyle {
  final AppButtonVariant variant;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  _ButtonStyle({
    required this.variant,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

// Helper class for theme colors
class _ThemeColors {
  final Color primary;
  final Color text;
  final Color border;

  _ThemeColors({
    required this.primary,
    required this.text,
    required this.border,
  });
}
