import 'package:flutter/material.dart';

/// Shubhmilan design system v3 — Premium Indian romance identity.
///
/// Palette centred on rose (romance primary), gold (premium secondary),
/// and saffron (Indian heritage tertiary/accent).
/// Light mode: warm ivory surfaces with rose primary.
/// Dark mode: warm charcoal surfaces with lighter rose accent.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════
  // BRAND PALETTE (logo-derived, mode-independent)
  // ═══════════════════════════════════════════════════════════════════

  /// Rose — romance primary, hearts, like button, match moments.
  static const Color rosePrimary = Color(0xFFD63B6A);
  static const Color rosePrimaryLight = Color(0xFFEA6090);
  static const Color rosePrimaryDark = Color(0xFFB02457);
  static const Color roseDeep = Color(0xFF8B1338); // hero gradient top

  /// Saffron — Indian cultural heritage, premium badges, tertiary accent.
  static const Color saffron = Color(0xFFCB6D35);
  static const Color saffronLight = Color(0xFFE09B5C);
  static const Color saffronDark = Color(0xFFB05A24);

  /// Gold — premium secondary, star ratings, shimmer, super-like.
  static const Color gold = Color(0xFFD4A855);
  static const Color goldLight = Color(0xFFEACA7E);
  static const Color goldDark = Color(0xFFAB8733);

  /// Emerald — success, match confirmed, positive states.
  static const Color indiaGreen = Color(0xFF2D6A4F);
  static const Color indiaGreenLight = Color(0xFF40916C);
  static const Color indiaGreenDark = Color(0xFF1B4332);

  /// Navy — trust, links, secondary UI.
  static const Color navy = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF3B5CC6);

  /// Rose aliases kept for backward compatibility.
  static const Color rose = rosePrimary;
  static const Color roseLight = rosePrimaryLight;
  static const Color roseDark = rosePrimaryDark;

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

  /// Auth hero — fills login/onboarding background so glassmorphism works.
  /// Deep maroon → vibrant rose → warm amber → ivory.
  static const LinearGradient authHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF8B1338), // roseDeep
      Color(0xFFD63B6A), // rosePrimary
      Color(0xFFE09B5C), // saffronLight
      Color(0xFFFAF7F4), // lightBackground
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  /// Brand gradient — rose → saffron (romantic + Indian cultural warmth).
  /// Used on primary CTAs, filled buttons, sign-in button.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFD63B6A), Color(0xFFCB6D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Heart gradient — rose → roseLight. For like button and match moments.
  static const LinearGradient heartGradient = LinearGradient(
    colors: [Color(0xFFD63B6A), Color(0xFFEA6090)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Accent gradients (legacy, kept for PrimaryButton + other widgets).
  static const LinearGradient accentGradientLight = LinearGradient(
    colors: [Color(0xFFD63B6A), Color(0xFFCB6D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientDark = LinearGradient(
    colors: [Color(0xFFEA6090), Color(0xFFD63B6A)],
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
    colors: [Color(0xFFD63B6A), Color(0xFFEA6090)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1714), Color(0xFF0F0D0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════════════
  // MALE THEME — deep navy-blue scale (gender-adaptive theming)
  // ═══════════════════════════════════════════════════════════════════

  /// Deep professional blue — primary for male user sessions.
  static const Color malePrimary      = Color(0xFF1565C0);
  static const Color malePrimaryLight = Color(0xFF5E92D2);
  static const Color malePrimaryDark  = Color(0xFF0D3B7D);

  /// Male auth hero — deep navy → steel blue → sky → ivory.
  static const LinearGradient maleAuthHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D3B7D), // malePrimaryDark
      Color(0xFF1565C0), // malePrimary
      Color(0xFF5E92D2), // malePrimaryLight
      Color(0xFFFAF7F4), // lightBackground
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  /// Male brand gradient — deep blue → steel blue. For CTAs and buttons.
  static const LinearGradient maleBrandGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Male heart/like gradient — matches the like button for male sessions.
  static const LinearGradient maleHeartGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF5E92D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
