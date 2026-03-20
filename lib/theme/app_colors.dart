import 'package:flutter/material.dart';

/// Centralised colour palette — mirrors the Figma design tokens.
abstract final class AppColors {
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

  /// Border colour for card edges — muted at 20 % opacity.
  static Color border = const Color(0xFFA67FF5).withValues(alpha: 0.2);
}
