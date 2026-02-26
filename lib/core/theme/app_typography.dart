import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Serif (Playfair Display) for headings; Inter for body and UI. Clear hierarchy and readability.
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

  // Serif — headings (slightly tighter letter-spacing for impact)
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: _primary,
        letterSpacing: -0.8,
        height: 1.2,
      );
  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _primary,
        letterSpacing: -0.4,
        height: 1.25,
      );
  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _primary,
        height: 1.3,
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
        height: 1.35,
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

  // Sans — body & UI (comfortable line height)
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
        fontWeight: FontWeight.w600,
        color: _tertiary,
        letterSpacing: 1.2,
      );
}
