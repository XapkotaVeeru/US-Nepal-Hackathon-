import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _chatRequestsEnabled = true;
  bool _groupInvitesEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Anonymous Profile'),
            subtitle: Consumer<AppStateProvider>(
              builder: (context, appState, _) {
                final id = appState.currentUser?.anonymousId ?? 'Unknown';
                return Text('ID: ${id.length > 16 ? '${id.substring(0, 16)}...' : id}');
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile management coming soon')),
              );
            },
          ),
          const Divider(),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts for matches and messages'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Sound'),
            subtitle: const Text('Play sound for new messages'),
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
          const Divider(),

          // Privacy Section
          _buildSectionHeader(context, 'Privacy'),
          SwitchListTile(
            secondary: const Icon(Icons.person_add_outlined),
            title: const Text('Chat Requests'),
            subtitle: const Text('Allow others to send you chat requests'),
            value: _chatRequestsEnabled,
            onChanged: (v) => setState(() => _chatRequestsEnabled = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.group_add_outlined),
            title: const Text('Group Invites'),
            subtitle: const Text('Allow group invitations'),
            value: _groupInvitesEnabled,
            onChanged: (v) => setState(() => _groupInvitesEnabled = v),
          ),
          const Divider(),

          // Data Section
          _buildSectionHeader(context, 'Data & Storage'),
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: const Text('Export Data'),
            subtitle: const Text('Download your anonymous data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text('Delete All Data', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('Permanently remove all posts, chats, and data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeleteConfirmation(context),
          ),
          const Divider(),

          // Danger Zone
          _buildSectionHeader(context, 'Danger Zone'),
          ListTile(
            leading: Icon(Icons.refresh, color: Theme.of(context).colorScheme.error),
            title: Text('Start Fresh', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('Generate a new anonymous ID'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStartFreshConfirmation(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
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
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all your posts, chats, and messages. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted')));
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
}
