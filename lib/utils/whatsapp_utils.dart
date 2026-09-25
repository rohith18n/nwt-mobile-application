import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/utils/logger.dart';

/// Utility class for launching WhatsApp with pre-filled messages
class WhatsAppUtils {
  /// Checks if WhatsApp is installed on the device
  /// 
  /// Returns `true` if WhatsApp is installed and can be launched, `false` otherwise.
  /// This check should be performed before showing WhatsApp option to users.
  static Future<bool> isWhatsAppInstalled() async {
    try {
      // For Android, we also check https as a fallback because we can always 
      // open wa.me in a browser even if the app-specific scheme check fails.
      // This ensures the support button is visible as requested.
      if (Platform.isAndroid) {
        final Uri whatsappScheme = Uri.parse('whatsapp://send');
        final bool canLaunchWhatsApp = await canLaunchUrl(whatsappScheme);
        if (canLaunchWhatsApp) return true;

        // Fallback: Check if we can at least open the wa.me link in a browser
        final Uri waMeUrl = Uri.parse('https://wa.me/911234567890');
        return await canLaunchUrl(waMeUrl);
      }

      // For iOS and others, stick to the specific scheme check
      final Uri whatsappScheme = Uri.parse('whatsapp://');
      return await canLaunchUrl(whatsappScheme);
    } catch (e) {
      AppLogger.error(
        'Error checking WhatsApp installation: $e',
        tag: 'WhatsAppUtils',
      );
      // On error, default to true on Android to show the button (graceful failure)
      return Platform.isAndroid;
    }
  }

  /// Opens WhatsApp with a pre-filled message
  /// 
  /// [phoneNumber] - The phone number in international format (e.g., "911234567890")
  ///                 Should not include + or special characters
  /// [message] - The message to pre-fill in WhatsApp
  /// 
  /// Returns `true` if successful, `false` if failed.
  /// Does not throw exceptions - logs errors instead for graceful fallback.
  /// 
  /// Uses https://wa.me/ URL scheme which works on both Android and iOS
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Remove any non-digit characters from phone number
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanPhoneNumber.isEmpty) {
        AppLogger.error(
          'Invalid phone number: $phoneNumber',
          tag: 'WhatsAppUtils',
        );
        return false;
      }

      final Uri url = Uri.parse(
        'https://wa.me/$cleanPhoneNumber?text=${Uri.encodeComponent(message)}',
      );

      // On iOS, canLaunchUrl may return false for https://wa.me/ URLs even if WhatsApp is installed
      // Try to launch directly and catch errors instead of relying solely on canLaunchUrl
      bool canLaunch = false;
      try {
        canLaunch = await canLaunchUrl(url);
      } catch (e) {
        // On iOS, try to launch even if check fails
        canLaunch = true;
      }

      if (canLaunch) {
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return true;
        } catch (e, stackTrace) {
          AppLogger.error(
            'Error launching WhatsApp URL: $e',
            tag: 'WhatsAppUtils',
            stackTrace: stackTrace,
          );
          return false;
        }
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error launching WhatsApp: $e',
        tag: 'WhatsAppUtils',
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
