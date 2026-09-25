import 'dart:math';

import 'package:flutter/material.dart';

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset centerOffset;

  CircularRevealClipper({required this.fraction, required this.centerOffset});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double radius = sqrt(pow(size.width, 2) + pow(size.height, 2));
    final double currentRadius = radius * fraction;

    path.addOval(Rect.fromCircle(center: centerOffset, radius: currentRadius));

    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction ||
        oldClipper.centerOffset != centerOffset;
  }
}
