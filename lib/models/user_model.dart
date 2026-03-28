class AnonymousUser {
  final String anonymousId;
  final String displayName;
  final DateTime createdAt;
  final int totalPosts;
  final int totalChats;

  AnonymousUser({
    required this.anonymousId,
    required this.displayName,
    required this.createdAt,
    this.totalPosts = 0,
    this.totalChats = 0,
  });

  factory AnonymousUser.fromJson(Map<String, dynamic> json) {
    return AnonymousUser(
      anonymousId: json['anonymousId'] as String,
      displayName: json['displayName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalPosts: json['totalPosts'] as int? ?? 0,
      totalChats: json['totalChats'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anonymousId': anonymousId,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'totalPosts': totalPosts,
      'totalChats': totalChats,
    };
  }

  AnonymousUser copyWith({
    String? anonymousId,
    String? displayName,
    DateTime? createdAt,
    int? totalPosts,
    int? totalChats,
  }) {
    return AnonymousUser(
      anonymousId: anonymousId ?? this.anonymousId,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      totalPosts: totalPosts ?? this.totalPosts,
      totalChats: totalChats ?? this.totalChats,
    );
  }
}
