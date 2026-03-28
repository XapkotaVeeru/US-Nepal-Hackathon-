import 'package:flutter/material.dart';
import '../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isProfileSaved = false;
  String _anonymousId = 'anon_abc123xyz';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Anonymous User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $_anonymousId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save profile option
                    if (!_isProfileSaved)
                      FilledButton.icon(
                        onPressed: () {
                          _showSaveProfileDialog(context);
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Profile'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Profile Saved',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Activity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, '5', 'Posts', Icons.post_add),
                        _buildStatItem(
                          context,
                          '3',
                          'Chats',
                          Icons.chat_bubble,
                        ),
                        _buildStatItem(context, '2', 'Groups', Icons.group),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // My posts section
            Text('My Posts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildMyPostsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMyPostsList(BuildContext context) {
    // Mock posts data
    final posts = [
      Post(
        id: '1',
        content:
            'I feel overwhelmed with studies and don\'t know how to handle the pressure...',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        riskLevel: RiskLevel.low,
      ),
      Post(
        id: '2',
        content: 'Feeling anxious about upcoming exams and career decisions...',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        riskLevel: RiskLevel.medium,
      ),
      Post(
        id: '3',
        content: 'Having trouble sleeping due to stress...',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        riskLevel: RiskLevel.low,
      ),
    ];

    if (posts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.post_add,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'No posts yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Share your feelings on the Home tab',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: posts.map((post) => _buildPostCard(context, post)).toList(),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRiskLevelColor(context, post.riskLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.riskLevel.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    _showPostOptions(context, post);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskLevelColor(BuildContext context, RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showSaveProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saving your profile will allow you to:'),
            const SizedBox(height: 12),
            const Text('• Access your chats on other devices'),
            const Text('• Keep your conversation history'),
            const Text('• Recover your data if you reinstall'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Anonymous ID:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _anonymousId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save this ID to access your profile on another device',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _isProfileSaved = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile saved! Keep your ID safe.'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete All Data'),
              subtitle: const Text('Remove all your posts and chats'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Start Fresh'),
              subtitle: const Text('Get a new anonymous ID'),
              onTap: () {
                Navigator.pop(context);
                _showStartFreshConfirmation(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all your posts, chats, and messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data deleted')));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStartFreshConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Fresh?'),
        content: const Text(
          'This will generate a new anonymous ID. You won\'t be able to access your current chats and data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _anonymousId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
                _isProfileSaved = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New anonymous ID generated')),
              );
            },
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mental Health Support',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.favorite, size: 48),
      children: [
        const Text(
          'A safe, anonymous platform for peer support and emotional wellness.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Remember: This is not a replacement for professional therapy. If you\'re in crisis, please contact emergency services.',
        ),
      ],
    );
  }

  void _showPostOptions(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Full Post'),
              onTap: () {
                Navigator.pop(context);
                // Show full post
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Post'),
              onTap: () {
                Navigator.pop(context);
                // Delete post
              },
            ),
          ],
        ),
      ),
    );
  }
}
