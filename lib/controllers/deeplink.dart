import 'dart:async';

import 'package:get/get.dart';
import 'package:nwt_app/screens/dashboard/dashboard.dart';
import 'package:nwt_app/screens/invitation/invitation.dart';
import 'package:nwt_app/services/auth/auth.dart';
import 'package:nwt_app/services/deep_linking/branch_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/main/stacked_navbar.dart';

class DeepLinkController extends GetxController {
  static DeepLinkController get instance => Get.find();

  StreamSubscription? _streamSubscription;
  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    initializeBranchSubscription();
  }

  Future<void> initializeBranchSubscription() async {
    _streamSubscription = BranchService.to.trackLink((data) async {
      AppLogger.info(data.toString(), tag: 'DeepLinkController');

      // Check if we have a route in the deep link data
      if (data.containsKey('route')) {
        final String route = data['route'];
        AppLogger.info('Deep link route: $route', tag: 'DeepLinkController');

        // Validate token before handling any deep link navigation
        final bool isValid = await _validateTokenAndNavigateToRoute(data);
        if (!isValid) {
          return;
        } else {
          _navigateToRoute(data);
        }
      } else {
        AppLogger.info('No route in deep link data', tag: 'DeepLinkController');
        // Default navigation if no route specified
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
      }
    });
  }

  /// Validates the user's authentication token and navigates to the appropriate route
  /// If token is valid, navigates to the requested route
  /// If token is invalid, navigates to the splash screen for re-authentication
  Future<bool> _validateTokenAndNavigateToRoute(
    Map<dynamic, dynamic> data,
  ) async {
    try {
      // Try to fetch user profile to validate token
      final response = await _authService.getUserProfile(
        onLoading: (_) {}, // Silently handle loading
      );

      // Check if response was successful and user data exists
      if (response.success && response.user != null) {
        AppLogger.info(
          'Token validation successful',
          tag: 'DeepLinkController',
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Error occurred during validation, navigate to splash screen
      AppLogger.error(
        'Error validating token',
        error: e,
        tag: 'DeepLinkController',
      );
      return false;
    }
  }

  /// Navigate to the appropriate route based on the deep link data
  void _navigateToRoute(Map<dynamic, dynamic> data) {
    final String route = data['route'];

    switch (route) {
      case '/invite':
        if (data.containsKey('invitationId')) {
          final String invitationId = data['invitationId'];
          AppLogger.info(
            'Navigating to invitation screen with ID: $invitationId',
            tag: 'DeepLinkController',
          );
          Get.offAll(
            () => FamilyFinanceInvitationScreen(inviteId: invitationId),
          );
        } else {
          AppLogger.error(
            'Missing invitationId for /invite route',
            tag: 'DeepLinkController',
          );
          Get.offAll(() => StackedNavbar(selectedIdx: 0));
        }
        break;

      default:
        // Default navigation for unknown routes
        AppLogger.info(
          'Unknown route: $route, navigating to Dashboard',
          tag: 'DeepLinkController',
        );
        Get.offAll(() => StackedNavbar(selectedIdx: 0));
        break;
    }
  }

  @override
  void onClose() {
    _streamSubscription?.cancel();
    super.onClose();
  }
}
