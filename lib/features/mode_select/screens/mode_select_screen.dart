import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
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
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
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

                    _ModeOption(
                      mode: AppMode.dating,
                      title: l.modeDating,
                      subtitle: l.modeDatingSubtitle,
                      gradientColors: [AppColors.saffron, AppColors.saffronLight],
                      icon: Icons.favorite_rounded,
                      isSelected: _selected == AppMode.dating,
                      onTap: () => setState(() => _selected = AppMode.dating),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.03, end: 0),

                    const SizedBox(height: 16),

                    _ModeOption(
                      mode: AppMode.matrimony,
                      title: l.modeMatrimony,
                      subtitle: l.modeMatrimonySubtitle,
                      gradientColors: [AppColors.indiaGreen, AppColors.indiaGreenLight],
                      icon: Icons.diversity_3_rounded,
                      isSelected: _selected == AppMode.matrimony,
                      onTap: () => setState(() => _selected = AppMode.matrimony),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.03, end: 0),

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
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _selected != null ? 1.0 : 0.4,
                  child: FilledButton(
                    onPressed: _selected != null ? _confirm : null,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: _selected == AppMode.matrimony
                          ? AppColors.indiaGreen
                          : null,
                    ),
                    child: Text(
                      l.continueButton,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
