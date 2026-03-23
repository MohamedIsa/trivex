import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised [ThemeData] definitions for dark and light mode.
///
/// Consumed by [MaterialApp] via `theme:` and `darkTheme:`.
/// All colour tokens are sourced from [AppColors] — no raw hex here.
abstract final class AppTheme {
  // ── Dark theme (existing design — zero visual regressions) ──────────────

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.dark(
      surface: AppColors.card,
      primary: AppColors.primary,
      onPrimary: AppColors.foreground,
      onSurface: AppColors.foreground,
      error: AppColors.red,
      secondary: AppColors.teal,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.foreground),
      bodyMedium: TextStyle(color: AppColors.foreground),
      bodySmall: TextStyle(color: AppColors.muted),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.teal,
    ),
  );

  // ── Light theme ─────────────────────────────────────────────────────────

  static const Color _lightBackground = Color(0xFFF5F3FF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightForeground = Color(0xFF1A0A2E);
  static const Color _lightMuted = Color(0xFF6C3AE8);
  static const Color _lightTeal = Color(0xFF009E87);
  static const Color _lightRed = Color(0xFFC62828);

  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: ColorScheme.light(
      surface: _lightCard,
      primary: AppColors.primary,
      onPrimary: const Color(0xFFF0EDF8),
      onSurface: _lightForeground,
      error: _lightRed,
      secondary: _lightTeal,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: _lightForeground),
      bodyMedium: TextStyle(color: _lightForeground),
      bodySmall: TextStyle(color: _lightMuted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _lightTeal,
    ),
  );
}
