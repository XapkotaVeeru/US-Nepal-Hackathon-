import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/create_post_card.dart';
import '../widgets/match_results_card.dart';
import '../providers/app_state_provider.dart';
import '../providers/community_provider.dart';
import '../providers/post_provider.dart';
import 'chats_screen.dart';
import 'journaling_screen.dart';
import 'mood_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

              // Error message
              if (postProvider.error != null)
                _buildErrorCard(context, postProvider),
              if (postProvider.error != null) const SizedBox(height: 16),

              // Create post or show results (MAIN FEATURE - moved to top)
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
              const SizedBox(height: 20),

              // Mood Today Widget
              _buildMoodWidget(context),
              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // Recent Chats (horizontal) - removed dummy data, will show real chats from backend
              const SizedBox(height: 20),

              // Continue Conversation Card - removed dummy data
              const SizedBox(height: 16),

              // People who replied - removed dummy data
              const SizedBox(height: 16),

              // Last Post Summary
              if (postProvider.postHistory.isNotEmpty)
                _buildLastPostSummary(context, postProvider),
              if (postProvider.postHistory.isNotEmpty)
                const SizedBox(height: 16),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
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
              content: Text('Group discovery coming soon! 🔍'),
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
                padding:
                    EdgeInsets.only(right: action != actions.last ? 10 : 0),
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
                            color: (action['color'] as Color)
                                .withValues(alpha: 0.12),
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
                style: TextStyle(fontSize: 11, color: colorScheme.outline),
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
