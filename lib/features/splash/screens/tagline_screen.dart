import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Week 13 — Launch tagline screen (optional post-splash).
class TaglineScreen extends StatelessWidget {
  const TaglineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.darkBackground, AppColors.darkSurface],
                )
              : AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                      'Depth-first connections.\nNo mindless swiping.',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: accent,
                        height: 1.3,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 24),
                Text(
                  'See full profiles. Send thoughtful intros. Explore by map.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: Text(AppLocalizations.of(context)!.getStarted),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
