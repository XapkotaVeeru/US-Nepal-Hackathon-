import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _activeUserId;

  NotificationProvider(this._apiService);

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
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
      _notifications = await _apiService.listNotifications(userId: userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
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
      _notifications = requests.map(_notificationFromRequest).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading chat requests: $e');
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
