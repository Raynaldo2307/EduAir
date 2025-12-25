import 'package:flutter/material.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // 1) Color Tokens (Design System)
  // ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB2EBF2), Color(0xFF0288D1)],
  );

  // Brand / core colors
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color secondaryColor = Color(0xFFB2EBF2);
  static const Color tertiary = Color(0xFF4DD0E1);

  // Neutrals
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color shadow = Colors.black26;

  // Text
  static const Color textPrimary = Color(0xFF0D47A1);
  static const Color textOnWhite = Colors.black87;

  // Surfaces
  static const Color surface = Color(0xFFFDFDFD);
  static const Color surfaceVariant = Color(0xFFE0F7FA);
  static const Color outline = Color(0xFFB0BEC5);

  // Accents / misc
  static const Color accent = Color(0xFFE1F5FE);
  static const Color heroStripBackground = Color.fromARGB(255, 223, 244, 237);

  // Destructive / error
  static const Color danger = Colors.red; // can customize later if needed

  // ─────────────────────────────────────────────
  // 2) Layout Tokens (spacing, radius)
  // ─────────────────────────────────────────────
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;

  static const EdgeInsets screenPadding =
      EdgeInsets.fromLTRB(16, 24, 16, 32);

  // ─────────────────────────────────────────────
  // 3) ColorScheme using tokens
  // ─────────────────────────────────────────────
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: white,
    secondary: secondaryColor,
    onSecondary: textPrimary,
    surface: surface,
    onSurface: textPrimary,
    error: danger,
    onError: white,
    tertiary: tertiary,
    onTertiary: white,
    outline: outline,
  );

  // ─────────────────────────────────────────────
  // 4) ThemeData using ColorScheme
  // ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: surface,

      // Base typography used across the app
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: white,
      ),
    );
  }
}