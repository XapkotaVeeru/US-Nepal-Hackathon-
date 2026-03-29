import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/mock_social_data.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  bool _isUsingMockData = false;
  String? _error;
  String? _activeUserId;

  NotificationProvider(this._apiService);

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isUsingMockData => _isUsingMockData;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void bindUser(String? userId) {
    if (userId == null || userId.isEmpty) return;
    if (_activeUserId == userId) return;
    _activeUserId = userId;
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final userId = _activeUserId;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final remoteNotifications = await _apiService.listNotifications(userId: userId);
      if (remoteNotifications.isEmpty) {
        _loadMockNotifications(userId);
      } else {
        _notifications = remoteNotifications;
        _isUsingMockData = false;
      }
    } catch (e) {
      debugPrint('Error loading notifications, falling back to mock data: $e');
      _loadMockNotifications(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatRequests(String anonymousId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requests = await _apiService.getChatRequests(anonymousId);
      if (requests.isEmpty) {
        _loadMockNotifications(anonymousId);
      } else {
        _notifications = requests.map(_notificationFromRequest).toList();
        _isUsingMockData = false;
      }
    } catch (e) {
      debugPrint('Error loading chat requests, falling back to mock data: $e');
      _loadMockNotifications(anonymousId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NotificationItem?> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? actionData,
  }) async {
    final userId = _activeUserId;
    if (userId == null) return null;

    final created = await _apiService.createNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
      actionData: actionData,
    );

    if (created != null) {
      _notifications.insert(0, created);
      notifyListeners();
    }
    return created;
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void addPendingMatchRequest({
    required String requesterId,
    required String requesterName,
    required String targetUserId,
    required String targetUserName,
  }) {
    final requestId = 'req_${DateTime.now().microsecondsSinceEpoch}';
    addNotification(
      NotificationItem(
        id: requestId,
        type: NotificationType.matchRequest,
        title: 'Chat Request',
        message:
            '$requesterName wants to start a private chat with $targetUserName.',
        timestamp: DateTime.now(),
        isRead: false,
        actionData: {
          'requestId': requestId,
          'requestType': 'direct',
          'requesterId': requesterId,
          'requesterName': requesterName,
          'targetUserId': targetUserId,
          'targetUserName': targetUserName,
        },
      ),
    );
  }

  void addPendingGroupInvite({
    required String requesterId,
    required String requesterName,
    required String targetUserId,
    required String targetUserName,
    required String groupName,
  }) {
    final requestId = 'req_${DateTime.now().microsecondsSinceEpoch}';
    addNotification(
      NotificationItem(
        id: requestId,
        type: NotificationType.groupInvite,
        title: 'Group Request',
        message:
            '$requesterName wants to create "$groupName" with $targetUserName.',
        timestamp: DateTime.now(),
        isRead: false,
        actionData: {
          'requestId': requestId,
          'requestType': 'group',
          'requesterId': requesterId,
          'requesterName': requesterName,
          'targetUserId': targetUserId,
          'targetUserName': targetUserName,
          'groupName': groupName,
        },
      ),
    );
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    _markAsReadRemote(notificationId);
  }

  Future<void> _markAsReadRemote(String notificationId) async {
    if (_isMockId(notificationId)) return;
    final updated = await _apiService.markNotificationRead(
      notificationId: notificationId,
    );
    if (updated == null) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    _notifications[index] = updated;
    notifyListeners();
  }

  void markAllAsRead() {
    final unreadIds = _notifications
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id)
        .toList();
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    for (final id in unreadIds) {
      _markAsReadRemote(id);
    }
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  Future<void> acceptChatRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isMockId(requestId)) {
        final notification = _notifications.firstWhere(
          (item) => item.actionData?['requestId'] == requestId,
          orElse: () => NotificationItem(
            id: 'mock-fallback',
            type: NotificationType.message,
            title: 'Chat ready',
            message: 'You can open the support chat now.',
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );
        _notifications.removeWhere((n) => n.actionData?['requestId'] == requestId);
        _notifications.insert(
          0,
          NotificationItem(
            id: 'mock-accepted-${DateTime.now().microsecondsSinceEpoch}',
            type: NotificationType.message,
            title: 'Chat ready',
            message: 'Your support chat is ready for you to open.',
            timestamp: DateTime.now(),
            isRead: false,
            actionData: notification.actionData,
          ),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _apiService.acceptChatRequest(requestId);
      if (_activeUserId != null) {
        await loadNotifications();
      } else {
        _notifications.removeWhere((n) => n.actionData?['requestId'] == requestId);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error accepting chat request: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> declineChatRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isMockId(requestId)) {
        _notifications.removeWhere((n) => n.actionData?['requestId'] == requestId);
        _notifications.insert(
          0,
          NotificationItem(
            id: 'mock-declined-${DateTime.now().microsecondsSinceEpoch}',
            type: NotificationType.system,
            title: 'Request declined',
            message: 'The request was cleared from your notification list.',
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _apiService.declineChatRequest(requestId);
      if (_activeUserId != null) {
        await loadNotifications();
      } else {
        _notifications.removeWhere((n) => n.actionData?['requestId'] == requestId);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error declining chat request: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordRoutingNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      await createNotification(
        type: type,
        title: title,
        message: message,
        actionData: actionData,
      );
    } catch (e) {
      debugPrint('Error recording routing notification: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _loadMockNotifications(String userId) {
    _notifications = MockSocialData.notificationsFor(currentUserId: userId);
    _isUsingMockData = true;
    _error = null;
  }

  bool _isMockId(String id) => id.startsWith('mock-');

  NotificationItem _notificationFromRequest(Map<String, dynamic> request) {
    final type = request['type'] == 'group'
        ? NotificationType.groupInvite
        : NotificationType.matchRequest;
    final requestId = request['requestId']?.toString() ?? '';
    final createdAt = DateTime.tryParse(
          request['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now();
    final fromUserName =
        request['fromUserName']?.toString() ?? 'Anonymous Peer';
    final toUserName = request['toUserName']?.toString() ?? 'You';
    final groupName = request['groupName']?.toString();

    return NotificationItem(
      id: requestId,
      type: type,
      title: type == NotificationType.groupInvite
          ? 'Group Request'
          : 'Chat Request',
      message: type == NotificationType.groupInvite
          ? '$fromUserName wants to create "$groupName" with $toUserName.'
          : '$fromUserName wants to start a private chat with $toUserName.',
      timestamp: createdAt,
      isRead: false,
      actionData: {
        'requestId': requestId,
        'requestType': request['type'],
        'requesterId': request['fromUserId'],
        'requesterName': fromUserName,
        'targetUserId': request['toUserId'],
        'targetUserName': toUserName,
        'groupName': groupName,
      },
    );
  }
}
