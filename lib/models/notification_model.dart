enum NotificationType {
  matchRequest,
  groupInvite,
  message,
  matchFound,
  system,
}

NotificationType notificationTypeFromApi(String? raw) {
  switch (raw) {
    case 'match_request':
      return NotificationType.matchRequest;
    case 'group_invite':
      return NotificationType.groupInvite;
    case 'message':
      return NotificationType.message;
    case 'match_found':
      return NotificationType.matchFound;
    case 'system':
    default:
      return NotificationType.system;
  }
}

String notificationTypeToApi(NotificationType type) {
  switch (type) {
    case NotificationType.matchRequest:
      return 'match_request';
    case NotificationType.groupInvite:
      return 'group_invite';
    case NotificationType.message:
      return 'message';
    case NotificationType.matchFound:
      return 'match_found';
    case NotificationType.system:
      return 'system';
  }
}

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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] ?? json['created_at'];
    return NotificationItem(
      id: json['id'] as String? ?? '',
      type: notificationTypeFromApi(json['type'] as String?),
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      timestamp: createdAt is String
          ? DateTime.tryParse(createdAt) ?? DateTime.now()
          : DateTime.now(),
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      actionData: (json['actionData'] ?? json['action_data'])
          as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'type': notificationTypeToApi(type),
      'title': title,
      'message': message,
      'action_data': actionData,
    };
  }

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
