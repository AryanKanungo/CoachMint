import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color brand = Color(0xFF00E5A0);        // Mint green
  static const Color brandDim = Color(0xFF00B87A);
  static const Color surface = Color(0xFF0D0F14);      // Near-black
  static const Color surfaceCard = Color(0xFF161A23);  // Card bg
  static const Color surfaceElevated = Color(0xFF1E2330); // Elevated card
  static const Color border = Color(0xFF262C3A);       // Subtle border

  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textMuted = Color(0xFF4A5568);

  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB547);
  static const Color danger = Color(0xFFFF4C6A);
  static const Color info = Color(0xFF4C8EFF);

  // Resilience score colors
  static const Color strong = Color(0xFF00E5A0);
  static const Color moderate = Color(0xFFFFB547);
  static const Color building = Color(0xFFFF8C42);
  static const Color fragile = Color(0xFFFF4C6A);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: brand,
        secondary: brandDim,
        surface: surfaceCard,
        error: danger,
        onPrimary: Color(0xFF0D0F14),
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.syneTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48, fontWeight: FontWeight.w800, color: textPrimary,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            fontSize: 36, fontWeight: FontWeight.w800, color: textPrimary,
            letterSpacing: -1,
          ),
          displaySmall: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData (
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: const Color(0xFF0D0F14),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: brand),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: brand,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Syne',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    );
  }
}

// Color helpers based on resilience score
Color resilienceColor(int score) {
  if (score >= 75) return AppTheme.strong;
  if (score >= 50) return AppTheme.moderate;
  if (score >= 25) return AppTheme.building;
  return AppTheme.fragile;
}

String resilienceLabel(int score) {
  if (score >= 75) return 'STRONG';
  if (score >= 50) return 'MODERATE';
  if (score >= 25) return 'BUILDING';
  return 'FRAGILE';
}