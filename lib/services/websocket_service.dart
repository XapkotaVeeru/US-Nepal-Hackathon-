import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message_model.dart';

enum ConnectionState { disconnected, connecting, connected, reconnecting }

class WebSocketService {
  final String wsUrl;
  final String anonymousId;

  WebSocketChannel? _channel;
  ConnectionState _state = ConnectionState.disconnected;

  final _messageController = StreamController<Message>.broadcast();
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _rawEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  WebSocketService({
    required this.wsUrl,
    required this.anonymousId,
  });

  Stream<Message> get messages => _messageController.stream;
  Stream<ConnectionState> get connectionState => _stateController.stream;
  Stream<Map<String, dynamic>> get rawEvents => _rawEventController.stream;
  ConnectionState get currentState => _state;

  /// Connect to the backend WebSocket
  Future<void> connect() async {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      return;
    }

    _updateState(ConnectionState.connecting);

    try {
      final uri = Uri.parse('$wsUrl?anonymousId=$anonymousId');
      debugPrint('WebSocket connecting to: $uri');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;
      debugPrint('WebSocket connected successfully');

      // Start heartbeat to keep connection alive
      _startHeartbeat();

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _handleError(e);
    }
  }

  /// Send a chat message via WebSocket
  /// Matches backend route: "sendMessage"
  void sendMessage({
    required String communityId,
    required String content,
  }) {
    if (_state != ConnectionState.connected) {
      debugPrint('WebSocket not connected, cannot send message');
      return;
    }

    final payload = {
      'action': 'sendMessage',
      'communityId': communityId,
      'content': content,
      'senderId': anonymousId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel?.sink.add(jsonEncode(payload));
    debugPrint('WS → sendMessage to $communityId');
  }

  /// Join a community channel via WebSocket
  /// Matches backend route: "joinCommunity"
  void joinCommunity(String communityId) {
    if (_state != ConnectionState.connected) {
      debugPrint('WebSocket not connected, cannot join community');
      return;
    }

    final payload = {
      'action': 'joinCommunity',
      'communityId': communityId,
      'userId': anonymousId,
    };

    _channel?.sink.add(jsonEncode(payload));
    debugPrint('WS → joinCommunity: $communityId');
  }

  /// Leave a community channel
  void leaveCommunity(String communityId) {
    if (_state != ConnectionState.connected) return;

    final payload = {
      'action': 'leaveCommunity',
      'communityId': communityId,
      'userId': anonymousId,
    };

    _channel?.sink.add(jsonEncode(payload));
    debugPrint('WS → leaveCommunity: $communityId');
  }

  /// Send a raw action (for extensibility)
  void sendAction(String action, Map<String, dynamic> data) {
    if (_state != ConnectionState.connected) return;

    final payload = {
      'action': action,
      ...data,
      'senderId': anonymousId,
    };

    _channel?.sink.add(jsonEncode(payload));
  }

  // ── Legacy API (for backward compat with ChatProvider) ──

  @Deprecated('Use sendMessage with communityId instead')
  void sendSessionMessage({
    required String sessionId,
    required String content,
  }) {
    sendMessage(communityId: sessionId, content: content);
  }

  @Deprecated('Use joinCommunity instead')
  void joinSession(String sessionId) {
    joinCommunity(sessionId);
  }

  @Deprecated('Use leaveCommunity instead')
  void leaveSession(String sessionId) {
    leaveCommunity(sessionId);
  }

  // ═══════════════════════════════════════════════
  //  Internal handlers
  // ═══════════════════════════════════════════════

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      debugPrint('WS ← ${json['type'] ?? json['action'] ?? 'unknown'}');

      // Forward raw events
      _rawEventController.add(json);

      // Parse as Message if applicable
      if (json['type'] == 'message' || json['action'] == 'newMessage') {
        final messageData = json['data'] ?? json;
        final message = Message.fromJson(messageData as Map<String, dynamic>);
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _updateState(ConnectionState.disconnected);
    _stopHeartbeat();
    _attemptReconnect();
  }

  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _updateState(ConnectionState.disconnected);
    _stopHeartbeat();
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached ($_maxReconnectAttempts)');
      return;
    }

    _reconnectAttempts++;
    _updateState(ConnectionState.reconnecting);

    // Exponential backoff: 3s, 6s, 12s, 24s, ...
    final delay = _reconnectDelay * (1 << (_reconnectAttempts - 1).clamp(0, 5));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      debugPrint(
          'Reconnecting... (attempt $_reconnectAttempts, delay: ${delay.inSeconds}s)');
      connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_state == ConnectionState.connected) {
        try {
          _channel?.sink.add(jsonEncode({'action': 'ping'}));
        } catch (e) {
          debugPrint('Heartbeat failed: $e');
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updateState(ConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Disconnect and cleanup
  void disconnect() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _updateState(ConnectionState.disconnected);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
    _rawEventController.close();
  }
}
