import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/check_in_model.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../screens/chat_room_screen.dart';

class MatchResultsCard extends StatelessWidget {
  final CheckInResult result;
  final VoidCallback onCreateNewPost;

  const MatchResultsCard({
    super.key,
    required this.result,
    required this.onCreateNewPost,
  });

  @override
  Widget build(BuildContext context) {
    if (result.analysis.riskLevel == 'HIGH' &&
        result.matching.crisisResources.isNotEmpty) {
      return _buildHighRiskCard(context);
    }

    return _buildMatchResultsCard(context);
  }

  Widget _buildHighRiskCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 48,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Immediate Support First',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your check-in may reflect strong distress. We\'re prioritizing crisis support before peer matching.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...result.matching.crisisResources.map(
              (resource) => _buildCrisisResourceTile(context, resource),
            ),
            const SizedBox(height: 12),
            Text(
              result.analysis.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onCreateNewPost,
              child: const Text('Start a New Check-In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchResultsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  result.submission.cameFromVoice
                      ? Icons.graphic_eq_rounded
                      : Icons.auto_awesome_rounded,
                  size: 44,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 10),
                Text(
                  'We turned your check-in into a support map',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  result.analysis.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (result.backendMessage?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.backendMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotional Analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      context,
                      icon: Icons.favorite_outline,
                      label: result.analysis.emotionalLabels.join(' · '),
                    ),
                    _chip(
                      context,
                      icon: Icons.show_chart_rounded,
                      label:
                          '${result.analysis.moodDirectionLabel} ${result.analysis.sentimentScore.toStringAsFixed(2)}',
                    ),
                    _chip(
                      context,
                      icon: Icons.bolt_rounded,
                      label:
                          '${result.analysis.intensityLabel} intensity (${result.analysis.intensity}/5)',
                    ),
                    _chip(
                      context,
                      icon: Icons.memory_rounded,
                      label: result.analysis.sourceLabel,
                    ),
                  ],
                ),
                if (result.analysis.themes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Themes: ${result.analysis.themes.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Recommendations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...result.matching.recommendations.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relevant Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Prepared for future similarity matching and direct support routing.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ...result.matching.members.map(
                  (member) => _buildMemberTile(context, member),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relevant Communities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'These rooms were ranked from your emotional labels, themes, and intensity.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ...result.matching.communities.map(
                  (community) => _buildCommunityTile(context, community),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Embeddings Readiness',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  result.matching.retrievalPlan.backendHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Query seed: ${result.matching.retrievalPlan.queryText}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tags: ${result.matching.retrievalPlan.tags.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCreateNewPost,
                child: const Text('New Check-In'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    SupportMemberRecommendation member,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(member.anonymousName[0])),
        title: Text(member.anonymousName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.reason, style: const TextStyle(fontSize: 12)),
            Text(
              '${(member.similarityScore * 100).toInt()}% fit • ${member.lastActive} • ${member.sharedThemes}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: () => _requestPeerChat(context, member),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Request'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCommunityTile(
    BuildContext context,
    SupportCommunityRecommendation community,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(community.emoji)),
        title: Text(community.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.reason,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${community.memberCount} members • ${community.matchedThemes.join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: () => _openCommunity(context, community),
          icon: const Icon(Icons.forum_outlined, size: 18),
          label: const Text('Open'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCrisisResourceTile(
    BuildContext context,
    dynamic resource,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          resource.available24_7 ? Icons.access_time : Icons.schedule,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          resource.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.description),
            const SizedBox(height: 4),
            Text(
              resource.phone,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (resource.url != null)
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _launchUrl(resource.url!),
              ),
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => _launchUrl('tel:${resource.phone}'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _requestPeerChat(
    BuildContext context,
    SupportMemberRecommendation member,
  ) async {
    final anonymousId = context.read<AppStateProvider>().anonymousId;
    if (anonymousId == null) return;

    try {
      await context.read<ChatProvider>().sendChatRequest(
            fromUserId: anonymousId,
            toUserId: member.id,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat request sent to ${member.anonymousName}'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Direct peer chat routing is not live yet, but this recommendation is ready for the future matching backend.',
          ),
        ),
      );
    }
  }

  void _openCommunity(
    BuildContext context,
    SupportCommunityRecommendation community,
  ) {
    context.read<CommunityProvider>().joinCommunity(community.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          communityId: community.id,
          communityName: community.name,
          communityEmoji: community.emoji,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
