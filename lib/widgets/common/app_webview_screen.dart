import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import '../../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AppWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const AppWebViewScreen({Key? key, required this.url, this.title = 'Web View'})
    : super(key: key);

  @override
  State<AppWebViewScreen> createState() => _AppWebViewScreenState();
}

class _AppWebViewScreenState extends State<AppWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    debugPrint('AppWebViewScreen initiated with URL: ${widget.url}');
  }

  @override
  void dispose() {
    webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.chevron_left, size: 32),
            ),
            Expanded(
              child: Center(
                child: AppText(
                  widget.title,
                  variant: AppTextVariant.headline6,
                  weight: AppTextWeight.semiBold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Opacity(
              opacity: 0,
              child: Icon(Icons.history_toggle_off, size: 32),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              cacheEnabled: true,
              useOnLoadResource: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: true,
              transparentBackground: true,
              supportZoom: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              useOnDownloadStart: true,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                isLoading = false;
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint("WebView Console: ${consoleMessage.message}");
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                isLoading = false;
                loadError = message;
              });
              debugPrint("WebView error: $message");
            },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              final url = downloadStartRequest.url;
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint("Could not launch download URL: $url");
                }
              } catch (e) {
                debugPrint("Error launching download URL: $e");
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
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
                  debugPrint("Error launching non-HTTP URL: $e");
                  return NavigationActionPolicy.CANCEL;
                }
              }
              // Allow all navigation actions to proceed
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (isLoading)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.linkColor,
              ),
            ),
          if (loadError != null)
            Center(
              child: Text(
                'Error: $loadError',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
