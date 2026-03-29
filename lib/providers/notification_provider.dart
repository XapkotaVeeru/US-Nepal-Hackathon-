import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

enum NotificationType { matchRequest, groupInvite, message, matchFound }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? actionData;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.actionData,
  });

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionData: actionData ?? this.actionData,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._apiService);

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
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
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
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
      final notificationIndex = _notifications.indexWhere(
        (n) => n.actionData?['requestId'] == requestId,
      );
      final notification =
          notificationIndex == -1 ? null : _notifications[notificationIndex];

      try {
        await _apiService.acceptChatRequest(requestId);
      } catch (e) {
        debugPrint('Accept chat request API failed, keeping local flow: $e');
      }

      _notifications.removeWhere((n) => n.actionData?['requestId'] == requestId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error accepting chat request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> declineChatRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        await _apiService.declineChatRequest(requestId);
      } catch (e) {
        debugPrint('Decline chat request API failed, keeping local flow: $e');
      }

      _notifications.removeWhere((n) => n.actionData?['requestId'] == requestId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error declining chat request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
