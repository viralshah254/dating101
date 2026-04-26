import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../auth/auth_post_sign_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class ModeSelectScreen extends ConsumerStatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  ConsumerState<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends ConsumerState<ModeSelectScreen> {
  AppMode? _selected;

  Future<void> _confirm() async {
    if (_selected == null) return;
    await ref.read(appModeProvider.notifier).setMode(_selected!);
    unawaited(pushModeToServer(_selected!, ref));
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft ambient rose background — ties to login/auth screen family
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.rosePrimary.withValues(alpha: 0.10),
                    AppColors.rosePrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 56),
                        Text(
                          l.modeSelectTitle,
                          style: AppTypography.displayLarge.copyWith(
                            color: onSurface,
                            fontSize: 34,
                            height: 1.15,
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          l.modeSelectSubtitle,
                          style: AppTypography.bodyLarge.copyWith(
                            color: onSurface.withValues(alpha: 0.65),
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 40),

                        // Dating: rose → deep rose (passionate, modern)
                        _ModeOption(
                          mode: AppMode.dating,
                          title: l.modeDating,
                          subtitle: l.modeDatingSubtitle,
                          gradientColors: [AppColors.rosePrimary, AppColors.roseDeep],
                          icon: Icons.favorite_rounded,
                          isSelected: _selected == AppMode.dating,
                          onTap: () => setState(() => _selected = AppMode.dating),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.03, end: 0),

                        const SizedBox(height: 16),

                        // Matrimony: gold → saffron (heritage, warmth, Indian identity)
                        _ModeOption(
                          mode: AppMode.matrimony,
                          title: l.modeMatrimony,
                          subtitle: l.modeMatrimonySubtitle,
                          gradientColors: [AppColors.gold, AppColors.saffron],
                          icon: Icons.diversity_3_rounded,
                          isSelected: _selected == AppMode.matrimony,
                          onTap: () => setState(() => _selected = AppMode.matrimony),
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.03, end: 0),

                        const SizedBox(height: 16),

                        // Both: rose → gold (the full brand duo)
                        _ModeOption(
                          mode: AppMode.both,
                          title: l.modeBoth,
                          subtitle: l.modeBothSubtitle,
                          gradientColors: [AppColors.rosePrimary, AppColors.gold],
                          icon: Icons.people_alt_rounded,
                          isSelected: _selected == AppMode.both,
                          onTap: () => setState(() => _selected = AppMode.both),
                        ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.03, end: 0),

                        const SizedBox(height: 24),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz, size: 18, color: onSurface.withValues(alpha: 0.45)),
                              const SizedBox(width: 6),
                              Text(
                                l.modeSwitchHint,
                                style: AppTypography.bodySmall.copyWith(
                                  color: onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _selected != null ? 1.0 : 0.45,
                    child: GestureDetector(
                      onTap: _selected != null ? _confirm : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: _selected == AppMode.matrimony
                              ? const LinearGradient(
                                  colors: [AppColors.gold, AppColors.saffron],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : _selected == AppMode.both
                                  ? AppColors.brandGradient
                                  : AppColors.heartGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _selected != null
                              ? [
                                  BoxShadow(
                                    color: (_selected == AppMode.matrimony
                                            ? AppColors.gold
                                            : AppColors.rosePrimary)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            l.continueButton,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final AppMode mode;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor = isSelected ? gradientColors.first : Theme.of(context).dividerColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? gradientColors.first.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: gradientColors.first.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? gradientColors
                      : [onSurface.withValues(alpha: 0.08), onSurface.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: isSelected ? gradientColors.first : onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.65),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? gradientColors.first : onSurface.withValues(alpha: 0.25),
                  width: isSelected ? 7 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
