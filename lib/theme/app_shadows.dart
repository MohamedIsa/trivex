import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Centralised box-shadow constants — replaces all inline BoxShadow() calls.
abstract final class AppShadows {
  /// Primary purple glow (buttons, selected elements).
  static final BoxShadow primaryGlow = BoxShadow(
    color: AppColors.primaryGlow,
    blurRadius: 24,
  );

  /// Stronger primary glow (winner score card).
  static final BoxShadow primaryGlowStrong = BoxShadow(
    color: AppColors.primaryGlowStrong,
    blurRadius: 24,
  );

  /// Teal accent glow.
  static final BoxShadow tealGlow = BoxShadow(
    color: AppColors.accentGlow,
    blurRadius: 12,
  );

  /// Smaller primary glow for difficulty pills.
  static final BoxShadow primaryGlowSmall = BoxShadow(
    color: AppColors.primaryGlow,
    blurRadius: 16,
  );
}
