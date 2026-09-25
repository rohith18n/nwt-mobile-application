import 'package:flutter/material.dart';

enum DotDirection {
  horizontal,
  vertical,
}

class DotIndicator extends StatelessWidget {
  final int dotCount;
  final DotDirection direction;
  final Color dotColor;
  final double dotSize;
  final double? dotSpacing;
  final double dotRadius;

  const DotIndicator({
    Key? key,
    required this.dotCount,
    required this.direction,
    this.dotColor = Colors.blue,
    this.dotSize = 4.0,
    this.dotSpacing,
    this.dotRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dots = List.generate(
          dotCount,
          (index) => Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(dotRadius),
            ),
          ),
        );

        if (direction == DotDirection.horizontal) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: dots.expand((dot) => [
              dot,
              if (dot != dots.last) SizedBox(width: dotSpacing ?? 6),
            ]).toList(),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: dots.expand((dot) => [
            dot,
            if (dot != dots.last) SizedBox(height: dotSpacing ?? 6),
          ]).toList(),
        );
      },
    );
  }
}
