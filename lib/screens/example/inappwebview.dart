import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../constants/colors.dart';

class InAppWebViewExample extends StatefulWidget {
  final String url;
  final String title;

  const InAppWebViewExample({
    Key? key,
    required this.url,
    this.title = 'Web View',
  }) : super(key: key);

  @override
  State<InAppWebViewExample> createState() => _InAppWebViewExampleState();
}

class _InAppWebViewExampleState extends State<InAppWebViewExample> {
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
      settings: PullToRefreshSettings(
        color: AppColors.lightPrimary,
      ),
      onRefresh: () async {
        if (webViewController != null) {
          await webViewController!.reload();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (webViewController != null) {
                webViewController!.reload();
              }
            },
          ),
        ],
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
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: true,
              transparentBackground: true,
              supportZoom: true,
              domStorageEnabled: true,
              databaseEnabled: true,
            ),
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
                currentUrl = url.toString();
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                isLoading = false;
                currentUrl = url.toString();
              });
              pullToRefreshController?.endRefreshing();
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              setState(() {
                currentUrl = url.toString();
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              print("Console Message: ${consoleMessage.message}");
            },
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                value: progress,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightPrimary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationControls(webViewController: webViewController),
    );
  }
}

class NavigationControls extends StatelessWidget {
  final InAppWebViewController? webViewController;

  const NavigationControls({
    Key? key,
    required this.webViewController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if (webViewController != null) {
                if (await webViewController!.canGoBack()) {
                  await webViewController!.goBack();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No back history item")),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if (webViewController != null) {
                if (await webViewController!.canGoForward()) {
                  await webViewController!.goForward();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No forward history item")),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              if (webViewController != null) {
                webViewController!.loadUrl(
                  urlRequest: URLRequest(url: WebUri('https://networthtracker.in')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
