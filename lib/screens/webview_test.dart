import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:nwt_app/screens/example/inappwebview.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class WebViewTestScreen extends StatefulWidget {
  const WebViewTestScreen({super.key});

  @override
  State<WebViewTestScreen> createState() => _WebViewTestScreenState();
}

class _WebViewTestScreenState extends State<WebViewTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              'AppRouter Demo',
              variant: AppTextVariant.headline3,
              colorType: AppTextColorType.primary,
            ),
            const SizedBox(height: 30),
            AppButton(
              text: 'Open WebView (to)',
              onPressed: () {
                // Navigate using AppRouter.to (keeps current screen in stack)
                Get.to(
                  const InAppWebViewExample(
                    url: 'https://pub.dev/packages/flutter_inappwebview/example',
                    title: 'Flutter InAppWebView Example',
                  ),
                  transition: Transition.rightToLeft,
                );
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Open WebView (off)',
              onPressed: () {
                // Navigate using AppRouter.off (removes current screen from stack)
                Get.off(
                  const InAppWebViewExample(
                    url: 'https://pub.dev/packages/flutter_inappwebview/example',
                    title: 'Flutter InAppWebView Example',
                  ),
                  transition: Transition.rightToLeft,
                );
              },
              variant: AppButtonVariant.secondary,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Show Success Snackbar',
              onPressed: () {
                Get.snackbar(
                  'Success',
                  'This is a success message using AppRouter',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  colorText: Colors.green,
                );
              },
              variant: AppButtonVariant.outlined,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Show Error Snackbar',
              onPressed: () {
                Get.snackbar(
                  'Error',
                  'This is an error message using AppRouter',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  colorText: Colors.red,
                );
              },
              variant: AppButtonVariant.destructive,
            ),
          ],
        ),
      ),
    );
  }
}