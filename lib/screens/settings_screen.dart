import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final user = appState.currentUser;
        final isBusy = appState.isLoading;
        final id = user?.anonymousId ?? 'Unknown';

        return Scaffold(
          appBar: AppBar(title: const Text('Settings'), centerTitle: true),
          body: ListView(
            children: [
              // Account Section
              _buildSectionHeader(context, 'Account'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Anonymous Profile'),
                subtitle: Text(
                  user == null
                      ? 'Profile unavailable'
                      : '${user.displayName}\nID: ${id.length > 16 ? '${id.substring(0, 16)}...' : id}',
                ),
                isThreeLine: user != null,
                trailing: const Icon(Icons.chevron_right),
                onTap: user == null || isBusy
                    ? null
                    : () => _showEditDisplayNameDialog(context, user.displayName),
              ),
              const Divider(),

              // Notifications Section
              _buildSectionHeader(context, 'Notifications'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Push Notifications'),
                subtitle: const Text(
                  'Receive alerts for matches and messages',
                ),
                value: user?.notificationsEnabled ?? true,
                onChanged: user == null || isBusy
                    ? null
                    : (value) => _saveSettings(
                          context,
                          notificationsEnabled: value,
                        ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Sound'),
                subtitle: const Text('Play sound for new messages'),
                value: user?.soundEnabled ?? true,
                onChanged: user == null || isBusy
                    ? null
                    : (value) => _saveSettings(
                          context,
                          soundEnabled: value,
                        ),
              ),
              const Divider(),

              // Privacy Section
              _buildSectionHeader(context, 'Privacy'),
              SwitchListTile(
                secondary: const Icon(Icons.person_add_outlined),
                title: const Text('Chat Requests'),
                subtitle: const Text(
                  'Allow others to send you chat requests',
                ),
                value: user?.chatRequestsEnabled ?? true,
                onChanged: user == null || isBusy
                    ? null
                    : (value) => _saveSettings(
                          context,
                          chatRequestsEnabled: value,
                        ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.group_add_outlined),
                title: const Text('Group Invites'),
                subtitle: const Text('Allow group invitations'),
                value: user?.groupInvitesEnabled ?? true,
                onChanged: user == null || isBusy
                    ? null
                    : (value) => _saveSettings(
                          context,
                          groupInvitesEnabled: value,
                        ),
              ),
              const Divider(),

              // Data Section
              _buildSectionHeader(context, 'Data & Storage'),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: const Text('Export Data'),
                subtitle: const Text('Copy your anonymous profile bundle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: user == null || isBusy ? null : () => _exportData(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete App Data',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Reset chat-linked profile data but keep this anonymous ID',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: user == null || isBusy
                    ? null
                    : () => _showDeleteConfirmation(context),
              ),
              const Divider(),

              // Danger Zone
              _buildSectionHeader(context, 'Danger Zone'),
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Start Fresh',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text('Generate a new anonymous ID'),
                trailing: const Icon(Icons.chevron_right),
                onTap: isBusy ? null : () => _showStartFreshConfirmation(context),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App Data?'),
        content: const Text(
          'This clears the profile-linked data managed by this app and resets your settings, while keeping the same anonymous ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await context.read<AppStateProvider>().resetProfileData();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile data reset')),
                );
              } catch (_) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not reset your profile data'),
                  ),
                );
              }
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
        content: const Text('This will generate a new anonymous ID. You won\'t be able to access your current chats and data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final appState = context.read<AppStateProvider>();
              await appState.clearProfile();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New anonymous ID generated!')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings(
    BuildContext context, {
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? chatRequestsEnabled,
    bool? groupInvitesEnabled,
  }) async {
    try {
      await context.read<AppStateProvider>().updateSettings(
            notificationsEnabled: notificationsEnabled,
            soundEnabled: soundEnabled,
            chatRequestsEnabled: chatRequestsEnabled,
            groupInvitesEnabled: groupInvitesEnabled,
          );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save settings')),
      );
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final profileData = await context.read<AppStateProvider>().exportProfile();
    final payload = const JsonEncoder.withIndent('  ').convert(profileData);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Profile'),
        content: SingleChildScrollView(
          child: SelectableText(payload),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (!context.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile bundle copied to clipboard'),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showEditDisplayNameDialog(
    BuildContext context,
    String currentDisplayName,
  ) {
    final controller = TextEditingController(text: currentDisplayName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'Anonymous Brave Butterfly',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final nextName = controller.text.trim();
              if (nextName.isEmpty) return;

              try {
                await context.read<AppStateProvider>().updateDisplayName(nextName);
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Display name updated')),
                );
              } catch (_) {
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not update your display name'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
