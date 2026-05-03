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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NormatiqColors.neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: const BorderSide(color: NormatiqColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: const BorderSide(color: NormatiqColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide:
              const BorderSide(color: NormatiqColors.primary600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: const BorderSide(color: NormatiqColors.danger700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide:
              const BorderSide(color: NormatiqColors.danger700, width: 2),
        ),
        labelStyle: const TextStyle(color: NormatiqColors.neutral500),
        floatingLabelStyle: const TextStyle(
            color: NormatiqColors.primary600, fontWeight: FontWeight.w600),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide:
              const BorderSide(color: NormatiqColors.accent500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide: const BorderSide(color: NormatiqColors.danger700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          borderSide:
              const BorderSide(color: NormatiqColors.danger700, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        floatingLabelStyle: const TextStyle(
            color: NormatiqColors.accent500, fontWeight: FontWeight.w600),
      ),
    );
  }
}
