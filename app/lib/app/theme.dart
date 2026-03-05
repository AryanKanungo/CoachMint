import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color brand           = Color(0xFF00E5A0);
  static const Color brandDim        = Color(0xFF00B87A);
  static const Color surface         = Color(0xFF0D0F14);
  static const Color surfaceCard     = Color(0xFF161A23);
  static const Color surfaceElevated = Color(0xFF1E2330);
  static const Color border          = Color(0xFF262C3A);
  static const Color textPrimary     = Color(0xFFF0F2F5);
  static const Color textSecondary   = Color(0xFF8A94A6);
  static const Color textMuted       = Color(0xFF4A5568);
  static const Color success         = Color(0xFF00E5A0);
  static const Color warning         = Color(0xFFFFB547);
  static const Color danger          = Color(0xFFFF4C6A);
  static const Color info            = Color(0xFF4C8EFF);

  // Category colors
  static const Color essential    = Color(0xFF4C8EFF);
  static const Color nonEssential = Color(0xFFFFB547);
  static const Color savings      = Color(0xFF00E5A0);
  static const Color income       = Color(0xFFB47FFF);

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
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge:   TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.5),
          displayMedium:  TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
          displaySmall:   TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
          headlineLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
          headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
          bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
          bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
          bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
          labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.5),
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
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brand, width: 1.5)),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle:  const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: const Color(0xFF0D0F14),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Color resilienceColor(int score) {
  if (score >= 75) return AppTheme.success;
  if (score >= 50) return AppTheme.warning;
  if (score >= 25) return AppTheme.nonEssential;
  return AppTheme.danger;
}

String resilienceLabel(int score) {
  if (score >= 75) return 'STRONG';
  if (score >= 50) return 'MODERATE';
  if (score >= 25) return 'BUILDING';
  return 'FRAGILE';
}

/// Categories used across SMS categorization + dashboard
const kCategories = [
  {
    'label': 'Essential',
    'icon': Icons.home_rounded,
    'color': AppTheme.essential,
    'sub': 'Rent, groceries, utilities, medicine, fuel',
  },
  {
    'label': 'Non-Essential',
    'icon': Icons.local_cafe_rounded,
    'color': AppTheme.nonEssential,
    'sub': 'Food delivery, shopping, entertainment',
  },
  {
    'label': 'Savings',
    'icon': Icons.savings_rounded,
    'color': AppTheme.savings,
    'sub': 'Emergency fund, goals, FD',
  },
  {
    'label': 'Investments',
    'icon': Icons.trending_up_rounded,
    'color': AppTheme.income,
    'sub': 'SIP, stocks, mutual funds',
  },
];

const kCategoryColors = {
  'Essential':     AppTheme.essential,
  'Non-Essential': AppTheme.nonEssential,
  'Savings':       AppTheme.savings,
  'Investments':   AppTheme.income,
};