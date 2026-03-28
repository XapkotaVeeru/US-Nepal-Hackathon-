import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';

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
    // Show different UI based on risk level
    if (post.riskLevel == RiskLevel.high) {
      return _buildHighRiskCard(context);
    } else {
      return _buildMatchResultsCard(context);
    }
  }

  Widget _buildHighRiskCard(BuildContext context) {
    // Mock crisis resources - will come from backend
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
        padding: const EdgeInsets.all(20.0),
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

            // Crisis resources
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
    // Mock similar users - will come from backend
    final similarUsers = [
      SimilarUser(
        id: '1',
        anonymousName: 'Anonymous Butterfly',
        similarityScore: 0.89,
        lastActive: '2 hours ago',
        commonTheme: 'Academic pressure and stress',
      ),
      SimilarUser(
        id: '2',
        anonymousName: 'Anonymous Phoenix',
        similarityScore: 0.85,
        lastActive: '5 hours ago',
        commonTheme: 'Feeling overwhelmed',
      ),
      SimilarUser(
        id: '3',
        anonymousName: 'Anonymous Dove',
        similarityScore: 0.82,
        lastActive: '1 day ago',
        commonTheme: 'Study-related anxiety',
      ),
    ];

    final supportGroups = [
      SupportGroup(
        id: '1',
        name: 'Academic Stress Support',
        memberCount: 12,
        theme: 'Students dealing with academic pressure',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      SupportGroup(
        id: '2',
        name: 'Overwhelmed Together',
        memberCount: 8,
        theme: 'Managing overwhelming feelings',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success message
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'We found people dealing with similar feelings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with others who understand what you\'re going through',
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

        // 1-to-1 Chat Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                      '1-to-1 Chat Available',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect privately with someone who understands',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Similar users list
                ...similarUsers.map(
                  (user) => _buildSimilarUserTile(context, user),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Group Chat Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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

                // Support groups list
                ...supportGroups.map(
                  (group) => _buildSupportGroupTile(context, group),
                ),

                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // Create new group
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
        const SizedBox(height: 16),

        // Action buttons
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
      child: ListTile(
        leading: CircleAvatar(child: Text(user.anonymousName[0])),
        title: Text(user.anonymousName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.commonTheme ?? 'Similar feelings',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${(user.similarityScore * 100).toInt()}% match • ${user.lastActive}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: () {
            // Send chat request
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chat request sent to ${user.anonymousName}'),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Chat'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        isThreeLine: true,
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
            // Join group
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
}
