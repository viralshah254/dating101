import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Launch tagline screen — cinematic entrance with layered stagger.
class TaglineScreen extends StatelessWidget {
  const TaglineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).colorScheme.surface,
                      ],
                    )
                  : AppColors.splashGradient,
            ),
          ),

          // Ambient radial glow
          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: isDark ? 0.15 : 0.10),
                    accent.withValues(alpha: 0.0),
                  ],
                  radius: 0.7,
                ),
              ),
            ).animate().fadeIn(duration: 800.ms),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Eyebrow label
                  Text(
                    'SHUBHMILAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: accent.withValues(alpha: 0.6),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: AppMotion.fast)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // Hero headline — two lines with individual stagger
                  Text(
                        'Depth-first connections.',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(
                          color: accent,
                          height: 1.3,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: AppMotion.medium)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        curve: AppMotion.reveal,
                      ),

                  const SizedBox(height: 4),

                  Text(
                        'No mindless swiping.',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(
                          color: accent,
                          height: 1.3,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 280.ms, duration: AppMotion.medium)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        curve: AppMotion.reveal,
                      ),

                  const SizedBox(height: 28),

                  Text(
                    'See full profiles. Send thoughtful intros.\nExplore by map.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.55,
                    ),
                  ).animate().fadeIn(delay: 420.ms, duration: AppMotion.medium),

                  const SizedBox(height: 52),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => context.go('/login'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.getStarted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 560.ms, duration: AppMotion.medium)
                      .slideY(begin: 0.08, end: 0, curve: AppMotion.spring),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
