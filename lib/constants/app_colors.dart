import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand per spec
  static const Color purple = Color(0xFF7C3AED); // Purple primary
  static const Color blue = Color(0xFF3B82F6);   // Blue accent
  static const Color teal = Color(0xFF14B8A6);   // Teal
  static const Color orange = Color(0xFFF97316); // Orange
  static const Color pink = Color(0xFFEC4899);   // Pink

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceDark = Color(0xFF111318);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  // Gradient combinations for backgrounds
  static const List<Color> purpleToTeal = [purple, teal];

  static const List<Color> orangeToPink = [orange, pink];

  static LinearGradient backgroundPurpleTeal({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: purpleToTeal);

  static LinearGradient backgroundOrangePink({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: orangeToPink);
}

ThemeData buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}


