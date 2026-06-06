import 'package:flutter/material.dart';

class AppTheme {
  // Dark backgrounds
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color darkBgSecondary = Color(0xFF2D2D2D);
  
  // Pastel accents
  static const Color pastelMint = Color(0xFFB4E7D8);
  static const Color pastelBlush = Color(0xFFFFD7DC);
  static const Color pastelLavender = Color(0xFFD4C5E2);
  static const Color pastelPeach = Color(0xFFFFD4A3);
  static const Color pastelYellow = Color(0xFFFFF4A3);
  
  // Text colors
  static const Color textLight = Color(0xFFE8E8E8);
  static const Color textMuted = Color(0xFFB0B0B0);
  
  // Status colors
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.dark(
        primary: pastelMint,
        secondary: pastelBlush,
        tertiary: pastelLavender,
        surface: darkBgSecondary,
        onPrimary: darkBg,
        onSurface: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBgSecondary,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkBgSecondary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          color: textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pastelMint,
          foregroundColor: darkBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pastelMint,
          side: BorderSide(color: pastelMint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: textMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: textMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: pastelMint, width: 2),
        ),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(pastelMint),
        side: BorderSide(color: pastelMint),
      ),
    );
  }
}
