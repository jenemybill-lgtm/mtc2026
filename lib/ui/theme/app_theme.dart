import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4361EE); // Vibrant Blue
  static const Color primaryNavy = Color(0xFF1E293B); // Dark Navy
  static const Color accentPink = Color(0xFFF72585);
  static const Color successGreen = Color(0xFF38B000);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color backgroundLight = Color(0xFFF1F5F9); // Light Gray-Blue

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: const Color(0xFF3A0CA3), // Deep Purple
      surface: Colors.white,
      background: backgroundLight,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy,
      titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryNavy, letterSpacing: -0.5),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryBlue, width: 2.0)),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blueGrey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: primaryBlue.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
      ),
    ),
    scaffoldBackgroundColor: backgroundLight,
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Colors.black.withValues(alpha: 0.06),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
  );
}
