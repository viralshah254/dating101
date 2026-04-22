import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Shubhmilan type scale v2.
///
/// Serif (Playfair Display) for headings — premium Indian elegance.
/// Sans (Inter) for body/UI — modern readability.
///
/// Colors are baked into static getters for backward-compat. The [setDark]
/// toggle is driven by [AppTheme.light()] / [AppTheme.dark()] and is safe
/// because Flutter rebuilds the entire widget tree on theme mode change.
class AppTypography {
  AppTypography._();

  static bool _isDark = false;

  static void setDark(bool value) => _isDark = value;

  static Color get _primary =>
      _isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  static Color get _secondary =>
      _isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  static Color get _tertiary =>
      _isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

  // ═══════════════════════════════════════════════════════════════════
  // SERIF — headings (Playfair Display: elegant, premium)
  // ═══════════════════════════════════════════════════════════════════

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: _primary,
        letterSpacing: -0.8,
        height: 1.18,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _primary,
        letterSpacing: -0.4,
        height: 1.22,
      );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _primary,
        letterSpacing: -0.2,
        height: 1.28,
      );

  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.32,
      );

  static TextStyle get headlineSmall => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.35,
      );

  static TextStyle get titleLarge => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.35,
      );

  static TextStyle get titleMedium => GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.4,
      );

  static TextStyle get titleSmall => GoogleFonts.playfairDisplay(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.4,
      );

  // ═══════════════════════════════════════════════════════════════════
  // SANS — body & UI (Inter: modern, readable)
  // ═══════════════════════════════════════════════════════════════════

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _primary,
        height: 1.6,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _primary,
        height: 1.55,
        letterSpacing: 0.05,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _secondary,
        height: 1.45,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _primary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _secondary,
        letterSpacing: 0.05,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _tertiary,
        letterSpacing: 0.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _tertiary,
        height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _tertiary,
        letterSpacing: 1.4,
      );

  // ═══════════════════════════════════════════════════════════════════
  // MATERIAL TEXT THEME — integrates the above into ThemeData
  // ═══════════════════════════════════════════════════════════════════

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
