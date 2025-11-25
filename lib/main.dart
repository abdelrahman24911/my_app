import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'models/mission_model.dart';
import 'models/user_model.dart';
import 'models/auth_model.dart';
import 'models/parental_control_model.dart';
import 'models/screen_time_model.dart';
import 'screens/analytics_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sleep_tracker_screen.dart';
import 'services/screen_time_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MindQuestApp());
}

class MindQuestApp extends StatelessWidget {
  const MindQuestApp({super.key});

  // Cache text theme to avoid recreating on every build
  static final _lightTextTheme = GoogleFonts.interTextTheme();
  static final _darkTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthModel()),
        ChangeNotifierProvider(
          create: (_) => UserModel(
            username: 'MindQuest User',
            xp: 120,
            level: 3,
            streakDays: 3,
            badges: 5,
            rank: 42,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MissionsModel()),
        ChangeNotifierProvider(create: (_) => ParentalControlModel()),
        ChangeNotifierProvider(create: (_) {
          final screenTimeModel = ScreenTimeModel();
          // Initialize the screen time service
          ScreenTimeService.initialize(screenTimeModel);
          return screenTimeModel;
        }),
      ],
      child: MaterialApp(
        title: 'MindQuest',
        theme: buildTheme(Brightness.light).copyWith(textTheme: _lightTextTheme),
        darkTheme: buildTheme(Brightness.dark).copyWith(textTheme: _darkTextTheme),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when isAuthenticated changes
    return Selector<AuthModel, bool>(
      selector: (_, authModel) => authModel.isAuthenticated,
      builder: (context, isAuthenticated, child) {
        if (isAuthenticated) {
          return const RootNav();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> with TickerProviderStateMixin {
  int _index = 0;
  bool _isCollapsed = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const String _prefsKeySelectedIndex = 'selected_tab_index';

  // Lazy screen creation - screens are only created when accessed
  List<Widget> get _screens => [
    const HomeScreen(),
    const ChallengesScreen(),
    const CommunityScreen(),
    const AnalyticsScreen(),
    const SleepTrackerScreen(),
    const ProfileScreen(),
  ];

  final _navItems = const [
    {'icon': LucideIcons.home, 'label': 'Home'},
    {'icon': LucideIcons.target, 'label': 'Challenges'},
    {'icon': LucideIcons.users, 'label': 'Community'},
    {'icon': LucideIcons.barChart3, 'label': 'Analytics'},
    {'icon': LucideIcons.focus, 'label': 'Focus & Block'},
    {'icon': LucideIcons.moon, 'label': 'Sleep'},
    {'icon': LucideIcons.user, 'label': 'Profile'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _restoreSelectedIndex();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  Future<void> _restoreSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefsKeySelectedIndex);
    if (saved != null && saved >= 0 && saved < _screens.length) {
      setState(() {
        _index = saved;
      });
    }
  }

  Future<void> _persistSelectedIndex(int newIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeySelectedIndex, newIndex);
  }

  void _setIndex(int newIndex) {
    if (newIndex == _index) return;
    setState(() => _index = newIndex);
    _persistSelectedIndex(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.purple;
    final unselectedColor = Colors.grey;
    
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.digit1): () => _setIndex(0),
        LogicalKeySet(LogicalKeyboardKey.digit2): () => _setIndex(1),
        LogicalKeySet(LogicalKeyboardKey.digit3): () => _setIndex(2),
        LogicalKeySet(LogicalKeyboardKey.digit4): () => _setIndex(3),
        LogicalKeySet(LogicalKeyboardKey.digit5): () => _setIndex(4),
        LogicalKeySet(LogicalKeyboardKey.digit6): () => _setIndex(5),
        LogicalKeySet(LogicalKeyboardKey.digit7): () => _setIndex(6),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleCollapse,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('MindQuest'),
              ],
            ),
            elevation: 1,
          ),
          body: Stack(
        children: [
          // Use IndexedStack for better performance - keeps all screens in widget tree
          // but only shows the selected one, avoiding rebuild overhead
          IndexedStack(
            index: _index,
            children: _screens,
          ),
          // Scrim when sidebar is open
          if (!_isCollapsed)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleCollapse,
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
            ),
          // Launcher icon moved into AppBar title; removed floating icon
          // Collapsible Left Sidebar Navigation
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container
                (
                  width: _isCollapsed ? 0 : 220,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Button (top of sidebar)
                        GestureDetector(
                          onTap: _toggleCollapse,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isCollapsed ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                if (!_isCollapsed) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Navigation',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Navigation Items
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView(
                              children: _navItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final isSelected = index == _index;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      _setIndex(index);
                                      _toggleCollapse();
                                    },
                                    child: Container(
                                      height: 56,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? selectedColor.withOpacity(0.12)
                                            : Colors.grey.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(color: selectedColor, width: 1)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item['icon'] as IconData,
                                            color: isSelected ? selectedColor : unselectedColor,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item['label'] as String,
                                              style: TextStyle(
                                                color: isSelected ? selectedColor : unselectedColor,
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
