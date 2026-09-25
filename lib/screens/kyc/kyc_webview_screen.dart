import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

const String _logTag = 'KycWebView';

/// Sanitize URL for logging: scheme + host only, no query/fragment.
String _sanitizedUrlForLog(String? url) {
  if (url == null || url.isEmpty) return '(empty)';
  try {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host} (length=${url.length})';
  } catch (_) {
    return '(parse failed length=${url.length})';
  }
}

/// Full-screen WebView for KYC onboarding. User closes manually when done.
/// No redirect detection; caller runs post-close flow (pan/verify → success screen).
class KycWebViewScreen extends StatefulWidget {
  final String journeyUrl;
  final VoidCallback? onClose;

  const KycWebViewScreen({super.key, required this.journeyUrl, this.onClose});

  @override
  State<KycWebViewScreen> createState() => _KycWebViewScreenState();
}

/// Placeholder callback host used by MFU when KYC_CALLBACK_URL is not set.
const String _placeholderCallbackHost = 'example.com';

class _KycWebViewScreenState extends State<KycWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;
  String? loadError;
  Timer? _loadFallbackTimer;

  /// Set when we detect redirect to placeholder (e.g. example.com) so user sees a fix message.
  String? _redirectWarningMessage;

  void _close() {
    widget.onClose?.call();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _cancelLoadFallback() {
    _loadFallbackTimer?.cancel();
    _loadFallbackTimer = null;
  }

  void _startLoadFallback() {
    _cancelLoadFallback();
    _loadFallbackTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      setState(() {
        if (isLoading) isLoading = false;
      });
      _cancelLoadFallback();
    });
  }

  @override
  void dispose() {
    _cancelLoadFallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(widget.journeyUrl);
    AppLogger.info(
      'KYC WebView build url=${_sanitizedUrlForLog(widget.journeyUrl)} valid=${uri != null}',
      tag: _logTag,
    );
    if (widget.journeyUrl.isEmpty || uri == null) {
      AppLogger.warning(
        'KYC WebView invalid URL length=${widget.journeyUrl.length} uriNull=${uri == null}',
        tag: _logTag,
      );
      return Scaffold(
        backgroundColor: AppColors.darkCardBG,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: GestureDetector(
            onTap: _close,
            child: const Icon(Icons.chevron_left, size: 32),
          ),
          centerTitle: true,
          title: const AppText(
            'KYC',
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
                  'Invalid KYC page URL.',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: _close,
          child: const Icon(
            Icons.chevron_left,
            size: 32,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        title: const AppText(
          'KYC',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                javaScriptEnabled: true,
                cacheEnabled: true,
                domStorageEnabled: true,
                useHybridComposition: true,
                allowsInlineMediaPlayback: true,
                verticalScrollBarEnabled: true,
                horizontalScrollBarEnabled: true,
                transparentBackground: false,
                supportZoom: true,
                databaseEnabled: true,
                useOnDownloadStart: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
                AppLogger.info('KYC WebView created', tag: _logTag);
              },
              onLoadStart: (controller, url) {
                AppLogger.info(
                  'KYC WebView onLoadStart url=${_sanitizedUrlForLog(url?.toString())}',
                  tag: _logTag,
                );
                _startLoadFallback();
                setState(() {
                  isLoading = true;
                  loadError = null;
                });
              },
              onLoadStop: (controller, url) {
                final urlStr = url?.toString() ?? '';
                AppLogger.info(
                  'KYC WebView onLoadStop url=${_sanitizedUrlForLog(urlStr)}',
                  tag: _logTag,
                );
                if (urlStr.contains(_placeholderCallbackHost)) {
                  AppLogger.warning(
                    'KYC WebView redirected to placeholder callback ($_placeholderCallbackHost). Set KYC_CALLBACK_URL in MFU env.',
                    tag: _logTag,
                  );
                  setState(() {
                    _redirectWarningMessage =
                        'KYC was redirected to a placeholder page. Your backend needs a valid KYC callback URL (set KYC_CALLBACK_URL in the server environment), then try again.';
                  });
                }
                _cancelLoadFallback();
                setState(() {
                  isLoading = false;
                  loadError = null;
                });
              },
              onLoadError: (controller, url, code, message) {
                AppLogger.error(
                  'KYC WebView onLoadError code=$code message=$message url=${_sanitizedUrlForLog(url?.toString())}',
                  tag: _logTag,
                );
                _cancelLoadFallback();
                setState(() {
                  isLoading = false;
                  loadError = message;
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() => this.progress = progress / 100);
              },
              onDownloadStartRequest: (controller, downloadStartRequest) async {
                final url = downloadStartRequest.url;
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    AppLogger.error(
                      "Could not launch download URL: $url",
                      tag: _logTag,
                    );
                  }
                } catch (e) {
                  AppLogger.error(
                    "Error launching download URL: $e",
                    tag: _logTag,
                  );
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                final url = uri?.toString() ?? '';
                AppLogger.info(
                  'KYC WebView shouldOverrideUrlLoading url=$url',
                  tag: _logTag,
                );
                if (url.contains(_placeholderCallbackHost)) {
                  AppLogger.info(
                    'KYC WebView blocking redirect to placeholder callback',
                    tag: _logTag,
                  );
                  return NavigationActionPolicy.CANCEL;
                }

                // Intercept PDF links to handle them externally (fixes blank screen on Android)
                if (uri != null && uri.path.toLowerCase().endsWith('.pdf')) {
                  AppLogger.info(
                    'KYC WebView intercepting PDF link: $url',
                    tag: _logTag,
                  );
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      return NavigationActionPolicy.CANCEL;
                    }
                  } catch (e) {
                    AppLogger.error(
                      "Error launching PDF URL: $e",
                      tag: _logTag,
                    );
                  }
                }

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
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return NavigationActionPolicy.CANCEL;
                  } catch (e) {
                    AppLogger.error(
                      "Error launching non-HTTP URL: $e",
                      tag: _logTag,
                    );
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
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
            ),
          if (isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.lightPrimary,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 16,
                      ),
                      child: Text(
                        'Loading... ${(progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_redirectWarningMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _redirectWarningMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: _close,
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
