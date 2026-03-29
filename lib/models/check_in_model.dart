import 'post_model.dart';

enum CheckInInputMode { text, voice }

enum MoodDirection { upward, steady, downward }

enum SupportNeedLevel { low, medium, high, urgent }

enum UserCategory {
  unspecified,
  student,
  professional,
  under18,
  caregiver,
}

enum SupportCategory {
  generalSupport,
  peerSupport,
  academicStress,
  burnoutSupport,
  youthSupport,
  familySupport,
  griefSupport,
  sleepSupport,
  selfWorthSupport,
  socialSupport,
  crisisSupport,
}

extension SupportNeedLevelX on SupportNeedLevel {
  String get label {
    switch (this) {
      case SupportNeedLevel.low:
        return 'Low';
      case SupportNeedLevel.medium:
        return 'Moderate';
      case SupportNeedLevel.high:
        return 'High';
      case SupportNeedLevel.urgent:
        return 'Urgent';
    }
  }
}

extension UserCategoryX on UserCategory {
  String get label {
    switch (this) {
      case UserCategory.unspecified:
        return 'General';
      case UserCategory.student:
        return 'Student';
      case UserCategory.professional:
        return 'Professional';
      case UserCategory.under18:
        return 'Under 18';
      case UserCategory.caregiver:
        return 'Caregiver';
    }
  }

  String get audienceDescriptor {
    switch (this) {
      case UserCategory.student:
        return 'Students dealing with similar pressure';
      case UserCategory.professional:
        return 'Working professionals facing similar stress';
      case UserCategory.under18:
        return 'Young people needing age-appropriate emotional support';
      case UserCategory.caregiver:
        return 'Caregivers carrying emotional load';
      case UserCategory.unspecified:
        return 'People with similar lived experience';
    }
  }
}

extension SupportCategoryX on SupportCategory {
  String get label {
    switch (this) {
      case SupportCategory.generalSupport:
        return 'General Support';
      case SupportCategory.peerSupport:
        return 'Peer Support';
      case SupportCategory.academicStress:
        return 'Academic Stress';
      case SupportCategory.burnoutSupport:
        return 'Burnout Support';
      case SupportCategory.youthSupport:
        return 'Youth Support';
      case SupportCategory.familySupport:
        return 'Family Support';
      case SupportCategory.griefSupport:
        return 'Grief Support';
      case SupportCategory.sleepSupport:
        return 'Sleep Support';
      case SupportCategory.selfWorthSupport:
        return 'Self-Worth Support';
      case SupportCategory.socialSupport:
        return 'Social Anxiety Support';
      case SupportCategory.crisisSupport:
        return 'Immediate Safety Support';
    }
  }
}

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
  final String originalText;
  final String sentimentLabel;
  final List<String> emotionalLabels;
  final MoodDirection moodDirection;
  final double sentimentScore;
  final int intensity;
  final String intensityLabel;
  final String riskLevel;
  final SupportNeedLevel supportNeedLevel;
  final SupportCategory supportCategory;
  final UserCategory userCategory;
  final String? userCategoryEvidence;
  final List<String> themes;
  final List<String> routingTags;
  final List<String> supportRecommendations;
  final String summary;
  final String source;
  final bool usedFallback;

  const EmotionalAnalysisResult({
    required this.originalText,
    required this.sentimentLabel,
    required this.emotionalLabels,
    required this.moodDirection,
    required this.sentimentScore,
    required this.intensity,
    required this.intensityLabel,
    required this.riskLevel,
    required this.supportNeedLevel,
    required this.supportCategory,
    required this.userCategory,
    required this.userCategoryEvidence,
    required this.themes,
    required this.routingTags,
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

  String get sourceLabel {
    if (usedFallback) return 'Local fallback';

    switch (source) {
      case 'huggingface-embedding-analyzer':
        return 'Hugging Face embeddings';
      case 'hybrid-emotion-analysis':
        return 'Hybrid analysis';
      case 'local-heuristic-analyzer':
        return 'Local analysis';
      default:
        return source;
    }
  }
  String get supportNeedLabel => supportNeedLevel.label;
  String get supportCategoryLabel => supportCategory.label;
  String get userCategoryLabel => userCategory.label;
  bool get hasExplicitUserCategory => userCategory != UserCategory.unspecified;
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
  final UserCategory audienceCategory;
  final bool directRequestAllowed;
  final String? safetyNote;

  const SupportMemberRecommendation({
    required this.id,
    required this.anonymousName,
    required this.similarityScore,
    required this.lastActive,
    required this.reason,
    required this.sharedThemes,
    this.audienceCategory = UserCategory.unspecified,
    this.directRequestAllowed = true,
    this.safetyNote,
  });
}

class SupportGroupRecommendation {
  final String id;
  final String title;
  final String description;
  final String identityDescriptor;
  final String linkedCommunityId;
  final List<String> matchedThemes;
  final String actionLabel;

  const SupportGroupRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.identityDescriptor,
    required this.linkedCommunityId,
    required this.matchedThemes,
    this.actionLabel = 'Open group',
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
  final SupportCategory supportCategory;
  final UserCategory audienceCategory;
  final String audienceDescriptor;

  const SupportCommunityRecommendation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.memberCount,
    required this.reason,
    required this.matchedThemes,
    this.supportCategory = SupportCategory.generalSupport,
    this.audienceCategory = UserCategory.unspecified,
    this.audienceDescriptor = 'People with similar lived experience',
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
  final List<SupportGroupRecommendation> groups;
  final List<SupportMemberRecommendation> members;
  final List<SupportCommunityRecommendation> communities;
  final List<SupportRecommendationItem> recommendations;
  final List<CrisisResource> crisisResources;
  final EmbeddingRetrievalPlan retrievalPlan;
  final String source;

  const SupportMatchResult({
    required this.groups,
    required this.members,
    required this.communities,
    required this.recommendations,
    required this.crisisResources,
    required this.retrievalPlan,
    required this.source,
  });

  List<String> get recommendedGroupIds =>
      groups.map((group) => group.id).toList(growable: false);
  List<String> get recommendedCommunityIds =>
      communities.map((community) => community.id).toList(growable: false);
  List<String> get recommendedPersonIds =>
      members.map((member) => member.id).toList(growable: false);
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
