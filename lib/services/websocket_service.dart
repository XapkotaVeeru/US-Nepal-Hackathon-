import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/message_model.dart';

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class WebSocketService {
  final String wsUrl;
  final String anonymousId;

  WebSocketChannel? _channel;
  ConnectionState _state = ConnectionState.disconnected;
  bool _shouldReconnect = true;

  final _messageController = StreamController<Message>.broadcast();
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _rawEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  WebSocketService({
    required this.wsUrl,
    required this.anonymousId,
  });

  Stream<Message> get messages => _messageController.stream;
  Stream<ConnectionState> get connectionState => _stateController.stream;
  Stream<Map<String, dynamic>> get rawEvents => _rawEventController.stream;
  ConnectionState get currentState => _state;

  Future<void> connect() async {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      return;
    }

    _shouldReconnect = true;
    _updateState(
      _reconnectAttempts > 0
          ? ConnectionState.reconnecting
          : ConnectionState.connecting,
    );

    try {
      final base = Uri.parse(wsUrl);
      final uri = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'anonymousId': anonymousId,
        },
      );
      debugPrint('WebSocket connecting to: $uri');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

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

  void sendMessage({
    required String communityId,
    required String content,
    String? senderName,
  }) {
    if (_state != ConnectionState.connected) {
      debugPrint('WebSocket not connected, cannot send message');
      return;
    }

    _channel?.sink.add(
      jsonEncode({
        'action': 'sendMessage',
        'communityId': communityId,
        'content': content,
        'senderId': anonymousId,
        'senderName': senderName ?? 'Anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  void joinCommunity(String communityId) {
    if (_state != ConnectionState.connected) {
      debugPrint('WebSocket not connected, cannot join community');
      return;
    }

    _channel?.sink.add(
      jsonEncode({
        'action': 'joinCommunity',
        'communityId': communityId,
        'userId': anonymousId,
      }),
    );
  }

  void leaveCommunity(String communityId) {
    if (_state != ConnectionState.connected) return;

    _channel?.sink.add(
      jsonEncode({
        'action': 'leaveCommunity',
        'communityId': communityId,
        'userId': anonymousId,
      }),
    );
  }

  void sendAction(String action, Map<String, dynamic> data) {
    if (_state != ConnectionState.connected) return;

    _channel?.sink.add(
      jsonEncode({
        'action': action,
        ...data,
        'senderId': anonymousId,
      }),
    );
  }

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

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      _rawEventController.add(json);

      if (json['type'] == 'message' || json['action'] == 'newMessage') {
        final messageData = json['data'] ?? json;
        _messageController.add(
          Message.fromJson(messageData as Map<String, dynamic>),
        );
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _stopHeartbeat();
    if (_isFatalHandshakeFailure(error)) {
      _shouldReconnect = false;
      _updateState(ConnectionState.failed);
      return;
    }
    _updateState(ConnectionState.disconnected);
    _attemptReconnect();
  }

  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _stopHeartbeat();
    _updateState(ConnectionState.disconnected);
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (!_shouldReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateState(ConnectionState.failed);
      return;
    }

    _reconnectAttempts++;
    _updateState(ConnectionState.reconnecting);

    final delay = _reconnectDelay * (1 << (_reconnectAttempts - 1).clamp(0, 4));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
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
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  bool _isFatalHandshakeFailure(dynamic error) {
    final message = error.toString().toLowerCase();
    return message.contains('http status code: 403') ||
        message.contains('was not upgraded to websocket') ||
        message.contains('forbidden');
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _updateState(ConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
    _rawEventController.close();
  }
}
