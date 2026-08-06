import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:nwt_app/services/analytics/analytics_service.dart';

class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _logScreenView(PageRoute<dynamic> route) {
    var screenName = route.settings.name;
    
    // For anonymous Get.to() routes, extract widget class name from GetPageRoute
    if (screenName == null || screenName == '/' || screenName.isEmpty) {
      if (route is GetPageRoute) {
        final widget = route.page?.call();
        if (widget != null) {
          screenName = widget.runtimeType.toString();
        }
      }
      screenName ??= 'unknown_screen';
    }
    
    // Remove leading slash if present
    if (screenName.startsWith('/')) {
      screenName = screenName.substring(1);
    }
    
    // Convert CamelCase or path to snake_case for standard event naming
    var formattedName = screenName
        .replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (m) => '_${m[0]}')
        .toLowerCase()
        .replaceAll('/', '_')
        .replaceAll('-', '_');

    // Strip trailing _screen/_page/_widget to avoid _screen_screen_viewed duplication
    formattedName = formattedName
        .replaceAll(RegExp(r'_screen$'), '')
        .replaceAll(RegExp(r'_page$'), '')
        .replaceAll(RegExp(r'_widget$'), '');

    final eventName = '${formattedName}_screen_viewed';

    AnalyticsService.to.logScreenView(
      screenName: screenName,
      screenClass: 'Flutter',
    );
    
    // Also explicitly log the screen_viewed event per specs
    AnalyticsService.to.logEvent(
      name: eventName,
      parameters: {'screen_name': screenName},
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _logScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _logScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _logScreenView(previousRoute);
    }
  }
}
