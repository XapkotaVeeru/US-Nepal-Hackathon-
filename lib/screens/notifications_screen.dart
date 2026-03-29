import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notifications.isEmpty) {
          return const _EmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: provider.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final notification = provider.notifications[index];
            return NotificationTile(notification: notification);
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Request approvals and updates will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final isActionable = notification.type == NotificationType.matchRequest ||
        notification.type == NotificationType.groupInvite;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                provider.addNotification(notification);
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 0,
        color: isUnread
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColor(context, notification.type),
                child: Icon(
                  _getIcon(notification.type),
                  color: Colors.white,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.message),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () => provider.markAsRead(notification.id),
            ),
            if (isActionable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _decline(context, notification),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _accept(context, notification),
                        child: Text(
                          notification.type == NotificationType.groupInvite
                              ? 'Accept Group'
                              : 'Accept Chat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, NotificationItem notification) async {
    final provider = context.read<NotificationProvider>();
    provider.markAsRead(notification.id);

    final requestId = notification.actionData?['requestId'] as String?;
    if (requestId == null) return;

    await provider.acceptChatRequest(requestId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notification.type == NotificationType.groupInvite
              ? 'Group created. You can open it from Chats.'
              : 'Chat is ready. You can open it from Chats.',
        ),
      ),
    );
  }

  Future<void> _decline(
    BuildContext context,
    NotificationItem notification,
  ) async {
    final provider = context.read<NotificationProvider>();
    final requestId = notification.actionData?['requestId'] as String?;
    if (requestId == null) return;

    await provider.declineChatRequest(requestId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request declined.')),
    );
  }
}

IconData _getIcon(NotificationType type) {
  switch (type) {
    case NotificationType.matchRequest:
      return Icons.person_add;
    case NotificationType.groupInvite:
      return Icons.group_add;
    case NotificationType.message:
      return Icons.message;
    case NotificationType.matchFound:
      return Icons.check_circle;
  }
}

Color _getColor(BuildContext context, NotificationType type) {
  final scheme = Theme.of(context).colorScheme;

  switch (type) {
    case NotificationType.matchRequest:
      return scheme.primary;
    case NotificationType.groupInvite:
      return scheme.secondary;
    case NotificationType.message:
      return scheme.tertiary;
    case NotificationType.matchFound:
      return Colors.green;
  }
}

String _formatTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return '${time.day}/${time.month}/${time.year}';
}
