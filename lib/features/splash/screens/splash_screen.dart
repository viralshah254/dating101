import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Week 13 — Animated splash: logo morph, saffron glow, adaptive dark/light.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bg,
                    AppColors.darkSurface,
                    bg,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.saffron.withValues(alpha: 0.08),
                    bg,
                    AppColors.indiaGreen.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo + saffron glow
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 80,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'D',
                    style: AppTypography.displayLarge.copyWith(
                      color: accent,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                'DesiLink',
                style: AppTypography.displayMedium.copyWith(color: accent),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                'Sophisticated connections, globally.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
              const Spacer(flex: 2),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(delay: 700.ms)
                  .then()
                  .shimmer(duration: 1200.ms, color: accent.withValues(alpha: 0.3)),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
