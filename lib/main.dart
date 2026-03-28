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

  final anonymousIdService = await AnonymousIdService.create();

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
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F5FF),
        ),

        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
          ),
        ),

        home: const MainNavigationScreen(),
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
      // 🌈 Gradient AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Mental Health Support',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),

      drawer: const AppDrawer(),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // 🧊 Floating Bottom Nav
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black12,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
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
              // 🌈 Gradient Header
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF42A5F5)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.favorite, color: Colors.pink),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.displayName ?? 'Anonymous User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              _tile(context, Icons.settings, "Settings"),
              _tile(context, Icons.save, "Save Profile"),
              _tile(context, Icons.upload, "Import Profile"),
              const Divider(),
              _tile(context, Icons.help_outline, "Help & Support"),
              _tile(context, Icons.privacy_tip_outlined, "Privacy Policy"),
              _tile(context, Icons.info_outline, "About"),
              const Divider(),
              _tile(context, Icons.refresh, "Start Fresh", destructive: true),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      {bool destructive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: destructive
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: destructive
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => Navigator.pop(context),
      ),
    );
  }
}