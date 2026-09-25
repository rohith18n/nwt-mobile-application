import 'package:flutter/material.dart';
import 'package:nwt_app/constants/enums.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

/// A widget that displays a percentage delta value with appropriate styling.
///
/// This widget shows a percentage change with color-coding based on whether the change
/// is positive, negative, or neutral. It can optionally cap extreme values.
class DeltaIndicator extends StatelessWidget {
  /// The delta value to display as a percentage
  final double deltaValue;

  /// The type of delta (positive, negative, or neutral)
  final DeltaType deltaType;

  /// Whether to cap extreme percentage values to ±100%
  final bool capValue;

  /// Custom background color for the container (overrides default color based on deltaType)
  final Color? backgroundColor;

  /// Custom text color type for the delta text (overrides default color based on deltaType)
  final AppTextColorType? textColorType;

  /// Custom padding for the container
  final EdgeInsets? padding;

  /// Custom border radius for the container
  final BorderRadius? borderRadius;

  /// Custom text variant for the delta text
  final AppTextVariant textVariant;

  /// Custom text weight for the delta text
  final AppTextWeight textWeight;

  /// Text alignment for the delta text
  final TextAlign? textAlign;

  const DeltaIndicator({
    super.key,
    required this.deltaValue,
    required this.deltaType,
    this.capValue = false,
    this.backgroundColor,
    this.textColorType,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.borderRadius,
    this.textVariant = AppTextVariant.bodySmall,
    this.textWeight = AppTextWeight.medium,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    // Process delta value
    double displayValue = capValue ? _capValue(deltaValue) : deltaValue;

    // Format as percentage with proper sign
    String displayDelta = '${displayValue.toStringAsFixed(2)}%';

    // Add + sign for positive values
    if (deltaType == DeltaType.positive) {
      displayDelta = '+$displayDelta';
    } else {
      displayDelta = displayDelta;
    }

    // Determine colors based on delta type
    Color bgColor;
    AppTextColorType txtColorType;

    switch (deltaType) {
      case DeltaType.positive:
        bgColor = Colors.green.withOpacity(0.2);
        txtColorType = AppTextColorType.success;
        break;
      case DeltaType.negative:
        bgColor = Colors.red.withOpacity(0.2);
        txtColorType = AppTextColorType.error;
        break;
      case DeltaType.neutral:
        bgColor = Colors.grey.withOpacity(0.2);
        txtColorType = AppTextColorType.gray;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(6),
      ),
      child: AppText(
        displayDelta,
        variant: textVariant,
        weight: textWeight,
        colorType: textColorType ?? txtColorType,
        textAlign: textAlign,
      ),
    );
  }

  /// Caps percentage values to be within -100% to 100%
  double _capValue(double value) {
    if (value > 100) return 100;
    if (value < -100) return -100;
    return value;
  }
}

// DeltaType enum is now defined in constants/enums.dart
