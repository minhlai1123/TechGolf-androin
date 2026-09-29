import 'package:flutter/material.dart';

/// Golf App Theme with outdoor high-contrast palette
class AppTheme {
  static const Color primaryGreen = Color(0xFF00C853); // Emerald
  static const Color darkGolfGreen = Color(0xFF1B5E20);
  static const Color darkBackground = Color(0xFF121A15);
  static const Color darkSurface = Color(0xFF1C2821);
  static const Color surfaceElevated = Color(0xFF26352C);
  static const Color textHighContrast = Colors.white;
  static const Color textMuted = Color(0xFFA5D6A7);
  static const Color goldAccent = Color(0xFFFFD54F);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        surface: darkSurface,
        onPrimary: Colors.black,
        onSurface: textHighContrast,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textHighContrast,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      useMaterial3: true,
    );
  }
}
