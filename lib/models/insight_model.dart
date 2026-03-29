/// Models for the insights / analytics screen.
library;

class InsightData {
  final MoodTrend moodTrend;
  final ChatActivity chatActivity;
  final CommunityEngagement communityEngagement;
  final YoureNotAloneStats youreNotAlone;
  final WeeklySummary weeklySummary;

  InsightData({
    required this.moodTrend,
    required this.chatActivity,
    required this.communityEngagement,
    required this.youreNotAlone,
    required this.weeklySummary,
  });

  factory InsightData.fromJson(Map<String, dynamic> json) {
    return InsightData(
      moodTrend: MoodTrend.fromJson(json['moodTrend'] as Map<String, dynamic>? ?? {}),
      chatActivity: ChatActivity.fromJson(json['chatActivity'] as Map<String, dynamic>? ?? {}),
      communityEngagement: CommunityEngagement.fromJson(
          json['communityEngagement'] as Map<String, dynamic>? ?? {}),
      youreNotAlone: YoureNotAloneStats.fromJson(
          json['youreNotAlone'] as Map<String, dynamic>? ?? {}),
      weeklySummary: WeeklySummary.fromJson(json['weeklySummary'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Generate realistic mock data
  static InsightData mock() {
    return InsightData(
      moodTrend: MoodTrend(
        dailyScores: [3, 4, 3, 5, 4, 6, 5, 7, 6, 5, 7, 6, 8, 7],
        averageMood: 5.4,
        trend: 'improving',
        bestDay: 'Wednesday',
      ),
      chatActivity: ChatActivity(
        dailyMessages: [12, 8, 15, 20, 6, 18, 22],
        totalMessages: 101,
        peakHour: '9 PM',
        activeDays: 6,
      ),
      communityEngagement: CommunityEngagement(
        communitiesJoined: 4,
        postsCreated: 7,
        reactionsGiven: 23,
        helpfulReplies: 12,
        topCommunity: 'Anxiety Warriors',
      ),
      youreNotAlone: YoureNotAloneStats(
        usersOnlineNow: 342,
        postsToday: 1284,
        matchesMadeToday: 89,
        communitiesActive: 10,
        messagesExchangedToday: 5621,
      ),
      weeklySummary: WeeklySummary(
        headline: 'Your mood improved 18% this week 🌱',
        highlights: [
          'You connected with 3 new peers',
          'Participated in 4 community discussions',
          'Logged mood 6 out of 7 days',
          'Your most active day was Wednesday',
        ],
        encouragement:
            'Consistency is key to growth. You\'re building real connections that matter.',
      ),
    );
  }
}

class MoodTrend {
  final List<int> dailyScores;
  final double averageMood;
  final String trend;
  final String bestDay;

  MoodTrend({
    required this.dailyScores,
    required this.averageMood,
    required this.trend,
    required this.bestDay,
  });

  factory MoodTrend.fromJson(Map<String, dynamic> json) {
    return MoodTrend(
      dailyScores: (json['dailyScores'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          [5, 5, 5, 5, 5, 5, 5],
      averageMood: (json['averageMood'] as num?)?.toDouble() ?? 5.0,
      trend: json['trend'] as String? ?? 'stable',
      bestDay: json['bestDay'] as String? ?? 'N/A',
    );
  }
}

class ChatActivity {
  final List<int> dailyMessages;
  final int totalMessages;
  final String peakHour;
  final int activeDays;

  ChatActivity({
    required this.dailyMessages,
    required this.totalMessages,
    required this.peakHour,
    required this.activeDays,
  });

  factory ChatActivity.fromJson(Map<String, dynamic> json) {
    return ChatActivity(
      dailyMessages: (json['dailyMessages'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          [0, 0, 0, 0, 0, 0, 0],
      totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
      peakHour: json['peakHour'] as String? ?? 'N/A',
      activeDays: (json['activeDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityEngagement {
  final int communitiesJoined;
  final int postsCreated;
  final int reactionsGiven;
  final int helpfulReplies;
  final String topCommunity;

  CommunityEngagement({
    required this.communitiesJoined,
    required this.postsCreated,
    required this.reactionsGiven,
    required this.helpfulReplies,
    required this.topCommunity,
  });

  factory CommunityEngagement.fromJson(Map<String, dynamic> json) {
    return CommunityEngagement(
      communitiesJoined: (json['communitiesJoined'] as num?)?.toInt() ?? 0,
      postsCreated: (json['postsCreated'] as num?)?.toInt() ?? 0,
      reactionsGiven: (json['reactionsGiven'] as num?)?.toInt() ?? 0,
      helpfulReplies: (json['helpfulReplies'] as num?)?.toInt() ?? 0,
      topCommunity: json['topCommunity'] as String? ?? 'N/A',
    );
  }
}

class YoureNotAloneStats {
  final int usersOnlineNow;
  final int postsToday;
  final int matchesMadeToday;
  final int communitiesActive;
  final int messagesExchangedToday;

  YoureNotAloneStats({
    required this.usersOnlineNow,
    required this.postsToday,
    required this.matchesMadeToday,
    required this.communitiesActive,
    required this.messagesExchangedToday,
  });

  factory YoureNotAloneStats.fromJson(Map<String, dynamic> json) {
    return YoureNotAloneStats(
      usersOnlineNow: (json['usersOnlineNow'] as num?)?.toInt() ?? 0,
      postsToday: (json['postsToday'] as num?)?.toInt() ?? 0,
      matchesMadeToday: (json['matchesMadeToday'] as num?)?.toInt() ?? 0,
      communitiesActive: (json['communitiesActive'] as num?)?.toInt() ?? 0,
      messagesExchangedToday: (json['messagesExchangedToday'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeeklySummary {
  final String headline;
  final List<String> highlights;
  final String encouragement;

  WeeklySummary({
    required this.headline,
    required this.highlights,
    required this.encouragement,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      headline: json['headline'] as String? ?? 'Keep going!',
      highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      encouragement: json['encouragement'] as String? ?? 'Every step counts.',
    );
  }
}
