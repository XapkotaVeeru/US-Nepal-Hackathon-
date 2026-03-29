import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/discover_screen.dart';
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
import 'services/emotional_analysis_service.dart';
import 'services/llm_chat_service.dart';
import 'services/support_matching_service.dart';
import 'config/backend_config.dart';

import 'providers/app_state_provider.dart';
import 'providers/post_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/community_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/mood_provider.dart';
import 'repositories/journal_repository.dart';
import 'repositories/mood_repository.dart';
import 'widgets/help_me_now_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final anonymousIdService = await AnonymousIdService.create();

  const apiBaseUrl = BackendConfig.defaultApiBaseUrl;
  final apiService = ApiService(baseUrl: apiBaseUrl);
  const emotionalAnalysisService = ResilientEmotionalAnalysisService(
    remoteAdapter: HuggingFaceEmbeddingEmotionalAnalysisAdapter(),
    fallback: LocalEmotionalAnalysisService(),
  );
  const supportMatchingService = LocalSupportMatchingService();
  const llmChatService = ResilientLlmChatService(
    fallback: LocalSupportLlmChatService(
      emotionalAnalysisService: emotionalAnalysisService,
    ),
  );
  final moodRepository = MoodRepository(apiService);
  final journalRepository = JournalRepository(apiService);

  runApp(MentalHealthSupportApp(
    anonymousIdService: anonymousIdService,
    apiService: apiService,
    emotionalAnalysisService: emotionalAnalysisService,
    supportMatchingService: supportMatchingService,
    llmChatService: llmChatService,
    moodRepository: moodRepository,
    journalRepository: journalRepository,
  ));
}

/// ─────────────────────────────────────────────
///  Design Tokens
/// ─────────────────────────────────────────────
class AppColors {
  static const sage = Color(0xFF52A77A);
  static const sageLight = Color(0xFF7EC8A0);
  static const sageDark = Color(0xFF3A7A5A);

  static const cream = Color(0xFFF7F5F0);
  static const creamDark = Color(0xFFEDE9E0);

  static const amber = Color(0xFFE8A838);
  static const amberSoft = Color(0xFFFFF3D8);

  static const ink = Color(0xFF1C2B2A);
  static const inkLight = Color(0xFF5C706C);
  static const inkMuted = Color(0xFF9AACAA);

  static const darkSurface = Color(0xFF14201E);
  static const darkCard = Color(0xFF1F2E2B);
  static const darkBorder = Color(0xFF2C3F3B);
}

/// ─────────────────────────────────────────────
///  App Root
/// ─────────────────────────────────────────────
class MentalHealthSupportApp extends StatelessWidget {
  final AnonymousIdService anonymousIdService;
  final ApiService apiService;
  final EmotionalAnalysisService emotionalAnalysisService;
  final SupportMatchingService supportMatchingService;
  final LlmChatService llmChatService;
  final MoodRepository moodRepository;
  final JournalRepository journalRepository;

  const MentalHealthSupportApp({
    super.key,
    required this.anonymousIdService,
    required this.apiService,
    required this.emotionalAnalysisService,
    required this.supportMatchingService,
    required this.llmChatService,
    required this.moodRepository,
    required this.journalRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<EmotionalAnalysisService>.value(
          value: emotionalAnalysisService,
        ),
        Provider<SupportMatchingService>.value(
          value: supportMatchingService,
        ),
        Provider<LlmChatService>.value(
          value: llmChatService,
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AppStateProvider(anonymousIdService, apiService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PostProvider(
            apiService: apiService,
            emotionalAnalysisService: emotionalAnalysisService,
            supportMatchingService: supportMatchingService,
          ),
        ),
        ChangeNotifierProxyProvider<AppStateProvider, ChatProvider>(
          create: (_) => ChatProvider(
            apiService: apiService,
            llmChatService: llmChatService,
          ),
          update: (_, appState, chatProvider) {
            final provider = chatProvider ??
                ChatProvider(
                  apiService: apiService,
                  llmChatService: llmChatService,
                );
            if (BackendConfig.supportsWebSockets(apiService.baseUrl)) {
              provider.bindAnonymousUser(
                anonymousId: appState.anonymousId,
                wsUrl: BackendConfig.websocketUrlFor(apiService.baseUrl),
              );
            } else {
              provider.disableRealtime();
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppStateProvider, NotificationProvider>(
          create: (_) => NotificationProvider(apiService),
          update: (_, appState, notificationProvider) {
            final provider =
                notificationProvider ?? NotificationProvider(apiService);
            provider.bindUser(appState.anonymousId);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppStateProvider, CommunityProvider>(
          create: (_) => CommunityProvider(apiService: apiService),
          update: (_, appState, communityProvider) {
            final provider =
                communityProvider ?? CommunityProvider(apiService: apiService);
            final userId = appState.anonymousId;
            if (userId != null) {
              provider.setAnonymousId(userId);
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppStateProvider, MoodProvider>(
          create: (_) => MoodProvider(moodRepository),
          update: (_, appState, moodProvider) {
            final provider = moodProvider ?? MoodProvider(moodRepository);
            provider.bindUser(
              userId: appState.anonymousId,
              displayName: appState.currentUser?.displayName,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppStateProvider, JournalProvider>(
          create: (_) => JournalProvider(journalRepository),
          update: (_, appState, journalProvider) {
            final provider =
                journalProvider ?? JournalProvider(journalRepository);
            provider.bindUser(
              userId: appState.anonymousId,
              displayName: appState.currentUser?.displayName,
            );
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Serenity',
        debugShowCheckedModeBanner: false,

        // ── Light Theme ──────────────────────────
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.sage,
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFD4EFE1),
            onPrimaryContainer: AppColors.sageDark,
            secondary: AppColors.amber,
            onSecondary: Colors.white,
            secondaryContainer: AppColors.amberSoft,
            onSecondaryContainer: Color(0xFF7A4A00),
            surface: AppColors.cream,
            onSurface: AppColors.ink,
            surfaceContainerHighest: AppColors.creamDark,
            error: Color(0xFFD45C5C),
            onError: Colors.white,
            outline: AppColors.inkMuted,
          ),
          scaffoldBackgroundColor: AppColors.cream,
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          textTheme: _buildTextTheme(AppColors.ink),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sage,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.creamDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // ── Dark Theme ──────────────────────────
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.dark,
            primary: AppColors.sageLight,
            onPrimary: AppColors.darkSurface,
            primaryContainer: AppColors.sageDark,
            onPrimaryContainer: AppColors.sageLight,
            secondary: AppColors.amber,
            onSecondary: AppColors.darkSurface,
            secondaryContainer: Color(0xFF3D2800),
            onSecondaryContainer: AppColors.amber,
            surface: AppColors.darkSurface,
            onSurface: Color(0xFFE8F0EE),
            surfaceContainerHighest: AppColors.darkCard,
            error: Color(0xFFFF8A8A),
            onError: AppColors.darkSurface,
            outline: AppColors.darkBorder,
          ),
          scaffoldBackgroundColor: AppColors.darkSurface,
          cardTheme: CardThemeData(
            elevation: 0,
            color: AppColors.darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkSurface,
            foregroundColor: Color(0xFFE8F0EE),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          textTheme: _buildTextTheme(const Color(0xFFE8F0EE)),
        ),

        home: const MainNavigationScreen(),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'serif',
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: -1,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: 'serif',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'serif',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.1,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: baseColor.withValues(alpha: 0.75),
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  Main Navigation Shell
/// ─────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _tabControllers;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoverScreen(),
    ChatsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chats',
    ),
    _NavItem(
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _tabControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _tabControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    _tabControllers[_currentIndex].reverse();
    _tabControllers[index].forward();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ── Top App Bar ──────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Builder(
          builder: (ctx) =>
              _TopBar(onMenuTap: () => Scaffold.of(ctx).openDrawer()),
        ),
      ),

      drawer: const AppDrawer(),
      floatingActionButton: const HelpMeNowButton(),

      // ── Body ─────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Custom Bottom Navigation ─────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.creamDark.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : AppColors.sage.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isSelected = i == _currentIndex;
                return _NavButton(
                  item: item,
                  isSelected: isSelected,
                  controller: _tabControllers[i],
                  onTap: () => _onTabTapped(i),
                  colorScheme: colorScheme,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  Top Bar
/// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _TopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cream,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.creamDark,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              onPressed: onMenuTap,
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFE8F0EE) : AppColors.ink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 14,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              tooltip: 'Menu',
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'serenity',
                  style: textTheme.headlineMedium?.copyWith(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    color: AppColors.sage,
                    fontSize: 20,
                  ),
                ),
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const Spacer(),
            _TopBarAction(icon: Icons.search_rounded, onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.creamDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFFE8F0EE) : AppColors.inkLight,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  Nav Button
/// ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final AnimationController controller;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.controller,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 48 : 36,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: isSelected ? 0.3 : 0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  App Drawer
/// ─────────────────────────────────────────────
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          final user = appState.currentUser;

          return Column(
            children: [
              // ── Profile Header ───────────────
              _DrawerHeader(user: user, isDark: isDark, textTheme: textTheme),

              // ── Navigation Items ─────────────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // TOOLS section
                    _DrawerSection(
                      label: 'TOOLS',
                      items: [
                        _DrawerItem(
                          icon: Icons.insights_rounded,
                          label: 'Insights',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const InsightsScreen()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.mood_rounded,
                          label: 'Mood Tracking',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MoodTrackingScreen()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.book_outlined,
                          label: 'Journaling',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const JournalingScreen()),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ACCOUNT section
                    _DrawerSection(
                      label: 'ACCOUNT',
                      items: [
                        _DrawerItem(
                          icon: Icons.tune_rounded,
                          label: 'Settings',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.info_outline_rounded,
                          label: 'About Serenity',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Crisis Resources — visually distinct
                    _DrawerItem(
                      icon: Icons.emergency_rounded,
                      label: 'Crisis Resources',
                      isDark: isDark,
                      isEmergency: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CrisisResourcesScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Logout / destructive
                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout / Start Fresh',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutConfirmation(context, appState);
                      },
                    ),
                  ],
                ),
              ),

              // ── Footer ───────────────────────
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.sage,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You are not alone.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.sage,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout_rounded,
            size: 40, color: Theme.of(ctx).colorScheme.error),
        title: const Text('Logout & Start Fresh?'),
        content: const Text(
          'This will generate a new anonymous ID. '
          "You won't be able to access your current chats, posts, "
          'and journal entries.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await appState.clearProfile();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out. New anonymous ID generated!'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  Drawer Sub-widgets
/// ─────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final TextTheme textTheme;

  const _DrawerHeader(
      {required this.user, required this.isDark, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.creamDark,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sage, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.sageLight.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: AppColors.sage,
                    size: 26,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user?.displayName ?? 'Anonymous',
            style: textTheme.titleLarge?.copyWith(
              fontFamily: 'serif',
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 2),
            Text(
              'ID: ${user.anonymousId.toString().substring(0, 12)}...',
              style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🌿  Safe Space Member',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.sage,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _DrawerSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Column(children: items),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;
  final bool isEmergency;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color textColor;
    final Color bgColor;

    if (isDestructive) {
      iconColor = const Color(0xFFD45C5C);
      textColor = const Color(0xFFD45C5C);
      bgColor = const Color(0xFFD45C5C).withValues(alpha: 0.1);
    } else if (isEmergency) {
      iconColor = const Color(0xFFE8A838);
      textColor = isDark ? const Color(0xFFFFD580) : const Color(0xFF7A4A00);
      bgColor = const Color(0xFFE8A838).withValues(alpha: 0.12);
    } else {
      iconColor = AppColors.sage;
      textColor = isDark ? const Color(0xFFCFDDDA) : AppColors.inkLight;
      bgColor = isDark ? AppColors.darkCard : AppColors.creamDark;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
