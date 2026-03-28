import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/anonymous_id_service.dart';
import 'services/api_service.dart';
import 'providers/app_state_provider.dart';
import 'providers/post_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final anonymousIdService = await AnonymousIdService.create();

  // TODO: Replace with actual backend URL
  const apiBaseUrl = 'https://your-api-gateway-url.amazonaws.com';
  final apiService = ApiService(baseUrl: apiBaseUrl);

  runApp(MentalHealthSupportApp(
    anonymousIdService: anonymousIdService,
    apiService: apiService,
  ));
}

class MentalHealthSupportApp extends StatelessWidget {
  final AnonymousIdService anonymousIdService;
  final ApiService apiService;

  const MentalHealthSupportApp({
    super.key,
    required this.anonymousIdService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(anonymousIdService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PostProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotificationProvider(apiService)..loadMockNotifications(),
        ),
      ],
      child: MaterialApp(
        title: 'Mental Health Support',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B4CE6),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B4CE6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Support'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          final user = appState.currentUser;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.favorite,
                        size: 32,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'Anonymous User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? 'ID: ${user.anonymousId.substring(0, 12)}...'
                          : '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save Profile'),
                subtitle: const Text('Export your anonymous ID'),
                onTap: () {
                  Navigator.pop(context);
                  if (user != null) {
                    _showSaveProfileDialog(context, user.anonymousId);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Import Profile'),
                subtitle: const Text('Restore from another device'),
                onTap: () {
                  Navigator.pop(context);
                  _showImportProfileDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyDialog(context);
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
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Start Fresh',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text('Get a new anonymous ID'),
                onTap: () {
                  Navigator.pop(context);
                  _showStartFreshConfirmation(context);
                },
              ),
            ],
          );
        },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                // TODO: Implement theme switching
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme switching coming soon')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive match notifications'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
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

  void _showSaveProfileDialog(BuildContext context, String anonymousId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Save your Anonymous ID to access your profile on other devices.'),
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
                    anonymousId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ Keep this ID safe and private',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: anonymousId));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showImportProfileDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your Anonymous ID to restore your profile:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Anonymous ID',
                border: OutlineInputBorder(),
                hintText: 'Paste your ID here',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'This will replace your current profile',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an ID')),
                );
                return;
              }

              // TODO: Implement profile import
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile import coming soon')),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use this app:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('1. Share your feelings on the Home tab'),
              const SizedBox(height: 8),
              const Text('2. We\'ll match you with similar people'),
              const SizedBox(height: 8),
              const Text('3. Accept chat requests in Notifications'),
              const SizedBox(height: 8),
              const Text('4. Chat anonymously in the Chats tab'),
              const SizedBox(height: 16),
              Text(
                'Crisis Resources:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('🆘 988 Suicide & Crisis Lifeline'),
              const Text('📱 Text "HELLO" to 741741'),
              const Text('🌐 NAMI Helpline: 1-800-950-6264'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ This is peer support, not professional therapy. If you\'re in crisis, please call emergency services.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
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

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Privacy Matters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('• All interactions are anonymous'),
              const SizedBox(height: 8),
              const Text('• We don\'t collect personal information'),
              const SizedBox(height: 8),
              const Text('• Your messages are encrypted'),
              const SizedBox(height: 8),
              const Text('• AI analyzes text for matching only'),
              const SizedBox(height: 8),
              const Text('• Data is stored securely on AWS'),
              const SizedBox(height: 16),
              Text(
                'What We Collect:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('• Anonymous ID (generated locally)'),
              const SizedBox(height: 8),
              const Text('• Your posts and messages'),
              const SizedBox(height: 8),
              const Text('• Chat session metadata'),
              const SizedBox(height: 16),
              Text(
                'What We Don\'t Collect:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('• Real name or email'),
              const SizedBox(height: 8),
              const Text('• Phone number'),
              const SizedBox(height: 8),
              const Text('• Location data'),
              const SizedBox(height: 8),
              const Text('• Device identifiers'),
            ],
          ),
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mental Health Support',
      applicationVersion: '1.0.0',
      applicationIcon:
          const Icon(Icons.favorite, size: 48, color: Color(0xFF6B4CE6)),
      children: [
        const Text(
          'A safe, anonymous platform for peer support and emotional wellness.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Built with Flutter and powered by AWS AI services.',
        ),
        const SizedBox(height: 16),
        const Text(
          '💜 Remember: This is not a replacement for professional therapy. If you\'re in crisis, please contact emergency services.',
        ),
      ],
    );
  }

  void _showStartFreshConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Fresh?'),
        content: const Text(
          'This will generate a new anonymous ID. You won\'t be able to access your current chats and data.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final appState = context.read<AppStateProvider>();
              await appState.clearProfile();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New anonymous ID generated!')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }
}
