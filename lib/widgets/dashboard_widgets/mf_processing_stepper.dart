import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/dashboard_widgets/vertical_stepper.dart';

class MFProcessingStepper extends StatefulWidget {
  final List<StepData> steps;
  final Duration stepDuration;
  final VoidCallback? onComplete;
  final bool autoStart;

  const MFProcessingStepper({
    super.key,
    required this.steps,
    this.stepDuration = const Duration(seconds: 3),
    this.onComplete,
    this.autoStart = true,
  });

  static final List<StepData> defaultSteps = [
    StepData(
      title: 'Contacting MF Central',
      icon: Icons.cloud_sync,
      state: ProcessingStepState.pending,
    ),
    StepData(
      title: 'Fetching Data from MF Central',
      icon: Icons.download_rounded,
      state: ProcessingStepState.pending,
    ),
    StepData(
      title: 'Processing Data',
      icon: Icons.settings,
      state: ProcessingStepState.pending,
    ),
    StepData(
      title: 'Analyzing your Portfolio',
      icon: Icons.analytics_rounded,
      state: ProcessingStepState.pending,
    ),
  ];

  @override
  State<MFProcessingStepper> createState() => _MFProcessingStepperState();
}

class _MFProcessingStepperState extends State<MFProcessingStepper> {
  late List<StepData> currentSteps;
  Timer? _timer;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    currentSteps = List.from(
      widget.steps.isEmpty ? MFProcessingStepper.defaultSteps : widget.steps,
    );
    if (widget.autoStart) {
      _startProcessing();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startProcessing() {
    // Reset all steps to pending first
    for (var i = 0; i < currentSteps.length; i++) {
      _updateStepState(i, ProcessingStepState.pending);
    }

    // Reset index
    _currentStepIndex = 0;
    // Set first step to loading
    _updateStepState(0, ProcessingStepState.loading);

    _timer = Timer.periodic(widget.stepDuration, (timer) {
      if (_currentStepIndex < currentSteps.length) {
        setState(() {
          // Mark current step as success
          _updateStepState(_currentStepIndex, ProcessingStepState.success);

          // Move to next step
          _currentStepIndex++;

          // If there's a next step, mark it as loading
          if (_currentStepIndex < currentSteps.length) {
            _updateStepState(_currentStepIndex, ProcessingStepState.loading);
          } else {
            // All steps completed
            timer.cancel();
            widget.onComplete?.call();
          }
        });
      }
    });
  }

  void _updateStepState(int index, ProcessingStepState state) {
    if (index >= 0 && index < currentSteps.length) {
      currentSteps[index] = StepData(
        title: currentSteps[index].title,
        icon: currentSteps[index].icon,
        state: state,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mutual Funds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ModernVerticalStepper(
            steps: currentSteps,
            enableHaptics: true,
            enableShimmer: true,
            spacing: 32,
          ),
          const SizedBox(height: 24),
          Row(
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
  }
}
