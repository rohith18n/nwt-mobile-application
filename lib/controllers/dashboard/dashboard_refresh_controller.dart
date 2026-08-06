import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Holds optional callbacks for the Dashboard to refetch FIP/AA data after delink or link.
/// Consent revoke flow calls [notifyAfterDelink]; consent link success calls [notifyAfterLink].
/// Dashboard registers both in initState and clears them in dispose.
///
/// When callbacks are null (Dashboard disposed, e.g. user navigated away during polling),
/// we set [pendingLinkRefresh] / [pendingDelinkRefresh]. Dashboard checks these in initState
/// and triggers refresh when it mounts so data appears when user returns.
class DashboardRefreshController extends GetxController {
  static DashboardRefreshController get to => Get.find<DashboardRefreshController>();

  VoidCallback? onAfterDelink;
  VoidCallback? onAfterLink;

  /// Set when notifyAfterLink was called but callback was null. Dashboard consumes in initState.
  bool pendingLinkRefresh = false;

  /// Set when notifyAfterDelink was called but callback was null. Dashboard consumes in initState.
  bool pendingDelinkRefresh = false;

  void notifyAfterDelink() {
    if (onAfterDelink != null) {
      onAfterDelink!();
    } else {
      pendingDelinkRefresh = true;
    }
  }

  void notifyAfterLink() {
    if (onAfterLink != null) {
      onAfterLink!();
    } else {
      pendingLinkRefresh = true;
    }
  }
}
