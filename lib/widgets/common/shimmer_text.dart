import 'package:flutter/material.dart';
import 'package:nwt_app/constants/colors.dart';

/// A text widget with a shimmer effect that respects the app's theme
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  final TextAlign? textAlign;
  final double? lineHeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  /// Duration for one complete shimmer animation cycle
  final Duration shimmerDuration;

  /// Gradient colors for the shimmer effect
  /// If null, colors will be derived from the theme
  final List<Color>? shimmerColors;

  /// Whether the shimmer effect is enabled
  final bool isShimmering;

  const ShimmerText(
    this.text, {
    this.style,
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.darkPrimary,
    this.textAlign,
    this.lineHeight,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.shimmerDuration = const Duration(milliseconds: 1500),
    this.shimmerColors,
    this.isShimmering = true,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isShimmering) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShimmering != oldWidget.isShimmering) {
      if (widget.isShimmering) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }

    if (widget.shimmerDuration != oldWidget.shimmerDuration) {
      _controller.duration = widget.shimmerDuration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine shimmer colors based on theme
    final List<Color> colors =
        widget.shimmerColors ?? _getShimmerColors(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0.0),
              end: Alignment(_animation.value, 0.0),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style:
                widget.style ??
                TextStyle(
                  color: widget.color,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                ),
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          ),
        );
      },
    );
  }

  List<Color> _getShimmerColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color;
    if (isDarkMode) {
      // Dark theme shimmer colors
      return [
        baseColor.withOpacity(0.5),
        baseColor,
        baseColor.withOpacity(0.5),
      ];
    } else {
      // Light theme shimmer colors
      return [
        baseColor.withOpacity(0.5),
        baseColor,
        baseColor.withOpacity(0.5),
      ];
    }
  }
}
