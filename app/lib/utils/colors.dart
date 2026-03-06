import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// AppColors — Single source of truth for the design system palette
/// Midnight Dark + Emerald Green accent
/// ════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  /// True app background: deep dark
  static const Color background = Color(0xFF121212);

  /// Card / surface background: slightly lifted
  static const Color surface = Color(0xFF1E1E1E);

  /// Elevated surface for inputs, chips, nested containers
  static const Color surfaceElevated = Color(0xFF252525);

  /// Highest elevated surface (e.g. modals, drawers)
  static const Color surfaceHigh = Color(0xFF2C2C2C);

  // ── Brand / Accent ────────────────────────────────────────────
  /// Primary emerald green — CTAs, active states, positive indicators
  static const Color primary = Color(0xFF2ECC71);

  /// Slightly brighter variant for glow / hover
  static const Color primaryBright = Color(0xFF00C853);

  /// Muted emerald for backgrounds behind green elements
  static const Color primaryMuted = Color(0x1A2ECC71); // 10% opacity

  // ── Text ──────────────────────────────────────────────────────
  /// Primary label text — pure white
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary label text — medium grey
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Muted / hint / placeholder text
  static const Color textMuted = Color(0xFF9E9E9E);

  /// Disabled text
  static const Color textDisabled = Color(0xFF616161);

  // ── Borders ───────────────────────────────────────────────────
  /// Default subtle border for cards and inputs
  static const Color border = Color(0xFF2A2A2A);

  /// Focused input border (faint green)
  static const Color borderFocus = Color(0x662ECC71); // 40% primary

  // ── Semantic Colors ───────────────────────────────────────────
  /// Success / income indicators
  static const Color success = Color(0xFF2ECC71);

  /// Warning / caution
  static const Color warning = Color(0xFFF39C12);

  /// Error / expense / danger
  static const Color danger = Color(0xFFE74C3C);

  /// Informational
  static const Color info = Color(0xFF3498DB);

  // ── Legacy aliases kept for backward compatibility ─────────────
  /// @deprecated — use [background]
  static const Color cardBackground = surface;

  /// @deprecated — use [primary]
  static const Color greenAccent = primary;

  /// @deprecated — use [danger]
  static const Color redAccent = danger;

  /// @deprecated — use [textPrimary]
  static const Color mainText = textPrimary;
  static const Color white = textPrimary;

  /// @deprecated — use [textMuted]
  static const Color secondaryText = textMuted;
}
