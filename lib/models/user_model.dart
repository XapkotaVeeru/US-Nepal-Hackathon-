class AnonymousUser {
  final String anonymousId;
  final String displayName;
  final DateTime createdAt;
  final int totalPosts;
  final int totalChats;
  final bool isActive;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool chatRequestsEnabled;
  final bool groupInvitesEnabled;

  AnonymousUser({
    required this.anonymousId,
    required this.displayName,
    required this.createdAt,
    this.totalPosts = 0,
    this.totalChats = 0,
    this.isActive = true,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.chatRequestsEnabled = true,
    this.groupInvitesEnabled = true,
  });

  factory AnonymousUser.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final notificationsRaw =
        json['notificationsEnabled'] ?? json['notifications_enabled'];
    final soundRaw = json['soundEnabled'] ?? json['sound_enabled'];
    final chatRequestsRaw =
        json['chatRequestsEnabled'] ?? json['chat_requests_enabled'];
    final groupInvitesRaw =
        json['groupInvitesEnabled'] ?? json['group_invites_enabled'];
    final isActiveRaw = json['isActive'] ?? json['is_active'];

    return AnonymousUser(
      anonymousId: (json['anonymousId'] ?? json['id']) as String,
      displayName:
          (json['displayName'] ?? json['display_name'] ?? 'Anonymous User')
              as String,
      createdAt: createdAtRaw is String
          ? DateTime.parse(createdAtRaw)
          : DateTime.now(),
      totalPosts: json['totalPosts'] as int? ?? 0,
      totalChats: json['totalChats'] as int? ?? 0,
      isActive: isActiveRaw is bool ? isActiveRaw : true,
      notificationsEnabled:
          notificationsRaw is bool ? notificationsRaw : true,
      soundEnabled: soundRaw is bool ? soundRaw : true,
      chatRequestsEnabled:
          chatRequestsRaw is bool ? chatRequestsRaw : true,
      groupInvitesEnabled:
          groupInvitesRaw is bool ? groupInvitesRaw : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anonymousId': anonymousId,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'totalPosts': totalPosts,
      'totalChats': totalChats,
      'isActive': isActive,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'chatRequestsEnabled': chatRequestsEnabled,
      'groupInvitesEnabled': groupInvitesEnabled,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'display_name': displayName,
      'notifications_enabled': notificationsEnabled,
      'sound_enabled': soundEnabled,
      'chat_requests_enabled': chatRequestsEnabled,
      'group_invites_enabled': groupInvitesEnabled,
    };
  }

  AnonymousUser copyWith({
    String? anonymousId,
    String? displayName,
    DateTime? createdAt,
    int? totalPosts,
    int? totalChats,
    bool? isActive,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? chatRequestsEnabled,
    bool? groupInvitesEnabled,
  }) {
    return AnonymousUser(
      anonymousId: anonymousId ?? this.anonymousId,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      totalPosts: totalPosts ?? this.totalPosts,
      totalChats: totalChats ?? this.totalChats,
      isActive: isActive ?? this.isActive,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      chatRequestsEnabled: chatRequestsEnabled ?? this.chatRequestsEnabled,
      groupInvitesEnabled: groupInvitesEnabled ?? this.groupInvitesEnabled,
    );
  }
}
