/// Model for micro-communities — small, topic-focused support groups
class MicroCommunity {
  final String id;
  final String name;
  final String topic;
  final String description;
  final String emoji;
  final int memberCount;
  final String? lastMessagePreview;
  final String? lastMessageAuthor;
  final DateTime? lastActiveAt;
  final SafetyLevel safetyLevel;
  final List<String> tags;
  final bool isJoined;
  final CommunityCategory category;

  MicroCommunity({
    required this.id,
    required this.name,
    required this.topic,
    required this.description,
    required this.emoji,
    required this.memberCount,
    this.lastMessagePreview,
    this.lastMessageAuthor,
    this.lastActiveAt,
    this.safetyLevel = SafetyLevel.safe,
    this.tags = const [],
    this.isJoined = false,
    this.category = CommunityCategory.support,
  });

  MicroCommunity copyWith({
    String? id,
    String? name,
    String? topic,
    String? description,
    String? emoji,
    int? memberCount,
    String? lastMessagePreview,
    String? lastMessageAuthor,
    DateTime? lastActiveAt,
    SafetyLevel? safetyLevel,
    List<String>? tags,
    bool? isJoined,
    CommunityCategory? category,
  }) {
    return MicroCommunity(
      id: id ?? this.id,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      memberCount: memberCount ?? this.memberCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAuthor: lastMessageAuthor ?? this.lastMessageAuthor,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      tags: tags ?? this.tags,
      isJoined: isJoined ?? this.isJoined,
      category: category ?? this.category,
    );
  }
}

enum SafetyLevel { safe, moderated, open }

enum CommunityCategory {
  support,
  wellness,
  academic,
  social,
  crisis,
  mindfulness,
}

/// Mock data for communities
class MockCommunities {
  static List<MicroCommunity> getAllCommunities() {
    return [
      MicroCommunity(
        id: 'c1',
        name: 'Anxiety Warriors',
        topic: 'Anxiety & Panic',
        description:
            'A safe space for people dealing with anxiety and panic attacks. Share coping strategies and find comfort in knowing you\'re not alone.',
        emoji: '🛡️',
        memberCount: 234,
        lastMessagePreview: 'The breathing technique from yesterday really helped me...',
        lastMessageAuthor: 'Anonymous Phoenix',
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
        safetyLevel: SafetyLevel.moderated,
        tags: ['anxiety', 'panic', 'coping', 'breathing'],
        category: CommunityCategory.support,
      ),
      MicroCommunity(
        id: 'c2',
        name: 'Study Stress Circle',
        topic: 'Academic Pressure',
        description:
            'For students feeling overwhelmed by academic demands. Share study tips, vent about deadlines, and support each other through exam season.',
        emoji: '📚',
        memberCount: 189,
        lastMessagePreview: 'Finals week is hitting different this semester...',
        lastMessageAuthor: 'Anonymous Owl',
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 12)),
        safetyLevel: SafetyLevel.safe,
        tags: ['academic', 'stress', 'exams', 'students'],
        category: CommunityCategory.academic,
      ),
      MicroCommunity(
        id: 'c3',
        name: 'Midnight Thoughts',
        topic: 'Late Night Support',
        description:
            'Can\'t sleep? Overthinking? Join others who are up late and need someone to talk to. Active mostly during late hours.',
        emoji: '🌙',
        memberCount: 312,
        lastMessagePreview: 'Anyone else can\'t stop their brain from racing?',
        lastMessageAuthor: 'Anonymous Deer',
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 1)),
        safetyLevel: SafetyLevel.moderated,
        tags: ['insomnia', 'overthinking', 'night', 'support'],
        category: CommunityCategory.support,
      ),
      MicroCommunity(
        id: 'c4',
        name: 'Mindful Mornings',
        topic: 'Mindfulness & Meditation',
        description:
            'Start your day with intention. Share mindfulness practices, guided meditations, and positive affirmations with the community.',
        emoji: '🧘',
        memberCount: 156,
        lastMessagePreview: 'Today\'s gratitude: I\'m grateful for this community 💛',
        lastMessageAuthor: 'Anonymous Swan',
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 3)),
        safetyLevel: SafetyLevel.safe,
        tags: ['mindfulness', 'meditation', 'morning', 'gratitude'],
        category: CommunityCategory.mindfulness,
      ),
      MicroCommunity(
        id: 'c5',
        name: 'Family Dynamics',
        topic: 'Family Issues',
        description:
            'Navigating complicated family relationships? You\'re not alone. Share your experiences and get advice from people who understand.',
        emoji: '🏠',
        memberCount: 98,
        lastMessagePreview: 'Setting boundaries is so hard but so necessary...',
        lastMessageAuthor: 'Anonymous Eagle',
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 6)),
        safetyLevel: SafetyLevel.moderated,
        tags: ['family', 'boundaries', 'relationships', 'healing'],
        category: CommunityCategory.support,
      ),
      MicroCommunity(
        id: 'c6',
        name: 'First Gen Support',
        topic: 'First Generation Students',
        description:
            'A community for first-generation college students navigating the unique challenges of being the first in their family.',
        emoji: '🌟',
        memberCount: 145,
        lastMessagePreview: 'Just got into grad school! First in my family!',
        lastMessageAuthor: 'Anonymous Dolphin',
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
        safetyLevel: SafetyLevel.safe,
        tags: ['first-gen', 'college', 'support', 'achievement'],
        category: CommunityCategory.academic,
      ),
      MicroCommunity(
        id: 'c7',
        name: 'Grief & Loss',
        topic: 'Coping with Loss',
        description:
            'A gentle space for those processing grief and loss. Share memories, feelings, and find comfort in shared understanding.',
        emoji: '🕊️',
        memberCount: 76,
        lastMessagePreview: 'It gets easier, but you never stop missing them...',
        lastMessageAuthor: 'Anonymous Bear',
        lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
        safetyLevel: SafetyLevel.moderated,
        tags: ['grief', 'loss', 'healing', 'remembrance'],
        category: CommunityCategory.support,
      ),
      MicroCommunity(
        id: 'c8',
        name: 'Self-Care Squad',
        topic: 'Self-Care & Wellness',
        description:
            'Share self-care routines, wellness tips, and encourage each other to prioritize mental health in daily life.',
        emoji: '💆',
        memberCount: 267,
        lastMessagePreview: 'Started journaling this week and it\'s been amazing!',
        lastMessageAuthor: 'Anonymous Panda',
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
        safetyLevel: SafetyLevel.safe,
        tags: ['self-care', 'wellness', 'routine', 'health'],
        category: CommunityCategory.wellness,
      ),
      MicroCommunity(
        id: 'c9',
        name: 'Social Anxiety Hub',
        topic: 'Social Anxiety',
        description:
            'For those struggling with social situations. Practice conversations, share victories (big and small), and build confidence together.',
        emoji: '💬',
        memberCount: 203,
        lastMessagePreview: 'I actually raised my hand in class today! 🎉',
        lastMessageAuthor: 'Anonymous Fox',
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 4)),
        safetyLevel: SafetyLevel.safe,
        tags: ['social anxiety', 'confidence', 'growth', 'practice'],
        category: CommunityCategory.support,
      ),
      MicroCommunity(
        id: 'c10',
        name: 'Depression Daily',
        topic: 'Living with Depression',
        description:
            'A moderated space for people managing depression. Share daily wins, struggles, and support each other through the fog.',
        emoji: '🌤️',
        memberCount: 178,
        lastMessagePreview: 'Managed to shower and eat breakfast today 💪',
        lastMessageAuthor: 'Anonymous Wolf',
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 45)),
        safetyLevel: SafetyLevel.moderated,
        tags: ['depression', 'daily', 'wins', 'support'],
        category: CommunityCategory.support,
      ),
    ];
  }

  static List<MicroCommunity> getTrending() {
    final all = getAllCommunities();
    return [all[0], all[2], all[7], all[9]];
  }

  static List<MicroCommunity> getSuggested() {
    final all = getAllCommunities();
    return [all[1], all[5], all[3]];
  }

  static List<MicroCommunity> getRecentlyActive() {
    final all = getAllCommunities();
    final sorted = List<MicroCommunity>.from(all)
      ..sort((a, b) =>
          (b.lastActiveAt ?? DateTime(2000)).compareTo(a.lastActiveAt ?? DateTime(2000)));
    return sorted.take(5).toList();
  }

  static MicroCommunity? findCommunityForTopic(String topic) {
    final lower = topic.toLowerCase();
    final all = getAllCommunities();
    for (final community in all) {
      for (final tag in community.tags) {
        if (lower.contains(tag) || tag.contains(lower)) {
          return community;
        }
      }
    }
    // Default fallback
    return all[0];
  }
}
