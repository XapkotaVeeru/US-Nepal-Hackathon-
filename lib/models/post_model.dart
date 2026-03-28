class Post {
  final String id;
  final String content;
  final DateTime createdAt;
  final RiskLevel riskLevel;
  final List<SimilarUser>? similarUsers;
  final List<SupportGroup>? supportGroups;

  Post({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.riskLevel,
    this.similarUsers,
    this.supportGroups,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.toString() == 'RiskLevel.${json['riskLevel']}',
      ),
      similarUsers: json['similarUsers'] != null
          ? (json['similarUsers'] as List)
                .map((u) => SimilarUser.fromJson(u))
                .toList()
          : null,
      supportGroups: json['supportGroups'] != null
          ? (json['supportGroups'] as List)
                .map((g) => SupportGroup.fromJson(g))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'riskLevel': riskLevel.toString().split('.').last,
      'similarUsers': similarUsers?.map((u) => u.toJson()).toList(),
      'supportGroups': supportGroups?.map((g) => g.toJson()).toList(),
    };
  }
}

enum RiskLevel { low, medium, high }

class SimilarUser {
  final String id;
  final String anonymousName;
  final double similarityScore;
  final String? lastActive;
  final String? commonTheme;

  SimilarUser({
    required this.id,
    required this.anonymousName,
    required this.similarityScore,
    this.lastActive,
    this.commonTheme,
  });

  factory SimilarUser.fromJson(Map<String, dynamic> json) {
    return SimilarUser(
      id: json['id'],
      anonymousName: json['anonymousName'],
      similarityScore: json['similarityScore'].toDouble(),
      lastActive: json['lastActive'],
      commonTheme: json['commonTheme'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anonymousName': anonymousName,
      'similarityScore': similarityScore,
      'lastActive': lastActive,
      'commonTheme': commonTheme,
    };
  }
}

class SupportGroup {
  final String id;
  final String name;
  final int memberCount;
  final String theme;
  final DateTime createdAt;

  SupportGroup({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.theme,
    required this.createdAt,
  });

  factory SupportGroup.fromJson(Map<String, dynamic> json) {
    return SupportGroup(
      id: json['id'],
      name: json['name'],
      memberCount: json['memberCount'],
      theme: json['theme'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'memberCount': memberCount,
      'theme': theme,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CrisisResource {
  final String name;
  final String phone;
  final String? url;
  final String description;
  final bool available24_7;

  CrisisResource({
    required this.name,
    required this.phone,
    this.url,
    required this.description,
    required this.available24_7,
  });

  factory CrisisResource.fromJson(Map<String, dynamic> json) {
    return CrisisResource(
      name: json['name'],
      phone: json['phone'],
      url: json['url'],
      description: json['description'],
      available24_7: json['available24_7'],
    );
  }
}
