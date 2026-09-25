import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/dashboard_widgets/animated_processing_text.dart';

class AnimatedTextExample extends StatefulWidget {
  const AnimatedTextExample({super.key});

  @override
  State<AnimatedTextExample> createState() => _AnimatedTextExampleState();
}

class _AnimatedTextExampleState extends State<AnimatedTextExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedProcessingText(
          texts: AnimatedProcessingText.defaultTexts,
          onComplete: () {
            debugPrint('Animation sequence completed!');
          },
        ),
      ),
    );
  }
}
