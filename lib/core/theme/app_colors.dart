import 'package:flutter/material.dart';

/// Saathi / Shubhmilan design system — splash-inspired: warm peach → pale teal.
/// Primary: warm orange (logo). Secondary: soft green. Surfaces: peach/teal tints.
class AppColors {
  AppColors._();

  // ——— Splash palette (drive app backgrounds and gradients) ———
  /// Warm desaturated peach — splash top, warm surfaces.
  static const Color splashPeach = Color(0xFFF2E4DB);
  /// Muted light mid-tone — gradient middle.
  static const Color splashMid = Color(0xFFEAE6E1);
  /// Pale teal — splash bottom, cool surfaces.
  static const Color splashTeal = Color(0xFFDCE8E5);

  // ——— Primary accent (warm orange from logo) ———
  static const Color saffron = Color(0xFFD97036);
  static const Color saffronLight = Color(0xFFE8925A);
  static const Color saffronDark = Color(0xFFC25A28);

  /// India green — success, positive actions, secondary accent.
  static const Color indiaGreen = Color(0xFF2D6A4F);
  static const Color indiaGreenLight = Color(0xFF40916C);
  static const Color indiaGreenDark = Color(0xFF1B4332);

  /// Navy — secondary UI, outlines, trust.
  static const Color navy = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF2E4A9E);

  // ——— Light mode (splash-aligned) ———
  static const Color lightBackground = Color(0xFFF9F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF2EDE8);
  static const Color lightAccent = saffron;
  static const Color lightAccentLight = Color(0xFFFFF0E6);
  static const Color lightAccentDark = saffronDark;
  static const Color lightBlue = navy;
  static const Color lightBlueLight = navyLight;
  static const Color lightCharcoal = Color(0xFF2A2520);
  static const Color lightTextPrimary = Color(0xFF2A2520);
  static const Color lightTextSecondary = Color(0xFF5C544C);
  static const Color lightTextTertiary = Color(0xFF7A7269);
  static const Color lightDivider = Color(0xFFE5E0DA);
  static const Color lightError = Color(0xFFB91C1C);
  static const Color lightSuccess = indiaGreen;

  // ——— Dark mode ———
  static const Color darkBackground = Color(0xFF0C0A09);
  static const Color darkSurface = Color(0xFF1C1917);
  static const Color darkSurfaceVariant = Color(0xFF292524);
  static const Color darkAccent = saffronLight;
  static const Color darkAccentDim = Color(0xFFEA580C);
  static const Color darkBlue = Color(0xFF60A5FA);
  static const Color darkTextPrimary = Color(0xFFFAFAF9);
  static const Color darkTextSecondary = Color(0xFFA8A29E);
  static const Color darkTextTertiary = Color(0xFF78716C);
  static const Color darkDivider = Color(0xFF44403C);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkSuccess = indiaGreenLight;

  // ——— Gradients ———
  static const LinearGradient accentGradientLight = LinearGradient(
    colors: [Color(0xFFD97036), Color(0xFFE8925A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradientDark = LinearGradient(
    colors: [Color(0xFFE8925A), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Splash gradient: warm peach → muted mid → pale teal (matches splash screen).
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [splashPeach, splashMid, splashTeal],
    stops: [0.0, 0.45, 1.0],
  );

  /// Hero / marketing gradient (warm orange → white → green).
  static const LinearGradient flagGradient = LinearGradient(
    colors: [Color(0xFFD97036), Color(0xFFFFFFFF), Color(0xFF2D6A4F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
}
