import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/theme_controller.dart';

class AnimatedProcessingText extends StatefulWidget {
  final List<String> texts;
  final Duration duration;
  final VoidCallback? onComplete;
  final bool autoStart;
  final TextStyle? textStyle;

  const AnimatedProcessingText({
    super.key,
    required this.texts,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
    this.autoStart = true,
    this.textStyle,
  });

  static final List<String> defaultTexts = [
    'Contacting MF Central...',
    'Fetching your data...',
    'Processing information...',
    'Analyzing your portfolio...',
    'Almost there...',
  ];

  @override
  State<AnimatedProcessingText> createState() => _AnimatedProcessingTextState();
}

class _AnimatedProcessingTextState extends State<AnimatedProcessingText> {
  late List<String> currentTexts;
  Timer? _timer;
  int _currentIndex = 0;
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    currentTexts = List.from(widget.texts.isEmpty ? AnimatedProcessingText.defaultTexts : widget.texts);
    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _currentIndex = 0;
    setState(() {});

    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < currentTexts.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mutual Funds',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentTexts[_currentIndex],
                  key: ValueKey(_currentIndex),
                  style: widget.textStyle?.copyWith(
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ) ?? TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Financial Data is 100% Protected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
