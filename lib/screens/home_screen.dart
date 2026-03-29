import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/emotion_service.dart';
import '../services/speech_service.dart';
import '../widgets/create_post_card.dart';
import '../widgets/match_results_card.dart';
import '../providers/app_state_provider.dart';
import '../providers/community_provider.dart';
import '../providers/post_provider.dart';
import 'chat_room_screen.dart';
import 'chats_screen.dart';
import 'journaling_screen.dart';
import 'mood_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isAnalyzingVoice = false;
  String _voiceTranscript = '';
  EmotionAnalysis? _voiceAnalysis;
  String? _voiceError;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, PostProvider>(
      builder: (context, appState, postProvider, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Auto-join banner
              _buildAutoJoinBanner(context),

              // Mood Today Widget
              _buildMoodWidget(context),
              const SizedBox(height: 16),

              // Voice check-in
              _buildVoiceSentimentCard(context),
              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // Recent Chats (horizontal)
              _buildRecentChats(context),
              const SizedBox(height: 20),

              // Continue Conversation Card
              _buildContinueConversation(context),
              const SizedBox(height: 16),

              // People who replied
              _buildPeopleReplied(context),
              const SizedBox(height: 16),

              // Last Post Summary
              if (postProvider.postHistory.isNotEmpty)
                _buildLastPostSummary(context, postProvider),
              if (postProvider.postHistory.isNotEmpty) const SizedBox(height: 16),

              // Error message
              if (postProvider.error != null)
                _buildErrorCard(context, postProvider),
              if (postProvider.error != null) const SizedBox(height: 16),

              // Create post or show results
              if (postProvider.isSubmitting)
                _buildLoadingCard(context)
              else if (postProvider.matchResults != null &&
                  postProvider.currentPost != null)
                MatchResultsCard(
                  post: postProvider.currentPost!,
                  onCreateNewPost: () => postProvider.clearMatchResults(),
                )
              else
                CreatePostCard(
                  anonymousId: appState.anonymousId ?? '',
                  isSubmitting: postProvider.isSubmitting,
                ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startVoiceCheckIn() async {
    if (_isAnalyzingVoice) return;

    final initialized = await _speechService.initialize();
    if (!initialized) {
      setState(() {
        _voiceError = 'Speech recognition is not available on this device.';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _voiceError = null;
      _voiceTranscript = '';
    });

    await _speechService.startListening(
      onResult: (transcript) {
        if (!mounted) return;
        setState(() {
          _voiceTranscript = transcript;
        });
      },
    );
  }

  Future<void> _stopVoiceCheckIn() async {
    if (!_isListening) return;

    setState(() => _isListening = false);
    final transcript = await _speechService.stopListening();
    if (!mounted) return;

    final normalized = transcript.trim();
    if (normalized.isEmpty) {
      setState(() {
        _voiceError = 'Could not capture speech. Try again with a longer check-in.';
      });
      return;
    }

    setState(() {
      _voiceTranscript = normalized;
      _isAnalyzingVoice = true;
      _voiceError = null;
    });

    try {
      final analysis = await EmotionService.analyzeEmotion(normalized);
      if (!mounted) return;
      setState(() {
        _voiceAnalysis = analysis;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _voiceError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingVoice = false);
      }
    }
  }

  void _openRecommendedGroup() {
    final analysis = _voiceAnalysis;
    if (analysis == null) return;

    final communityProvider = context.read<CommunityProvider>();
    final community = EmotionService.matchCommunityForRecommendation(
      analysis.recommendedGroup,
      communityProvider.allCommunities,
    );
    if (community == null) return;

    communityProvider.joinCommunity(community.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          communityId: community.id,
          communityName: community.name,
          communityEmoji: community.emoji,
          pendingVoiceMessage: _voiceTranscript,
        ),
      ),
    );
  }

  Widget _buildVoiceSentimentCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final analysis = _voiceAnalysis;
    final recommendedCommunity = analysis == null
        ? null
        : EmotionService.matchCommunityForRecommendation(
            analysis.recommendedGroup,
            context.watch<CommunityProvider>().allCommunities,
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Mood Check-In',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Press and hold to talk. We\'ll estimate sentiment and suggest a supportive space.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onLongPressStart: (_) => _startVoiceCheckIn(),
            onLongPressEnd: (_) => _stopVoiceCheckIn(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: _isListening
                      ? [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ]
                      : [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.touch_app_rounded,
                    color: _isListening ? Colors.white : colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening ? 'Listening...' : 'Hold to speak',
                    style: TextStyle(
                      color: _isListening ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isAnalyzingVoice) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          if (_voiceTranscript.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Transcript',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _voiceTranscript,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (_voiceError != null) ...[
            const SizedBox(height: 12),
            Text(
              _voiceError!,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (analysis != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInsightChip(
                  context,
                  icon: Icons.favorite_outline,
                  label: analysis.sentimentLabel,
                ),
                _buildInsightChip(
                  context,
                  icon: Icons.bolt_rounded,
                  label: '${analysis.energy} energy',
                ),
                _buildInsightChip(
                  context,
                  icon: Icons.health_and_safety_outlined,
                  label: 'Risk ${analysis.riskLevel.toUpperCase()}',
                ),
                _buildInsightChip(
                  context,
                  icon: Icons.memory_rounded,
                  label: analysis.source == 'remote' ? 'AI analysis' : 'On-device fallback',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              analysis.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (analysis.keywords.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Detected themes: ${analysis.keywords.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
            if (recommendedCommunity != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                ),
                child: Row(
                  children: [
                    Text(
                      recommendedCommunity.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendedCommunity.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recommendedCommunity.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openRecommendedGroup,
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Open Recommended Chat'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInsightChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoJoinBanner(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.autoJoinBanner == null) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_add,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.autoJoinBanner!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => provider.dismissAutoJoinBanner(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.tertiary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'How are you today?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re not alone. Share and connect with others who understand.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodEmoji(context, '😊', 'Great'),
              _buildMoodEmoji(context, '🙂', 'Good'),
              _buildMoodEmoji(context, '😐', 'Meh'),
              _buildMoodEmoji(context, '😔', 'Low'),
              _buildMoodEmoji(context, '😢', 'Tough'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEmoji(BuildContext context, String emoji, String label) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoodTrackingScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = [
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Talk to\nSomeone',
        'color': colorScheme.primary,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chat: ChatItem(
                  id: 'new',
                  name: 'New Conversation',
                  lastMessage: '',
                  timestamp: 'now',
                  unreadCount: 0,
                  isGroup: false,
                ),
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.explore_outlined,
        'label': 'Join a\nGroup',
        'color': colorScheme.tertiary,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Switch to the Discover tab to find groups! 🔍'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      },
      {
        'icon': Icons.mood_outlined,
        'label': 'Track\nMood',
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MoodTrackingScreen()),
          );
        },
      },
      {
        'icon': Icons.book_outlined,
        'label': 'Write\nJournal',
        'color': Colors.teal,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalingScreen()),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: action != actions.last ? 10 : 0),
                child: InkWell(
                  onTap: action['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: (action['color'] as Color).withValues(alpha: 0.08),
                      border: Border.all(
                        color:
                            (action['color'] as Color).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                (action['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            color: action['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentChats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentChats = [
      {
        'name': 'Anonymous Butterfly',
        'message': 'Thank you for sharing...',
        'emoji': '🦋',
        'unread': 2
      },
      {
        'name': 'Study Stress Circle',
        'message': 'Finals week tips',
        'emoji': '📚',
        'unread': 5
      },
      {
        'name': 'Anonymous Dove',
        'message': 'Hope you\'re better!',
        'emoji': '🕊️',
        'unread': 0
      },
      {
        'name': 'Anxiety Warriors',
        'message': 'New breathing exercise',
        'emoji': '🛡️',
        'unread': 3
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Chats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to the Chats tab – for now show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switch to the Chats tab to see all conversations 💬'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentChats.length,
            itemBuilder: (context, index) {
              final chat = recentChats[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chat: ChatItem(
                          id: '$index',
                          name: chat['name'] as String,
                          lastMessage: chat['message'] as String,
                          timestamp: 'now',
                          unreadCount: chat['unread'] as int,
                          isGroup: index == 1 || index == 3,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.secondaryContainer,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(chat['emoji'] as String,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                          if ((chat['unread'] as int) > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: colorScheme.surface, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${chat['unread']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (chat['name'] as String).replaceAll('Anonymous ', ''),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueConversation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer.withValues(alpha: 0.4),
            colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🦋', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue your conversation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Anonymous Butterfly is waiting for your reply',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    chat: ChatItem(
                      id: '1',
                      name: 'Anonymous Butterfly',
                      lastMessage: 'Thank you for sharing...',
                      timestamp: '2 hours ago',
                      unreadCount: 2,
                      isGroup: false,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleReplied(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply_all, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'People who replied to your post',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReplyItem(
              context, '🔥', 'Anonymous Phoenix', 'I totally understand...', '2h'),
          _buildReplyItem(context, '🦉', 'Anonymous Owl',
              'Same here, you\'re not alone', '5h'),
        ],
      ),
    );
  }

  Widget _buildReplyItem(BuildContext context, String emoji, String name,
      String preview, String time) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  preview,
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(time,
              style: TextStyle(fontSize: 11, color: colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildLastPostSummary(
      BuildContext context, PostProvider postProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastPost = postProvider.postHistory.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Your Last Post',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                _formatTime(lastPost.createdAt),
                style:
                    TextStyle(fontSize: 11, color: colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastPost.content.length > 120
                ? '${lastPost.content.substring(0, 120)}...'
                : lastPost.content,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, PostProvider postProvider) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                postProvider.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => postProvider.clearError(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Finding people who understand...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re looking for people with similar experiences.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
