import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int currentScreenIndex;
  final int totalSteps;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.currentScreenIndex,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress based on current screen index
    // Total screens: 0-8 (9 screens total)
    // Progress = (currentScreenIndex + 1) / 9
    final double progress = (currentScreenIndex + 1) / 9;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          //   child: AppText(
          //     'Question ${currentStep + currentScreenIndex * 4} of $totalSteps',
          //     variant: AppTextVariant.bodySmall,
          //     customColor: Colors.grey[400],
          //   ),
          // ),
        ],
      ),
    );
  }
}
