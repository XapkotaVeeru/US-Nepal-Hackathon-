import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/micro_community_model.dart';

/// Placeholder — replace with your deployed sentiment API URL.
const String kEmotionAnalysisApiUrl =
    'https://your-ai-sentiment-api.example.com/analyze';

class EmotionAnalysis {
  final String sentimentLabel;
  final double sentimentScore;
  final String energy;
  final String recommendedGroup;
  final String riskLevel;
  final String summary;
  final List<String> keywords;
  final String source;

  const EmotionAnalysis({
    required this.sentimentLabel,
    required this.sentimentScore,
    required this.energy,
    required this.recommendedGroup,
    required this.riskLevel,
    required this.summary,
    required this.keywords,
    required this.source,
  });

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json) {
    final keywords = (json['keywords'] as List?)
            ?.map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    return EmotionAnalysis(
      sentimentLabel: json['sentiment_label']?.toString() ??
          json['sentiment']?.toString() ??
          'Mixed',
      sentimentScore:
          (json['sentiment_score'] as num?)?.toDouble() ??
              (json['score'] as num?)?.toDouble() ??
              0,
      energy: json['energy']?.toString() ?? 'Steady',
      recommendedGroup: json['recommended_group']?.toString() ?? 'Self-Care Squad',
      riskLevel: json['risk_level']?.toString() ?? 'LOW',
      summary: json['summary']?.toString() ?? 'You shared something meaningful.',
      keywords: keywords,
      source: json['source']?.toString() ?? 'remote',
    );
  }
}

class EmotionService {
  EmotionService._();

  /// Sends [text] to the sentiment API and returns structured results.
  static Future<EmotionAnalysis> analyzeEmotion(String text) async {
    if (kEmotionAnalysisApiUrl.contains('your-ai-sentiment-api.example.com')) {
      return analyzeEmotionLocally(text);
    }

    final uri = Uri.parse(kEmotionAnalysisApiUrl);
    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EmotionApiException(
          'Request failed (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw EmotionApiException('Invalid response shape');
      }

      return EmotionAnalysis.fromJson(decoded);
    } catch (_) {
      return analyzeEmotionLocally(text);
    }
  }

  static EmotionAnalysis analyzeEmotionLocally(String text) {
    final normalized = text.toLowerCase();

    const riskTerms = [
      'suicide',
      'kill myself',
      'self harm',
      'hurt myself',
      'end it',
      'don\'t want to live',
      'hopeless',
      'worthless',
    ];
    const lowMoodTerms = [
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
    ];
    const positiveTerms = [
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
    ];
    const highEnergyTerms = [
      'can\'t stop',
      'racing',
      'restless',
      'shaking',
      'spiraling',
      'panic',
      'urgent',
    ];

    final matchedKeywords = <String>{
      ...riskTerms.where(normalized.contains),
      ...lowMoodTerms.where(normalized.contains),
      ...positiveTerms.where(normalized.contains),
      ...highEnergyTerms.where(normalized.contains),
    }.toList();

    final riskMatches = riskTerms.where(normalized.contains).length;
    final lowMoodMatches = lowMoodTerms.where(normalized.contains).length;
    final positiveMatches = positiveTerms.where(normalized.contains).length;
    final highEnergyMatches = highEnergyTerms.where(normalized.contains).length;

    final score = ((positiveMatches * 0.35) - (lowMoodMatches * 0.45) - (riskMatches * 0.8))
        .clamp(-1.0, 1.0)
        .toDouble();

    final riskLevel = switch (riskMatches) {
      >= 2 => 'HIGH',
      1 => 'MEDIUM',
      _ when lowMoodMatches >= 4 => 'MEDIUM',
      _ => 'LOW',
    };

    final sentimentLabel = switch (score) {
      >= 0.35 => 'Positive',
      <= -0.4 => 'Heavy',
      _ => 'Mixed',
    };

    final energy = highEnergyMatches >= 2
        ? 'High'
        : normalized.contains('tired') || normalized.contains('exhausted')
            ? 'Low'
            : 'Steady';

    final recommendedGroup = _recommendedGroupForText(normalized);
    final summary = switch (sentimentLabel) {
      'Positive' =>
        'You sound like you are finding some steadier ground. Keeping connection going could help maintain that momentum.',
      'Heavy' =>
        'Your check-in sounds emotionally heavy. A supportive space with people who relate may help you feel less alone right now.',
      _ =>
        'Your feelings sound mixed and important. A supportive group could help you sort through what is weighing on you.',
    };

    return EmotionAnalysis(
      sentimentLabel: sentimentLabel,
      sentimentScore: score,
      energy: energy,
      recommendedGroup: recommendedGroup,
      riskLevel: riskLevel,
      summary: summary,
      keywords: matchedKeywords.take(5).toList(),
      source: 'local-fallback',
    );
  }

  static String _recommendedGroupForText(String normalized) {
    if (normalized.contains('study') ||
        normalized.contains('exam') ||
        normalized.contains('college') ||
        normalized.contains('school')) {
      return 'Study Stress Circle';
    }
    if (normalized.contains('sleep') ||
        normalized.contains('night') ||
        normalized.contains('insomnia') ||
        normalized.contains('racing')) {
      return 'Midnight Thoughts';
    }
    if (normalized.contains('family') || normalized.contains('parent')) {
      return 'Family Dynamics';
    }
    if (normalized.contains('grief') ||
        normalized.contains('loss') ||
        normalized.contains('miss them')) {
      return 'Grief & Loss';
    }
    if (normalized.contains('anxiety') ||
        normalized.contains('panic') ||
        normalized.contains('scared')) {
      return 'Anxiety Warriors';
    }
    if (normalized.contains('sad') ||
        normalized.contains('depressed') ||
        normalized.contains('hopeless')) {
      return 'Depression Daily';
    }
    return 'Self-Care Squad';
  }

  /// Maps API [recommendedGroup] label to a [MicroCommunity] in [communities].
  static MicroCommunity? matchCommunityForRecommendation(
    String recommendedGroup,
    List<MicroCommunity> communities,
  ) {
    if (communities.isEmpty) return null;
    final g = recommendedGroup.toLowerCase().trim();

    String? id;
    if (g.contains('anxiety')) {
      id = 'c1';
    } else if (g.contains('depression')) {
      id = 'c10';
    } else if (g.contains('loneliness') || g.contains('connection')) {
      id = 'c3';
    } else if (g.contains('stress') || g.contains('burnout')) {
      id = 'c8';
    } else if (g.contains('relationship')) {
      id = 'c5';
    } else if (g.contains('student')) {
      id = 'c2';
    } else if (g.contains('work')) {
      id = 'c2';
    } else if (g.contains('general')) {
      id = 'c8';
    }

    MicroCommunity? byId(String? cid) {
      if (cid == null) return null;
      for (final c in communities) {
        if (c.id == cid) return c;
      }
      return null;
    }

    final direct = byId(id);
    if (direct != null) return direct;

    for (final c in communities) {
      final name = c.name.toLowerCase();
      if (g.isNotEmpty && (g.contains(name) || name.contains(g))) {
        return c;
      }
    }
    return communities.first;
  }
}

class EmotionApiException implements Exception {
  final String message;
  EmotionApiException(this.message);

  @override
  String toString() => message;
}
