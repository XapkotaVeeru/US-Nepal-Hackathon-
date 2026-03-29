import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/check_in_model.dart';
import '../models/notification_model.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../providers/notification_provider.dart';
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
                      label:
                          '${result.analysis.sentimentLabel} · ${result.analysis.emotionalLabels.join(' · ')}',
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
                          '${result.analysis.intensityLabel} intensity (${result.analysis.intensity}/5) · ${result.analysis.supportNeedLabel} need',
                    ),
                    _chip(
                      context,
                      icon: Icons.route_outlined,
                      label: result.analysis.supportCategoryLabel,
                    ),
                    _chip(
                      context,
                      icon: result.submission.cameFromVoice
                          ? Icons.mic_none_rounded
                          : Icons.keyboard_alt_outlined,
                      label:
                          result.submission.cameFromVoice ? 'Voice input' : 'Text input',
                    ),
                    if (result.analysis.hasExplicitUserCategory)
                      _chip(
                        context,
                        icon: Icons.badge_outlined,
                        label: result.analysis.userCategoryLabel,
                      ),
                    if (result.analysis.userCategoryEvidence?.isNotEmpty == true)
                      _chip(
                        context,
                        icon: Icons.find_in_page_outlined,
                        label:
                            'Explicit cue: ${result.analysis.userCategoryEvidence}',
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
        if (result.matching.groups.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identity-Aware Groups',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These group routes describe the kind of support space that best fits the emotional context and any explicit identity cues.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ...result.matching.groups.map(
                    (group) => _buildGroupTile(context, group),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
                  result.analysis.userCategory == UserCategory.under18
                      ? 'Young-person routing stays careful here, so direct requests are limited in favor of moderated spaces.'
                      : 'These people were ranked from emotion, themes, and support category fit.',
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
                  'These rooms were ranked from sentiment, support category, themes, and identity-aware routing.',
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
              '${(member.similarityScore * 100).toInt()}% fit • ${member.lastActive} • ${member.audienceCategory.label} • ${member.sharedThemes}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (member.safetyNote != null) ...[
              const SizedBox(height: 4),
              Text(
                member.safetyNote!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: member.directRequestAllowed
              ? () => _requestPeerChat(context, member)
              : null,
          icon: Icon(
            member.directRequestAllowed
                ? Icons.chat_bubble_outline
                : Icons.shield_outlined,
            size: 18,
          ),
          label: Text(member.directRequestAllowed ? 'Request' : 'Use groups'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    SupportGroupRecommendation group,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.groups_2_outlined)),
        title: Text(group.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.description, style: const TextStyle(fontSize: 12)),
            Text(
              '${group.identityDescriptor} • ${group.matchedThemes.join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: () => _openLinkedGroup(context, group),
          icon: const Icon(Icons.forum_outlined, size: 18),
          label: Text(group.actionLabel),
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
              '${community.memberCount} members • ${community.audienceDescriptor} • ${community.matchedThemes.join(', ')}',
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
      final request = await context.read<ChatProvider>().sendChatRequest(
            fromUserId: anonymousId,
            toUserId: member.id,
            contextSummary:
                '${result.analysis.supportCategoryLabel} route from check-in',
            matchedThemes: result.analysis.themes,
            supportCategory: result.analysis.supportCategory.name,
            userCategory: result.analysis.userCategory.name,
          );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            communityId: request.sessionId,
            communityName: member.anonymousName,
            communityEmoji: '🤝',
          ),
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

  Future<void> _openCommunity(
    BuildContext context,
    SupportCommunityRecommendation community,
  ) async {
    context.read<CommunityProvider>().joinCommunity(community.id);
    await context.read<NotificationProvider>().recordRoutingNotification(
      type: NotificationType.groupInvite,
      title: 'Support route opened',
      message:
          'You opened ${community.name} because it matches ${result.analysis.supportCategoryLabel.toLowerCase()} and ${result.analysis.userCategory.audienceDescriptor.toLowerCase()}.',
      actionData: {
        'communityId': community.id,
        'communityName': community.name,
        'communityEmoji': community.emoji,
      },
    );
    if (!context.mounted) return;
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

  Future<void> _openLinkedGroup(
    BuildContext context,
    SupportGroupRecommendation group,
  ) async {
    SupportCommunityRecommendation? community;
    for (final item in result.matching.communities) {
      if (item.id == group.linkedCommunityId) {
        community = item;
        break;
      }
    }

    final target = community ??
        SupportCommunityRecommendation(
          id: group.linkedCommunityId,
          name: group.title,
          emoji: '💬',
          description: group.description,
          memberCount: 0,
          reason: group.identityDescriptor,
          matchedThemes: group.matchedThemes,
          supportCategory: result.analysis.supportCategory,
          audienceCategory: result.analysis.userCategory,
          audienceDescriptor: result.analysis.userCategory.audienceDescriptor,
        );

    await _openCommunity(context, target);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
