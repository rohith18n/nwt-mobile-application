import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  InAppWebViewController? webViewController;
  bool isLoading = true;

  Future<bool> _handleBack() async {
    if (webViewController != null &&
        await webViewController!.canGoBack()) {
      webViewController!.goBack();
      return false;
    }
    return true;
  }

  void _checkPaymentStatus(Uri? url) {
    if (url == null) return;

    String currentUrl = url.toString();

    /// CHANGE THESE URLS ACCORDING TO YOUR PAYMENT GATEWAY
    if (currentUrl.contains("payment-success")) {
      Navigator.pop(context, "SUCCESS");
    }

    if (currentUrl.contains("payment-failed")) {
      Navigator.pop(context, "FAILED");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Complete Payment"),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest:
              URLRequest(url: WebUri(widget.paymentUrl)),

              initialSettings: InAppWebViewSettings(
                supportZoom: false,
                builtInZoomControls: false,
                displayZoomControls: false,
                overScrollMode: OverScrollMode.NEVER,
                useShouldOverrideUrlLoading: true,
              ),

              onWebViewCreated: (controller) {
                webViewController = controller;
              },

              onLoadStart: (controller, url) {
                setState(() {
                  isLoading = true;
                });

                _checkPaymentStatus(url);
              },

              onLoadStop: (controller, url) async {
                setState(() {
                  isLoading = false;
                });

                /// Fix zoom issue when keyboard closes
                await controller.evaluateJavascript(source: """
                  var meta = document.createElement('meta');
                  meta.name = "viewport";
                  meta.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
                  document.getElementsByTagName('head')[0].appendChild(meta);
                """);

                _checkPaymentStatus(url);
              },

              shouldOverrideUrlLoading:
                  (controller, navigationAction) async {
                Uri? uri = navigationAction.request.url;

                _checkPaymentStatus(uri);

                return NavigationActionPolicy.ALLOW;
              },
            ),

            /// Loader
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}