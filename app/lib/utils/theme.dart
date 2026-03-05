import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Palette ──────────────────────────────────────────────
  // Deep navy base — financial trust, not generic dark
  static const Color surface         = Color(0xFF080C14);   // near-black navy
  static const Color surfaceCard     = Color(0xFF0F1520);   // card bg — blue-dark
  static const Color surfaceElevated = Color(0xFF172030);   // elevated surface
  static const Color surfaceInput    = Color(0xFF111927);   // input bg

  // Borders — very subtle, cool-toned
  static const Color border          = Color(0xFF1E2D42);
  static const Color borderLight     = Color(0xFF253348);

  // Brand — warm gold. Reads as "financial authority", not "startup"
  static const Color brand           = Color(0xFFC9A84C);   // refined gold
  static const Color brandLight      = Color(0xFFE8C96A);   // gold highlight
  static const Color brandDim        = Color(0xFF8A6E2F);   // gold dim

  // Text
  static const Color textPrimary     = Color(0xFFF2F4F8);
  static const Color textSecondary   = Color(0xFF7A8EA8);
  static const Color textMuted       = Color(0xFF3D5068);

  // Semantic
  static const Color success         = Color(0xFF2ECC8E);   // muted green — not neon
  static const Color warning         = Color(0xFFE8A020);   // amber
  static const Color danger          = Color(0xFFE8445A);   // deep red
  static const Color info            = Color(0xFF3D80D4);   // steel blue

  // Resilience score colors — desaturated, professional
  static const Color strong          = Color(0xFF2ECC8E);
  static const Color moderate        = Color(0xFFE8A020);
  static const Color building        = Color(0xFFE86820);
  static const Color fragile         = Color(0xFFE8445A);

  static ThemeData dark() {
    // DM Sans for body — clean, slightly humanist, finance-appropriate
    // Cormorant Garamond display weight for large numbers — editorial authority
    final base = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: brand,
        secondary: brandLight,
        surface: surfaceCard,
        error: danger,
        onPrimary: Color(0xFF080C14),
        onSurface: textPrimary,
      ),
      textTheme: base.copyWith(
        // Display — used for big numbers, section headers
        displayLarge: GoogleFonts.dmSans(
          fontSize: 52,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -2.0,
          height: 1.0,
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displaySmall: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.8,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.2,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1.2,         // spaced caps for section labels
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1.4,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),   // tighter radius — financial
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: const Color(0xFF080C14),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),  // sharp corners
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: brand, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: brand,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textSecondary),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        actionsIconTheme: const IconThemeData(color: textSecondary),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceCard,
        modalBackgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          side: BorderSide(color: border),
        ),
        dragHandleColor: borderLight,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}

// ── Color helpers ──────────────────────────────────────────────────────────

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