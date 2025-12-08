import 'package:flutter/material.dart';

class AppTheme {
  // 1) Tokens
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB2EBF2), Color(0xFF0288D1)],
  );

  static const Color primaryColor = Color(0xFF0288D1);
  static const Color secondaryColor = Color(0xFFB2EBF2);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color accent = Color(0xFFE1F5FE);
  static const Color textPrimary = Color(0xFF0D47A1);
  static const Color textOnWhite = Colors.black87;
  static const Color heroStripBackground = Color.fromARGB(255, 223, 244, 237);

  static const Color surface = Color(0xFFFDFDFD);
  static const Color surfaceVariant = Color(0xFFE0F7FA);
  static const Color outline = Color(0xFFB0BEC5);
  static const Color shadow = Colors.black26;
  static const Color tertiary = Color(0xFF4DD0E1);

  // 2) ColorScheme using tokens
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: white,
    secondary: secondaryColor,
    onSecondary: textPrimary,
    surface: surface,
    onSurface: textPrimary,
    error: Colors.red,
    onError: white,
    tertiary: tertiary,
    onTertiary: white,
    outline: outline,
  );

  // 3) ThemeData using ColorScheme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: white,
      ),
    );
  }
}
