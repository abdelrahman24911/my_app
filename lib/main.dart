import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'constants/app_colors.dart';
import 'models/mission_model.dart';
import 'models/user_model.dart';
import 'models/auth_model.dart';
import 'models/parental_control_model.dart';
import 'models/screen_time_model.dart';
import 'models/sleep_model.dart';
import 'screens/challenges_screen.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parental_control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/mini_games_screen.dart';
import 'screens/sleep_tracking_screen.dart';
import 'services/screen_time_service.dart';

void main() {
  runApp(const MindQuestApp());
}

class MindQuestApp extends StatelessWidget {
  const MindQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme();
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
        ChangeNotifierProvider(create: (_) => SleepModel()),
        ChangeNotifierProvider(create: (_) {
          final screenTimeModel = ScreenTimeModel();
          // Initialize the screen time service
          ScreenTimeService.initialize(screenTimeModel);
          return screenTimeModel;
        }),
      ],
      child: MaterialApp(
        title: 'MindQuest',
        theme: buildTheme(Brightness.light).copyWith(textTheme: textTheme),
        darkTheme: buildTheme(Brightness.dark).copyWith(textTheme: textTheme),
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
    return Consumer<AuthModel>(
      builder: (context, authModel, child) {
        if (authModel.isAuthenticated) {
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

class _RootNavState extends State<RootNav> {
  int _index = 0;
  final _screens = const [
    HomeScreen(),
    ChallengesScreen(),
    MiniGamesScreen(),
    SleepTrackingScreen(),
    CommunityScreen(),
    AnalyticsScreen(),
    ParentalControlScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.purple;
    final unselectedColor = Colors.grey;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.target), label: 'Challenges'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.gamepad2), label: 'Games'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.moon), label: 'Sleep'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.barChart3), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.shield), label: 'Parental'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}
