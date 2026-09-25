import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/controllers/theme_controller.dart';

enum ProcessingStepState { pending, loading, success }

class StepData {
  final String title;
  final IconData icon;
  final ProcessingStepState state;

  StepData({required this.title, required this.icon, required this.state});
}

class ModernVerticalStepper extends StatefulWidget {
  final List<StepData> steps;
  final double lineThickness;
  final double iconSize;
  final double spacing;
  final bool enableHaptics;
  final bool enableShimmer;
  final Duration stepDuration;
  final Duration lineDuration;
  final Duration shimmerDuration;

  const ModernVerticalStepper({
    super.key,
    required this.steps,
    this.lineThickness = 2,
    this.iconSize = 28,
    this.spacing = 50,
    this.enableHaptics = true,
    this.enableShimmer = true,
    this.stepDuration = const Duration(milliseconds: 600),
    this.lineDuration = const Duration(milliseconds: 800),
    this.shimmerDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<ModernVerticalStepper> createState() => _ModernVerticalStepperState();
}

class _ModernVerticalStepperState extends State<ModernVerticalStepper>
    with TickerProviderStateMixin {
  Color _getStepColor(ProcessingStepState state, bool isDarkMode) {
    switch (state) {
      case ProcessingStepState.success:
        return AppColors.success;
      case ProcessingStepState.loading:
        return isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary;
      case ProcessingStepState.pending:
        return isDarkMode ? AppColors.darkTextGray : AppColors.lightTextGray;
    }
  }

  Widget _buildStepIcon(StepData step, bool isDarkMode, int index) {
    if (widget.enableHaptics && step.state == ProcessingStepState.success) {
      HapticFeedback.lightImpact();
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: widget.iconSize,
            height: widget.iconSize,
            decoration: BoxDecoration(
              color: _getStepColor(step.state, isDarkMode).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStepColor(step.state, isDarkMode),
                width: 2,
              ),
              gradient:
                  widget.enableShimmer &&
                          step.state == ProcessingStepState.loading
                      ? LinearGradient(
                        begin: Alignment(-1.0, -0.5),
                        end: Alignment(1.0, 0.5),
                        colors: [
                          _getStepColor(
                            step.state,
                            isDarkMode,
                          ).withOpacity(0.05),
                          _getStepColor(
                            step.state,
                            isDarkMode,
                          ).withOpacity(0.2),
                          _getStepColor(
                            step.state,
                            isDarkMode,
                          ).withOpacity(0.05),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                      : null,
              boxShadow: [
                BoxShadow(
                  color: _getStepColor(step.state, isDarkMode).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                step.state == ProcessingStepState.loading
                    ? Stack(
                      children: [
                        if (widget.enableShimmer)
                          SizedBox(
                                width: widget.iconSize,
                                height: widget.iconSize,
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: widget.shimmerDuration,
                                color: _getStepColor(
                                  step.state,
                                  isDarkMode,
                                ).withOpacity(0.3),
                              ),
                        Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getStepColor(step.state, isDarkMode),
                                ),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .rotate(
                              duration: widget.stepDuration,
                              curve: Curves.linear,
                            ),
                      ],
                    )
                    : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            step.state == ProcessingStepState.success
                                ? Icons.check
                                : step.icon,
                            size: widget.iconSize * 0.6,
                            color: _getStepColor(step.state, isDarkMode),
                          ),
                        );
                      },
                    ),
          ),
        );
      },
    );
  }

  late final List<AnimationController> _iconControllers;
  late final List<AnimationController> _lineControllers;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _iconControllers = List.generate(
      widget.steps.length,
      (index) =>
          AnimationController(vsync: this, duration: widget.stepDuration)
            ..forward(),
    );

    _lineControllers = List.generate(
      widget.steps.length - 1,
      (index) =>
          AnimationController(vsync: this, duration: widget.lineDuration)
            ..forward(from: 0.0),
    );
  }

  @override
  void dispose() {
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    for (var controller in _lineControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDarkMode = themeController.isDarkMode;
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              children: List.generate(widget.steps.length * 2 - 1, (index) {
                if (index.isEven) {
                  final stepIndex = index ~/ 2;
                  final step = widget.steps[stepIndex];
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.2, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _iconControllers[stepIndex],
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _iconControllers[stepIndex],
                      child: Row(
                        children: [
                          _buildStepIcon(step, isDarkMode, stepIndex),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _getStepColor(
                                      step.state,
                                      isDarkMode,
                                    ),
                                  ),
                                ),
                                if (step.state == ProcessingStepState.loading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Processing',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getStepColor(
                                              step.state,
                                              isDarkMode,
                                            ),
                                          ),
                                        ),
                                        _buildLoadingDots(isDarkMode),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final lineIndex = index ~/ 2;
                  final currentStep = widget.steps[lineIndex];
                  return SizeTransition(
                    sizeFactor: _lineControllers[lineIndex],
                    axisAlignment: -1,
                    child: Container(
                      margin: EdgeInsets.only(left: widget.iconSize / 2 - 1),
                      height: widget.spacing,
                      child: VerticalDivider(
                        width: 2,
                        thickness: widget.lineThickness,
                        color:
                            currentStep.state == ProcessingStepState.success
                                ? _getStepColor(
                                  ProcessingStepState.success,
                                  isDarkMode,
                                ).withOpacity(0.5)
                                : _getStepColor(
                                  ProcessingStepState.pending,
                                  isDarkMode,
                                ).withOpacity(0.2),
                      ),
                    ),
                  );
                }
              }),
            ),
          );
        },
      );
    });
  }

  Widget _buildLoadingDots(bool isDarkMode) {
    return SizedBox(
      width: 24,
      child: Row(
        children: List.generate(
          3,
          (index) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    math.sin(value * math.pi * 2 + index * 0.5) * 2,
                  ),
                  child: Text(
                    '.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStepColor(
                        ProcessingStepState.loading,
                        isDarkMode,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
