import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF4361EE); // Vibrant Blue
  static const Color primaryNavy = Color(0xFF1E293B); // Dark Slate/Navy
  static const Color accentPink = Color(0xFFF72585); // Vibrant Pink
  static const Color successGreen = Color(0xFF38B000); 
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color backgroundLight = Color(0xFFF1F5F9); 
  static const Color backgroundDark = Color(0xFF0F172A); // Very deep slate/navy
  static const Color cardDark = Color(0xFF1E293B); // Lighter slate for cards

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme(), // Apply Poppins font globally
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: const Color(0xFF7209B7), // Vibrant Purple
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundLight,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy,
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w900, 
        fontSize: 16, 
        color: primaryNavy, 
        letterSpacing: 0.5
      ),
      iconTheme: const IconThemeData(color: primaryNavy),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1.0),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: primaryBlue.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      extendedTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, letterSpacing: 1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryBlue, width: 2.0)),
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shadowColor: primaryBlue.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Colors.black.withValues(alpha: 0.06),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: const Color(0xFF7209B7),
      surface: cardDark,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: cardDark,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w900, 
        fontSize: 16, 
        color: Colors.white, 
        letterSpacing: 0.5
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: primaryBlue.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      extendedTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, letterSpacing: 1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0F172A), // Darker than card
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryBlue, width: 2.0)),
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shadowColor: primaryBlue.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
    ),
  );
}
