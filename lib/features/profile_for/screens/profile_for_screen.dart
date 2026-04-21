import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/creating_for_provider.dart';

class ProfileForScreen extends ConsumerStatefulWidget {
  const ProfileForScreen({super.key});

  @override
  ConsumerState<ProfileForScreen> createState() => _ProfileForScreenState();
}

class _ProfileForScreenState extends ConsumerState<ProfileForScreen> {
  // null = Myself (not selected yet is represented by _confirmed == false)
  // We use a sentinel _nothingSelected to distinguish "not tapped" from "tapped Myself".
  static const String _nothingSelected = '__none__';
  String? _selected = _nothingSelected;

  bool get _hasSelection => _selected != _nothingSelected;

  Future<void> _confirm() async {
    if (!_hasSelection) return;
    final value = _selected; // null = Myself, non-null = family role
    ref.read(creatingForProvider.notifier).state = value;
    ref.read(creatingForAnsweredProvider.notifier).state = true;

    if (value == null) {
      // Myself → let user pick Dating / Matrimony / Both
      if (mounted) context.go('/mode-select');
    } else {
      // Family member → always Matrimony
      await ref.read(appModeProvider.notifier).setMode(AppMode.matrimony);
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final options = _options(l);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft ambient rose background — matches the mode-select screen family
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
                          l.wizardStepCreatingFor,
                          style: AppTypography.displayLarge.copyWith(
                            color: onSurface,
                            fontSize: 34,
                            height: 1.15,
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          l.creatingForScreenSubtitle,
                          style: AppTypography.bodyLarge.copyWith(
                            color: onSurface.withValues(alpha: 0.65),
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 32),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: options.asMap().entries.map((e) {
                                final idx = e.key;
                                final opt = e.value;
                                final isSelected = _selected == opt.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ForOptionCard(
                                    emoji: opt.emoji,
                                    label: opt.label,
                                    subtitle: opt.subtitle,
                                    isSelected: isSelected,
                                    onTap: () =>
                                        setState(() => _selected = opt.value),
                                  )
                                      .animate(
                                        delay: Duration(milliseconds: 200 + idx * 60),
                                      )
                                      .fadeIn(duration: 300.ms)
                                      .slideX(
                                        begin: -0.03,
                                        end: 0,
                                        duration: 300.ms,
                                        curve: Curves.easeOut,
                                      ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hasSelection ? 1.0 : 0.45,
                    child: GestureDetector(
                      onTap: _hasSelection ? _confirm : null,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.heartGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _hasSelection
                              ? [
                                  BoxShadow(
                                    color: AppColors.rosePrimary
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

  List<_Option> _options(AppLocalizations l) => [
        _Option(value: null, emoji: '🙋', label: l.creatingForMyself, subtitle: l.creatingForMyselfSubtitle),
        _Option(value: 'daughter', emoji: '👩', label: l.creatingForDaughter, subtitle: l.creatingForDaughterSubtitle),
        _Option(value: 'son', emoji: '👨', label: l.creatingForSon, subtitle: l.creatingForSonSubtitle),
        _Option(value: 'sister', emoji: '👩‍👧', label: l.creatingForSister, subtitle: l.creatingForSisterSubtitle),
        _Option(value: 'brother', emoji: '👨‍👦', label: l.creatingForBrother, subtitle: l.creatingForBrotherSubtitle),
        _Option(value: 'relative', emoji: '🏠', label: l.creatingForRelative, subtitle: l.creatingForRelativeSubtitle),
      ];
}

class _Option {
  const _Option({
    required this.value,
    required this.emoji,
    required this.label,
    required this.subtitle,
  });
  final String? value;
  final String emoji;
  final String label;
  final String subtitle;
}

class _ForOptionCard extends StatelessWidget {
  const _ForOptionCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final selectedColor = AppColors.gold;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.07)
              : cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.6)
                : cs.outline.withValues(alpha: 0.18),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: selectedColor.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? selectedColor.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? selectedColor : onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded,
                      color: selectedColor, size: 22, key: const ValueKey('check'))
                  : Icon(Icons.radio_button_unchecked_rounded,
                      color: onSurface.withValues(alpha: 0.25),
                      size: 22,
                      key: const ValueKey('uncheck')),
            ),
          ],
        ),
      ),
    );
  }
}
