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
      themes: ['anxiety', 'social anxiety', 'academic pressure'],
      lastActive: '8 min ago',
      style: 'Good at helping when worries start spiraling before a task or conversation.',
      audienceCategory: UserCategory.student,
      focusCategory: SupportCategory.socialSupport,
      youthSafe: true,
    ),
    const _LocalPeerProfile(
      id: 'peer-family-1',
      anonymousName: 'Anonymous Cedar',
      themes: ['family stress', 'relationships', 'self-worth'],
      lastActive: '24 min ago',
      style: 'Often supports people navigating pressure at home.',
      audienceCategory: UserCategory.caregiver,
      focusCategory: SupportCategory.familySupport,
    ),
    const _LocalPeerProfile(
      id: 'peer-grief-1',
      anonymousName: 'Anonymous River',
      themes: ['grief', 'connection', 'sleep disruption'],
      lastActive: '1 hr ago',
      style: 'Warm listener for loss, loneliness, and late-night check-ins.',
      audienceCategory: UserCategory.unspecified,
      focusCategory: SupportCategory.griefSupport,
    ),
    const _LocalPeerProfile(
      id: 'peer-burnout-1',
      anonymousName: 'Anonymous Maple',
      themes: ['burnout', 'work', 'sleep disruption'],
      lastActive: '2 hrs ago',
      style: 'Useful when work pressure is bleeding into sleep and energy.',
      audienceCategory: UserCategory.professional,
      focusCategory: SupportCategory.burnoutSupport,
    ),
    const _LocalPeerProfile(
      id: 'peer-hope-1',
      anonymousName: 'Anonymous Horizon',
      themes: ['connection', 'self-worth', 'emotional processing'],
      lastActive: 'Today',
      style: 'Tends to reflect back strengths and steady momentum.',
      audienceCategory: UserCategory.unspecified,
      focusCategory: SupportCategory.peerSupport,
      youthSafe: true,
    ),
    const _LocalPeerProfile(
      id: 'peer-youth-1',
      anonymousName: 'Anonymous Finch',
      themes: ['academic pressure', 'school', 'stress'],
      lastActive: '14 min ago',
      style: 'Best for young people who want school-life support in a calmer room.',
      audienceCategory: UserCategory.under18,
      focusCategory: SupportCategory.youthSupport,
      youthSafe: true,
    ),
  ];

  static const List<_SupportGroupProfile> _groupPool = [
    _SupportGroupProfile(
      id: 'group-student-stress',
      title: 'Students dealing with exam stress',
      description:
          'A study-pressure route for deadlines, test anxiety, and academic overwhelm.',
      identityDescriptor: 'Student support route',
      linkedCommunityId: 'c2',
      supportCategory: SupportCategory.academicStress,
      audienceCategory: UserCategory.student,
      themes: ['academic pressure', 'stress', 'study'],
    ),
    _SupportGroupProfile(
      id: 'group-professional-burnout',
      title: 'Working professionals facing burnout',
      description:
          'A route for job pressure, work fatigue, and the feeling of never switching off.',
      identityDescriptor: 'Professional support route',
      linkedCommunityId: 'c11',
      supportCategory: SupportCategory.burnoutSupport,
      audienceCategory: UserCategory.professional,
      themes: ['burnout', 'work', 'career'],
    ),
    _SupportGroupProfile(
      id: 'group-young-support',
      title: 'Young people needing emotional support',
      description:
          'A youth-safe route that leans toward moderated spaces before unknown direct matching.',
      identityDescriptor: 'Youth-safe support route',
      linkedCommunityId: 'c12',
      supportCategory: SupportCategory.youthSupport,
      audienceCategory: UserCategory.under18,
      themes: ['youth', 'stress', 'school'],
    ),
    _SupportGroupProfile(
      id: 'group-family-support',
      title: 'People navigating family pressure',
      description:
          'A route for home stress, boundaries, relationship strain, and emotional fallout.',
      identityDescriptor: 'Family support route',
      linkedCommunityId: 'c5',
      supportCategory: SupportCategory.familySupport,
      audienceCategory: UserCategory.unspecified,
      themes: ['family stress', 'relationships'],
    ),
    _SupportGroupProfile(
      id: 'group-gentle-peer-support',
      title: 'People needing a calmer support space',
      description:
          'A gentler route for loneliness, mixed emotions, and needing steady peer support.',
      identityDescriptor: 'General peer support route',
      linkedCommunityId: 'c8',
      supportCategory: SupportCategory.peerSupport,
      audienceCategory: UserCategory.unspecified,
      themes: ['connection', 'self-worth', 'emotional processing'],
    ),
  ];

  @override
  Future<SupportMatchResult> buildMatches({
    required CheckInSubmission submission,
    required EmotionalAnalysisResult analysis,
  }) async {
    final communities = _rankCommunities(analysis);
    final groups = _rankGroups(analysis);
    final members = _rankPeers(analysis);

    return SupportMatchResult(
      groups: groups,
      members: members,
      communities: communities,
      recommendations: _buildRecommendationItems(
        analysis,
        groups,
        communities,
      ),
      crisisResources:
          analysis.riskLevel == 'HIGH' ? _defaultCrisisResources() : const [],
      retrievalPlan: EmbeddingRetrievalPlan(
        queryText:
            '${analysis.emotionalLabels.join(' ')} ${analysis.themes.join(' ')} ${analysis.supportCategoryLabel} ${submission.content}',
        tags: [
          ...analysis.routingTags,
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
    final eligiblePeers = analysis.userCategory == UserCategory.under18
        ? _peerPool.where((peer) => peer.youthSafe).toList()
        : _peerPool;

    final scored = eligiblePeers.map((peer) {
      final shared = <String>[
        ...peer.themes.where(
          (theme) => analysis.themes.any(
            (match) =>
                match.toLowerCase().contains(theme) ||
                theme.contains(match.toLowerCase()),
          ),
        ),
      ];

      final score = (shared.length * 0.22) +
          (peer.focusCategory == analysis.supportCategory ? 0.22 : 0) +
          (_audienceFit(peer.audienceCategory, analysis.userCategory) ? 0.18 : 0) +
          (analysis.emotionalLabels.any(
                (label) =>
                    peer.style.toLowerCase().contains(label.toLowerCase()) ||
                    peer.themes.any(
                      (theme) => label.toLowerCase().contains(theme),
                    ),
              )
              ? 0.08
              : 0) +
          (peer.youthSafe && analysis.userCategory == UserCategory.under18
              ? 0.08
              : 0.02);

      final directRequestAllowed =
          analysis.userCategory != UserCategory.under18;

      return (
        peer: peer,
        score: score.clamp(0.52, 0.98),
        shared: shared.isEmpty ? analysis.themes.take(2).toList() : shared,
        directRequestAllowed: directRequestAllowed,
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
        audienceCategory: item.peer.audienceCategory,
        directRequestAllowed: item.directRequestAllowed,
        safetyNote: item.directRequestAllowed
            ? null
            : 'Youth check-ins are routed to moderated spaces before direct peer requests.',
      );
    }).toList();
  }

  List<SupportGroupRecommendation> _rankGroups(
    EmotionalAnalysisResult analysis,
  ) {
    final scored = _groupPool.map((group) {
      final matchedThemes = group.themes
          .where(
            (theme) => analysis.themes.any(
              (match) =>
                  match.toLowerCase().contains(theme) ||
                  theme.contains(match.toLowerCase()),
            ),
          )
          .toList();

      final score = matchedThemes.length * 3 +
          (group.supportCategory == analysis.supportCategory ? 4 : 0) +
          (_audienceFit(group.audienceCategory, analysis.userCategory) ? 3 : 0) +
          (analysis.supportNeedLevel == SupportNeedLevel.high &&
                  group.supportCategory == SupportCategory.peerSupport
              ? 1
              : 0);

      return (group: group, score: score, matchedThemes: matchedThemes);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(3).map((item) {
      final matchedThemes = item.matchedThemes.isEmpty
          ? analysis.themes.take(2).toList()
          : item.matchedThemes;
      return SupportGroupRecommendation(
        id: item.group.id,
        title: item.group.title,
        description: item.group.description,
        identityDescriptor: item.group.identityDescriptor,
        linkedCommunityId: item.group.linkedCommunityId,
        matchedThemes: matchedThemes.take(3).toList(),
        actionLabel: analysis.userCategory == UserCategory.under18
            ? 'Open youth-safe group'
            : 'Open group',
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

      if (_communityMatchesSupportCategory(community, analysis.supportCategory)) {
        matchedThemes.add(analysis.supportCategory.label);
      }

      final score = matchedThemes.length * 3 +
          (_communityMatchesSupportCategory(community, analysis.supportCategory)
              ? 4
              : 0) +
          (_communityMatchesAudience(community, analysis.userCategory) ? 3 : 0) +
          (analysis.supportNeedLevel != SupportNeedLevel.low &&
                  community.safetyLevel == SafetyLevel.moderated
              ? 2
              : 0) -
          (analysis.userCategory == UserCategory.under18 &&
                  !_communityMatchesAudience(community, UserCategory.under18)
              ? 3
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
        reason: _communityReason(
          community: item.community,
          analysis: analysis,
          matchedThemes: matchedThemes,
        ),
        matchedThemes: matchedThemes.take(3).toList(),
        supportCategory: analysis.supportCategory,
        audienceCategory: analysis.userCategory,
        audienceDescriptor: analysis.userCategory.audienceDescriptor,
      );
    }).toList();
  }

  List<SupportRecommendationItem> _buildRecommendationItems(
    EmotionalAnalysisResult analysis,
    List<SupportGroupRecommendation> groups,
    List<SupportCommunityRecommendation> communities,
  ) {
    final items = <SupportRecommendationItem>[
      SupportRecommendationItem(
        title: 'Name the support route',
        description:
            'Your check-in fits ${analysis.supportCategoryLabel.toLowerCase()} best right now.',
        actionLabel: 'Review route',
      ),
      SupportRecommendationItem(
        title: 'Start with the safest fit',
        description: groups.isEmpty
            ? 'A moderated support space is still available.'
            : '${groups.first.title} is the strongest match for what you shared.',
        actionLabel: groups.isEmpty ? 'Find support' : groups.first.actionLabel,
      ),
    ];

    if (analysis.supportNeedLevel == SupportNeedLevel.high ||
        analysis.supportNeedLevel == SupportNeedLevel.urgent) {
      items.insert(
        0,
        const SupportRecommendationItem(
          title: 'Slow the pace first',
          description:
              'Higher-intensity check-ins often land better after one grounding step or a quieter room.',
          actionLabel: 'Try grounding',
        ),
      );
    }

    if (analysis.userCategory == UserCategory.under18) {
      items.add(
        const SupportRecommendationItem(
          title: 'Youth-safe routing',
          description:
              'Direct unknown-peer requests stay limited here, so moderated youth spaces come first.',
          actionLabel: 'Open youth group',
        ),
      );
    } else if (communities.isNotEmpty) {
      items.add(
        SupportRecommendationItem(
          title: 'Open the most relevant room',
          description:
              '${communities.first.name} matches the emotional context and themes we detected.',
          actionLabel: 'Open community',
        ),
      );
    }

    return items.take(4).toList();
  }

  bool _audienceFit(UserCategory target, UserCategory actual) {
    if (target == UserCategory.unspecified || actual == UserCategory.unspecified) {
      return false;
    }
    return target == actual;
  }

  bool _communityMatchesAudience(
    MicroCommunity community,
    UserCategory userCategory,
  ) {
    switch (userCategory) {
      case UserCategory.student:
        return community.audienceTags.contains('student');
      case UserCategory.professional:
        return community.audienceTags.contains('professional');
      case UserCategory.under18:
        return community.audienceTags.contains('under18');
      case UserCategory.caregiver:
        return community.audienceTags.contains('caregiver');
      case UserCategory.unspecified:
        return community.audienceTags.isEmpty ||
            community.audienceTags.contains('general');
    }
  }

  bool _communityMatchesSupportCategory(
    MicroCommunity community,
    SupportCategory category,
  ) {
    final haystack = [
      community.topic.toLowerCase(),
      community.description.toLowerCase(),
      ...community.tags.map((tag) => tag.toLowerCase()),
    ].join(' ');

    switch (category) {
      case SupportCategory.academicStress:
        return haystack.contains('academic') ||
            haystack.contains('exam') ||
            haystack.contains('student');
      case SupportCategory.burnoutSupport:
        return haystack.contains('burnout') ||
            haystack.contains('career') ||
            haystack.contains('work');
      case SupportCategory.youthSupport:
        return haystack.contains('youth') || haystack.contains('school');
      case SupportCategory.familySupport:
        return haystack.contains('family') ||
            haystack.contains('relationship');
      case SupportCategory.griefSupport:
        return haystack.contains('grief') || haystack.contains('loss');
      case SupportCategory.sleepSupport:
        return haystack.contains('night') ||
            haystack.contains('sleep') ||
            haystack.contains('insomnia');
      case SupportCategory.selfWorthSupport:
        return haystack.contains('self') || haystack.contains('confidence');
      case SupportCategory.socialSupport:
        return haystack.contains('social') || haystack.contains('conversation');
      case SupportCategory.peerSupport:
      case SupportCategory.generalSupport:
        return haystack.contains('support') || haystack.contains('wellness');
      case SupportCategory.crisisSupport:
        return community.safetyLevel == SafetyLevel.moderated;
    }
  }

  String _communityReason({
    required MicroCommunity community,
    required EmotionalAnalysisResult analysis,
    required List<String> matchedThemes,
  }) {
    final identityPart = analysis.userCategory == UserCategory.unspecified
        ? ''
        : '${analysis.userCategory.audienceDescriptor}. ';
    final themePart = matchedThemes.isEmpty
        ? analysis.supportCategory.label.toLowerCase()
        : matchedThemes.join(', ');
    return '${identityPart}Good fit for $themePart.';
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
  final UserCategory audienceCategory;
  final SupportCategory focusCategory;
  final bool youthSafe;

  const _LocalPeerProfile({
    required this.id,
    required this.anonymousName,
    required this.themes,
    required this.lastActive,
    required this.style,
    required this.audienceCategory,
    required this.focusCategory,
    this.youthSafe = false,
  });
}

class _SupportGroupProfile {
  final String id;
  final String title;
  final String description;
  final String identityDescriptor;
  final String linkedCommunityId;
  final SupportCategory supportCategory;
  final UserCategory audienceCategory;
  final List<String> themes;

  const _SupportGroupProfile({
    required this.id,
    required this.title,
    required this.description,
    required this.identityDescriptor,
    required this.linkedCommunityId,
    required this.supportCategory,
    required this.audienceCategory,
    required this.themes,
  });
}
