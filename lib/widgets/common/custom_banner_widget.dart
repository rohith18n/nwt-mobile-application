import 'package:flutter/material.dart';

class CustomBannerWidget extends StatelessWidget {
  final Widget child;
  final String? bannerText;
  final Color bannerColor;
  final Color textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final BannerLocation location;
  final double bannerHeight;
  final double bannerWidth;
  final BorderRadius? borderRadius;
  final Widget? customBannerContent;

  const CustomBannerWidget({
    super.key,
    required this.child,
    this.bannerText,
    this.bannerColor = Colors.red,
    this.textColor = Colors.white,
    this.fontSize = 10,
    this.fontWeight = FontWeight.bold,
    this.fontFamily,
    this.location = BannerLocation.topEnd,
    this.bannerHeight = 24,
    this.bannerWidth = 80,
    this.borderRadius,
    this.customBannerContent,
  }) : assert(
          bannerText != null || customBannerContent != null,
          'Either bannerText or customBannerContent must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          child,
          _buildBanner(),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final isTopLocation = location == BannerLocation.topStart || location == BannerLocation.topEnd;
    final isLeftLocation = location == BannerLocation.topStart || location == BannerLocation.bottomStart;

    return Positioned(
      top: isTopLocation ? 0 : null,
      bottom: !isTopLocation ? 0 : null,
      left: isLeftLocation ? 0 : null,
      right: !isLeftLocation ? 0 : null,
      child: Transform.rotate(
        angle: _getRotationAngle(),
        child: Container(
          height: bannerHeight,
          width: bannerWidth,
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Center(
            child: customBannerContent ?? 
              Text(
                bannerText ?? '',
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  fontFamily: fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
          ),
        ),
      ),
    );
  }

  double _getRotationAngle() {
    switch (location) {
      case BannerLocation.topStart:
        return -0.785398; // -45 degrees
      case BannerLocation.topEnd:
        return 0.785398; // 45 degrees
      case BannerLocation.bottomStart:
        return 0.785398; // 45 degrees
      case BannerLocation.bottomEnd:
        return -0.785398; // -45 degrees
    }
  }
}

// Enhanced version with more customization options
class CustomBannerWidgetAdvanced extends StatelessWidget {
  final Widget child;
  final Widget bannerContent;
  final Color? bannerColor;
  final Gradient? bannerGradient;
  final BannerLocation location;
  final double bannerHeight;
  final double bannerWidth;
  final BorderRadius? borderRadius;
  final EdgeInsets? bannerPadding;
  final BoxDecoration? bannerDecoration;
  final bool showShadow;

  const CustomBannerWidgetAdvanced({
    super.key,
    required this.child,
    required this.bannerContent,
    this.bannerColor,
    this.bannerGradient,
    this.location = BannerLocation.topEnd,
    this.bannerHeight = 24,
    this.bannerWidth = 80,
    this.borderRadius,
    this.bannerPadding,
    this.bannerDecoration,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          child,
          _buildAdvancedBanner(),
        ],
      ),
    );
  }

  Widget _buildAdvancedBanner() {
    final isTopLocation = location == BannerLocation.topStart || location == BannerLocation.topEnd;
    final isLeftLocation = location == BannerLocation.topStart || location == BannerLocation.bottomStart;

    return Positioned(
      top: isTopLocation ? 0 : null,
      bottom: !isTopLocation ? 0 : null,
      left: isLeftLocation ? 0 : null,
      right: !isLeftLocation ? 0 : null,
      child: Transform.rotate(
        angle: _getRotationAngle(),
        child: Container(
          height: bannerHeight,
          width: bannerWidth,
          padding: bannerPadding ?? const EdgeInsets.all(4),
          decoration: bannerDecoration ?? BoxDecoration(
            color: bannerColor ?? Colors.red,
            gradient: bannerGradient,
            boxShadow: showShadow ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(child: bannerContent),
        ),
      ),
    );
  }

  double _getRotationAngle() {
    switch (location) {
      case BannerLocation.topStart:
        return -0.785398; // -45 degrees
      case BannerLocation.topEnd:
        return 0.785398; // 45 degrees
      case BannerLocation.bottomStart:
        return 0.785398; // 45 degrees
      case BannerLocation.bottomEnd:
        return -0.785398; // -45 degrees
    }
  }
}
