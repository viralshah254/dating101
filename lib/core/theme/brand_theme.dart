import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shubhmilan brand extension — custom tokens not in Material's ThemeData.
///
/// Access via `Theme.of(context).extension<BrandTheme>()!`.
class BrandTheme extends ThemeExtension<BrandTheme> {
  const BrandTheme({
    required this.accentGradient,
    required this.premiumGradient,
    required this.roseGradient,
    required this.goldGradient,
    required this.surfaceGlass,
    required this.surfaceGlassBorder,
    required this.textSubtle,
    required this.textMuted,
    required this.saffron,
    required this.gold,
    required this.emerald,
    required this.rose,
    required this.cardBorder,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.badgePremium,
    required this.badgeNew,
    required this.navBarSurface,
    required this.navBarBorder,
    required this.heroOverlay,
    required this.isDark,
  });

  final LinearGradient accentGradient;
  final LinearGradient premiumGradient;
  final LinearGradient roseGradient;
  final LinearGradient goldGradient;
  final Color surfaceGlass;
  final Color surfaceGlassBorder;
  final Color textSubtle;
  final Color textMuted;
  final Color saffron;
  final Color gold;
  final Color emerald;
  final Color rose;
  final Color cardBorder;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color badgePremium;
  final Color badgeNew;
  final Color navBarSurface;
  final Color navBarBorder;
  final Color heroOverlay;
  final bool isDark;

  static const BrandTheme light = BrandTheme(
    accentGradient: AppColors.accentGradientLight,
    premiumGradient: AppColors.premiumGradient,
    roseGradient: AppColors.roseGradient,
    goldGradient: AppColors.goldGradient,
    surfaceGlass: Color(0xCCFFFFFF),
    surfaceGlassBorder: Color(0x33D4A855),
    textSubtle: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextTertiary,
    saffron: AppColors.saffron,
    gold: AppColors.gold,
    emerald: AppColors.indiaGreen,
    rose: AppColors.rose,
    cardBorder: Color(0x0F1E1B18),
    shimmerBase: Color(0xFFF3EDE7),
    shimmerHighlight: Color(0xFFFAF7F4),
    badgePremium: AppColors.gold,
    badgeNew: AppColors.rose,
    navBarSurface: Color(0xFAFFFFFF),
    navBarBorder: Color(0x14CB6D35),
    heroOverlay: Color(0x33000000),
    isDark: false,
  );

  static const BrandTheme dark = BrandTheme(
    accentGradient: AppColors.accentGradientDark,
    premiumGradient: AppColors.premiumGradientDark,
    roseGradient: AppColors.roseGradient,
    goldGradient: AppColors.goldGradient,
    surfaceGlass: Color(0xCC1A1714),
    surfaceGlassBorder: Color(0x33E8A46C),
    textSubtle: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextTertiary,
    saffron: AppColors.darkAccent,
    gold: AppColors.goldLight,
    emerald: AppColors.indiaGreenLight,
    rose: AppColors.roseLight,
    cardBorder: Color(0x1AF5F2EF),
    shimmerBase: Color(0xFF262220),
    shimmerHighlight: Color(0xFF302C28),
    badgePremium: AppColors.goldLight,
    badgeNew: AppColors.roseLight,
    navBarSurface: Color(0xFA1A1714),
    navBarBorder: Color(0x14E8A46C),
    heroOverlay: Color(0x55000000),
    isDark: true,
  );

  @override
  BrandTheme copyWith({
    LinearGradient? accentGradient,
    LinearGradient? premiumGradient,
    LinearGradient? roseGradient,
    LinearGradient? goldGradient,
    Color? surfaceGlass,
    Color? surfaceGlassBorder,
    Color? textSubtle,
    Color? textMuted,
    Color? saffron,
    Color? gold,
    Color? emerald,
    Color? rose,
    Color? cardBorder,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? badgePremium,
    Color? badgeNew,
    Color? navBarSurface,
    Color? navBarBorder,
    Color? heroOverlay,
    bool? isDark,
  }) {
    return BrandTheme(
      accentGradient: accentGradient ?? this.accentGradient,
      premiumGradient: premiumGradient ?? this.premiumGradient,
      roseGradient: roseGradient ?? this.roseGradient,
      goldGradient: goldGradient ?? this.goldGradient,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      surfaceGlassBorder: surfaceGlassBorder ?? this.surfaceGlassBorder,
      textSubtle: textSubtle ?? this.textSubtle,
      textMuted: textMuted ?? this.textMuted,
      saffron: saffron ?? this.saffron,
      gold: gold ?? this.gold,
      emerald: emerald ?? this.emerald,
      rose: rose ?? this.rose,
      cardBorder: cardBorder ?? this.cardBorder,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      badgePremium: badgePremium ?? this.badgePremium,
      badgeNew: badgeNew ?? this.badgeNew,
      navBarSurface: navBarSurface ?? this.navBarSurface,
      navBarBorder: navBarBorder ?? this.navBarBorder,
      heroOverlay: heroOverlay ?? this.heroOverlay,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  BrandTheme lerp(ThemeExtension<BrandTheme>? other, double t) {
    if (other is! BrandTheme) return this;
    return BrandTheme(
      accentGradient: t < 0.5 ? accentGradient : other.accentGradient,
      premiumGradient: t < 0.5 ? premiumGradient : other.premiumGradient,
      roseGradient: t < 0.5 ? roseGradient : other.roseGradient,
      goldGradient: t < 0.5 ? goldGradient : other.goldGradient,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      surfaceGlassBorder: Color.lerp(surfaceGlassBorder, other.surfaceGlassBorder, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      saffron: Color.lerp(saffron, other.saffron, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      badgePremium: Color.lerp(badgePremium, other.badgePremium, t)!,
      badgeNew: Color.lerp(badgeNew, other.badgeNew, t)!,
      navBarSurface: Color.lerp(navBarSurface, other.navBarSurface, t)!,
      navBarBorder: Color.lerp(navBarBorder, other.navBarBorder, t)!,
      heroOverlay: Color.lerp(heroOverlay, other.heroOverlay, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
