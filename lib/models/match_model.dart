/// Represents a match between two users based on AI similarity analysis.
class MatchResult {
  final String id;
  final String postId;
  final String userId1;
  final String userId2;
  final String user2DisplayName;
  final double similarityScore;
  final List<String> commonTopics;
  final MatchStatus status;
  final DateTime createdAt;
  final String? chatRoomId;

  MatchResult({
    required this.id,
    required this.postId,
    required this.userId1,
    required this.userId2,
    required this.user2DisplayName,
    required this.similarityScore,
    required this.commonTopics,
    this.status = MatchStatus.proposed,
    required this.createdAt,
    this.chatRoomId,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      userId1: json['userId1'] as String? ?? '',
      userId2: json['userId2'] as String? ?? '',
      user2DisplayName: json['user2DisplayName'] as String? ?? 'Anonymous Peer',
      similarityScore: (json['similarityScore'] is String)
          ? double.tryParse(json['similarityScore'] as String) ?? 0.0
          : (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
      commonTopics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ??
          (json['commonTopics'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      status: MatchStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'proposed'),
        orElse: () => MatchStatus.proposed,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      chatRoomId: json['chatRoomId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userId1': userId1,
        'userId2': userId2,
        'user2DisplayName': user2DisplayName,
        'similarityScore': similarityScore,
        'commonTopics': commonTopics,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (chatRoomId != null) 'chatRoomId': chatRoomId,
      };
}

enum MatchStatus { proposed, accepted, declined, expired }
