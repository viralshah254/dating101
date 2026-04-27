import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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

  LinearGradient _ctaGradient() {
    if (_selected == null) {
      return LinearGradient(
        colors: [
          AppColors.rosePrimary.withValues(alpha: 0.6),
          AppColors.saffron.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    switch (_selected!) {
      case AppMode.dating:
        return const LinearGradient(
          colors: [Color(0xFFD63B6A), Color(0xFFCB6D35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppMode.matrimony:
        return const LinearGradient(
          colors: [Color(0xFFCB6D35), Color(0xFFD4A855)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppMode.both:
        return AppColors.brandGradient;
    }
  }

  Color _ctaShadowColor() {
    if (_selected == null) return AppColors.rosePrimary;
    switch (_selected!) {
      case AppMode.dating:
        return AppColors.rosePrimary;
      case AppMode.matrimony:
        return AppColors.gold;
      case AppMode.both:
        return AppColors.rosePrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD63B6A),
                    Color(0xFFCB6D35),
                    Color(0xFFD4A855),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.22,
            left: 0,
            right: 0,
            height: size.height * 0.10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.modeSelectTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: size.width < 380 ? 28 : 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                          shadows: const [
                            Shadow(
                              color: Color(0x26000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08, end: 0),
                      const SizedBox(height: 6),
                      Text(
                        l.modeSelectSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.45,
                          shadows: const [
                            Shadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModeOption(
                            title: l.modeMatrimony,
                            subtitle: l.modeMatrimonySubtitle,
                            gradientColors: [AppColors.gold, AppColors.saffron],
                            icon: Icons.diversity_3_rounded,
                            isSelected: _selected == AppMode.matrimony,
                            onTap: () => setState(() => _selected = AppMode.matrimony),
                          ).animate(
                            delay: 160.ms,
                          ).fadeIn(duration: 280.ms).slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 280.ms,
                                curve: Curves.easeOut,
                              ),
                          const SizedBox(height: 10),
                          _ModeOption(
                            title: l.modeDating,
                            subtitle: l.modeDatingSubtitle,
                            gradientColors: [AppColors.rosePrimary, AppColors.roseDeep],
                            icon: Icons.favorite_rounded,
                            isSelected: _selected == AppMode.dating,
                            onTap: () => setState(() => _selected = AppMode.dating),
                          ).animate(
                            delay: 215.ms,
                          ).fadeIn(duration: 280.ms).slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 280.ms,
                                curve: Curves.easeOut,
                              ),
                          const SizedBox(height: 10),
                          _ModeOption(
                            title: l.modeBoth,
                            subtitle: l.modeBothSubtitle,
                            gradientColors: [AppColors.rosePrimary, AppColors.gold],
                            icon: Icons.people_alt_rounded,
                            isSelected: _selected == AppMode.both,
                            onTap: () => setState(() => _selected = AppMode.both),
                          ).animate(
                            delay: 270.ms,
                          ).fadeIn(duration: 280.ms).slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 280.ms,
                                curve: Curves.easeOut,
                              ),
                          const SizedBox(height: 20),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 18,
                                  color: onSurface.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l.modeSwitchHint,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: onSurface.withValues(alpha: 0.45),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _selected != null ? 1.0 : 0.4,
                    child: GestureDetector(
                      onTap: _selected != null ? _confirm : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _ctaGradient(),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selected != null
                              ? [
                                  BoxShadow(
                                    color: _ctaShadowColor().withValues(alpha: 0.28),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            l.continueButton,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
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
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final accent = gradientColors.first;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.07) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent.withValues(alpha: 0.5) : cs.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isSelected
                    ? LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : cs.surfaceContainerHighest,
              ),
              child: Icon(
                icon,
                size: 25,
                color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: isSelected ? accent : onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: isSelected ? 0.68 : 0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: accent,
                      size: 24,
                      key: ValueKey<String>('c-$title'),
                    )
                  : Icon(
                      Icons.circle_outlined,
                      color: onSurface.withValues(alpha: 0.2),
                      size: 22,
                      key: ValueKey<String>('u-$title'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
