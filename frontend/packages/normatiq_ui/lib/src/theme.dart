import 'package:flutter/material.dart';
import 'tokens.dart';

class NormatiqTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NormatiqColors.primary600,
        primary: NormatiqColors.primary600,
        secondary: NormatiqColors.accent500,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: NormatiqColors.neutral50,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          side: const BorderSide(color: NormatiqColors.neutral200),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: NormatiqColors.neutral900,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    const darkSurface = Color(0xFF0F172A); // Slate 950
    const darkCard = Color(0xFF1E293B); // Slate 800

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: NormatiqColors.primary600,
        primary: NormatiqColors.accent500,
        secondary: NormatiqColors.accent500,
        surface: darkSurface,
        onSurface: Colors.white,
        surfaceContainer: darkCard,
      ),
      scaffoldBackgroundColor: darkSurface,
      dividerColor: Colors.white10,
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }
}
