import 'package:flutter/material.dart';

class F1Colors {
  static const Color primary = Color(0xFFE10600);
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF242424);
  static const Color surfaceVariant = Color(0xFF2E2E2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color divider = Color(0xFF3A3A3A);

  // Team colors
  static const Map<String, Color> teamColors = {
    'Red Bull Racing': Color(0xFF3671C6),
    'Ferrari': Color(0xFFE8002D),
    'Mercedes': Color(0xFF27F4D2),
    'McLaren': Color(0xFFFF8000),
    'Aston Martin': Color(0xFF229971),
    'Alpine': Color(0xFF0093CC),
    'Williams': Color(0xFF64C4FF),
    'AlphaTauri': Color(0xFF6692FF),
    'RB': Color(0xFF6692FF),
    'Alfa Romeo': Color(0xFFC92D4B),
    'Kick Sauber': Color(0xFF52E252),
    'Haas': Color(0xFFB6BABD),
  };

  static Color getTeamColor(String? teamName) {
    if (teamName == null) return textSecondary;
    for (final entry in teamColors.entries) {
      if (teamName.contains(entry.key) || entry.key.contains(teamName)) {
        return entry.value;
      }
    }
    return textSecondary;
  }
}

final f1DarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: F1Colors.primary,
    surface: F1Colors.surface,
    onSurface: F1Colors.textPrimary,
    secondary: Color(0xFF3A3A3A),
    onSecondary: F1Colors.textPrimary,
  ),
  scaffoldBackgroundColor: F1Colors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: F1Colors.background,
    foregroundColor: F1Colors.textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: F1Colors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  ),
  cardTheme: const CardThemeData(
    color: F1Colors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: F1Colors.primary,
    unselectedLabelColor: F1Colors.textSecondary,
    indicatorColor: F1Colors.primary,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: F1Colors.surface,
    selectedItemColor: F1Colors.primary,
    unselectedItemColor: F1Colors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  dividerTheme: const DividerThemeData(
    color: F1Colors.divider,
    thickness: 1,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: F1Colors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: F1Colors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: F1Colors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: F1Colors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      color: F1Colors.textPrimary,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: F1Colors.textSecondary,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: F1Colors.textSecondary,
      fontSize: 12,
    ),
  ),
);
