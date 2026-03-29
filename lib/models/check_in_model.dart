import 'post_model.dart';

enum CheckInInputMode { text, voice }

enum MoodDirection { upward, steady, downward }

class CheckInSubmission {
  final String anonymousId;
  final String content;
  final CheckInInputMode inputMode;
  final DateTime createdAt;
  final String captureSource;
  final String? transcript;

  const CheckInSubmission({
    required this.anonymousId,
    required this.content,
    required this.inputMode,
    required this.createdAt,
    required this.captureSource,
    this.transcript,
  });

  bool get cameFromVoice => inputMode == CheckInInputMode.voice;
}

class EmotionalAnalysisResult {
  final List<String> emotionalLabels;
  final MoodDirection moodDirection;
  final double sentimentScore;
  final int intensity;
  final String intensityLabel;
  final String riskLevel;
  final List<String> themes;
  final List<String> supportRecommendations;
  final String summary;
  final String source;
  final bool usedFallback;

  const EmotionalAnalysisResult({
    required this.emotionalLabels,
    required this.moodDirection,
    required this.sentimentScore,
    required this.intensity,
    required this.intensityLabel,
    required this.riskLevel,
    required this.themes,
    required this.supportRecommendations,
    required this.summary,
    required this.source,
    required this.usedFallback,
  });

  String get moodDirectionLabel {
    switch (moodDirection) {
      case MoodDirection.upward:
        return 'Lifting';
      case MoodDirection.steady:
        return 'Mixed';
      case MoodDirection.downward:
        return 'Heavy';
    }
  }

  String get sourceLabel => usedFallback ? 'Local fallback' : source;
}

class SupportRecommendationItem {
  final String title;
  final String description;
  final String actionLabel;

  const SupportRecommendationItem({
    required this.title,
    required this.description,
    required this.actionLabel,
  });
}

class SupportMemberRecommendation {
  final String id;
  final String anonymousName;
  final double similarityScore;
  final String lastActive;
  final String reason;
  final String sharedThemes;

  const SupportMemberRecommendation({
    required this.id,
    required this.anonymousName,
    required this.similarityScore,
    required this.lastActive,
    required this.reason,
    required this.sharedThemes,
  });
}

class SupportCommunityRecommendation {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int memberCount;
  final String reason;
  final List<String> matchedThemes;

  const SupportCommunityRecommendation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.memberCount,
    required this.reason,
    required this.matchedThemes,
  });
}

class EmbeddingRetrievalPlan {
  final String queryText;
  final List<String> tags;
  final String backendHint;
  final bool backendReady;

  const EmbeddingRetrievalPlan({
    required this.queryText,
    required this.tags,
    required this.backendHint,
    required this.backendReady,
  });
}

class SupportMatchResult {
  final List<SupportMemberRecommendation> members;
  final List<SupportCommunityRecommendation> communities;
  final List<SupportRecommendationItem> recommendations;
  final List<CrisisResource> crisisResources;
  final EmbeddingRetrievalPlan retrievalPlan;
  final String source;

  const SupportMatchResult({
    required this.members,
    required this.communities,
    required this.recommendations,
    required this.crisisResources,
    required this.retrievalPlan,
    required this.source,
  });
}

class CheckInResult {
  final String submissionId;
  final CheckInSubmission submission;
  final EmotionalAnalysisResult analysis;
  final SupportMatchResult matching;
  final String status;
  final String? backendMessage;

  const CheckInResult({
    required this.submissionId,
    required this.submission,
    required this.analysis,
    required this.matching,
    required this.status,
    this.backendMessage,
  });
}
