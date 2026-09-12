import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4361EE); 
  static const Color primaryNavy = Color(0xFF1E293B); 
  static const Color accentSlate = Color(0xFF64748B); 
  static const Color successGreen = Color(0xFF16A34A); 
  static const Color dangerRed = Color(0xFFDC2626); 
  static const Color backgroundLight = Color(0xFFE2E8F0); // Soft, eye-soothing slate background
  static const Color surfaceSoft = Color(0xFFF8FAFC); // Eye-soothing soft fill for cards

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: primaryNavy,
      surface: surfaceSoft,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: surfaceSoft,
      foregroundColor: primaryNavy,
      titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryNavy, letterSpacing: -0.2),
      iconTheme: IconThemeData(color: primaryNavy),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
      ),
      color: surfaceSoft,
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
      fillColor: const Color(0xFFF1F5F9), // Soft eye-soothing fill
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryBlue, width: 2.0)),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
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
      color: Colors.black.withValues(alpha: 0.08),
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
