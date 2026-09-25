import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/dashboard_widgets/mf_processing_stepper.dart';

class MFProcessingSteps extends StatefulWidget {
  const MFProcessingSteps({super.key});

  @override
  State<MFProcessingSteps> createState() => _MFProcessingStepsState();
}

class _MFProcessingStepsState extends State<MFProcessingSteps> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MFProcessingStepper(steps: MFProcessingStepper.defaultSteps),
      ),
    );
  }
}
