import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen WebView for the Finarkein consent journey.
/// When [redirectUrlToDetect] is provided and the webview loads that URL (or one containing it),
/// the webview auto-closes. Otherwise user taps Close. Caller runs post-close flow (consent status + data result).
class FinarkeinJourneyWebView extends StatefulWidget {
  final String journeyUrl;
  final String? redirectUrlToDetect;
  final VoidCallback? onRedirectDetected;

  /// When true, hides the back button in the app bar.
  final bool hideBackButton;

  const FinarkeinJourneyWebView({
    super.key,
    required this.journeyUrl,
    this.redirectUrlToDetect,
    this.onRedirectDetected,
    this.hideBackButton = false,
  });

  @override
  State<FinarkeinJourneyWebView> createState() =>
      _FinarkeinJourneyWebViewState();
}

class _FinarkeinJourneyWebViewState extends State<FinarkeinJourneyWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;
  String? loadError;
  bool _hasAutoClosed = false;
  int? _lastLoggedProgress;
  Timer? _urlCheckTimer;

  static const String _logTag = 'FinarkeinJourneyWebView';

  /// Pops the route. [completedWithRedirect] true when redirect URL was detected (journey completed), false when user tapped back (cancelled).
  void _close({bool completedWithRedirect = false}) {
    if (context.mounted) {
      Navigator.of(context).pop(completedWithRedirect);
    }
  }

  bool _urlMatchesRedirect(String? url) {
    final pattern = widget.redirectUrlToDetect?.trim();
    if (pattern == null || pattern.isEmpty || url == null || url.isEmpty) {
      return false;
    }
    // More robust matching: ignore trailing slashes and case
    final normalizedUrl = url.toLowerCase().replaceAll(RegExp(r'/$'), '');
    final normalizedPattern = pattern.toLowerCase().replaceAll(
      RegExp(r'/$'),
      '',
    );
    return normalizedUrl.contains(normalizedPattern);
  }

  void _maybeAutoClose(String? url) {
    if (_hasAutoClosed) return;
    if (!_urlMatchesRedirect(url)) return;
    _hasAutoClosed = true;
    _urlCheckTimer?.cancel();
    widget.onRedirectDetected?.call();
    AppLogger.info(
      '[WebViewCallback] Redirect URL detected, auto-closing url=$url',
      tag: _logTag,
    );
    // Close immediately without waiting for postFrameCallback
    if (mounted) _close(completedWithRedirect: true);
  }

  void _startPeriodicUrlCheck() {
    // iOS-specific: Periodically check URL as some callbacks may not fire
    if (!Platform.isIOS) return;
    _urlCheckTimer?.cancel();
    _urlCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_hasAutoClosed || !mounted) {
        timer.cancel();
        return;
      }
      final controller = webViewController;
      if (controller != null) {
        try {
          final url = await controller.getUrl();
          final urlStr = url?.toString();
          if (_urlMatchesRedirect(urlStr)) {
            AppLogger.info(
              '[PeriodicCheck] Redirect URL detected on iOS: $urlStr',
              tag: _logTag,
            );
            _maybeAutoClose(urlStr);
          }
        } catch (e) {
          AppLogger.error(
            '[PeriodicCheck] Error checking URL: $e',
            tag: _logTag,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _urlCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(widget.journeyUrl);
    if (widget.journeyUrl.isEmpty || uri == null) {
      return Scaffold(
        backgroundColor: AppColors.darkCardBG,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: widget.hideBackButton
              ? null
              : GestureDetector(
                  onTap: _close,
                  child: const Icon(Icons.chevron_left, size: 32),
                ),
          centerTitle: true,
          title: const AppText(
            'Account Aggregator',
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText(
                  'Invalid consent page URL.',
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(onPressed: _close, child: const Text('Close')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkCardBG,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: widget.hideBackButton
            ? null
            : GestureDetector(
                onTap: _close,
                child: const Icon(Icons.chevron_left, size: 32),
              ),
        centerTitle: true,
        title: const AppText(
          'Account Aggregator',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              cacheEnabled: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: true,
              transparentBackground: true,
              supportZoom: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
              _startPeriodicUrlCheck();
              AppLogger.info(
                '[WebViewCallback] onWebViewCreated',
                tag: _logTag,
              );
            },
            onLoadStart: (controller, url) {
              if (!mounted) return;
              final urlStr = url?.toString();
              if (_urlMatchesRedirect(urlStr)) {
                _maybeAutoClose(urlStr);
                return;
              }
              setState(() {
                isLoading = true;
                loadError = null;
              });
              AppLogger.info(
                '[WebViewCallback] onLoadStart url=$url',
                tag: _logTag,
              );
            },
            onLoadStop: (controller, url) async {
              if (!mounted) return;
              setState(() {
                isLoading = false;
                loadError = null;
              });
              final currentUrl = url?.toString();
              AppLogger.info(
                '[WebViewCallback] onLoadStop url=$currentUrl',
                tag: _logTag,
              );
              final fallbackUrl = await controller.getUrl();
              if (!mounted) return;
              final urlToCheck = currentUrl ?? fallbackUrl?.toString();
              if (_urlMatchesRedirect(urlToCheck)) {
                AppLogger.info(
                  '[WebViewCallback] onLoadStop fallback: redirect detected',
                  tag: _logTag,
                );
                _maybeAutoClose(urlToCheck);
              }
            },
            onLoadError: (controller, url, code, message) {
              if (!mounted) return;
              setState(() {
                isLoading = false;
                loadError = message;
              });
              AppLogger.error(
                '[WebViewCallback] onLoadError url=$url code=$code message=$message',
                tag: _logTag,
              );
            },
            onProgressChanged: (controller, progress) {
              if (!mounted) return;
              setState(() => this.progress = progress / 100);
              final pct = (progress / 100).round();
              if ((pct == 25 || pct == 50 || pct == 100) &&
                  (_lastLoggedProgress == null || pct != _lastLoggedProgress)) {
                _lastLoggedProgress = pct;
                AppLogger.info(
                  '[WebViewCallback] onProgressChanged progress=$pct%',
                  tag: _logTag,
                );
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              final urlStr = uri?.toString();
              AppLogger.info(
                '[WebViewCallback] shouldOverrideUrlLoading url=$urlStr',
                tag: _logTag,
              );

              if (_urlMatchesRedirect(urlStr)) {
                _maybeAutoClose(urlStr);
                return NavigationActionPolicy.CANCEL;
              }

              // Handle custom schemes (UPI, mailto, etc.)
              if (uri != null &&
                  ![
                    "http",
                    "https",
                    "file",
                    "chrome",
                    "data",
                    "javascript",
                    "about",
                  ].contains(uri.scheme)) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }
              }

              return NavigationActionPolicy.ALLOW;
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              final urlStr = url?.toString();
              AppLogger.info(
                '[WebViewCallback] onUpdateVisitedHistory url=$urlStr androidIsReload=$androidIsReload',
                tag: _logTag,
              );
              if (_urlMatchesRedirect(urlStr)) {
                _maybeAutoClose(urlStr);
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              AppLogger.info(
                '[WebViewCallback] onConsoleMessage level=${consoleMessage.messageLevel} message=${consoleMessage.message}',
                tag: _logTag,
              );
            },
          ),
          if (loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      'Failed to load page: $loadError',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(onPressed: _close, child: const Text('Close')),
                  ],
                ),
              ),
            )
          else if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    color: AppColors.lightPrimary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Loading... ${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
