import 'package:flutter/material.dart';

/// Extension methods for widgets to help with common layout patterns
extension WidgetExtensions on Widget {
  /// Adds vertical spacing after this widget when used in a column
  Widget withSpacing({double height = 12.0}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        this,
        SizedBox(height: height),
      ],
    );
  }
}

/// Extension methods for lists of widgets
extension WidgetListExtensions on List<Widget> {
  /// Adds spacing between widgets in a list, useful for Column children
  List<Widget> withSpacingBetween({double spacing = 12.0}) {
    if (isEmpty) return [];
    if (length == 1) return this;

    final result = <Widget>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }
}
