import 'package:flutter/material.dart';

/// Shared design tokens for spacing/radius/elevation consistency.
class AppTokens {
  AppTokens._();

  // Spacing
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Radius
  static const double radius8 = 8;
  static const double radius12 = 12;
  static const double radius14 = 14;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radiusPill = 999;

  // Elevation
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;

  static BorderRadius rounded(double value) => BorderRadius.circular(value);
}
