import 'package:flutter/material.dart';

/// Shared design tokens for spacing, radius, elevation, motion, shadows, and icons.
class AppTokens {
  AppTokens._();

  // ═══════════════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════════════

  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // ═══════════════════════════════════════════════════════════════════
  // RADIUS
  // ═══════════════════════════════════════════════════════════════════

  static const double radius4 = 4;
  static const double radius8 = 8;
  static const double radius12 = 12;
  static const double radius14 = 14;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radius28 = 28;
  static const double radius32 = 32;
  static const double radiusPill = 999;

  static BorderRadius rounded(double value) => BorderRadius.circular(value);

  // ═══════════════════════════════════════════════════════════════════
  // ELEVATION
  // ═══════════════════════════════════════════════════════════════════

  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;
  static const double elevation8 = 8;

  // ═══════════════════════════════════════════════════════════════════
  // MOTION — durations and curves for premium, restrained animation
  // ═══════════════════════════════════════════════════════════════════

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 450);
  static const Duration durationEmphasis = Duration(milliseconds: 600);

  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccelerate = Curves.easeInCubic;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveSharp = Curves.easeInOut;

  // ═══════════════════════════════════════════════════════════════════
  // SHADOWS — semantic elevation levels (use with BoxDecoration)
  // ═══════════════════════════════════════════════════════════════════

  static List<BoxShadow> shadowSubtle(bool isDark) => [
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF3D2E1C))
              .withValues(alpha: isDark ? 0.20 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowCard(bool isDark) => [
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF3D2E1C))
              .withValues(alpha: isDark ? 0.28 : 0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF3D2E1C))
              .withValues(alpha: isDark ? 0.12 : 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> shadowElevated(bool isDark) => [
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF3D2E1C))
              .withValues(alpha: isDark ? 0.35 : 0.10),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: (isDark ? Colors.black : const Color(0xFF3D2E1C))
              .withValues(alpha: isDark ? 0.15 : 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowGlow(Color color, {double intensity = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════════════

  static const double iconXS = 14;
  static const double iconSM = 18;
  static const double iconMD = 22;
  static const double iconLG = 28;
  static const double iconXL = 36;
  static const double iconHero = 48;
}
