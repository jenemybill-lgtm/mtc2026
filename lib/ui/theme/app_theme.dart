import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2563EB); // Executive Corporate Blue
  static const Color primaryNavy = Color(0xFF0A192F); // Deep Corporate Navy
  static const Color accentSlate = Color(0xFF64748B); // Professional Slate Gray
  static const Color successGreen = Color(0xFF16A34A); // Formal Green
  static const Color dangerRed = Color(0xFFDC2626); // Formal Red
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean Crisp Surface

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: primaryNavy,
      surface: Colors.white,
      background: backgroundLight,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy,
      titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryNavy, letterSpacing: -0.2),
      iconTheme: IconThemeData(color: primaryNavy),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryBlue, width: 2.0)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentSlate),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shadowColor: primaryBlue.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
  );
}
