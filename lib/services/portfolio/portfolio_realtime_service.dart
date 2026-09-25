import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:nwt_app/constants/storage_keys.dart';

import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class PortfolioRealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  // Stream for broadcasting incoming messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // Connection state
  final _stateController =
      StreamController<RealtimeConnectionState>.broadcast();
  Stream<RealtimeConnectionState> get connectionState =>
      _stateController.stream;
  RealtimeConnectionState _currentState = RealtimeConnectionState.disconnected;

  // Ping/Pong timers
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  final Duration _heartbeatInterval = const Duration(seconds: 25);
  final Duration _pongTimeout = const Duration(seconds: 45);

  // Reconnect logic
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  RealtimeConnectionState get currentState => _currentState;

  void _setState(RealtimeConnectionState state) {
    if (_currentState != state) {
      print(
        '🔌 [WS] PortfolioRealtimeService: _setState changed from ${_currentState.name} to ${state.name}',
      );
      _currentState = state;
      _stateController.add(state);
      AppLogger.info(
        '🔌 Realtime Service State: ${state.name}',
        tag: 'PortfolioRealtimeService',
      );
    }
  }

  Future<void> connect() async {
    print(
      '🔌 [WS] PortfolioRealtimeService: connect() started. Current state: ${_currentState.name}',
    );
    _isDisposed = false; // Reset disposed flag when explicitly connecting!
    if (_currentState == RealtimeConnectionState.connecting ||
        _currentState == RealtimeConnectionState.connected) {
      print(
        '🔌 [WS] PortfolioRealtimeService: Already connecting or connected. Aborting connect().',
      );
      return;
    }

    _setState(RealtimeConnectionState.connecting);

    try {
      print(
        '🔌 [WS] PortfolioRealtimeService: Reading auth token from SecureStorage...',
      );
      final String? token = await SecureStorage.read(
        StorageKeys.AUTH_TOKEN_KEY,
      );
      print(
        '🔌 [WS] PortfolioRealtimeService: Token read complete. Exists: ${token != null && token.isNotEmpty}',
      );
      if (token == null || token.isEmpty) {
        throw Exception('No auth token available');
      }

      print(
        '🔌 [WS] PortfolioRealtimeService: Getting baseUrl from RemoteConfigService...',
      );
      final baseUrl = "https://testing.pivotmoney.app/api/v1";
      print('🔌 [WS] PortfolioRealtimeService: baseUrl retrieved: $baseUrl');
      final sessionUrl = Uri.parse('$baseUrl/realtime/session/');

      print(
        '🔌 [WS] PortfolioRealtimeService: Fetching session ticket from: $sessionUrl...',
      );
      final response = await http.post(
        sessionUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
        '🔌 [WS] PortfolioRealtimeService: Session ticket response status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get realtime session. Status: ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body);
      print(
        '🔌 [WS] PortfolioRealtimeService: Session ticket response body parsed: success=${body['success']}',
      );
      if (body['success'] != true ||
          body['data'] == null ||
          body['data']['ws_url'] == null) {
        throw Exception('Invalid response format for realtime session');
      }

      final wsUrl = body['data']['ws_url'] as String;
      print(
        '🔌 [WS] PortfolioRealtimeService: Session ticket wsUrl retrieved: $wsUrl',
      );
      await _connectWebSocket(wsUrl);
    } catch (e, stackTrace) {
      print(
        '🔌 [WS] PortfolioRealtimeService: Exception caught in connect(): $e',
      );
      print('🔌 [WS] PortfolioRealtimeService: StackTrace: $stackTrace');
      AppLogger.error(
        '🔌 Failed to connect: $e',
        tag: 'PortfolioRealtimeService',
      );
      _handleDisconnect(retry: true);
    }
  }

  Future<void> _connectWebSocket(String wsUrl) async {
    try {
      print(
        '🔌 [WS] PortfolioRealtimeService: _connectWebSocket() connecting to $wsUrl...',
      );
      AppLogger.info(
        '🔌 Connecting to WebSocket: $wsUrl',
        tag: 'PortfolioRealtimeService',
      );

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print(
        '🔌 [WS] PortfolioRealtimeService: WebSocket channel created successfully.',
      );

      _setState(RealtimeConnectionState.connected);
      _reconnectAttempts = 0; // Reset attempts on successful connect

      _channelSubscription = _channel!.stream.listen(
        (message) {
          print(
            '🔌 [WS] PortfolioRealtimeService: Received raw message on stream: $message',
          );
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print(
            '🔌 [WS] PortfolioRealtimeService: WebSocket onError triggered: $error',
          );
          AppLogger.error(
            '🔌 WebSocket Error: $error',
            tag: 'PortfolioRealtimeService',
          );
          _handleDisconnect(retry: true);
        },
        onDone: () {
          print(
            '🔌 [WS] PortfolioRealtimeService: WebSocket onDone triggered. CloseCode: ${_channel?.closeCode}, CloseReason: ${_channel?.closeReason}',
          );
          AppLogger.warning(
            '🔌 WebSocket Closed. Code: ${_channel?.closeCode}, Reason: ${_channel?.closeReason}',
            tag: 'PortfolioRealtimeService',
          );
          _handleDisconnect(retry: true);
        },
      );
    } catch (e) {
      print(
        '🔌 [WS] PortfolioRealtimeService: Exception caught in _connectWebSocket(): $e',
      );
      AppLogger.error(
        '🔌 Error establishing WebSocket connection: $e',
        tag: 'PortfolioRealtimeService',
      );
      _handleDisconnect(retry: true);
    }
  }

  void _handleIncomingMessage(dynamic message) {
    if (message is! String) return;

    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'hello') {
        _startHeartbeat();
        // Send start message automatically after hello
        sendStartMessage();
      } else if (type == 'pong') {
        _handlePong();
      } else {
        // Forward portfolio events to the controller
        _messageController.add(data);
      }
    } catch (e) {
      AppLogger.error(
        '🔌 Error parsing WebSocket message: $e\nMessage: $message',
        tag: 'PortfolioRealtimeService',
      );
    }
  }

  void sendStartMessage() {
    _sendMessage({"type": "start", "topic": "portfolio"});
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_currentState == RealtimeConnectionState.connected &&
        _channel != null) {
      final payload = jsonEncode(data);
      print('🔌 [WS] PortfolioRealtimeService: Sending message: $payload');
      _channel!.sink.add(payload);
    } else {
      AppLogger.warning(
        '🔌 Attempted to send message while not connected',
        tag: 'PortfolioRealtimeService',
      );
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _pingTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendMessage({
        "type": "ping",
        "sent_at": DateTime.now().toUtc().toIso8601String(),
      });

      // Start timeout timer waiting for pong
      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = Timer(_pongTimeout, () {
        AppLogger.error(
          '🔌 Pong timeout. Disconnecting.',
          tag: 'PortfolioRealtimeService',
        );
        _handleDisconnect(retry: true);
      });
    });
  }

  void _handlePong() {
    _pongTimeoutTimer?.cancel();
  }

  void _stopHeartbeat() {
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
  }

  void _handleDisconnect({bool retry = false}) {
    _stopHeartbeat();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;

    if (retry && !_isDisposed) {
      _setState(RealtimeConnectionState.reconnecting);
      _scheduleReconnect();
    } else {
      _setState(RealtimeConnectionState.disconnected);
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectAttempts++;
    // Backoff: 1s, 2s, 5s, 10s, 20s, max 30s
    int delaySeconds;
    if (_reconnectAttempts == 1) {
      delaySeconds = 1;
    } else if (_reconnectAttempts == 2) {
      delaySeconds = 2;
    } else if (_reconnectAttempts == 3) {
      delaySeconds = 5;
    } else if (_reconnectAttempts == 4) {
      delaySeconds = 10;
    } else if (_reconnectAttempts == 5) {
      delaySeconds = 20;
    } else {
      delaySeconds = 30;
    }

    AppLogger.info(
      '🔌 Scheduling reconnect in $delaySeconds seconds (Attempt $_reconnectAttempts)',
      tag: 'PortfolioRealtimeService',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _handleDisconnect(retry: false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}
