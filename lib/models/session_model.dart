class ChatSession {
  final String id;
  final String type; // 'individual' or 'group'
  final String name;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.type,
    required this.name,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final participantIds =
        (json['participantIds'] ?? json['participant_ids']) as List? ?? const [];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final lastMessageTime = json['lastMessageTime'] ?? json['last_message_time'];
    final unreadCount = json['unreadCount'] ?? json['unread_count'];
    final isActive = json['isActive'] ?? json['is_active'];

    return ChatSession(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'group',
      name: json['name'] as String? ?? 'Support Chat',
      participantIds: participantIds.map((item) => item.toString()).toList(),
      lastMessage: (json['lastMessage'] ?? json['last_message']) as String?,
      lastMessageTime: lastMessageTime != null
          ? DateTime.tryParse(lastMessageTime.toString())
          : null,
      unreadCount: unreadCount as int? ?? 0,
      isActive: isActive as bool? ?? true,
      createdAt: createdAt is String
          ? DateTime.tryParse(createdAt) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ChatSession copyWith({
    String? id,
    String? type,
    String? name,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
