import 'package:flutter/material.dart';

/// Extension on Color class to provide additional functionality
extension ColorExtensions on Color {
  /// Returns a new color that is this color with the provided alpha value
  Color withValues({required double alpha}) {
    return withOpacity(alpha);
  }
}
