import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// ════════════════════════════════════════════════════════════════
/// AppTheme — Global MaterialApp ThemeData configuration
/// All screens use Theme.of(context) to pull from here.
/// ════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // ── Direct color references (for non-Theme widget usage) ──────
  static const Color surface          = AppColors.background;
  static const Color surfaceCard      = AppColors.surface;
  static const Color surfaceElevated  = AppColors.surfaceElevated;
  static const Color brand            = AppColors.primary;
  static const Color border           = AppColors.border;
  static const Color textPrimary      = AppColors.textPrimary;
  static const Color textSecondary    = AppColors.textSecondary;
  static const Color textMuted        = AppColors.textMuted;
  static const Color danger           = AppColors.danger;
  static const Color warning          = AppColors.warning;
  static const Color success          = AppColors.success;
  static const Color info             = AppColors.info;

  // ── Border Radius ─────────────────────────────────────────────
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radiusCard = 12.0; // uniform card radius

  static BorderRadius get cardRadius =>
      BorderRadius.circular(radiusCard);

  // ─────────────────────────────────────────────────────────────
  // Main ThemeData
  // ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      // ── Scaffold ───────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── ColorScheme ────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary:          AppColors.primary,
        onPrimary:        Colors.black,
        secondary:        AppColors.primary,
        onSecondary:      Colors.black,
        surface:          AppColors.surface,
        onSurface:        AppColors.textPrimary,
        error:            AppColors.danger,
        onError:          Colors.white,
        outline:          AppColors.border,
        surfaceContainerHighest: AppColors.surfaceElevated,
      ),

      // ── AppBar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),

      // ── Elevated Button ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  AppColors.primary,
          foregroundColor:  Colors.black,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
          disabledForegroundColor: Colors.black45,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.dmSans(
          color: AppColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // ── BottomNavigationBar ────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),

      // ── Drawer ─────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ───────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Icon ───────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),

      // ── Typography ─────────────────────────────────────────
      textTheme: _buildTextTheme(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TextTheme using DM Sans
  // ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display
      displayLarge: GoogleFonts.dmSans(
        fontSize: 57, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -2,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 45, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -1.5,
      ),
      displaySmall: GoogleFonts.dmSans(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -1,
      ),
      // Headline
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      // Title
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      // Body
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      // Label
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: AppColors.textMuted, letterSpacing: 1.2,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: returns color for a resilience score
  // ─────────────────────────────────────────────────────────────
  static Color resilienceColor(int score) {
    if (score >= 70) return success;
    if (score >= 40) return warning;
    return danger;
  }
}

// Top-level convenience alias so existing code calling
// `resilienceColor(score)` without class prefix still compiles.
Color resilienceColor(int score) => AppTheme.resilienceColor(score);
