import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/mood_tracking_screen.dart';
import 'screens/journaling_screen.dart';
import 'screens/crisis_resources_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
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
              // Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
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
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? 'ID: ${user.anonymousId.substring(0, 12)}...'
                          : 'Your safe, anonymous space',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),

              // 1. Insights
              ListTile(
                leading: const Icon(Icons.insights),
                title: const Text('Insights'),
                subtitle: const Text('Weekly mood trends & stats'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InsightsScreen()),
                  );
                },
              ),

              // 2. Mood Tracking
              ListTile(
                leading: const Icon(Icons.mood),
                title: const Text('Mood Tracking'),
                subtitle: const Text('Log how you\'re feeling'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MoodTrackingScreen()),
                  );
                },
              ),

              // 3. Journaling
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Journaling'),
                subtitle: const Text('Write your thoughts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JournalingScreen()),
                  );
                },
              ),

              // 4. Crisis Resources
              ListTile(
                leading: Icon(
                  Icons.emergency,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Crisis Resources',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Helplines & emergency contacts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CrisisResourcesScreen()),
                  );
                },
              ),

              const Divider(),

              // 5. Settings
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              // 6. About App
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About App'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AboutScreen()),
                  );
                },
              ),

              const Divider(),

              // 7. Logout (Start Fresh)
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text('Start fresh with a new ID'),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.logout,
            size: 40, color: Theme.of(context).colorScheme.error),
        title: const Text('Logout & Start Fresh?'),
        content: const Text(
          'This will generate a new anonymous ID. You won\'t be able to access your current chats, posts, and journal entries.\n\nThis action cannot be undone.',
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
                  const SnackBar(
                    content: Text('Logged out. New anonymous ID generated!'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

