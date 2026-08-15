import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/logger.dart';

class ESignWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const ESignWebViewScreen({
    super.key,
    required this.url,
    this.title = 'E-Sign Document',
  });

  @override
  State<ESignWebViewScreen> createState() => _ESignWebViewScreenState();
}

class _ESignWebViewScreenState extends State<ESignWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            AppLogger.info('Page started: $url', tag: 'ESignWebView');
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            AppLogger.info('Page finished: $url', tag: 'ESignWebView');
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            AppLogger.info('Navigation request: ${request.url}', tag: 'ESignWebView');
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.error('WebView error: ${error.description} (${error.errorCode})', tag: 'ESignWebView');
          },
          onHttpError: (HttpResponseError error) {
            AppLogger.error('HTTP error: ${error.response?.statusCode}', tag: 'ESignWebView');
          },
        ),
      );
    
    // Add JavaScript channel to capture console logs
    _controller.addJavaScriptChannel(
      'FlutterConsole',
      onMessageReceived: (JavaScriptMessage message) {
        AppLogger.info('WebView Console: ${message.message}', tag: 'ESignWebView');
      },
    );
    
    // Android-specific configuration
    if (Platform.isAndroid) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return GeolocationPermissionsResponse(
            allow: true,
            retain: true,
          );
        },
      );
    }
    
    // Load the URL
    _controller.loadRequest(
      Uri.parse(widget.url),
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      },
    );
    
    // Inject console capture script after page loads
    _controller.runJavaScript('''
      (function() {
        var originalLog = console.log;
        var originalError = console.error;
        var originalWarn = console.warn;
        
        console.log = function() {
          FlutterConsole.postMessage('LOG: ' + Array.from(arguments).join(' '));
          originalLog.apply(console, arguments);
        };
        
        console.error = function() {
          FlutterConsole.postMessage('ERROR: ' + Array.from(arguments).join(' '));
          originalError.apply(console, arguments);
        };
        
        console.warn = function() {
          FlutterConsole.postMessage('WARN: ' + Array.from(arguments).join(' '));
          originalWarn.apply(console, arguments);
        };
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          widget.title,
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: isDarkMode 
                      ? AppColors.darkButtonBorder 
                      : AppColors.lightButtonBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode 
                        ? AppColors.darkButtonPrimaryBackground 
                        : AppColors.lightButtonPrimaryBackground,
                  ),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
