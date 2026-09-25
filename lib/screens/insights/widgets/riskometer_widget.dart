import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/widgets/common/custom_accordion.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class RiskometerWidget extends StatelessWidget {
  final String riskLevel;
  final double riskValue;

  const RiskometerWidget({
    super.key,
    required this.riskLevel,
    required this.riskValue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAccordion(
      title: 'Riskometer',
      initiallyExpanded: true,
      child: Column(
        children: [
          // Gauge
          SizedBox(height: 200, child: _buildRadialTextPointer()),
          // Risk level text
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Center(
              child: AppText(
                'This fund has $riskLevel risk',
                variant: AppTextVariant.bodyLarge,
                weight: AppTextWeight.medium,
                colorType: AppTextColorType.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialTextPointer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size / 2),
              painter: RiskometerPainter(
                riskValue: riskValue,
                riskLevel: riskLevel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class RiskometerPainter extends CustomPainter {
  final double riskValue;
  final String riskLevel;

  RiskometerPainter({required this.riskValue, required this.riskLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - 2 * AppSizing.scaffoldHorizontalPadding;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 80.0
          ..strokeCap = StrokeCap.butt;

    final segmentColors = [
      const Color(0xFF5EC213),
      const Color(0xFFBDD527),
      const Color(0xFFFFD607),
      const Color(0xFFFE9105),
      const Color(0xFFFD5501),
      const Color(0xFFE00003),
    ];

    for (int i = 0; i < segmentColors.length; i++) {
      final startAngle = math.pi + (i * math.pi / 6);
      final sweepAngle = math.pi / 6;

      arcPaint.color = segmentColors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }

    final needleLength = radius * 0.85;

    double needleAngle;
    switch (riskLevel.toLowerCase()) {
      case 'low':
        needleAngle = math.pi + (math.pi / 12);
        break;
      case 'low to moderate':
        needleAngle = math.pi + (3 * math.pi / 12);
        break;
      case 'moderate':
        needleAngle = math.pi + (5 * math.pi / 12);
        break;
      case 'moderately high':
      case 'moderate to high':
        needleAngle = math.pi + (7 * math.pi / 12);
        break;
      case 'high':
        needleAngle = math.pi + (9 * math.pi / 12);
        break;
      case 'very high':
        needleAngle = math.pi + (11 * math.pi / 12);
        break;
      default:
        needleAngle = math.pi + (riskValue / 100 * math.pi);
    }

    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint =
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    canvas.drawLine(center, needleEnd, needlePaint);

    final knobPaint =
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 10.0, knobPaint);

    final knobBorderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawCircle(center, 10.0, knobBorderPaint);
  }

  @override
  bool shouldRepaint(RiskometerPainter oldDelegate) =>
      oldDelegate.riskValue != riskValue || oldDelegate.riskLevel != riskLevel;
}
