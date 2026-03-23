import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dynamic gradient backgrounds (adaptive dark/light).
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultGradient = gradient ??
        (isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.surface,
                  theme.scaffoldBackgroundColor,
                ],
              )
            : AppColors.splashGradient);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: defaultGradient),
      child: child,
    );
  }
}
