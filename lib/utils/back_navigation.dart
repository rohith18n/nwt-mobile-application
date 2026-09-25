import 'package:get/get.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

/// Centralized back navigation.
///
/// Goals:
/// - Close transient overlays first (dialogs/bottom sheets).
/// - Pop when there is a navigation stack (normal back behavior).
/// - Otherwise fall back to Home (`StackedNavbar(selectedIdx: 0)`), preserving the app's current behavior
///   for root-entry screens and deep-linked flows.
class BackNavigation {
  static void backOrHome({
    int homeIndex = 0,
    Transition? homeTransition,
  }) {
    // Use the root navigator directly; `maybePop` correctly closes dialogs,
    // bottom sheets (route-based), and normal pages when possible.
    final nav = Get.key.currentState;
    if (nav != null) {
      nav.maybePop().then((popped) {
        if (popped) return;
        Get.offAll(
          () => StackedNavbar(selectedIdx: homeIndex),
          transition: homeTransition,
        );
      });
      return;
    }

    // Fallback when navigator state is unavailable (should be rare).
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
      return;
    }

    Get.offAll(
      () => StackedNavbar(selectedIdx: homeIndex),
      transition: homeTransition,
    );
  }
}

