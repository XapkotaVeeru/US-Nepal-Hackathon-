import '../models/check_in_model.dart';
import '../models/micro_community_model.dart';
import '../models/post_model.dart';

abstract class SupportMatchingService {
  Future<SupportMatchResult> buildMatches({
    required CheckInSubmission submission,
    required EmotionalAnalysisResult analysis,
  });
}

abstract class EmbeddingMatchingBackend {
  Future<List<String>> retrieveSimilarContent({
    required String queryText,
    required List<String> tags,
  });
}

class LocalSupportMatchingService implements SupportMatchingService {
  final EmbeddingMatchingBackend? backend;

  const LocalSupportMatchingService({this.backend});

  static final List<_LocalPeerProfile> _peerPool = [
    const _LocalPeerProfile(
      id: 'peer-anxiety-1',
      anonymousName: 'Anonymous Lantern',
      themes: ['anxiety', 'academic pressure', 'burnout'],
      lastActive: '8 min ago',
      style: 'Good at breaking big worries into one next step.',
    ),
    const _LocalPeerProfile(
      id: 'peer-family-1',
      anonymousName: 'Anonymous Cedar',
      themes: ['family stress', 'relationships', 'self-worth'],
      lastActive: '24 min ago',
      style: 'Often supports people navigating pressure at home.',
    ),
    const _LocalPeerProfile(
      id: 'peer-grief-1',
      anonymousName: 'Anonymous River',
      themes: ['grief', 'connection', 'sleep disruption'],
      lastActive: '1 hr ago',
      style: 'Warm listener for loss, loneliness, and late-night check-ins.',
    ),
    const _LocalPeerProfile(
      id: 'peer-burnout-1',
      anonymousName: 'Anonymous Maple',
      themes: ['burnout', 'academic pressure', 'sleep disruption'],
      lastActive: '2 hrs ago',
      style: 'Useful when stress is bleeding into sleep and energy.',
    ),
    const _LocalPeerProfile(
      id: 'peer-hope-1',
      anonymousName: 'Anonymous Horizon',
      themes: ['connection', 'self-worth', 'emotional processing'],
      lastActive: 'Today',
      style: 'Tends to reflect back strengths and steady momentum.',
    ),
  ];

  @override
  Future<SupportMatchResult> buildMatches({
    required CheckInSubmission submission,
    required EmotionalAnalysisResult analysis,
  }) async {
    final communities = _rankCommunities(analysis);
    final members = _rankPeers(analysis);

    return SupportMatchResult(
      members: members,
      communities: communities,
      recommendations: _buildRecommendationItems(analysis, communities),
      crisisResources:
          analysis.riskLevel == 'HIGH' ? _defaultCrisisResources() : const [],
      retrievalPlan: EmbeddingRetrievalPlan(
        queryText:
            '${analysis.emotionalLabels.join(' ')} ${analysis.themes.join(' ')} ${submission.content}',
        tags: [
          ...analysis.themes,
          ...analysis.emotionalLabels.map((label) => label.toLowerCase()),
        ],
        backendHint:
            'Swap LocalSupportMatchingService with embeddings retrieval when Bedrock/vector search is ready.',
        backendReady: backend != null,
      ),
      source: backend == null ? 'local-matching-fallback' : 'hybrid-matching',
    );
  }

  List<SupportMemberRecommendation> _rankPeers(
    EmotionalAnalysisResult analysis,
  ) {
    final scored = _peerPool.map((peer) {
      final shared = peer.themes
          .where(
            (theme) => analysis.themes.any(
              (match) =>
                  match.toLowerCase().contains(theme) ||
                  theme.contains(match.toLowerCase()),
            ),
          )
          .toList();

      final score = (shared.length * 0.24) +
          (analysis.emotionalLabels.any(
                (label) => peer.style.toLowerCase().contains(label.toLowerCase()),
              )
              ? 0.08
              : 0) +
          (analysis.riskLevel == 'HIGH' ? 0.04 : 0.02);

      return (
        peer: peer,
        score: score.clamp(0.55, 0.97),
        shared: shared.isEmpty ? analysis.themes.take(2).toList() : shared,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(3).map((item) {
      return SupportMemberRecommendation(
        id: item.peer.id,
        anonymousName: item.peer.anonymousName,
        similarityScore: item.score,
        lastActive: item.peer.lastActive,
        reason: item.peer.style,
        sharedThemes: item.shared.join(', '),
      );
    }).toList();
  }

  List<SupportCommunityRecommendation> _rankCommunities(
    EmotionalAnalysisResult analysis,
  ) {
    final all = MockCommunities.getAllCommunities();
    final scored = all.map((community) {
      final matchedThemes = <String>[
        ...analysis.themes.where(
          (theme) => community.tags.any(
            (tag) =>
                tag.contains(theme.toLowerCase()) ||
                theme.toLowerCase().contains(tag),
          ),
        ),
      ];

      if (analysis.themes.any(
        (theme) => community.topic.toLowerCase().contains(theme.toLowerCase()),
      )) {
        matchedThemes.add(community.topic);
      }

      final score = matchedThemes.length * 3 +
          analysis.emotionalLabels.where(
            (label) => community.description.toLowerCase().contains(
                  label.toLowerCase(),
                ),
          ).length +
          (analysis.riskLevel != 'LOW' &&
                  community.safetyLevel == SafetyLevel.moderated
              ? 2
              : 0);

      return (community: community, score: score, matchedThemes: matchedThemes);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(3).map((item) {
      final matchedThemes = item.matchedThemes.isEmpty
          ? analysis.themes.take(2).toList()
          : item.matchedThemes;
      return SupportCommunityRecommendation(
        id: item.community.id,
        name: item.community.name,
        emoji: item.community.emoji,
        description: item.community.description,
        memberCount: item.community.memberCount,
        reason: 'Good fit for ${matchedThemes.join(', ')}',
        matchedThemes: matchedThemes.take(3).toList(),
      );
    }).toList();
  }

  List<SupportRecommendationItem> _buildRecommendationItems(
    EmotionalAnalysisResult analysis,
    List<SupportCommunityRecommendation> communities,
  ) {
    final items = <SupportRecommendationItem>[
      const SupportRecommendationItem(
        title: 'Reflect the sharpest feeling',
        description:
            'Lead with the emotion that feels biggest right now so peers know where to meet you.',
        actionLabel: 'Share one more detail',
      ),
      SupportRecommendationItem(
        title: 'Pick the most relevant room',
        description:
            communities.isEmpty ? 'We can still suggest a gentle support space.' : '${communities.first.name} looks like the best immediate fit.',
        actionLabel: 'Open community',
      ),
    ];

    if (analysis.intensity >= 4) {
      items.insert(
        0,
        const SupportRecommendationItem(
          title: 'Slow the pace first',
          description:
              'High-intensity check-ins often land better after one calming breath or grounding step.',
          actionLabel: 'Try grounding',
        ),
      );
    }

    if (analysis.themes.contains('sleep disruption')) {
      items.add(
        const SupportRecommendationItem(
          title: 'Night check-in fit',
          description:
              'A later-hours room may feel more responsive if this gets louder at night.',
          actionLabel: 'Find night support',
        ),
      );
    }

    return items.take(4).toList();
  }

  List<CrisisResource> _defaultCrisisResources() {
    return [
      CrisisResource(
        name: '988 Suicide & Crisis Lifeline',
        phone: '988',
        url: 'https://988lifeline.org',
        description: '24/7 free and confidential support',
        available24_7: true,
      ),
      CrisisResource(
        name: 'Crisis Text Line',
        phone: 'Text HOME to 741741',
        url: 'https://www.crisistextline.org',
        description: 'Text-based crisis support',
        available24_7: true,
      ),
      CrisisResource(
        name: 'NAMI Helpline',
        phone: '1-800-950-6264',
        url: 'https://www.nami.org/help',
        description: 'Mental health information and support',
        available24_7: false,
      ),
    ];
  }
}

class BedrockEmbeddingMatchingBackend implements EmbeddingMatchingBackend {
  const BedrockEmbeddingMatchingBackend();

  @override
  Future<List<String>> retrieveSimilarContent({
    required String queryText,
    required List<String> tags,
  }) {
    // TODO: Plug teammate embeddings/vector-retrieval flow here.
    throw UnimplementedError('Bedrock/vector retrieval is not wired yet.');
  }
}

class _LocalPeerProfile {
  final String id;
  final String anonymousName;
  final List<String> themes;
  final String lastActive;
  final String style;

  const _LocalPeerProfile({
    required this.id,
    required this.anonymousName,
    required this.themes,
    required this.lastActive,
    required this.style,
  });
}
