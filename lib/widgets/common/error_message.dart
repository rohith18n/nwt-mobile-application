import 'package:flutter/material.dart';

class AnimatedErrorMessage extends StatelessWidget {
  final String message;

  const AnimatedErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: message.isNotEmpty ? 1.0 : 0.0,
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 14,
        ),
      ),
    );
  }
}
