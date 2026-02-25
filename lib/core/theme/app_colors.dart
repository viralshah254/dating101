import 'package:flutter/material.dart';

/// saathi design system — Indian flag colors blended for a premium look.
/// Saffron (primary), India green (secondary/success), Navy (chakra), White.
class AppColors {
  AppColors._();

  // ——— Indian flag palette ———
  /// Saffron — flag top band. Primary accent for CTAs, selection, focus.
  static const Color saffron = Color(0xFFFF9933);
  static const Color saffronLight = Color(0xFFFFB366);
  static const Color saffronDark = Color(0xFFE68A00);

  /// India green — flag bottom band. Success, positive actions, secondary accent.
  static const Color indiaGreen = Color(0xFF138808);
  static const Color indiaGreenLight = Color(0xFF4CAF50);
  static const Color indiaGreenDark = Color(0xFF0D6606);

  /// Navy — Ashoka Chakra. Secondary UI, outlines, trust.
  static const Color navy = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF2E4A9E);

  // ——— Light mode ———
  static const Color lightBackground = Color(
    0xFFFFFBF7,
  ); // warm off-white (saffron tint)
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(
    0xFFFFF5EB,
  ); // very light saffron
  static const Color lightAccent = saffron;
  static const Color lightAccentLight = saffronLight;
  static const Color lightAccentDark = saffronDark;
  static const Color lightBlue = navy;
  static const Color lightBlueLight = navyLight;
  static const Color lightCharcoal = Color(0xFF2C2C2C);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF5C5C5C);
  static const Color lightTextTertiary = Color(0xFF8A8A8A);
  static const Color lightDivider = Color(0xFFEDE5DC);
  static const Color lightError = Color(0xFFC62828);
  static const Color lightSuccess = indiaGreen;

  // ——— Dark mode ———
  static const Color darkBackground = Color(0xFF0F172A); // deep navy
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkAccent = saffronLight; // saffron pops on dark
  static const Color darkAccentDim = Color(0xFFE68A00);
  static const Color darkBlue = Color(0xFF3B82F6);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkDivider = Color(0xFF475569);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkSuccess = indiaGreenLight;

  // ——— Gradients (saffron ↔ green blend) ———
  static const LinearGradient accentGradientLight = LinearGradient(
    colors: [Color(0xFFFF9933), Color(0xFFFFB366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradientDark = LinearGradient(
    colors: [Color(0xFFFFB366), Color(0xFFE68A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle flag-inspired gradient (saffron → white → green) for hero/splash.
  static const LinearGradient flagGradient = LinearGradient(
    colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
}
