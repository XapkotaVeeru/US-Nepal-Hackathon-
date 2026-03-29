enum MessageType { user, system, matchNotification, assistant }

enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final MessageStatus status;

  Message({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.user,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    MessageType parseType(String? t) {
      switch (t) {
        case 'system':
          return MessageType.system;
        case 'matchNotification':
        case 'match_notification':
          return MessageType.matchNotification;
        case 'assistant':
          return MessageType.assistant;
        default:
          return MessageType.user;
      }
    }

    MessageStatus parseStatus(String? s) {
      switch (s) {
        case 'sending':
          return MessageStatus.sending;
        case 'delivered':
          return MessageStatus.delivered;
        case 'read':
          return MessageStatus.read;
        case 'failed':
          return MessageStatus.failed;
        default:
          return MessageStatus.sent;
      }
    }

    return Message(
      id: json['id'] as String? ?? '',
      sessionId:
          (json['sessionId'] ?? json['session_id'] ?? json['communityId'])
                  as String? ??
              '',
      senderId: (json['senderId'] ?? json['sender_id']) as String? ?? '',
      senderName:
          (json['senderName'] ?? json['sender_name']) as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      timestamp:
          (json['timestamp'] ?? json['created_at'] ?? json['createdAt']) != null
          ? DateTime.tryParse(
                  (json['timestamp'] ?? json['created_at'] ?? json['createdAt'])
                      .toString(),
                ) ??
                DateTime.now()
          : DateTime.now(),
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      type: parseType(json['type'] as String?),
      status: parseStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      'status': status.name,
    };
  }

  Message copyWith({
    String? id,
    String? sessionId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}
