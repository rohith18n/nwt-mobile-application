import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:nwt_app/models/portfolio/realtime_portfolio_models.dart';
import 'package:nwt_app/services/portfolio/portfolio_realtime_service.dart';
import 'package:nwt_app/utils/app_logger.dart';

class PortfolioRealtimeController extends GetxController {
  final PortfolioRealtimeService _realtimeService;

  // Observables for UI state
  final Rx<RealtimeConnectionState> connectionState =
      RealtimeConnectionState.disconnected.obs;

  final Rx<RealtimePortfolioTotals?> totals = Rx<RealtimePortfolioTotals?>(
    null,
  );
  final RxMap<String, RealtimeHolding> holdingsMap =
      <String, RealtimeHolding>{}.obs;
  final RxList<UnsupportedHolding> unsupportedHoldings =
      <UnsupportedHolding>[].obs;

  final Set<String> _connectionClients = {};

  StreamSubscription? _stateSubscription;
  StreamSubscription? _messageSubscription;

  PortfolioRealtimeController({PortfolioRealtimeService? service})
    : _realtimeService = service ?? PortfolioRealtimeService();

  @override
  void onInit() {
    super.onInit();

    // Listen to connection state
    _stateSubscription = _realtimeService.connectionState.listen((state) {
      connectionState.value = state;
    });

    // Listen to incoming messages
    _messageSubscription = _realtimeService.messages.listen((message) {
      _handleRealtimeMessage(message);
    });
  }

  @override
  void onClose() {
    disconnect();
    _connectionClients.clear();
    _stateSubscription?.cancel();
    _messageSubscription?.cancel();
    super.onClose();
  }

  /// Called when a client requests WebSocket connection
  void connectClient(String clientId) {
    _connectionClients.add(clientId);
    AppLogger.info(
      '🔌 connectClient: $clientId | Active clients: $_connectionClients',
      tag: 'PortfolioRealtimeController',
    );
    connect();
  }

  /// Called when a client releases WebSocket connection
  void disconnectClient(String clientId) {
    _connectionClients.remove(clientId);
    AppLogger.info(
      '🔌 disconnectClient: $clientId | Active clients: $_connectionClients',
      tag: 'PortfolioRealtimeController',
    );
    if (_connectionClients.isEmpty) {
      disconnect();
    }
  }

  /// Called when the portfolio screen is opened
  void connect() {
    AppLogger.info(
      '🔌 Initializing Realtime Portfolio Connection',
      tag: 'PortfolioRealtimeController',
    );
    _realtimeService.connect();
  }

  /// Called when the portfolio screen is closed
  void disconnect() {
    AppLogger.info(
      '🔌 Disconnecting Realtime Portfolio',
      tag: 'PortfolioRealtimeController',
    );
    _realtimeService.disconnect();
    _clearState();
  }

  void _clearState() {
    totals.value = null;
    holdingsMap.clear();
    unsupportedHoldings.clear();
  }

  void _handleRealtimeMessage(Map<String, dynamic> message) {
    AppLogger.info(
      '🔌 WebSocket Response Received: ${jsonEncode(message)}',
      tag: 'PortfolioRealtimeController',
    );
    try {
      final type = message['type'] as String?;

      if (type == 'portfolio.snapshot') {
        final snapshot = PortfolioSnapshot.fromJson(message);
        _handleSnapshot(snapshot);
      } else if (type == 'portfolio.delta') {
        final delta = PortfolioDelta.fromJson(message);
        _handleDelta(delta);
      } else if (type == 'error') {
        AppLogger.error(
          '🔌 Realtime Portfolio Error: ${message['code']} - ${message['message']}',
          tag: 'PortfolioRealtimeController',
        );
      }
    } catch (e) {
      AppLogger.error(
        '🔌 Failed to parse realtime portfolio message: $e',
        tag: 'PortfolioRealtimeController',
      );
    }
  }

  void _handleSnapshot(PortfolioSnapshot snapshot) {
    AppLogger.info(
      '🔌 Received Portfolio Snapshot',
      tag: 'PortfolioRealtimeController',
    );

    // Replace totals
    totals.value = snapshot.totals;

    // Replace unsupported holdings
    unsupportedHoldings.assignAll(snapshot.unsupportedHoldings);

    // Replace live holdings
    final Map<String, RealtimeHolding> newMap = {};
    for (var holding in snapshot.holdings) {
      newMap[holding.isin] = holding;
    }
    holdingsMap.assignAll(newMap);
  }

  void _handleDelta(PortfolioDelta delta) {
    AppLogger.info(
      '🔌 Received Portfolio Delta',
      tag: 'PortfolioRealtimeController',
    );

    // Update totals if provided
    if (delta.totals != null) {
      totals.value = delta.totals;
    }

    // Patch changed holdings
    for (var updatedHolding in delta.holdings) {
      holdingsMap[updatedHolding.isin] = updatedHolding;
    }
  }
}
