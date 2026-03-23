import 'package:flutter/material.dart';

/// Shubhmilan design system v2 — Premium Indian identity + modern minimal UI.
///
/// Palette drawn from the logo flame (warm saffron-copper) and leaf (emerald).
/// Light mode: warm ivory surfaces with saffron accent.
/// Dark mode: warm charcoal surfaces with lighter copper accent.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════
  // BRAND PALETTE (logo-derived, mode-independent)
  // ═══════════════════════════════════════════════════════════════════

  /// Primary brand — warm saffron-copper from logo flame.
  static const Color saffron = Color(0xFFCB6D35);
  static const Color saffronLight = Color(0xFFE09B5C);
  static const Color saffronDark = Color(0xFFB05A24);

  /// Gold highlight — premium badges, star ratings, shimmer.
  static const Color gold = Color(0xFFD4A855);
  static const Color goldLight = Color(0xFFEACA7E);
  static const Color goldDark = Color(0xFFAB8733);

  /// Emerald — success, positive, secondary accent (logo leaf).
  static const Color indiaGreen = Color(0xFF2D6A4F);
  static const Color indiaGreenLight = Color(0xFF40916C);
  static const Color indiaGreenDark = Color(0xFF1B4332);

  /// Navy — trust, links, secondary UI.
  static const Color navy = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF3B5CC6);

  /// Rose — romantic accent, super-like, hearts.
  static const Color rose = Color(0xFFE74C6F);
  static const Color roseLight = Color(0xFFF28DA5);
  static const Color roseDark = Color(0xFFC22E54);

  // ═══════════════════════════════════════════════════════════════════
  // SPLASH PALETTE
  // ═══════════════════════════════════════════════════════════════════

  static const Color splashPeach = Color(0xFFF2E4DB);
  static const Color splashMid = Color(0xFFEAE6E1);
  static const Color splashTeal = Color(0xFFDCE8E5);

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT MODE
  // ═══════════════════════════════════════════════════════════════════

  static const Color lightBackground = Color(0xFFFAF7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3EDE7);
  static const Color lightSurfaceDim = Color(0xFFEDE6DF);
  static const Color lightAccent = saffron;
  static const Color lightAccentLight = Color(0xFFFFF0E6);
  static const Color lightAccentDark = saffronDark;
  static const Color lightBlue = navy;
  static const Color lightBlueLight = navyLight;
  static const Color lightCharcoal = Color(0xFF1E1B18);
  static const Color lightTextPrimary = Color(0xFF1E1B18);
  static const Color lightTextSecondary = Color(0xFF5C544C);
  static const Color lightTextTertiary = Color(0xFF8A8279);
  static const Color lightDivider = Color(0xFFE8E2DC);
  static const Color lightError = Color(0xFFBF2B2B);
  static const Color lightSuccess = indiaGreen;
  static const Color lightWarning = Color(0xFFD97706);

  // ═══════════════════════════════════════════════════════════════════
  // DARK MODE
  // ═══════════════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF0F0D0B);
  static const Color darkSurface = Color(0xFF1A1714);
  static const Color darkSurfaceVariant = Color(0xFF262220);
  static const Color darkSurfaceDim = Color(0xFF302C28);
  static const Color darkAccent = Color(0xFFE8A46C);
  static const Color darkAccentDim = Color(0xFFCB6D35);
  static const Color darkBlue = Color(0xFF7EB4F2);
  static const Color darkTextPrimary = Color(0xFFF5F2EF);
  static const Color darkTextSecondary = Color(0xFFADA6A0);
  static const Color darkTextTertiary = Color(0xFF78716C);
  static const Color darkDivider = Color(0xFF3D3835);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkSuccess = indiaGreenLight;
  static const Color darkWarning = Color(0xFFFBBF24);

  // ═══════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════

  static const LinearGradient accentGradientLight = LinearGradient(
    colors: [Color(0xFFCB6D35), Color(0xFFE09B5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientDark = LinearGradient(
    colors: [Color(0xFFE8A46C), Color(0xFFCB6D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A855), Color(0xFFEACA7E), Color(0xFFD4A855)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFCB6D35), Color(0xFFD4A855)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradientDark = LinearGradient(
    colors: [Color(0xFFE8A46C), Color(0xFFEACA7E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [splashPeach, splashMid, splashTeal],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient flagGradient = LinearGradient(
    colors: [Color(0xFFCB6D35), Color(0xFFFFFFFF), Color(0xFF2D6A4F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFE74C6F), Color(0xFFF28DA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1714), Color(0xFF0F0D0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
