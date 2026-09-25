import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class NetbankingWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentMethod; // 'POST' or 'GET'
  final Map<String, dynamic>? paymentParams;
  final int orderId;

  const NetbankingWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.paymentMethod,
    this.paymentParams,
    required this.orderId,
  });

  @override
  State<NetbankingWebViewScreen> createState() => _NetbankingWebViewScreenState();
}

class _NetbankingWebViewScreenState extends State<NetbankingWebViewScreen> {
  bool _isLoading = true;

  /// Build an HTML page that auto-submits a POST form with the given params.
  String _buildPostFormHtml() {
    final params = widget.paymentParams ?? {};
    final fields = params.entries.map((e) {
      final value = e.value.toString().replaceAll('"', '&quot;');
      return '<input type="hidden" name="${e.key}" value="$value">';
    }).join('\n');

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { background: #000; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
  </style>
</head>
<body>
  <form id="payForm" action="${widget.paymentUrl}" method="POST">
    $fields
  </form>
  <script>document.getElementById("payForm").submit();</script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: AppText(
          'Net Banking',
          variant: AppTextVariant.bodyLarge,
          weight: AppTextWeight.semiBold,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialData: widget.paymentMethod.toUpperCase() == 'POST'
                ? InAppWebViewInitialData(data: _buildPostFormHtml())
                : null,
            initialUrlRequest: widget.paymentMethod.toUpperCase() != 'POST'
                ? URLRequest(url: WebUri(widget.paymentUrl))
                : null,
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
            ),
            onWebViewCreated: (_) {},
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _isLoading = false);
            },
            onLoadStart: (controller, url) {
              if (mounted) setState(() => _isLoading = true);
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.darkPrimary),
            ),
        ],
      ),
    );
  }
}
