import 'package:flutter/material.dart';
import 'package:nwt_app/widgets/common/shimmer_text.dart';

class AnimatedAmount extends StatelessWidget {
  final bool isAmountVisible;
  final String amount;
  final String hiddenText;
  final Duration duration;
  final TextStyle? style;
  final Offset slideOffset;
  final Curve curve;
  final Alignment alignment;
  final bool isLoading;
  final bool isMain;

  const AnimatedAmount({
    super.key,
    required this.isAmountVisible,
    required this.amount,
    this.hiddenText = '••••••',
    this.duration = const Duration(milliseconds: 400),
    this.style,
    this.slideOffset = const Offset(0, 0.2),
    this.curve = Curves.easeOutCubic,
    this.alignment = Alignment.centerLeft,
    this.isLoading = false,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: alignment,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: slideOffset,
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: curve)),
              child: child,
            ),
          );
        },
        child: isLoading
            ? _buildAdaptiveText(
                context,
                const ValueKey('amount_visible'),
                shimmer: true,
              )
            : isAmountVisible
                ? _buildAdaptiveText(
                    context,
                    const ValueKey('amount_visible'),
                    text: amount,
                  )
                : _buildAdaptiveText(
                    context,
                    const ValueKey('amount_hidden'),
                    text: hiddenText,
                  ),
      ),
    );
  }

  Widget _buildAdaptiveText(
    BuildContext context,
    Key key, {
    String? text,
    bool shimmer = false,
  }) {
    final base = shimmer
        ? ShimmerText(
            key: key,
            "••••••",
            style: style ?? const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          )
        : Text(
            text ?? '',
            key: key,
            style: style ?? const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          );

    if (!isMain) return base;

    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is unbounded, skip FittedBox to avoid layout issues
        if (!constraints.hasBoundedWidth || constraints.maxWidth.isInfinite) {
          return base;
        }

        return SizedBox(
          width: constraints.maxWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: base,
          ),
        );
      },
    );
  }
}
