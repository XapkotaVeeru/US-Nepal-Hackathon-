import 'dart:async';

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
  final Map<String, Timer> _pendingBotReplies = {};
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

  /// Initialize WebSocket with backend endpoint
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
      final remoteSessions = await _apiService.getUserSessions(anonymousId);
      final localOnlySessions = _sessions
          .where((local) => !remoteSessions.any((remote) => remote.id == local.id))
          .toList();
      _sessions = [...localOnlySessions, ...remoteSessions];
      _sortSessions();
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

  /// Join a community channel (WebSocket + local message bucket).
  void joinCommunity(String communityId) {
    _messagesBySession.putIfAbsent(communityId, () => []);
    _wsService?.joinCommunity(communityId);
    notifyListeners();
  }

  void clearUnread(String communityId) {
    markSessionAsRead(communityId);
  }

  void sendTyping(String communityId) {
    _wsService?.sendAction('typing', {'communityId': communityId});
  }

  List<String> get typingUsers => const [];

  bool get isConnected =>
      _wsService != null && _connectionState == ConnectionState.connected;

  List<Message> messagesForCommunity(String communityId) =>
      getMessages(communityId);

  /// Send a user message in a community chat (optimistic local echo + WS).
  void sendMessage({
    required String communityId,
    required String content,
    required String senderId,
    required String senderName,
  }) {
    final msg = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: communityId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.user,
      status: MessageStatus.sent,
    );
    _messagesBySession.putIfAbsent(communityId, () => []);
    _messagesBySession[communityId]!.add(msg);
    _upsertSessionPreview(
      sessionId: communityId,
      lastMessage: content,
      lastMessageTime: msg.timestamp,
      createIfMissing: true,
    );
    notifyListeners();
    sendCommunityMessage(communityId: communityId, content: content);
    _scheduleBotReply(communityId: communityId, content: content);
  }

  void _scheduleBotReply({
    required String communityId,
    required String content,
  }) {
    _pendingBotReplies[communityId]?.cancel();
    _pendingBotReplies[communityId] = Timer(
      const Duration(milliseconds: 900),
      () {
        final reply = _generateBotReply(
          communityId: communityId,
          content: content,
        );
        final botMessage = Message(
          id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: communityId,
          senderId: 'serenity-assistant',
          senderName: 'Serenity Bot',
          content: reply,
          timestamp: DateTime.now(),
          type: MessageType.assistant,
          status: MessageStatus.delivered,
        );

        _messagesBySession.putIfAbsent(communityId, () => []);
        _messagesBySession[communityId]!.add(botMessage);
        _upsertSessionPreview(
          sessionId: communityId,
          lastMessage: reply,
          lastMessageTime: botMessage.timestamp,
        );
        notifyListeners();
        _pendingBotReplies.remove(communityId);
      },
    );
  }

  String _generateBotReply({
    required String communityId,
    required String content,
  }) {
    final normalized = content.toLowerCase();

    if (_containsAny(normalized, const [
      'suicide',
      'hurt myself',
      'self harm',
      'don\'t want to live',
      'hopeless',
    ])) {
      return 'I\'m really glad you said that out loud. Please reach out to a trusted person nearby and use the Crisis Resources section if you might be in immediate danger.';
    }

    if (_containsAny(normalized, const [
      'anxious',
      'panic',
      'overthinking',
      'racing',
    ])) {
      return 'That sounds really overwhelming. Try one tiny grounding step right now: name 5 things you can see, then take one slow breath with your shoulders dropped.';
    }

    if (_containsAny(normalized, const [
      'sad',
      'alone',
      'lonely',
      'depressed',
      'crying',
    ])) {
      return 'You don\'t have to carry that by yourself here. If it helps, tell us whether today feels heavy because of one event, or because everything has been building up.';
    }

    if (_containsAny(normalized, const [
      'exam',
      'study',
      'deadline',
      'college',
      'school',
    ])) {
      return 'Academic pressure can eat up all your headspace. What feels most urgent right now: the workload, fear of failing, or trying to recover your energy?';
    }

    if (_containsAny(normalized, const [
      'family',
      'parent',
      'relationship',
      'friend',
    ])) {
      return 'Relationship stress can linger long after the moment passes. If you want, share what happened and what part hurt the most so we can help you untangle it.';
    }

    if (_containsAny(normalized, const [
      'better',
      'grateful',
      'proud',
      'good',
      'hopeful',
    ])) {
      return 'That\'s worth holding onto. What helped even a little today? Naming it can make it easier to return to when things get hard again.';
    }

    if (communityId == 'c4') {
      return 'A gentle reset might help here. Try one sentence: "Right now, I notice..." and finish it without judging yourself.';
    }

    return 'Thanks for sharing that. I\'m here with you, and this space is too. If you want, say a little more about what today has felt like.';
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
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
    _upsertSessionPreview(
      sessionId: key,
      lastMessage: message.content,
      lastMessageTime: message.timestamp,
      unreadDelta: 1,
      createIfMissing: true,
    );

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

  void createSessionFromAcceptedRequest({
    required String requestId,
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    required bool isGroup,
    String? groupName,
  }) {
    final now = DateTime.now();
    final sessionId = isGroup ? 'group_$requestId' : 'direct_$requestId';
    final sessionName = isGroup
        ? (groupName?.trim().isNotEmpty == true
            ? groupName!.trim()
            : 'Support Circle with $otherUserName')
        : otherUserName;
    final initialMessage = isGroup
        ? 'This support circle is live. Start gently and make space for each other.'
        : 'Your chat request was accepted. Say hello when you are ready.';

    final existingIndex = _sessions.indexWhere((session) => session.id == sessionId);
    final session = ChatSession(
      id: sessionId,
      type: isGroup ? 'group' : 'individual',
      name: sessionName,
      participantIds: [currentUserId, otherUserId],
      lastMessage: initialMessage,
      lastMessageTime: now,
      unreadCount: 0,
      isActive: true,
      createdAt: now,
    );

    if (existingIndex == -1) {
      _sessions.insert(0, session);
    } else {
      _sessions[existingIndex] = session;
    }

    _messagesBySession.putIfAbsent(sessionId, () {
      return [
        Message(
          id: 'system-$requestId',
          sessionId: sessionId,
          senderId: isGroup ? 'group-system' : otherUserId,
          senderName: isGroup ? 'Serenity' : otherUserName,
          content: initialMessage,
          timestamp: now,
          type: isGroup ? MessageType.system : MessageType.matchNotification,
          status: MessageStatus.delivered,
        ),
      ];
    });

    _sortSessions();
    notifyListeners();
  }

  void _upsertSessionPreview({
    required String sessionId,
    required String lastMessage,
    required DateTime lastMessageTime,
    int unreadDelta = 0,
    bool createIfMissing = false,
  }) {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final existing = _sessions[sessionIndex];
      _sessions[sessionIndex] = existing.copyWith(
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: (existing.unreadCount + unreadDelta).clamp(0, 9999) as int,
      );
      _sortSessions();
      return;
    }

    if (!createIfMissing) return;

    _sessions.insert(
      0,
      ChatSession(
        id: sessionId,
        type: 'group',
        name: 'Conversation',
        participantIds: const [],
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: unreadDelta.clamp(0, 9999) as int,
        createdAt: lastMessageTime,
      ),
    );
    _sortSessions();
  }

  void _sortSessions() {
    _sessions.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.createdAt;
      final bTime = b.lastMessageTime ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _pendingBotReplies.values) {
      timer.cancel();
    }
    _wsService?.dispose();
    super.dispose();
  }
}
