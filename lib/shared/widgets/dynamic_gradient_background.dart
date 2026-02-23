import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Week 13 — Dynamic gradient backgrounds (adaptive dark/light).
class DynamicGradientBackground extends StatelessWidget {
  const DynamicGradientBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkBackground,
                  AppColors.darkSurface,
                  AppColors.darkBackground,
                ]
              : [
                  AppColors.lightBackground,
                  AppColors.lightSurfaceVariant.withValues(alpha: 0.3),
                  AppColors.lightBackground,
                ],
        );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: defaultGradient),
      child: child,
    );
  }
}
