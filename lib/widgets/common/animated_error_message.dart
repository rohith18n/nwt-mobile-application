import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class AnimatedErrorMessage extends StatelessWidget {
  final String? errorMessage;
  final Duration animationDuration;
  final EdgeInsetsGeometry padding;

  const AnimatedErrorMessage({
    super.key,
    required this.errorMessage,
    this.animationDuration = const Duration(milliseconds: 300),
    this.padding = const EdgeInsets.only(bottom: 0.0),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: animationDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child:
          errorMessage != null && errorMessage!.isNotEmpty
              ? Padding(
                key: ValueKey<String>(errorMessage!),
                padding: padding,
                child: Semantics(
                  liveRegion: true,
                  child: AppText(
                    errorMessage!,
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.error,
                    weight: AppTextWeight.medium,
                  ),
                ),
              )
              : const SizedBox.shrink(key: ValueKey<String>('empty')),
    );
  }
}
