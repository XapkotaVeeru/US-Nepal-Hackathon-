import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService;
  WebSocketService? _wsService;

  List<ChatSession> _sessions = [];
  final Map<String, List<Message>> _messagesBySession = {};
  bool _isLoading = false;
  String? _error;
  ConnectionState _connectionState = ConnectionState.disconnected;

  ChatProvider(this._apiService);

  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ConnectionState get connectionState => _connectionState;
  WebSocketService? get wsService => _wsService;
  int get totalUnreadCount =>
      _sessions.fold(0, (sum, s) => sum + s.unreadCount);

  /// Initialize WebSocket with AWS endpoint
  void initializeWebSocket(String wsUrl, String anonymousId) {
    _wsService?.dispose();

    _wsService = WebSocketService(wsUrl: wsUrl, anonymousId: anonymousId);

    // Listen to connection state
    _wsService!.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    // Listen to messages
    _wsService!.messages.listen((message) {
      _handleIncomingMessage(message);
    });

    _wsService!.connect();
  }

  /// Load user sessions
  Future<void> loadSessions(String anonymousId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _apiService.getUserSessions(anonymousId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a community
  Future<void> loadCommunityMessages(String communityId) async {
    try {
      final messages = await _apiService.getCommunityMessages(communityId);
      _messagesBySession[communityId] = messages;

      // Join WebSocket room for real-time updates
      _wsService?.joinCommunity(communityId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $e');
      notifyListeners();
    }
  }

  /// Load messages for a session (legacy)
  Future<void> loadMessages(String sessionId) async {
    try {
      final messages = await _apiService.getSessionMessages(sessionId);
      _messagesBySession[sessionId] = messages;

      // Join WebSocket room
      _wsService?.joinCommunity(sessionId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $e');
      notifyListeners();
    }
  }

  /// Send a message to a community
  void sendCommunityMessage({
    required String communityId,
    required String content,
  }) {
    try {
      _wsService?.sendMessage(communityId: communityId, content: content);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $e');
      notifyListeners();
    }
  }

  /// Send a message (legacy session-based)
  void sendMessage({
    required String sessionId,
    required String content,
  }) {
    sendCommunityMessage(communityId: sessionId, content: content);
  }

  /// Handle incoming WebSocket message
  void _handleIncomingMessage(Message message) {
    // Add to message list by community/session
    final key = message.sessionId;
    if (_messagesBySession.containsKey(key)) {
      _messagesBySession[key]!.add(message);
    } else {
      _messagesBySession[key] = [message];
    }

    // Update session last message if applicable
    final sessionIndex = _sessions.indexWhere((s) => s.id == key);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount: _sessions[sessionIndex].unreadCount + 1,
      );
    }

    notifyListeners();
  }

  /// Get messages for a session/community
  List<Message> getMessages(String id) {
    return _messagesBySession[id] ?? [];
  }

  /// Mark session as read
  void markSessionAsRead(String sessionId) {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] =
          _sessions[sessionIndex].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  /// Send chat request
  Future<void> sendChatRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _apiService.sendChatRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending chat request: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService?.dispose();
    super.dispose();
  }
}
