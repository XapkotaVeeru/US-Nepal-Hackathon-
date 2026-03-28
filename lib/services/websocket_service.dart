import 'dart:async';
import 'dart:convert';
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

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  WebSocketService({
    required this.wsUrl,
    required this.anonymousId,
  });

  Stream<Message> get messages => _messageController.stream;
  Stream<ConnectionState> get connectionState => _stateController.stream;
  ConnectionState get currentState => _state;

  /// Connect to WebSocket
  Future<void> connect() async {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      return;
    }

    _updateState(ConnectionState.connecting);

    try {
      final uri = Uri.parse('$wsUrl?anonymousId=$anonymousId');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _updateState(ConnectionState.connected);
      _reconnectAttempts = 0;

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Send a message
  void sendMessage({
    required String sessionId,
    required String content,
  }) {
    if (_state != ConnectionState.connected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'action': 'sendMessage',
      'sessionId': sessionId,
      'content': content,
      'senderId': anonymousId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel?.sink.add(jsonEncode(message));
  }

  /// Join a session
  void joinSession(String sessionId) {
    if (_state != ConnectionState.connected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'action': 'joinSession',
      'sessionId': sessionId,
      'userId': anonymousId,
    };

    _channel?.sink.add(jsonEncode(message));
  }

  /// Leave a session
  void leaveSession(String sessionId) {
    if (_state != ConnectionState.connected) return;

    final message = {
      'action': 'leaveSession',
      'sessionId': sessionId,
      'userId': anonymousId,
    };

    _channel?.sink.add(jsonEncode(message));
  }

  /// Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      if (json['type'] == 'message') {
        final message = Message.fromJson(json['data']);
        _messageController.add(message);
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  /// Handle errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _updateState(ConnectionState.disconnected);
    _attemptReconnect();
  }

  /// Handle disconnection
  void _handleDisconnect() {
    print('WebSocket disconnected');
    _updateState(ConnectionState.disconnected);
    _attemptReconnect();
  }

  /// Attempt to reconnect
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    _updateState(ConnectionState.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      print('Reconnecting... (attempt $_reconnectAttempts)');
      connect();
    });
  }

  /// Update connection state
  void _updateState(ConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Disconnect and cleanup
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _updateState(ConnectionState.disconnected);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}
