import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/micro_community_model.dart';
import '../providers/community_provider.dart';
import 'chats_screen.dart';

class CommunityPreviewScreen extends StatelessWidget {
  final MicroCommunity community;

  const CommunityPreviewScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        community.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        community.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        community.topic,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatChip(
                    context,
                    Icons.people_outline,
                    '${community.memberCount} members',
                    colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _buildStatChip(
                    context,
                    community.safetyLevel == SafetyLevel.moderated
                        ? Icons.shield_outlined
                        : Icons.verified_outlined,
                    community.safetyLevel == SafetyLevel.moderated
                        ? 'Moderated'
                        : 'Safe Space',
                    community.safetyLevel == SafetyLevel.moderated
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _buildStatChip(
                    context,
                    Icons.access_time_outlined,
                    _formatLastActive(community.lastActiveAt),
                    colorScheme.tertiary,
                  ),
                ],
              ),
            ),
          ),

          // Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    community.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Tags
          if (community.tags.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: community.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Recent Messages Preview
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Messages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _getMockMessages(context, colorScheme),
              ),
            ),
          ),

          // Guidelines
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Community Guidelines',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Be kind and supportive\n'
                      '• Respect everyone\'s anonymity\n'
                      '• No personal information sharing\n'
                      '• This is peer support, not therapy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          final isJoined = provider.isJoined(community.id);
          return Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: isJoined
                      ? FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  chat: ChatItem(
                                    id: community.id,
                                    name: community.name,
                                    lastMessage:
                                        community.lastMessagePreview ?? '',
                                    timestamp: 'now',
                                    unreadCount: 0,
                                    isGroup: true,
                                    memberCount: community.memberCount,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('Open Chat'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            provider.joinCommunity(community.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Welcome to ${community.name}! ${community.emoji}'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.group_add),
                          label: const Text('Join Community'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                ),
                if (isJoined) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      provider.leaveCommunity(community.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Left ${community.name}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: colorScheme.error,
                    ),
                    child: const Text('Leave'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getMockMessages(BuildContext context, ColorScheme colorScheme) {
    final messages = [
      {
        'author': 'Anonymous Phoenix',
        'text': 'Has anyone tried the breathing technique from the pinned post?',
        'time': '2 min ago',
        'emoji': '🔥',
      },
      {
        'author': 'Anonymous Dove',
        'text': 'Yes! The 4-7-8 method really works. I do it before exams now.',
        'time': '5 min ago',
        'emoji': '🕊️',
      },
      {
        'author': 'Anonymous Owl',
        'text': 'Thanks for sharing that. I\'ve been struggling all week.',
        'time': '12 min ago',
        'emoji': '🦉',
      },
      {
        'author': 'Anonymous Bear',
        'text': 'You\'re all amazing for being here and supporting each other. 💛',
        'time': '18 min ago',
        'emoji': '🐻',
      },
    ];

    return messages.map((msg) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(msg['emoji']!, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        msg['author']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        msg['time']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg['text']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatLastActive(DateTime? time) {
    if (time == null) return 'Recently';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
