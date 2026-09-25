import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:nwt_app/utils/logger.dart';

enum NetworkStatus { online, offline }

/// Service to monitor and manage network connectivity status
class ConnectivityService extends GetxService {
  // Observable network status
  final Rx<NetworkStatus> status = Rx<NetworkStatus>(NetworkStatus.online);

  // Getter for current network status
  NetworkStatus get networkStatus => status.value;

  // Getter for checking if network is connected
  bool get isConnected => status.value == NetworkStatus.online;

  // Stream subscription for connectivity changes
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  // Singleton instance
  static ConnectivityService get to =>
      Get.put<ConnectivityService>(ConnectivityService());

  /// Initialize the connectivity service
  Future<ConnectivityService> init() async {
    AppLogger.info(
      'Initializing ConnectivityService',
      tag: 'ConnectivityService',
    );

    // Check initial connection status
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);

    // Listen for connectivity changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results.first);
    });

    return this;
  }

  /// Update the connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    AppLogger.info('Connectivity changed: $result', tag: 'ConnectivityService');

    if (result == ConnectivityResult.none) {
      status.value = NetworkStatus.offline;
    } else {
      status.value = NetworkStatus.online;
    }
  }

  /// Manually check current connectivity status
  Future<NetworkStatus> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
    return status.value;
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
