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
    final adapter = remoteAdapter;
    if (adapter == null) {
      return fallback.analyze(request);
    }

    try {
      return await adapter.analyze(request);
    } catch (_) {
      return fallback.analyze(request);
    }
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
  ];

  static const _themeLexicon = <String, List<String>>{
    'academic pressure': ['study', 'exam', 'deadline', 'college', 'school'],
    'family stress': ['family', 'parent', 'home', 'mother', 'father'],
    'sleep disruption': ['sleep', 'night', 'insomnia', 'tired', 'awake'],
    'social anxiety': ['people', 'social', 'awkward', 'conversation'],
    'grief': ['grief', 'loss', 'miss them', 'funeral'],
    'burnout': ['burned out', 'burnout', 'exhausted', 'drained'],
    'self-worth': ['worthless', 'failure', 'not enough', 'ashamed'],
    'relationships': ['partner', 'breakup', 'relationship', 'friend'],
  };

  @override
  Future<EmotionalAnalysisResult> analyze(
    EmotionalAnalysisRequest request,
  ) async {
    final normalized = request.submission.content.toLowerCase();
    final riskMatches = _countMatches(normalized, _riskTerms);
    final heavyMoodMatches = _countMatches(normalized, _heavyMoodTerms);
    final positiveMatches = _countMatches(normalized, _positiveTerms);
    final highIntensityMatches = _countMatches(normalized, _highIntensityTerms);

    final themes = _extractThemes(normalized);
    final score =
        ((positiveMatches * 0.35) -
                (heavyMoodMatches * 0.42) -
                (riskMatches * 0.85))
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
            (heavyMoodMatches >= 3 ? 1 : 0))
        .clamp(1, 5);

    final emotionalLabels = _deriveEmotionalLabels(
      normalized: normalized,
      moodDirection: moodDirection,
      intensity: intensity,
      themes: themes,
      positiveMatches: positiveMatches,
    );

    final riskLevel = switch (riskMatches) {
      >= 2 => 'HIGH',
      1 => 'MEDIUM',
      _ when heavyMoodMatches >= 5 => 'MEDIUM',
      _ => 'LOW',
    };

    return EmotionalAnalysisResult(
      emotionalLabels: emotionalLabels,
      moodDirection: moodDirection,
      sentimentScore: score,
      intensity: intensity,
      intensityLabel: _intensityLabel(intensity),
      riskLevel: riskLevel,
      themes: themes.take(5).toList(),
      supportRecommendations: _buildSupportRecommendations(
        moodDirection: moodDirection,
        intensity: intensity,
        themes: themes,
        riskLevel: riskLevel,
      ),
      summary: _buildSummary(
        moodDirection: moodDirection,
        intensity: intensity,
        themes: themes,
        inputMode: request.submission.inputMode,
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
  }) {
    final labels = <String>{};

    if (normalized.contains('anxious') || normalized.contains('panic')) {
      labels.add('Anxious');
    }
    if (normalized.contains('overwhelmed') || intensity >= 4) {
      labels.add('Overwhelmed');
    }
    if (normalized.contains('sad') || normalized.contains('depressed')) {
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

  List<String> _buildSupportRecommendations({
    required MoodDirection moodDirection,
    required int intensity,
    required List<String> themes,
    required String riskLevel,
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
    required MoodDirection moodDirection,
    required int intensity,
    required List<String> themes,
    required CheckInInputMode inputMode,
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

    final themeNote = themes.isEmpty
        ? ''
        : ' Main themes: ${themes.take(3).join(', ')}.';

    final intensityNote = intensity >= 4
        ? ' Emotional intensity looks high, so recommendations should stay calm and immediate.'
        : '';

    return '$opener$themeNote $channelNote$intensityNote'.trim();
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
