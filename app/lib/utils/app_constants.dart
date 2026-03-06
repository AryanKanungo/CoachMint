import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// AppConstants — Design tokens, layout constants, and app-wide
/// string/icon lists that don't belong in theme or colors.
/// ════════════════════════════════════════════════════════════════
class AppConstants {
  AppConstants._();

  // ── Income types (unchanged functional data) ──────────────────
  static const List<String> incomeTypes = [
    'gig',
    'student',
    'salaried',
    'freelancer',
  ];

  static const List<String> incomeLabels = [
    'Gig Worker',
    'Student',
    'Salaried',
    'Freelancer',
  ];

  static const List<IconData> incomeIcons = [
    Icons.delivery_dining_rounded,
    Icons.school_rounded,
    Icons.business_center_rounded,
    Icons.computer_rounded,
  ];

  // ── Spacing ───────────────────────────────────────────────────
  static const double spacingXs  = 4.0;
  static const double spacingSm  = 8.0;
  static const double spacingMd  = 16.0;
  static const double spacingLg  = 24.0;
  static const double spacingXl  = 32.0;
  static const double spacingXxl = 48.0;

  /// Standard horizontal screen padding
  static const double screenPaddingH = 20.0;

  /// Standard vertical screen padding
  static const double screenPaddingV = 16.0;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  // ── Border Radii ──────────────────────────────────────────────
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;  // ← uniform card/button radius
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radiusFull = 999.0;

  // ── Animation Durations ───────────────────────────────────────
  static const Duration animFast   = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow   = Duration(milliseconds: 600);

  // ── App Strings ───────────────────────────────────────────────
  static const String appName = 'CoachMint';
  static const String tagline = 'Your money. Your rules.';
}
