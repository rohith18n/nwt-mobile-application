import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ZerodhaWebView extends StatefulWidget {
  final String url;
  final String title;

  const ZerodhaWebView({super.key, required this.url, required this.title});

  @override
  State<ZerodhaWebView> createState() => _ZerodhaWebViewState();
}

class _ZerodhaWebViewState extends State<ZerodhaWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  double progress = 0;
  bool isLoading = true;
  String currentUrl = '';

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: AppColors.lightPrimary),
      onRefresh: () async {
        if (webViewController != null) {
          webViewController!.reload();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          widget.title,
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.bold,
          colorType: AppTextColorType.primary,
        ),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: WebUri(Uri.decodeFull(widget.url)),
            ),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              cacheEnabled: true,
              useHybridComposition:
                  true, // Use hybrid composition for better stability
              allowsInlineMediaPlayback: true,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: true,
              transparentBackground: true,
              supportZoom: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              useOnDownloadStart: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            ),
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) {
              webViewController = controller;
              AppLogger.info('ZerodhaWebView - WebView created');
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
                currentUrl = url.toString();
              });
              AppLogger.info('ZerodhaWebView - Load started: $url');
            },
            onLoadStop: (controller, url) async {
              pullToRefreshController?.endRefreshing();
              setState(() {
                isLoading = false;
                currentUrl = url.toString();
              });
              AppLogger.info('ZerodhaWebView - Load stopped: $url');

              String contentCheckScript = """
                (function() {
                  return {
                    title: document.title,
                    bodyContent: document.body ? document.body.innerHTML.length : 0,
                    hasForm: document.forms.length > 0
                  };
                })();
              """;
              var result = await controller.evaluateJavascript(
                source: contentCheckScript,
              );
              AppLogger.info('ZerodhaWebView - Page content check: $result');
            },
            onLoadError: (controller, url, code, message) {
              pullToRefreshController?.endRefreshing();
              setState(() {
                isLoading = false;
              });
              AppLogger.error('ZerodhaWebView - Load error: $code, $message');

              Get.snackbar(
                'Error',
                'Failed to load page: $message',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.1),
                colorText: Colors.red,
              );
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url;
              if (uri != null) {
                AppLogger.info('ZerodhaWebView - Navigation to: $uri');
                if (uri.toString().contains(
                  'lab.networthtracker.in/api/v1/zerodha/redirection',
                )) {
                  AppLogger.info(
                    'ZerodhaWebView - Detected redirection callback',
                  );
                }
                if (![
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
                    AppLogger.error("Error launching non-HTTP URL: $e");
                    return NavigationActionPolicy.CANCEL;
                  }
                }
              }

              return NavigationActionPolicy.ALLOW;
            },
            onConsoleMessage: (controller, consoleMessage) {
              AppLogger.info(
                'ZerodhaWebView - Console: ${consoleMessage.message}',
              );
            },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              final url = downloadStartRequest.url;
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  AppLogger.error("Could not launch download URL: $url");
                }
              } catch (e) {
                AppLogger.error("Error launching download URL: $e");
              }
            },
          ),
          if (isLoading)
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
