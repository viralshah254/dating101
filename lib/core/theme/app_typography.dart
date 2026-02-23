import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Elegant serif for headings, clean sans for UI.
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

  // Serif — headings
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _primary,
        letterSpacing: -0.5,
      );
  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get headlineSmall => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get titleLarge => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get titleMedium => GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get titleSmall => GoogleFonts.playfairDisplay(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _primary,
      );

  // Sans — body & UI
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _primary,
        height: 1.5,
      );
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _primary,
        height: 1.45,
      );
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _secondary,
        height: 1.4,
      );
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _primary,
      );
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _secondary,
      );
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _tertiary,
        letterSpacing: 0.5,
      );
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _tertiary,
      );
  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _tertiary,
        letterSpacing: 1.2,
      );
}
