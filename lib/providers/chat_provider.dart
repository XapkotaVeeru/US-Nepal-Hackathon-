import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_request_model.dart';
import '../models/message_model.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';
import '../services/llm_chat_service.dart';
import '../services/mock_social_data.dart';
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
  bool _isUsingMockData = false;
  String? _error;
  ConnectionState _connectionState = ConnectionState.disconnected;

  ChatProvider({
    required ApiService apiService,
    required LlmChatService llmChatService,
  })  : _apiService = apiService,
        _llmChatService = llmChatService;

  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get isUsingMockData => _isUsingMockData;
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

  void disableRealtime() {
    _activeWsUrl = null;
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _wsService?.dispose();
    _connectionSubscription = null;
    _messageSubscription = null;
    _wsService = null;
    _connectionState = ConnectionState.disconnected;
    notifyListeners();
  }

  Future<void> loadSessions(String anonymousId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final remoteSessions = await _apiService.getUserSessions(anonymousId);
      _loadHybridSessions(
        anonymousId: anonymousId,
        remoteSessions: remoteSessions,
      );
    } catch (e) {
      debugPrint('Error loading sessions, falling back to mock data: $e');
      _loadMockSessions(anonymousId);
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
      if (messages.isEmpty) {
        _applyMockMessages(communityId);
      } else {
        _messagesBySession[communityId] = _mergeMessageLists(
          _messagesBySession[communityId] ?? const [],
          messages,
        );
      }

      if (_connectionState == ConnectionState.connected) {
        _wsService?.joinCommunity(communityId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages, falling back to mock data: $e');
      _applyMockMessages(communityId);
      notifyListeners();
    }
  }

  Future<void> loadMessages(String sessionId) async {
    try {
      final messages = await _apiService.getSessionMessages(sessionId);
      if (messages.isEmpty) {
        _applyMockMessages(sessionId);
      } else {
        _messagesBySession[sessionId] = _mergeMessageLists(
          _messagesBySession[sessionId] ?? const [],
          messages,
        );
      }

      if (_connectionState == ConnectionState.connected) {
        _wsService?.joinCommunity(sessionId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session messages, falling back to mock data: $e');
      _applyMockMessages(sessionId);
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
    _upsertSessionPreview(
      sessionId: communityId,
      sessionName: MockSocialData.sessionNameFor(communityId),
      lastMessage: normalized,
      lastMessageTime: message.timestamp,
      createIfMissing: true,
    );
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
          status: MessageStatus.delivered,
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

          final persisted = await _apiService.createSessionMessage(
            sessionId: communityId,
            senderId: 'serenity-assistant',
            senderName: 'Serenity Guide',
            content: reply.content,
            type: MessageType.assistant,
          );

          final botMessage = persisted ??
              Message(
                id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
                sessionId: communityId,
                senderId: 'serenity-assistant',
                senderName: 'Serenity Guide',
                content: reply.content,
                timestamp: DateTime.now(),
                type: MessageType.assistant,
                status: MessageStatus.delivered,
              );

          _handleIncomingMessage(botMessage.copyWith(status: MessageStatus.delivered));
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

  Future<ChatRequestResult> sendChatRequest({
    required String fromUserId,
    required String toUserId,
    String? contextSummary,
    List<String> matchedThemes = const [],
    String? supportCategory,
    String? userCategory,
  }) async {
    try {
      return await _apiService.sendChatRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        contextSummary: contextSummary,
        matchedThemes: matchedThemes,
        supportCategory: supportCategory,
        userCategory: userCategory,
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

  void _loadMockSessions(String anonymousId) {
    _isUsingMockData = true;
    _error = null;
    _sessions = MockSocialData.chatSessionsFor(currentUserId: anonymousId);

    for (final session in _sessions) {
      _messagesBySession[session.id] = _mergeMessageLists(
        _messagesBySession[session.id] ?? const [],
        MockSocialData.messagesForSession(
          sessionId: session.id,
          currentUserId: anonymousId,
        ),
      );
    }
    _sortSessions();
  }

  void _loadHybridSessions({
    required String anonymousId,
    required List<ChatSession> remoteSessions,
  }) {
    final mockSessions = MockSocialData.chatSessionsFor(currentUserId: anonymousId);

    if (remoteSessions.isEmpty) {
      _loadMockSessions(anonymousId);
      return;
    }

    final merged = <String, ChatSession>{
      for (final session in mockSessions) session.id: session,
    };

    for (final remoteSession in remoteSessions) {
      final mockSession = merged[remoteSession.id];
      merged[remoteSession.id] = _enrichSessionWithMock(
        remote: remoteSession,
        mock: mockSession,
      );
    }

    _sessions = merged.values.toList();
    _isUsingMockData = merged.length > remoteSessions.length;
    _error = null;

    for (final session in _sessions) {
      if (!MockSocialData.isMockBackedConversation(session.id)) continue;
      _messagesBySession[session.id] = _mergeMessageLists(
        _messagesBySession[session.id] ?? const [],
        MockSocialData.messagesForSession(
          sessionId: session.id,
          currentUserId: anonymousId,
        ),
      );
    }

    _sortSessions();
  }

  ChatSession _enrichSessionWithMock({
    required ChatSession remote,
    ChatSession? mock,
  }) {
    final resolvedType = remote.type.trim().isEmpty
        ? (mock?.type ?? MockSocialData.sessionTypeFor(remote.id))
        : remote.type;
    final resolvedName = _isGenericSessionName(remote.name)
        ? (mock?.name ?? MockSocialData.sessionNameFor(remote.id))
        : remote.name;

    return remote.copyWith(
      type: resolvedType,
      name: resolvedName,
      participantIds: remote.participantIds.isEmpty
          ? (mock?.participantIds ?? remote.participantIds)
          : remote.participantIds,
      lastMessage: (remote.lastMessage == null || remote.lastMessage!.trim().isEmpty)
          ? mock?.lastMessage
          : remote.lastMessage,
      lastMessageTime: remote.lastMessageTime ?? mock?.lastMessageTime,
    );
  }

  bool _isGenericSessionName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'support chat' ||
        normalized.startsWith('community ') ||
        normalized.startsWith('support session ');
  }

  void _applyMockMessages(String sessionId) {
    final currentUserId = _activeAnonymousId ?? 'anonymous-user';
    final mockMessages = MockSocialData.messagesForSession(
      sessionId: sessionId,
      currentUserId: currentUserId,
    );
    if (mockMessages.isEmpty) return;

    _isUsingMockData = true;
    final mergedMessages = _mergeMessageLists(
      _messagesBySession[sessionId] ?? const [],
      mockMessages,
    );
    _messagesBySession[sessionId] = mergedMessages;

    final latest = mergedMessages.isNotEmpty ? mergedMessages.last : null;
    if (latest != null) {
      _upsertSessionPreview(
        sessionId: sessionId,
        sessionName: MockSocialData.sessionNameFor(sessionId),
        lastMessage: latest.content,
        lastMessageTime: latest.timestamp,
        createIfMissing: true,
      );
    }
  }

  void _upsertSessionPreview({
    required String sessionId,
    required String sessionName,
    required String lastMessage,
    required DateTime lastMessageTime,
    int unreadDelta = 0,
    bool createIfMissing = false,
  }) {
    final sessionIndex = _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex != -1) {
      final existing = _sessions[sessionIndex];
      _sessions[sessionIndex] = existing.copyWith(
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: (existing.unreadCount + unreadDelta).clamp(0, 999),
      );
      _sortSessions();
      return;
    }

    if (!createIfMissing) return;

    _sessions.insert(
      0,
      ChatSession(
        id: sessionId,
        type: MockSocialData.sessionTypeFor(sessionId),
        name: sessionName,
        participantIds: [
          if (_activeAnonymousId != null) _activeAnonymousId!,
        ],
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: unreadDelta.clamp(0, 999),
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
