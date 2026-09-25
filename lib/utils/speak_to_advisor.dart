import 'package:get/get.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/app_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SpeakToAdvisor {
  static late String cachedCalendarURL;

  static void initialize(String calendarURL) {
    cachedCalendarURL = calendarURL;
    AppLogger.info(
      'SpeakToAdvisor initialized with base URL: $cachedCalendarURL',
    );
  }

  static void speakToAdvisor() async {
    try {
      Get.to(
        () =>
            AppWebViewScreen(url: cachedCalendarURL, title: 'Schedule Meeting'),
      );
    } catch (e) {
      AppLogger.error('Failed to open WebView: $e');
      // Fallback to external browser if Get navigation fails
      final url = Uri.parse(cachedCalendarURL);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      }
    }
  }
}
