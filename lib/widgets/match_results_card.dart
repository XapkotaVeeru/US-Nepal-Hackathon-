import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_model.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';

class MatchResultsCard extends StatelessWidget {
  final Post post;
  final VoidCallback onCreateNewPost;

  const MatchResultsCard({
    super.key,
    required this.post,
    required this.onCreateNewPost,
  });

  @override
  Widget build(BuildContext context) {
    if (post.riskLevel == RiskLevel.high) {
      return _buildHighRiskCard(context);
    }
    return _buildMatchResultsCard(context);
  }

  Widget _buildHighRiskCard(BuildContext context) {
    final crisisResources = [
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

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 48,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'re Here to Help',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Based on what you shared, we recommend speaking with a professional. Here are immediate support resources:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...crisisResources.map(
              (resource) => _buildCrisisResourceTile(context, resource),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'This platform is for peer support, not crisis intervention. Please reach out to professionals for immediate help.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onCreateNewPost,
              child: const Text('Create New Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrisisResourceTile(
    BuildContext context,
    CrisisResource resource,
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
                tooltip: 'Visit website',
              ),
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => _launchUrl('tel:${resource.phone}'),
              tooltip: 'Call now',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildMatchResultsCard(BuildContext context) {
    final similarUsers = post.similarUsers ?? [];
    final supportGroups = post.supportGroups ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  similarUsers.isNotEmpty
                      ? 'We found people dealing with similar feelings'
                      : 'Your post has been shared',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  similarUsers.isNotEmpty
                      ? 'Send a request and connect when the other person accepts.'
                      : 'We\'ll notify you when we find matches',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (similarUsers.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'People You Can Request',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a private chat request or create a small support group with them.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ...similarUsers.map(
                    (user) => _buildSimilarUserTile(context, user),
                  ),
                ],
              ),
            ),
          ),
        if (similarUsers.isNotEmpty) const SizedBox(height: 16),
        if (supportGroups.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Small Group Available',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join a supportive group with similar experiences',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ...supportGroups.map(
                    (group) => _buildSupportGroupTile(context, group),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Group discovery is unchanged for now.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Group'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (supportGroups.isNotEmpty) const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCreateNewPost,
                child: const Text('Not Now'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onCreateNewPost,
                child: const Text('New Post'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimilarUserTile(BuildContext context, SimilarUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(user.anonymousName[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.anonymousName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.commonTheme ?? 'Similar feelings',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(user.similarityScore * 100).toInt()}% match • ${user.lastActive ?? 'Recently active'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _sendChatRequest(context, user),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat Request'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendGroupRequest(context, user),
                    icon: const Icon(Icons.group_add_outlined, size: 18),
                    label: const Text('Create Group'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportGroupTile(BuildContext context, SupportGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${group.memberCount}')),
        title: Text(group.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.theme, style: const TextStyle(fontSize: 12)),
            Text(
              '${group.memberCount} members',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Request sent to join ${group.name}')),
            );
          },
          icon: const Icon(Icons.group_add, size: 18),
          label: const Text('Join'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendChatRequest(BuildContext context, SimilarUser user) async {
    final appState = context.read<AppStateProvider>();
    final chatProvider = context.read<ChatProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final requesterId = appState.anonymousId;
    final requesterName = appState.currentUser?.displayName ?? 'Anonymous';

    if (requesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your anonymous profile is still loading.')),
      );
      return;
    }

    try {
      await chatProvider.sendChatRequest(
        fromUserId: requesterId,
        toUserId: user.id,
      );
    } catch (_) {
      // Keep the local request flow working even if the backend endpoint is absent.
    }

    notificationProvider.addPendingMatchRequest(
      requesterId: requesterId,
      requesterName: requesterName,
      targetUserId: user.id,
      targetUserName: user.anonymousName,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chat request queued for ${user.anonymousName}. Accept it from Alerts to open the chat.',
        ),
      ),
    );
  }

  void _sendGroupRequest(BuildContext context, SimilarUser user) {
    final appState = context.read<AppStateProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final requesterId = appState.anonymousId;
    final requesterName = appState.currentUser?.displayName ?? 'Anonymous';

    if (requesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your anonymous profile is still loading.')),
      );
      return;
    }

    final groupName =
        user.commonTheme != null && user.commonTheme!.trim().isNotEmpty
            ? '${user.commonTheme!} Circle'
            : 'Shared Support Circle';

    notificationProvider.addPendingGroupInvite(
      requesterId: requesterId,
      requesterName: requesterName,
      targetUserId: user.id,
      targetUserName: user.anonymousName,
      groupName: groupName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Group request queued with ${user.anonymousName}. Accept it from Alerts to create the group.',
        ),
      ),
    );
  }
}
