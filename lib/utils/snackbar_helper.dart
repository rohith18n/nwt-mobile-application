import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';

class SnackbarHelper {
  static String? _lastMessage;
  static DateTime? _lastShown;

  static bool _shouldSkip(String message) {
    if (Get.isSnackbarOpen && _lastMessage == message) {
      if (_lastShown != null &&
          DateTime.now().difference(_lastShown!) < const Duration(seconds: 2)) {
        return true;
      }
    }
    _lastMessage = message;
    _lastShown = DateTime.now();
    return false;
  }

  /// Check if overlay is available for showing snackbars
  static bool _isOverlayAvailable() {
    try {
      // First check Get.overlayContext as GetX uses its internal navigator/overlay context
      if (Get.overlayContext != null) {
        return true;
      }

      // Fallback check if Get context is available and has overlay in the widget tree
      if (Get.context == null) {
        AppLogger.warning('Cannot show snackbar: Get.context is null');
        return false;
      }
      
      // Try to find overlay in the widget tree
      final overlay = Overlay.maybeOf(Get.context!, rootOverlay: false);
      if (overlay == null) {
        AppLogger.warning('Cannot show snackbar: No Overlay widget found');
        return false;
      }
      
      return true;
    } catch (e) {
      AppLogger.warning('Cannot show snackbar: $e');
      return false;
    }
  }

  static void showSuccess({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (_shouldSkip(message)) return;
    if (!_isOverlayAvailable()) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      SemanticsService.announce("$title: $message", TextDirection.ltr);
    });
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      shouldIconPulse: true,
      titleText: AppText(
        title,
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
        customColor: Colors.white,
      ),
      messageText: AppText(
        message,
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.regular,
        colorType: AppTextColorType.primary,
        customColor: Colors.white.withValues(alpha: 0.9),
      ),
      snackStyle: SnackStyle.FLOATING,
      overlayBlur: 0,
      overlayColor: Colors.black.withValues(alpha: 0.1),
      borderColor: const Color(0xFF4CAF50),
      borderWidth: 1,
    );
  }

  static void showError({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (_shouldSkip(message)) return;
    if (!_isOverlayAvailable()) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      SemanticsService.announce("$title: $message", TextDirection.ltr);
    });
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFC62828),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      icon: const Icon(Icons.error_outline, color: Colors.white),
      shouldIconPulse: true,
      titleText: AppText(
        title,
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
        customColor: Colors.white,
      ),
      messageText: AppText(
        message,
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.regular,
        colorType: AppTextColorType.primary,
        customColor: Colors.white.withValues(alpha: 0.9),
      ),
      snackStyle: SnackStyle.FLOATING,
      overlayBlur: 0,
      overlayColor: Colors.black.withValues(alpha: 0.1),
      borderColor: const Color(0xFFE57373),
      borderWidth: 1,
    );
  }

  static void showInfo({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (_shouldSkip(message)) return;
    if (!_isOverlayAvailable()) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      SemanticsService.announce("$title: $message", TextDirection.ltr);
    });
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: AppColors.lightPrimary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      icon: const Icon(Icons.info_outline, color: Colors.white),
      shouldIconPulse: true,
      titleText: AppText(
        title,
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
        customColor: Colors.white,
      ),
      messageText: AppText(
        message,
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.regular,
        colorType: AppTextColorType.primary,
        customColor: Colors.white.withValues(alpha: 0.9),
      ),
      snackStyle: SnackStyle.FLOATING,
      overlayBlur: 0,
      overlayColor: Colors.black.withValues(alpha: 0.1),
      borderColor: AppColors.lightButtonBorder,
      borderWidth: 1,
    );
  }

  static void showWarning({
    required String title,
    required String message,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (_shouldSkip(message)) return;
    if (!_isOverlayAvailable()) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      SemanticsService.announce("$title: $message", TextDirection.ltr);
    });
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: const Color(0xFFEF6C00),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      icon: const Icon(Icons.warning_amber_outlined, color: Colors.white),
      shouldIconPulse: true,
      titleText: AppText(
        title,
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
        customColor: Colors.white,
      ),
      messageText: AppText(
        message,
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.regular,
        colorType: AppTextColorType.primary,
        customColor: Colors.white.withValues(alpha: 0.9),
      ),
      snackStyle: SnackStyle.FLOATING,
      overlayBlur: 0,
      overlayColor: Colors.black.withValues(alpha: 0.1),
      borderColor: const Color(0xFFFFB74D),
      borderWidth: 1,
    );
  }

  /// Shows a top snackbar that stays visible for a long time (e.g. until
  /// closed programmatically via [Get.closeAllSnackbars]).
  static void showPersistentInfo({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(minutes: 30),
  }) {
    if (_shouldSkip(message)) return;
    if (!_isOverlayAvailable()) return;
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: AppColors.lightPrimary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
      icon: const Icon(Icons.info_outline, color: Colors.white),
      titleText: AppText(
        title,
        variant: AppTextVariant.headline6,
        weight: AppTextWeight.semiBold,
        colorType: AppTextColorType.primary,
        customColor: Colors.white,
      ),
      messageText: AppText(
        message,
        variant: AppTextVariant.bodyMedium,
        weight: AppTextWeight.regular,
        colorType: AppTextColorType.primary,
        customColor: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  /// Shows a persistent snackbar on the given scaffold. Use when Get.snackbar
  /// may not attach to the visible overlay (e.g. after Get.offAll navigation).
  static void showPersistentInfoOnScaffold(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(minutes: 30),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.lightPrimary,
      ),
    );
  }

  /// Safely closes all GetX snackbars.
  ///
  /// Workaround for a GetX `LateInitializationError` crash observed when closing
  /// snackbars during certain navigation transitions (e.g. `Get.back()` closing
  /// overlays while the snackbar controller isn't initialized yet).
  static void safeCloseAll() {
    try {
      Get.closeAllSnackbars();
    } catch (error) {
      AppLogger.error(
        'Error closing snackbars',
        error: error,
        stackTrace: StackTrace.current,
      );
      // Defensive: never let snackbar closing crash the app.
      //
      // Note: some SDKs may not expose `LateInitializationError` as a type, so
      // we keep this as a broad catch to avoid crashes regardless.
    }
  }
}
