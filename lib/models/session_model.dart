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
    return ChatSession(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
