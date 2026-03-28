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

  /// Add a notification (for testing or local notifications)
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all as read
  void markAllAsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Delete notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Accept chat request
  Future<void> acceptChatRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.acceptChatRequest(requestId);

      // Remove notification after accepting
      _notifications
          .removeWhere((n) => n.actionData?['requestId'] == requestId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error accepting chat request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Decline chat request
  Future<void> declineChatRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.declineChatRequest(requestId);

      // Remove notification after declining
      _notifications
          .removeWhere((n) => n.actionData?['requestId'] == requestId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error declining chat request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load mock notifications (for testing)
  void loadMockNotifications() {
    _notifications = [
      NotificationItem(
        id: '1',
        type: NotificationType.matchRequest,
        title: 'New Match Request',
        message: 'Anonymous Butterfly wants to connect with you',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        actionData: {
          'requestId': 'req_123',
          'userId': '123',
          'userName': 'Anonymous Butterfly'
        },
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.groupInvite,
        title: 'Group Invitation',
        message: 'You\'ve been invited to join "Academic Stress Support"',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
        actionData: {
          'requestId': 'req_456',
          'groupId': '456',
          'groupName': 'Academic Stress Support'
        },
      ),
      NotificationItem(
        id: '3',
        type: NotificationType.message,
        title: 'New Message',
        message: 'Anonymous Dove sent you a message',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionData: {'chatId': '789'},
      ),
      NotificationItem(
        id: '4',
        type: NotificationType.matchFound,
        title: 'Match Found!',
        message: 'We found 3 people with similar experiences',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        actionData: {'postId': '101'},
      ),
    ];
    notifyListeners();
  }
}
