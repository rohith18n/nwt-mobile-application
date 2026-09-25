import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/colors.dart';

class Avatar extends StatelessWidget {
  final String path;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool isNetworkImage;
  final Color? backgroundColor;

  const Avatar({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.isNetworkImage = true,
    this.backgroundColor,
  });

  Widget _buildShimmerPlaceholder() {
    return _AvatarShimmerPlaceholder(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(width / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If path is empty, show errorWidget directly
    if (path.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: errorWidget ?? const Icon(Icons.error),
      );
    }

    final bool isNetwork =
        isNetworkImage || path.toLowerCase().startsWith('http');
    final String cleanPath = path.split('?').first.toLowerCase();
    final bool isSvg = cleanPath.endsWith('.svg');

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(width / 2),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(width / 2),
        child:
            isNetwork
                ? isSvg
                    ? _NetworkSvgWithCssHack(
                      url: path,
                      width: width,
                      height: height,
                      fit: fit,
                      placeholderBuilder:
                          (context) =>
                              placeholder ?? _buildShimmerPlaceholder(),
                    )
                    : CachedNetworkImage(
                      width: width,
                      height: height,
                      imageUrl: path,
                      placeholder:
                          (context, url) =>
                              placeholder ?? _buildShimmerPlaceholder(),
                      errorWidget:
                          (context, url, error) =>
                              errorWidget ?? const Icon(Icons.error),
                      fit: fit,
                    )
                : isSvg
                ? SvgPicture.asset(
                  path,
                  width: width,
                  height: height,
                  colorFilter: null,
                  placeholderBuilder:
                      (context) => placeholder ?? _buildShimmerPlaceholder(),
                )
                : Image.asset(
                  path,
                  width: width,
                  height: height,
                  fit: fit,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          errorWidget ?? const Icon(Icons.error),
                ),
      ),
    );
  }
}

/// A shimmer placeholder for avatar loading states
class _AvatarShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Duration shimmerDuration;

  const _AvatarShimmerPlaceholder({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.shimmerDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<_AvatarShimmerPlaceholder> createState() =>
      _AvatarShimmerPlaceholderState();
}

class _AvatarShimmerPlaceholderState extends State<_AvatarShimmerPlaceholder>
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

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final List<Color> colors = [
      baseColor.withOpacity(0.15),
      baseColor.withOpacity(0.3),
      baseColor.withOpacity(0.15),
    ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0.0),
              end: Alignment(_animation.value, 0.0),
            ),
          ),
        );
      },
    );
  }
}

/// A network SVG renderer that manually parses and inlines basic CSS classes
/// since flutter_svg often strips `<style>` tags, resulting in black logos.
class _NetworkSvgWithCssHack extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final WidgetBuilder placeholderBuilder;

  const _NetworkSvgWithCssHack({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.placeholderBuilder,
  });

  @override
  State<_NetworkSvgWithCssHack> createState() => _NetworkSvgWithCssHackState();
}

class _NetworkSvgWithCssHackState extends State<_NetworkSvgWithCssHack> {
  static final Map<String, String> _cache = {};
  String? _svgString;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(_NetworkSvgWithCssHack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _svgString = null;
      _hasError = false;
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    if (_cache.containsKey(widget.url)) {
      if (mounted) {
        setState(() {
          _svgString = _cache[widget.url];
        });
      }
      return;
    }

    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final processedSvg = _injectCss(response.body);
        _cache[widget.url] = processedSvg;
        if (mounted) {
          setState(() {
            _svgString = processedSvg;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  String _injectCss(String svg) {
    try {
      // Extract the style block
      final styleMatch = RegExp(
        r'<style[^>]*>(.*?)</style>',
        dotAll: true,
      ).firstMatch(svg);
      if (styleMatch == null) return svg;

      final styleContent = styleMatch.group(1)!;
      // Match class rules like `.cls-1 { fill: #ED1C24; }`
      final classRegExp = RegExp(r'\.([a-zA-Z0-9_\-]+)\s*\{([^}]+)\}');
      final matches = classRegExp.allMatches(styleContent);

      String updatedSvg = svg;
      for (final match in matches) {
        final className = match.group(1)!;
        final rules = match.group(2)!.trim();
        // Inline the styles directly onto the elements
        updatedSvg = updatedSvg.replaceAll(
          'class="$className"',
          'style="$rules"',
        );
        updatedSvg = updatedSvg.replaceAll(
          "class='$className'",
          "style='$rules'",
        );
      }
      return updatedSvg;
    } catch (e) {
      return svg; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Icon(Icons.error);
    }
    if (_svgString == null) {
      return widget.placeholderBuilder(context);
    }
    return SvgPicture.string(
      _svgString!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholderBuilder: widget.placeholderBuilder,
    );
  }
}
