import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ─────────────────────────────────────────────────
  static const Color surface         = Color(0xFF080D14);
  static const Color surfaceCard     = Color(0xFF0D1520);
  static const Color surfaceElevated = Color(0xFF111E2E);
  static const Color surfaceInput    = Color(0xFF0D1520);

  static const Color border          = Color(0xFF1C2B3D);

  // Brand — blue-green, easy on dark eyes
  static const Color brand           = Color(0xFF00C896);
  static const Color brandDim        = Color(0xFF009E78);

  // Text
  static const Color textPrimary     = Color(0xFFE8EFF7);
  static const Color textSecondary   = Color(0xFF6B7E96);
  static const Color textMuted       = Color(0xFF3A4E63);

  // Semantic
  static const Color success         = Color(0xFF00C896);
  static const Color warning         = Color(0xFFE09520);
  static const Color danger          = Color(0xFFE03E52);
  static const Color info            = Color(0xFF3D7FD4);

  // Resilience
  static const Color strong          = Color(0xFF00C896);
  static const Color moderate        = Color(0xFFE09520);
  static const Color building        = Color(0xFFE07020);
  static const Color fragile         = Color(0xFFE03E52);

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
        onPrimary: Color(0xFF080D14),
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge:  GoogleFonts.dmSans(fontSize: 48, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1.5, height: 1.0),
        displayMedium: GoogleFonts.dmSans(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1.0, height: 1.1),
        displaySmall:  GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        headlineLarge: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3),
        headlineMedium:GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge:    GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
        titleMedium:   GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        titleSmall:    GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.4),
        bodyLarge:     GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6),
        bodyMedium:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
        bodySmall:     GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted, height: 1.5),
        labelLarge:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        labelSmall:    GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 1.6),
      ),

      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // THE FIX — every border state must be OutlineInputBorder
      // or Flutter falls back to the default underline
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        labelStyle:  GoogleFonts.dmSans(color: textSecondary, fontSize: 14),
        hintStyle:   GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        prefixStyle: GoogleFonts.dmSans(color: brand, fontSize: 16, fontWeight: FontWeight.w500),
        suffixStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // THE FIX — foregroundColor must be very dark on brand background
      // brand = #00C896 (light teal), so text = #080D14 (near-black)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: const Color(0xFF080D14),
          disabledBackgroundColor: const Color(0xFF1C2B3D),
          disabledForegroundColor: const Color(0xFF3A4E63),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // Outline button — ghost style, dark-bg friendly
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: brand,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textSecondary, size: 20),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: textPrimary, letterSpacing: -0.2,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceCard,
        modalBackgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          side: BorderSide(color: border),
        ),
        dragHandleColor: border,
        dragHandleSize: Size(36, 4),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}

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