import 'package:flutter/material.dart';

/// Centralised colour palette — mirrors the Figma design tokens.
///
/// Fully-opaque values use `static const`; pre-computed alpha variants use
/// `static final` so the object is created once and reused every build.
abstract final class AppColors {
  // ── Opaque palette ──────────────────────────────────────────────────────

  /// Main dark background.
  static const Color background = Color(0xFF1A0A2E);

  /// Card / top-bar background.
  static const Color card = Color(0xFF1E1433);

  /// Primary purple accent.
  static const Color primary = Color(0xFF6C3AE8);

  /// Light foreground text.
  static const Color foreground = Color(0xFFF0EDF8);

  /// Lavender muted accent.
  static const Color muted = Color(0xFFA67FF5);

  /// Teal / success.
  static const Color teal = Color(0xFF00E5C3);

  /// Red / error / danger.
  static const Color red = Color(0xFFE84747);

  // ── Pre-computed alpha variants ─────────────────────────────────────────

  /// Border colour for card edges — muted at 20 % opacity.
  static final Color border = muted.withValues(alpha: 0.2);

  /// Card at 30 % — unselected answer tile during reveal.
  static final Color cardDimmed = card.withValues(alpha: 0.3);

  /// Muted at 50 % — hint text, dimmed labels.
  static final Color mutedHalf = muted.withValues(alpha: 0.5);

  /// Muted at 40 % — borders, divider lines, disabled text.
  static final Color mutedSubtle = muted.withValues(alpha: 0.4);

  /// Muted at 30 % — badge background, tie border, dimmed badge.
  static final Color mutedFaint = muted.withValues(alpha: 0.3);

  /// Muted at 60 % — outlined button border.
  static final Color mutedMedium = muted.withValues(alpha: 0.6);

  /// Foreground at 50 % — dimmed badge text during reveal.
  static final Color foregroundHalf = foreground.withValues(alpha: 0.5);

  /// Primary at 25 % — button glow shadow.
  static final Color primaryGlow = primary.withValues(alpha: 0.25);

  /// Primary at 40 % — winner score-card glow.
  static final Color primaryGlowStrong = primary.withValues(alpha: 0.4);

  /// Teal at 30 % — sparkline gradient top.
  static final Color accentGlow = teal.withValues(alpha: 0.3);

  /// Teal at 0 % — sparkline gradient bottom (fully transparent).
  static final Color accentTransparent = teal.withValues(alpha: 0.0);

  /// Black at 70 % — reveal bottom-sheet backdrop.
  static final Color backdropOverlay = Colors.black.withValues(alpha: 0.7);
}
