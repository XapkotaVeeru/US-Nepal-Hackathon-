import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: provider.notifications.isEmpty
                    ? null
                    : () => provider.markAllAsRead(),
                tooltip: 'Mark all as read',
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationTile(
                context,
                provider.notifications[index],
                provider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see match requests and updates here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationItem notification,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      },
      child: Container(
        color: notification.isRead
            ? null
            : Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    _getNotificationColor(context, notification.type),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight:
                      notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.message),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                provider.markAsRead(notification.id);
                _handleNotificationTap(context, notification);
              },
            ),
            if (notification.type == NotificationType.matchRequest ||
                notification.type == NotificationType.groupInvite)
              _buildActionButtons(context, notification, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    NotificationItem notification,
    NotificationProvider provider,
  ) {
    final requestId = notification.actionData?['requestId'] as String?;
    if (requestId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Decline'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await provider.declineChatRequest(requestId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request declined')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept'),
            onPressed: () async {
              await provider.acceptChatRequest(requestId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request accepted')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
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

  Color _getNotificationColor(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.matchRequest:
        return Theme.of(context).colorScheme.primary;
      case NotificationType.groupInvite:
        return Theme.of(context).colorScheme.secondary;
      case NotificationType.message:
        return Theme.of(context).colorScheme.tertiary;
      case NotificationType.matchFound:
        return Colors.green;
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

  void _handleNotificationTap(
    BuildContext context,
    NotificationItem notification,
  ) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat
        break;
      case NotificationType.matchFound:
        // Navigate to home with results
        break;
      case NotificationType.matchRequest:
      case NotificationType.groupInvite:
        // Show detail dialog
        break;
    }
  }
}
