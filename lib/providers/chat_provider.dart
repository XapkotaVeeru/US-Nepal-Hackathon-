import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/message_model.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';
import '../services/llm_chat_service.dart';
import '../services/websocket_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService;
  final LlmChatService _llmChatService;

  WebSocketService? _wsService;
  StreamSubscription<ConnectionState>? _connectionSubscription;
  StreamSubscription<Message>? _messageSubscription;
  String? _activeAnonymousId;
  String? _activeWsUrl;

  List<ChatSession> _sessions = [];
  final Map<String, List<Message>> _messagesBySession = {};
  final Map<String, Timer> _pendingBotReplies = {};
  final Set<String> _joinedCommunities = {};
  bool _isLoading = false;
  String? _error;
  ConnectionState _connectionState = ConnectionState.disconnected;

  ChatProvider({
    required ApiService apiService,
    required LlmChatService llmChatService,
  })  : _apiService = apiService,
        _llmChatService = llmChatService;

  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ConnectionState get connectionState => _connectionState;
  WebSocketService? get wsService => _wsService;
  int get totalUnreadCount =>
      _sessions.fold(0, (sum, session) => sum + session.unreadCount);
  bool get isConnected =>
      _wsService != null && _connectionState == ConnectionState.connected;
  bool get isAssistantFallbackMode =>
      _connectionState == ConnectionState.failed ||
      _connectionState == ConnectionState.disconnected;
  List<String> get typingUsers => const [];

  void initializeWebSocket(String wsUrl, String anonymousId) {
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _wsService?.dispose();

    _wsService = WebSocketService(wsUrl: wsUrl, anonymousId: anonymousId);

    _connectionSubscription = _wsService!.connectionState.listen((state) {
      _connectionState = state;
      if (state == ConnectionState.connected) {
        for (final communityId in _joinedCommunities) {
          _wsService?.joinCommunity(communityId);
        }
      }
      notifyListeners();
    });

    _messageSubscription = _wsService!.messages.listen(_handleIncomingMessage);

    _wsService!.connect();
  }

  void bindAnonymousUser({
    required String? anonymousId,
    required String wsUrl,
  }) {
    if (anonymousId == null || anonymousId.isEmpty) return;

    final hasSameBinding =
        _activeAnonymousId == anonymousId && _activeWsUrl == wsUrl;
    if (hasSameBinding) return;

    _activeAnonymousId = anonymousId;
    _activeWsUrl = wsUrl;
    initializeWebSocket(wsUrl, anonymousId);
  }

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

  Future<void> openCommunity(String communityId) async {
    _joinedCommunities.add(communityId);
    _messagesBySession.putIfAbsent(communityId, () => []);
    await loadCommunityMessages(communityId);

    if (_connectionState == ConnectionState.connected) {
      _wsService?.joinCommunity(communityId);
    } else {
      _wsService?.connect();
    }
  }

  Future<void> loadCommunityMessages(String communityId) async {
    try {
      final messages = await _apiService.getCommunityMessages(communityId);
      _messagesBySession[communityId] = _mergeMessageLists(
        _messagesBySession[communityId] ?? const [],
        messages,
      );

      if (_connectionState == ConnectionState.connected) {
        _wsService?.joinCommunity(communityId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $e');
      notifyListeners();
    }
  }

  Future<void> loadMessages(String sessionId) async {
    try {
      final messages = await _apiService.getSessionMessages(sessionId);
      _messagesBySession[sessionId] = _mergeMessageLists(
        _messagesBySession[sessionId] ?? const [],
        messages,
      );

      if (_connectionState == ConnectionState.connected) {
        _wsService?.joinCommunity(sessionId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading session messages: $e');
      notifyListeners();
    }
  }

  void joinCommunity(String communityId) {
    _joinedCommunities.add(communityId);
    _messagesBySession.putIfAbsent(communityId, () => []);

    if (_connectionState == ConnectionState.connected) {
      _wsService?.joinCommunity(communityId);
    }

    notifyListeners();
  }

  void clearUnread(String communityId) {
    markSessionAsRead(communityId);
  }

  void sendTyping(String communityId) {
    if (_connectionState == ConnectionState.connected) {
      _wsService?.sendAction('typing', {'communityId': communityId});
    }
  }

  List<Message> messagesForCommunity(String communityId) =>
      getMessages(communityId);

  Future<void> sendMessage({
    required String communityId,
    required String content,
    required String senderId,
    required String senderName,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty) return;

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final message = Message(
      id: localId,
      sessionId: communityId,
      senderId: senderId,
      senderName: senderName,
      content: normalized,
      timestamp: DateTime.now(),
      type: MessageType.user,
      status: _connectionState == ConnectionState.connected
          ? MessageStatus.sending
          : MessageStatus.sent,
    );

    _messagesBySession.putIfAbsent(communityId, () => []);
    _messagesBySession[communityId]!.add(message);
    notifyListeners();

    if (_connectionState == ConnectionState.connected) {
      _wsService?.sendMessage(
        communityId: communityId,
        content: normalized,
        senderName: senderName,
      );
      _updateMessageStatus(
        communityId: communityId,
        messageId: localId,
        status: MessageStatus.sent,
      );
    } else {
      final persisted = await _apiService.createSessionMessage(
        sessionId: communityId,
        senderId: senderId,
        senderName: senderName,
        content: normalized,
      );

      if (persisted != null) {
        _replaceMessage(
          communityId: communityId,
          messageId: localId,
          replacement: persisted.copyWith(status: MessageStatus.delivered),
        );
      } else {
        _updateMessageStatus(
          communityId: communityId,
          messageId: localId,
          status: MessageStatus.failed,
        );
      }
    }

    _scheduleBotReply(
      communityId: communityId,
      communityName: communityId,
      content: normalized,
    );
  }

  void _scheduleBotReply({
    required String communityId,
    required String communityName,
    required String content,
  }) {
    _pendingBotReplies[communityId]?.cancel();
    _pendingBotReplies[communityId] = Timer(
      const Duration(milliseconds: 900),
      () async {
        try {
          final reply = await _llmChatService.generateReply(
            LlmChatRequest(
              communityId: communityId,
              communityName: communityName,
              latestUserMessage: content,
              recentMessages: List<Message>.from(
                _messagesBySession[communityId] ?? const [],
              ),
            ),
          );

          final botMessage = Message(
            id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
            sessionId: communityId,
            senderId: 'serenity-assistant',
            senderName: 'Serenity Guide',
            content: reply.content,
            timestamp: DateTime.now(),
            type: MessageType.assistant,
            status: MessageStatus.delivered,
          );

          _handleIncomingMessage(botMessage);
        } catch (e) {
          debugPrint('Error generating assistant reply: $e');
        } finally {
          _pendingBotReplies.remove(communityId);
        }
      },
    );
  }

  void _handleIncomingMessage(Message message) {
    final key = message.sessionId;
    _messagesBySession.putIfAbsent(key, () => []);
    final list = _messagesBySession[key]!;

    if (message.senderId == _activeAnonymousId) {
      final localIndex = list.lastIndexWhere(
        (candidate) =>
            candidate.senderId == message.senderId &&
            candidate.content == message.content &&
            candidate.id.startsWith('local-'),
      );
      if (localIndex != -1) {
        list[localIndex] = message.copyWith(status: MessageStatus.delivered);
        notifyListeners();
        return;
      }
    }

    if (list.any((candidate) => candidate.id == message.id)) {
      return;
    }

    list.add(message);

    final sessionIndex = _sessions.indexWhere((session) => session.id == key);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount: _sessions[sessionIndex].unreadCount + 1,
      );
    }

    notifyListeners();
  }

  List<Message> _mergeMessageLists(
    List<Message> existing,
    List<Message> incoming,
  ) {
    final merged = <String, Message>{};
    for (final message in [...existing, ...incoming]) {
      final key = message.id.isNotEmpty
          ? message.id
          : '${message.sessionId}:${message.senderId}:${message.timestamp.toIso8601String()}';
      merged[key] = message;
    }

    final items = merged.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items;
  }

  void _updateMessageStatus({
    required String communityId,
    required String messageId,
    required MessageStatus status,
  }) {
    final list = _messagesBySession[communityId];
    if (list == null) return;

    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = list[index].copyWith(status: status);
    notifyListeners();
  }

  void _replaceMessage({
    required String communityId,
    required String messageId,
    required Message replacement,
  }) {
    final list = _messagesBySession[communityId];
    if (list == null) return;

    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = replacement;
    notifyListeners();
  }

  List<Message> getMessages(String id) {
    return _messagesBySession[id] ?? [];
  }

  void markSessionAsRead(String sessionId) {
    final sessionIndex = _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] =
          _sessions[sessionIndex].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _pendingBotReplies.values) {
      timer.cancel();
    }
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _wsService?.dispose();
    super.dispose();
  }
}
