import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/check_in_model.dart';

class EmotionalAnalysisRequest {
  final CheckInSubmission submission;

  const EmotionalAnalysisRequest({
    required this.submission,
  });
}

abstract class EmotionalAnalysisService {
  Future<EmotionalAnalysisResult> analyze(EmotionalAnalysisRequest request);
}

abstract class EmotionalAnalysisAdapter {
  Future<EmotionalAnalysisResult> analyze(EmotionalAnalysisRequest request);
}

class ResilientEmotionalAnalysisService implements EmotionalAnalysisService {
  final EmotionalAnalysisAdapter? remoteAdapter;
  final EmotionalAnalysisService fallback;

  const ResilientEmotionalAnalysisService({
    this.remoteAdapter,
    required this.fallback,
  });

  @override
  Future<EmotionalAnalysisResult> analyze(
    EmotionalAnalysisRequest request,
  ) async {
    final localResult = await fallback.analyze(request);
    final adapter = remoteAdapter;
    if (adapter == null) {
      return localResult;
    }

    try {
      final remoteResult = await adapter.analyze(request);
      return _mergeResults(
        remote: remoteResult,
        local: localResult,
      );
    } catch (_) {
      return localResult;
    }
  }

  EmotionalAnalysisResult _mergeResults({
    required EmotionalAnalysisResult remote,
    required EmotionalAnalysisResult local,
  }) {
    final preferLocalSentiment =
        _isGenericSentiment(remote.sentimentLabel) &&
            !_isGenericSentiment(local.sentimentLabel);
    final preferLocalSupportCategory =
        remote.supportCategory == SupportCategory.generalSupport &&
            local.supportCategory != SupportCategory.generalSupport;
    final preferLocalMoodDirection =
        remote.moodDirection == MoodDirection.steady &&
            local.moodDirection != MoodDirection.steady;
    final preferLocalThemes =
        remote.themes.isEmpty ||
            (remote.themes.length == 1 &&
                remote.themes.first == 'emotional processing' &&
                local.themes.isNotEmpty);

    final primaryEmotions =
        _hasSpecificEmotions(local.emotionalLabels) &&
            !_hasSpecificEmotions(remote.emotionalLabels)
        ? local.emotionalLabels
        : remote.emotionalLabels;
    final secondaryEmotions = identical(primaryEmotions, remote.emotionalLabels)
        ? local.emotionalLabels
        : remote.emotionalLabels;

    final emotionLabels = _mergeOrderedLabels(
      primaryEmotions,
      secondaryEmotions,
    );
    final themes = _mergeOrderedLabels(
      preferLocalThemes ? local.themes : remote.themes,
      preferLocalThemes ? remote.themes : local.themes,
      limit: 5,
    );
    final routingTags = _mergeOrderedLabels(
      [
        ...remote.routingTags,
        ...local.routingTags,
      ],
      const [],
      limit: 10,
    );
    final supportRecommendations = _mergeOrderedLabels(
      remote.supportRecommendations,
      local.supportRecommendations,
      limit: 4,
    );

    final intensity = math.max(remote.intensity, local.intensity);
    final sentimentScore = ((remote.sentimentScore + local.sentimentScore) / 2)
        .clamp(-1.0, 1.0)
        .toDouble();

    return EmotionalAnalysisResult(
      originalText: remote.originalText,
      sentimentLabel:
          preferLocalSentiment ? local.sentimentLabel : remote.sentimentLabel,
      emotionalLabels: emotionLabels.isEmpty ? remote.emotionalLabels : emotionLabels,
      moodDirection:
          preferLocalMoodDirection ? local.moodDirection : remote.moodDirection,
      sentimentScore: sentimentScore,
      intensity: intensity,
      intensityLabel: intensity >= 5
          ? 'High'
          : intensity >= 4
              ? 'Elevated'
              : intensity >= 3
                  ? 'Moderate'
                  : 'Gentle',
      riskLevel: _preferHigherRiskLevel(remote.riskLevel, local.riskLevel),
      supportNeedLevel:
          remote.supportNeedLevel.index >= local.supportNeedLevel.index
          ? remote.supportNeedLevel
          : local.supportNeedLevel,
      supportCategory: preferLocalSupportCategory
          ? local.supportCategory
          : remote.supportCategory,
      userCategory: remote.userCategory != UserCategory.unspecified
          ? remote.userCategory
          : local.userCategory,
      userCategoryEvidence:
          remote.userCategoryEvidence ?? local.userCategoryEvidence,
      themes: themes,
      routingTags: routingTags,
      supportRecommendations: supportRecommendations,
      summary: preferLocalSentiment || preferLocalThemes
          ? local.summary
          : remote.summary,
      source: remote.source == local.source
          ? remote.source
          : 'hybrid-emotion-analysis',
      usedFallback: remote.usedFallback,
    );
  }

  bool _isGenericSentiment(String label) {
    return label == 'Mixed' || label == 'Heavy' || label == 'Positive';
  }

  bool _hasSpecificEmotions(List<String> labels) {
    return labels.any(
      (label) => !const {
        'Mixed',
        'Heavy',
        'Steadier',
        'Hopeful',
      }.contains(label),
    );
  }

  List<String> _mergeOrderedLabels(
    List<String> primary,
    List<String> secondary, {
    int limit = 3,
  }) {
    final values = <String>[];
    for (final label in [...primary, ...secondary]) {
      if (label.trim().isEmpty || values.contains(label)) continue;
      values.add(label);
      if (values.length == limit) break;
    }
    return values;
  }

  String _preferHigherRiskLevel(String a, String b) {
    const order = {
      'LOW': 0,
      'MEDIUM': 1,
      'HIGH': 2,
    };
    return (order[a] ?? 0) >= (order[b] ?? 0) ? a : b;
  }
}

class LocalEmotionalAnalysisService implements EmotionalAnalysisService {
  const LocalEmotionalAnalysisService();

  static const _riskTerms = [
    'suicide',
    'kill myself',
    'self harm',
    'hurt myself',
    'end it',
    'don\'t want to live',
    'hopeless',
    'worthless',
    'i want to disappear',
  ];

  static const _heavyMoodTerms = [
    'bad',
    'sad',
    'anxious',
    'overwhelmed',
    'tired',
    'alone',
    'stressed',
    'burned out',
    'panic',
    'scared',
    'crying',
    'depressed',
    'lonely',
    'drained',
    'numb',
    'ashamed',
    'frustrated',
    'frustrating',
    'angry',
    'irritated',
    'annoyed',
    'upset',
    'rough day',
    'terrible',
    'awful',
    'exhausted',
  ];

  static const _positiveTerms = [
    'better',
    'hopeful',
    'grateful',
    'calm',
    'good',
    'great',
    'happy',
    'proud',
    'excited',
    'relieved',
    'peaceful',
    'steady',
  ];

  static const _highIntensityTerms = [
    'can\'t stop',
    'racing',
    'restless',
    'shaking',
    'spiraling',
    'panic',
    'urgent',
    'breaking down',
    'falling apart',
    'overwhelmed',
    'frustrated',
    'upset',
  ];

  static const _themeLexicon = <String, List<String>>{
    'academic pressure': ['study', 'exam', 'deadline', 'college', 'school'],
    'family stress': ['family', 'parent', 'home', 'mother', 'father'],
    'sleep disruption': ['sleep', 'night', 'insomnia', 'tired', 'awake'],
    'social anxiety': ['people', 'social', 'awkward', 'conversation', 'judge me'],
    'grief': ['grief', 'loss', 'miss them', 'funeral'],
    'burnout': [
      'burned out',
      'burnout',
      'exhausted',
      'drained',
      'overworked',
      'too much work',
      'work pressure',
    ],
    'self-worth': ['worthless', 'failure', 'not enough', 'ashamed'],
    'relationships': ['partner', 'breakup', 'relationship', 'friend', 'argument'],
    'connection': ['alone', 'lonely', 'need someone', 'talk to someone'],
    'emotional processing': [
      'bad day',
      'rough day',
      'frustrated day',
      'trying to process',
      'mixed feelings',
    ],
  };

  static const _emotionCueLexicon = <String, List<String>>{
    'Frustrated': [
      'frustrated',
      'frustrating',
      'fed up',
      'annoyed',
      'irritated',
      'upset',
      'on my nerves',
      'bad day',
      'rough day',
    ],
    'Anxious': [
      'anxious',
      'worried',
      'nervous',
      'on edge',
      'panic',
      'mind racing',
      'restless',
      'tense',
    ],
    'Overwhelmed': [
      'overwhelmed',
      'too much',
      'cannot keep up',
      'can\'t keep up',
      'stressed',
      'pressure',
      'drowning',
      'breaking down',
    ],
    'Low': [
      'bad',
      'sad',
      'down',
      'terrible',
      'awful',
      'miserable',
      'depressed',
      'drained',
      'hopeless',
    ],
    'Lonely': [
      'alone',
      'lonely',
      'isolated',
      'nobody understands',
      'no one understands',
      'wish someone would talk',
    ],
    'Burned Out': [
      'burned out',
      'burnout',
      'exhausted',
      'worn out',
      'emotionally drained',
      'used up',
      'overworked',
    ],
    'Hopeful': [
      'hopeful',
      'grateful',
      'better',
      'relieved',
      'calm',
      'steady',
      'okay',
    ],
  };

  static const _studentTerms = [
    'student',
    'study',
    'studying',
    'exam',
    'class',
    'college',
    'school',
    'university',
    'campus',
    'semester',
    'assignment',
    'homework',
  ];

  static const _professionalTerms = [
    'work',
    'job',
    'office',
    'manager',
    'coworker',
    'career',
    'meeting',
    'client',
    'shift',
    'corporate',
  ];

  static const _caregiverTerms = [
    'caregiver',
    'taking care of',
    'my kids',
    'my child',
    'new mom',
    'new dad',
    'parenting',
  ];

  @override
  Future<EmotionalAnalysisResult> analyze(
    EmotionalAnalysisRequest request,
  ) async {
    final normalized = request.submission.content.toLowerCase();
    final riskMatches = _countMatches(normalized, _riskTerms);
    final heavyMoodMatches = _countMatches(normalized, _heavyMoodTerms);
    final positiveMatches = _countMatches(normalized, _positiveTerms);
    final highIntensityMatches = _countMatches(normalized, _highIntensityTerms);
    final emotionScores = _scoreEmotionCues(normalized);

    final themes = _extractThemes(normalized);
    final userCategorySignal = _inferUserCategory(normalized);
    final emotionPenalty = ((emotionScores['Frustrated'] ?? 0) * 0.08) +
        ((emotionScores['Anxious'] ?? 0) * 0.08) +
        ((emotionScores['Overwhelmed'] ?? 0) * 0.1) +
        ((emotionScores['Low'] ?? 0) * 0.08) +
        ((emotionScores['Lonely'] ?? 0) * 0.07) +
        ((emotionScores['Burned Out'] ?? 0) * 0.09);
    final score =
        ((positiveMatches * 0.35) -
                (heavyMoodMatches * 0.42) -
                (riskMatches * 0.85) -
                emotionPenalty)
            .clamp(-1.0, 1.0)
            .toDouble();

    final moodDirection = switch (score) {
      >= 0.35 => MoodDirection.upward,
      <= -0.35 => MoodDirection.downward,
      _ => MoodDirection.steady,
    };

    final intensity = (1 +
            riskMatches +
            highIntensityMatches +
            (request.submission.content.length > 180 ? 1 : 0) +
            (heavyMoodMatches >= 2 ? 1 : 0) +
            ((emotionScores['Overwhelmed'] ?? 0) >= 1.5 ? 1 : 0) +
            ((emotionScores['Burned Out'] ?? 0) >= 1.2 ? 1 : 0) +
            ((normalized.contains('frustrated') ||
                    normalized.contains('upset') ||
                    normalized.contains('angry'))
                ? 1
                : 0))
        .clamp(1, 5);

    final emotionalLabels = _deriveEmotionalLabels(
      normalized: normalized,
      moodDirection: moodDirection,
      intensity: intensity,
      themes: themes,
      positiveMatches: positiveMatches,
      emotionScores: emotionScores,
    );

    final riskLevel = switch (riskMatches) {
      >= 2 => 'HIGH',
      1 => 'MEDIUM',
      _ when heavyMoodMatches >= 5 => 'MEDIUM',
      _ => 'LOW',
    };

    final supportNeedLevel = _deriveSupportNeedLevel(
      riskLevel: riskLevel,
      intensity: intensity,
      moodDirection: moodDirection,
    );
    final supportCategory = _deriveSupportCategory(
      userCategory: userCategorySignal.category,
      themes: themes,
      riskLevel: riskLevel,
    );
    final sentimentLabel = _deriveSentimentLabel(
      riskLevel: riskLevel,
      score: score,
      moodDirection: moodDirection,
      intensity: intensity,
      emotionScores: emotionScores,
    );
    final routingTags = <String>{
      ...themes,
      ...emotionalLabels.map((label) => label.toLowerCase()),
      supportCategory.label.toLowerCase(),
      if (userCategorySignal.category != UserCategory.unspecified)
        userCategorySignal.category.label.toLowerCase(),
    }.toList();

    return EmotionalAnalysisResult(
      originalText: request.submission.content,
      sentimentLabel: sentimentLabel,
      emotionalLabels: emotionalLabels,
      moodDirection: moodDirection,
      sentimentScore: score,
      intensity: intensity,
      intensityLabel: _intensityLabel(intensity),
      riskLevel: riskLevel,
      supportNeedLevel: supportNeedLevel,
      supportCategory: supportCategory,
      userCategory: userCategorySignal.category,
      userCategoryEvidence: userCategorySignal.evidence,
      themes: themes.take(5).toList(),
      routingTags: routingTags,
      supportRecommendations: _buildSupportRecommendations(
        moodDirection: moodDirection,
        intensity: intensity,
        themes: themes,
        riskLevel: riskLevel,
        supportCategory: supportCategory,
        userCategory: userCategorySignal.category,
      ),
      summary: _buildSummary(
        sentimentLabel: sentimentLabel,
        moodDirection: moodDirection,
        intensity: intensity,
        themes: themes,
        inputMode: request.submission.inputMode,
        supportCategory: supportCategory,
        userCategory: userCategorySignal.category,
      ),
      source: 'local-heuristic-analyzer',
      usedFallback: true,
    );
  }

  int _countMatches(String text, List<String> patterns) {
    return patterns.where(text.contains).length;
  }

  List<String> _extractThemes(String normalized) {
    final themes = <String>[];
    for (final entry in _themeLexicon.entries) {
      if (entry.value.any(normalized.contains)) {
        themes.add(entry.key);
      }
    }
    if (themes.isEmpty) {
      themes.add(
        normalized.contains('alone') || normalized.contains('lonely')
            ? 'connection'
            : 'emotional processing',
      );
    }
    return themes;
  }

  List<String> _deriveEmotionalLabels({
    required String normalized,
    required MoodDirection moodDirection,
    required int intensity,
    required List<String> themes,
    required int positiveMatches,
    required Map<String, double> emotionScores,
  }) {
    final labels = <String>{};

    final rankedEmotionScores = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in rankedEmotionScores) {
      if (entry.value >= 1.0) {
        labels.add(entry.key);
      }
      if (labels.length == 3) break;
    }

    if (normalized.contains('anxious') || normalized.contains('panic')) {
      labels.add('Anxious');
    }
    if (normalized.contains('frustrated') ||
        normalized.contains('frustrating') ||
        normalized.contains('annoyed')) {
      labels.add('Frustrated');
    }
    if (normalized.contains('angry') || normalized.contains('irritated')) {
      labels.add('Angry');
    }
    if (normalized.contains('overwhelmed') || intensity >= 4) {
      labels.add('Overwhelmed');
    }
    if (normalized.contains('sad') ||
        normalized.contains('depressed') ||
        normalized.contains('bad') ||
        normalized.contains('awful') ||
        normalized.contains('terrible')) {
      labels.add('Low');
    }
    if (normalized.contains('lonely') || normalized.contains('alone')) {
      labels.add('Lonely');
    }
    if (positiveMatches > 0) {
      labels.add('Hopeful');
    }
    if (themes.contains('burnout')) {
      labels.add('Burned Out');
    }

    if (labels.isEmpty) {
      labels.add(
        switch (moodDirection) {
          MoodDirection.upward => 'Steadier',
          MoodDirection.steady => 'Mixed',
          MoodDirection.downward => 'Heavy',
        },
      );
    }

    return labels.take(3).toList();
  }

  Map<String, double> _scoreEmotionCues(String normalized) {
    final scores = <String, double>{};
    for (final entry in _emotionCueLexicon.entries) {
      var score = 0.0;
      for (final pattern in entry.value) {
        if (!normalized.contains(pattern)) continue;
        score += pattern.contains(' ') ? 0.9 : 0.65;
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    if (normalized.contains('bad') &&
        (normalized.contains('frustrated') || normalized.contains('upset'))) {
      scores['Frustrated'] = (scores['Frustrated'] ?? 0) + 0.6;
      scores['Low'] = (scores['Low'] ?? 0) + 0.4;
    }
    if (normalized.contains('stressed') &&
        (normalized.contains('work') || normalized.contains('job'))) {
      scores['Burned Out'] = (scores['Burned Out'] ?? 0) + 0.7;
      scores['Overwhelmed'] = (scores['Overwhelmed'] ?? 0) + 0.5;
    }
    if (normalized.contains('alone') && normalized.contains('bad')) {
      scores['Lonely'] = (scores['Lonely'] ?? 0) + 0.5;
    }

    return scores;
  }

  List<String> _buildSupportRecommendations({
    required MoodDirection moodDirection,
    required int intensity,
    required List<String> themes,
    required String riskLevel,
    required SupportCategory supportCategory,
    required UserCategory userCategory,
  }) {
    final recommendations = <String>[
      if (themes.contains('academic pressure'))
        'Try naming the one deadline or task that feels heaviest first.',
      if (themes.contains('family stress'))
        'A short boundary or distance reset may help before your next conversation.',
      if (themes.contains('sleep disruption'))
        'A low-stimulation wind-down can help before the next check-in tonight.',
      if (themes.contains('connection'))
        'A live group or one supportive peer may feel better than sitting with this alone.',
      if (supportCategory == SupportCategory.burnoutSupport)
        'Aim for spaces that understand work fatigue instead of generic advice.',
      if (userCategory == UserCategory.under18)
        'We will route you toward youth-safe spaces before one-to-one chat suggestions.',
    ];

    if (riskLevel == 'HIGH') {
      recommendations.insert(
        0,
        'Please reach out to immediate crisis support or someone nearby you trust.',
      );
    } else if (intensity >= 4) {
      recommendations.insert(
        0,
        'Try one grounding step before replying to anyone else.',
      );
    } else if (moodDirection == MoodDirection.upward) {
      recommendations.insert(
        0,
        'Notice what helped today so you can come back to it later.',
      );
    } else {
      recommendations.insert(
        0,
        'Share one more concrete detail so others can support you more specifically.',
      );
    }

    return recommendations.take(4).toList();
  }

  String _buildSummary({
    required String sentimentLabel,
    required MoodDirection moodDirection,
    required int intensity,
    required List<String> themes,
    required CheckInInputMode inputMode,
    required SupportCategory supportCategory,
    required UserCategory userCategory,
  }) {
    final opener = switch (moodDirection) {
      MoodDirection.upward =>
        'Your check-in sounds more grounded, with a few strengths worth holding onto.',
      MoodDirection.steady =>
        'Your check-in carries mixed emotions and a real need for understanding.',
      MoodDirection.downward =>
        'Your check-in sounds emotionally heavy and worth responding to with care.',
    };

    final channelNote = inputMode == CheckInInputMode.voice
        ? 'Because this came through voice, preserving your exact phrasing may help matching feel more human.'
        : 'The written detail gives us helpful signal for matching you to the right kind of support.';

    final identityNote = userCategory == UserCategory.unspecified
        ? ''
        : ' We picked a ${userCategory.label.toLowerCase()}-aware route.';
    final themeNote = themes.isEmpty
        ? ''
        : ' Main themes: ${themes.take(3).join(', ')}.';
    final routeNote =
        ' Suggested path: ${supportCategory.label.toLowerCase()}.';

    final intensityNote = intensity >= 4
        ? ' Emotional intensity looks high, so recommendations should stay calm and immediate.'
        : '';

    return '$opener $sentimentLabel tone detected.$themeNote $channelNote$identityNote$routeNote$intensityNote'
        .trim();
  }

  String _intensityLabel(int intensity) {
    switch (intensity) {
      case 1:
      case 2:
        return 'Gentle';
      case 3:
        return 'Moderate';
      case 4:
        return 'Elevated';
      case 5:
        return 'High';
    }
    return 'Moderate';
  }

  _UserCategorySignal _inferUserCategory(String normalized) {
    final ageMatch = RegExp(
      r"\b(?:i am|i'm|im)\s*(1[3-7])\b|\b(1[3-7])\s*(?:years old|year old|yo)\b|\bunder 18\b|\bminor\b|\bteenager\b",
    ).firstMatch(normalized);
    if (ageMatch != null) {
      return _UserCategorySignal(
        category: UserCategory.under18,
        evidence: ageMatch.group(0),
      );
    }

    final studentMatch = _studentTerms.firstWhere(
      normalized.contains,
      orElse: () => '',
    );
    if (studentMatch.isNotEmpty) {
      return _UserCategorySignal(
        category: UserCategory.student,
        evidence: studentMatch,
      );
    }

    final professionalMatch = _professionalTerms.firstWhere(
      normalized.contains,
      orElse: () => '',
    );
    if (professionalMatch.isNotEmpty) {
      return _UserCategorySignal(
        category: UserCategory.professional,
        evidence: professionalMatch,
      );
    }

    final caregiverMatch = _caregiverTerms.firstWhere(
      normalized.contains,
      orElse: () => '',
    );
    if (caregiverMatch.isNotEmpty) {
      return _UserCategorySignal(
        category: UserCategory.caregiver,
        evidence: caregiverMatch,
      );
    }

    return const _UserCategorySignal(category: UserCategory.unspecified);
  }

  SupportNeedLevel _deriveSupportNeedLevel({
    required String riskLevel,
    required int intensity,
    required MoodDirection moodDirection,
  }) {
    if (riskLevel == 'HIGH') return SupportNeedLevel.urgent;
    if (riskLevel == 'MEDIUM' || intensity >= 4) {
      return SupportNeedLevel.high;
    }
    if (moodDirection == MoodDirection.downward || intensity >= 3) {
      return SupportNeedLevel.medium;
    }
    return SupportNeedLevel.low;
  }

  SupportCategory _deriveSupportCategory({
    required UserCategory userCategory,
    required List<String> themes,
    required String riskLevel,
  }) {
    if (riskLevel == 'HIGH') return SupportCategory.crisisSupport;
    if (userCategory == UserCategory.under18) {
      return SupportCategory.youthSupport;
    }
    if (themes.contains('academic pressure')) {
      return SupportCategory.academicStress;
    }
    if (themes.contains('burnout') ||
        userCategory == UserCategory.professional) {
      return SupportCategory.burnoutSupport;
    }
    if (themes.contains('family stress')) {
      return SupportCategory.familySupport;
    }
    if (themes.contains('grief')) {
      return SupportCategory.griefSupport;
    }
    if (themes.contains('sleep disruption')) {
      return SupportCategory.sleepSupport;
    }
    if (themes.contains('social anxiety')) {
      return SupportCategory.socialSupport;
    }
    if (themes.contains('self-worth')) {
      return SupportCategory.selfWorthSupport;
    }
    if (themes.contains('relationships') ||
        themes.contains('connection') ||
        themes.contains('emotional processing')) {
      return SupportCategory.peerSupport;
    }
    return SupportCategory.generalSupport;
  }

  String _deriveSentimentLabel({
    required String riskLevel,
    required double score,
    required MoodDirection moodDirection,
    required int intensity,
    required Map<String, double> emotionScores,
  }) {
    if (riskLevel == 'HIGH') return 'Distressed';
    if ((emotionScores['Frustrated'] ?? 0) >= 1.2) return 'Frustrated';
    if ((emotionScores['Anxious'] ?? 0) >= 1.2) return 'Anxious';
    if ((emotionScores['Burned Out'] ?? 0) >= 1.2) return 'Burned Out';
    if ((emotionScores['Lonely'] ?? 0) >= 1.2) return 'Lonely';
    if (score >= 0.35) return 'Positive';
    if (moodDirection == MoodDirection.downward || intensity >= 4) {
      return 'Heavy';
    }
    return 'Mixed';
  }
}

class _UserCategorySignal {
  final UserCategory category;
  final String? evidence;

  const _UserCategorySignal({
    required this.category,
    this.evidence,
  });
}

class BedrockEmotionalAnalysisAdapter implements EmotionalAnalysisAdapter {
  const BedrockEmotionalAnalysisAdapter();

  @override
  Future<EmotionalAnalysisResult> analyze(
    EmotionalAnalysisRequest request,
  ) {
    // TODO: Plug teammate Bedrock emotional-analysis integration here.
    // Keep the request/response shape stable to minimize merge conflicts.
    throw UnimplementedError('Bedrock emotional analysis is not wired yet.');
  }
}

class HuggingFaceEmbeddingEmotionalAnalysisAdapter
    implements EmotionalAnalysisAdapter {
  static const String _defaultEndpoint = String.fromEnvironment(
    'HF_EMBEDDING_ENDPOINT',
    defaultValue:
        'https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2',
  );
  static const String _defaultApiToken = String.fromEnvironment(
    'HF_API_TOKEN',
    defaultValue: '',
  );

  static const Map<String, List<String>> _emotionAnchors = {
    'Frustrated': [
      'I feel frustrated and irritated with how the day went',
      'It was a bad and frustrating day',
      'Everything kept going wrong and it got on my nerves',
    ],
    'Overwhelmed': [
      'I feel overwhelmed and stretched too thin',
      'There is too much pressure on me right now',
      'I cannot keep up with everything today',
    ],
    'Low': [
      'I feel emotionally low and heavy',
      'It was a bad day and I feel down',
      'I feel sad, drained, and discouraged',
    ],
    'Anxious': [
      'I feel anxious and on edge',
      'My mind is racing and I cannot relax',
      'I feel tense and worried all day',
    ],
    'Lonely': [
      'I feel alone and disconnected',
      'I feel lonely and like nobody understands',
      'I wish someone would talk to me right now',
    ],
    'Burned Out': [
      'I feel burned out and exhausted',
      'I have no energy left after all this pressure',
      'I feel mentally drained and worn out',
    ],
    'Hopeful': [
      'I feel hopeful and a little better',
      'Things are improving and I feel steadier',
      'I feel grateful and more okay today',
    ],
  };

  static const Map<String, List<String>> _themeAnchors = {
    'academic pressure': [
      'I am stressed about exams and studying',
      'School deadlines and classes are overwhelming me',
    ],
    'family stress': [
      'My family situation is emotionally exhausting',
      'Pressure at home is making me feel worse',
    ],
    'sleep disruption': [
      'I cannot sleep and my nights feel restless',
      'I am tired because my sleep is broken',
    ],
    'social anxiety': [
      'Talking to people makes me nervous and awkward',
      'Social situations are making me anxious',
    ],
    'grief': [
      'I miss someone deeply and the loss feels heavy',
      'I am grieving and carrying sadness after a loss',
    ],
    'burnout': [
      'Work stress is causing burnout and exhaustion',
      'I feel overworked and emotionally drained',
    ],
    'self-worth': [
      'I feel like I am not enough and I keep doubting myself',
      'I feel worthless and ashamed today',
    ],
    'relationships': [
      'Relationship stress is making today feel worse',
      'A breakup or conflict with someone close is weighing on me',
    ],
    'connection': [
      'I need someone to talk to because today feels bad',
      'I want support and connection instead of being alone with this',
    ],
    'emotional processing': [
      'I had a rough emotional day and need space to process it',
      'I am trying to understand what I am feeling right now',
    ],
  };

  static const List<String> _positiveAnchors = [
    'I feel hopeful and supported',
    'Today feels calmer and better',
    'I feel grateful and steady',
  ];

  static const List<String> _negativeAnchors = [
    'I feel bad and emotionally heavy',
    'I feel frustrated and upset',
    'Today feels overwhelming and exhausting',
    'I feel lonely and low',
  ];

  static const List<String> _highIntensityAnchors = [
    'I am spiraling and everything feels too intense',
    'My emotions feel very strong and hard to manage',
    'I feel like I am falling apart today',
  ];

  final String endpoint;
  final String apiToken;
  final http.Client? client;

  const HuggingFaceEmbeddingEmotionalAnalysisAdapter({
    this.endpoint = _defaultEndpoint,
    this.apiToken = _defaultApiToken,
    this.client,
  });

  @override
  Future<EmotionalAnalysisResult> analyze(
    EmotionalAnalysisRequest request,
  ) async {
    const local = LocalEmotionalAnalysisService();
    final normalized = request.submission.content.toLowerCase().trim();
    if (normalized.isEmpty) {
      throw StateError('Cannot analyze empty check-in content.');
    }

    final emotionEntries = _emotionAnchors.entries.toList(growable: false);
    final themeEntries = _themeAnchors.entries.toList(growable: false);

    final inputs = <String>[
      request.submission.content,
      ...emotionEntries.expand((entry) => entry.value),
      ...themeEntries.expand((entry) => entry.value),
      ..._positiveAnchors,
      ..._negativeAnchors,
      ..._highIntensityAnchors,
    ];

    final embeddings = await _fetchEmbeddings(inputs);
    if (embeddings.length != inputs.length) {
      throw StateError('Embedding response shape did not match request inputs.');
    }

    final queryEmbedding = embeddings.first;
    var offset = 1;

    final emotionScores = <String, double>{};
    for (final entry in emotionEntries) {
      final vectors = embeddings.sublist(offset, offset + entry.value.length);
      offset += entry.value.length;
      emotionScores[entry.key] = _aggregateSimilarity(queryEmbedding, vectors);
    }

    final themeScores = <String, double>{};
    for (final entry in themeEntries) {
      final vectors = embeddings.sublist(offset, offset + entry.value.length);
      offset += entry.value.length;
      themeScores[entry.key] = _aggregateSimilarity(queryEmbedding, vectors);
    }

    final positiveScore = _aggregateSimilarity(
      queryEmbedding,
      embeddings.sublist(offset, offset + _positiveAnchors.length),
    );
    offset += _positiveAnchors.length;
    final negativeScore = _aggregateSimilarity(
      queryEmbedding,
      embeddings.sublist(offset, offset + _negativeAnchors.length),
    );
    offset += _negativeAnchors.length;
    final intensitySemanticScore = _aggregateSimilarity(
      queryEmbedding,
      embeddings.sublist(offset, offset + _highIntensityAnchors.length),
    );

    final riskMatches = local._countMatches(
      normalized,
      LocalEmotionalAnalysisService._riskTerms,
    );
    final lexicalHeavyMoodMatches = local._countMatches(
      normalized,
      LocalEmotionalAnalysisService._heavyMoodTerms,
    );
    final positiveMatches = local._countMatches(
      normalized,
      LocalEmotionalAnalysisService._positiveTerms,
    );
    final userCategorySignal = local._inferUserCategory(normalized);

    final sentimentScore = ((positiveScore + (positiveMatches * 0.08)) -
            (negativeScore + (lexicalHeavyMoodMatches * 0.06)) -
            (riskMatches * 0.12))
        .clamp(-1.0, 1.0)
        .toDouble();

    final moodDirection = switch (sentimentScore) {
      >= 0.2 => MoodDirection.upward,
      <= -0.2 => MoodDirection.downward,
      _ => MoodDirection.steady,
    };

    final semanticEmotionLabels = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final emotionalLabels = <String>{
      ...semanticEmotionLabels
          .where((entry) => entry.value >= 0.38)
          .take(3)
          .map((entry) => entry.key),
      ...local._deriveEmotionalLabels(
        normalized: normalized,
        moodDirection: moodDirection,
        intensity: 3,
        themes: const [],
        positiveMatches: positiveMatches,
        emotionScores: emotionScores,
      ),
    }.take(3).toList();

    final semanticThemes = themeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final themes = {
      ...semanticThemes
          .where((entry) => entry.value >= 0.34)
          .take(4)
          .map((entry) => entry.key),
      ...local._extractThemes(normalized),
    }.take(5).toList();

    final rawIntensity = 1 +
        (riskMatches > 0 ? 2 : 0) +
        (intensitySemanticScore >= 0.55 ? 2 : intensitySemanticScore >= 0.42 ? 1 : 0) +
        (normalized.contains('!') ? 1 : 0) +
        (lexicalHeavyMoodMatches >= 2 ? 1 : 0);
    final intensity = rawIntensity.clamp(1, 5);

    final riskLevel = switch (riskMatches) {
      >= 2 => 'HIGH',
      1 => 'MEDIUM',
      _ when negativeScore >= 0.72 && intensity >= 4 => 'MEDIUM',
      _ => 'LOW',
    };

    final supportNeedLevel = local._deriveSupportNeedLevel(
      riskLevel: riskLevel,
      intensity: intensity,
      moodDirection: moodDirection,
    );
    final supportCategory = local._deriveSupportCategory(
      userCategory: userCategorySignal.category,
      themes: themes,
      riskLevel: riskLevel,
    );
    final sentimentLabel = _semanticSentimentLabel(
      negativeScore: negativeScore,
      positiveScore: positiveScore,
      sentimentScore: sentimentScore,
      intensity: intensity,
      riskLevel: riskLevel,
      emotionScores: emotionScores,
    );

    final routingTags = <String>{
      ...themes,
      ...emotionalLabels.map((label) => label.toLowerCase()),
      supportCategory.label.toLowerCase(),
      if (userCategorySignal.category != UserCategory.unspecified)
        userCategorySignal.category.label.toLowerCase(),
    }.toList();

    return EmotionalAnalysisResult(
      originalText: request.submission.content,
      sentimentLabel: sentimentLabel,
      emotionalLabels: emotionalLabels.isEmpty ? ['Mixed'] : emotionalLabels,
      moodDirection: moodDirection,
      sentimentScore: sentimentScore,
      intensity: intensity,
      intensityLabel: local._intensityLabel(intensity),
      riskLevel: riskLevel,
      supportNeedLevel: supportNeedLevel,
      supportCategory: supportCategory,
      userCategory: userCategorySignal.category,
      userCategoryEvidence: userCategorySignal.evidence,
      themes: themes,
      routingTags: routingTags,
      supportRecommendations: local._buildSupportRecommendations(
        moodDirection: moodDirection,
        intensity: intensity,
        themes: themes,
        riskLevel: riskLevel,
        supportCategory: supportCategory,
        userCategory: userCategorySignal.category,
      ),
      summary: local._buildSummary(
        sentimentLabel: sentimentLabel,
        moodDirection: moodDirection,
        intensity: intensity,
        themes: themes,
        inputMode: request.submission.inputMode,
        supportCategory: supportCategory,
        userCategory: userCategorySignal.category,
      ),
      source: 'huggingface-embedding-analyzer',
      usedFallback: false,
    );
  }

  Future<List<List<double>>> _fetchEmbeddings(List<String> inputs) async {
    final httpClient = client ?? http.Client();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (apiToken.isNotEmpty) 'Authorization': 'Bearer $apiToken',
    };

    try {
      final response = await httpClient.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode({
          'inputs': inputs,
          'options': {'wait_for_model': true},
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Hugging Face embedding request failed: ${response.statusCode} ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      return _coerceEmbeddings(decoded);
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  List<List<double>> _coerceEmbeddings(dynamic decoded) {
    if (decoded is! List || decoded.isEmpty) {
      throw StateError('Unexpected Hugging Face embedding payload.');
    }

    if (decoded.first is num) {
      return [
        decoded.map((value) => (value as num).toDouble()).toList(),
      ];
    }

    final items = <List<double>>[];
    for (final item in decoded) {
      if (item is List && item.isNotEmpty && item.first is num) {
        items.add(item.map((value) => (value as num).toDouble()).toList());
        continue;
      }
      if (item is List && item.isNotEmpty && item.first is List) {
        items.add(_meanPool(item));
        continue;
      }
      throw StateError('Unsupported embedding shape from Hugging Face.');
    }
    return items;
  }

  List<double> _meanPool(List<dynamic> tokenVectors) {
    final vectors = tokenVectors
        .whereType<List>()
        .map(
          (vector) => vector.map((value) => (value as num).toDouble()).toList(),
        )
        .toList();
    if (vectors.isEmpty) {
      throw StateError('Cannot mean-pool an empty embedding response.');
    }

    final width = vectors.first.length;
    final pooled = List<double>.filled(width, 0);
    for (final vector in vectors) {
      for (var i = 0; i < width; i++) {
        pooled[i] += vector[i];
      }
    }
    return pooled.map((value) => value / vectors.length).toList();
  }

  double _aggregateSimilarity(
    List<double> query,
    List<List<double>> candidates,
  ) {
    if (candidates.isEmpty) return 0;

    final scores = candidates.map((vector) => _cosineSimilarity(query, vector)).toList()
      ..sort();
    return scores.last;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;

    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dot / math.sqrt(normA * normB);
  }

  String _semanticSentimentLabel({
    required double negativeScore,
    required double positiveScore,
    required double sentimentScore,
    required int intensity,
    required String riskLevel,
    required Map<String, double> emotionScores,
  }) {
    if (riskLevel == 'HIGH') return 'Distressed';
    if ((emotionScores['Frustrated'] ?? 0) >= 0.46) return 'Frustrated';
    if ((emotionScores['Anxious'] ?? 0) >= 0.46) return 'Anxious';
    if (positiveScore >= 0.5 && sentimentScore > 0) return 'Positive';
    if (negativeScore >= 0.48 || intensity >= 4 || sentimentScore <= -0.25) {
      return 'Heavy';
    }
    return 'Mixed';
  }
}
