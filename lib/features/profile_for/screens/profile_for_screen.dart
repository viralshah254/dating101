import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/onboarding/onboarding_progress_storage.dart';
import '../../../core/providers/repository_providers.dart';
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
  static const String _nothingSelected = '__none__';
  String? _selected = _nothingSelected;

  bool get _hasSelection => _selected != _nothingSelected;

  Future<void> _confirm() async {
    if (!_hasSelection) return;
    final value = _selected;
    ref.read(creatingForProvider.notifier).state = value;
    ref.read(creatingForAnsweredProvider.notifier).state = true;

    // Persist so cold-start restore can skip re-inserting the creating_for step.
    final uid = ref.read(authRepositoryProvider).currentUserId;
    await OnboardingProgressStorage.saveCreatingFor(
      uid,
      value: value,
      answered: true,
    );

    if (value == null) {
      if (mounted) context.go('/mode-select');
    } else {
      await ref.read(appModeProvider.notifier).setMode(AppMode.matrimony);
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = _options(l);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradient header strip ─────────────────────────────────────────
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
          // Fade gradient strip into surface
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

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header text over gradient
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.wizardStepCreatingFor,
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
                        l.creatingForScreenSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.85),
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

                const SizedBox(height: 24),

                // Option cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...options.asMap().entries.map((e) {
                            final idx = e.key;
                            final opt = e.value;
                            final isSelected = _selected == opt.value;
                            final isMyself = opt.value == null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ForOptionCard(
                                emoji: opt.emoji,
                                label: opt.label,
                                subtitle: opt.subtitle,
                                isSelected: isSelected,
                                isPrimary: isMyself,
                                onTap: () =>
                                    setState(() => _selected = opt.value),
                              )
                                  .animate(
                                    delay: Duration(milliseconds: 160 + idx * 55),
                                  )
                                  .fadeIn(duration: 280.ms)
                                  .slideY(
                                    begin: 0.06,
                                    end: 0,
                                    duration: 280.ms,
                                    curve: Curves.easeOut,
                                  ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Continue CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hasSelection ? 1.0 : 0.4,
                    child: GestureDetector(
                      onTap: _hasSelection ? _confirm : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _hasSelection
                              ? const LinearGradient(
                                  colors: [Color(0xFFD63B6A), Color(0xFFCB6D35)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    AppColors.rosePrimary.withValues(alpha: 0.6),
                                    AppColors.saffron.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _hasSelection
                              ? [
                                  BoxShadow(
                                    color: AppColors.rosePrimary.withValues(alpha: 0.30),
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

  List<_Option> _options(AppLocalizations l) => [
        _Option(value: null, emoji: '🙋', label: l.creatingForMyself, subtitle: l.creatingForMyselfSubtitle),
        _Option(value: 'daughter', emoji: '👩', label: l.creatingForDaughter, subtitle: l.creatingForDaughterSubtitle),
        _Option(value: 'son', emoji: '👦', label: l.creatingForSon, subtitle: l.creatingForSonSubtitle),
        _Option(value: 'sister', emoji: '👧', label: l.creatingForSister, subtitle: l.creatingForSisterSubtitle),
        _Option(value: 'brother', emoji: '👦', label: l.creatingForBrother, subtitle: l.creatingForBrotherSubtitle),
        _Option(value: 'relative', emoji: '🏡', label: l.creatingForRelative, subtitle: l.creatingForRelativeSubtitle),
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
    this.isPrimary = false,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    const selectedBorder = Color(0xFFD63B6A);
    const selectedTint = Color(0xFFD63B6A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedTint.withValues(alpha: 0.06)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? selectedBorder.withValues(alpha: 0.55)
                : cs.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedTint.withValues(alpha: 0.10),
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
            // Emoji avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFD63B6A), Color(0xFFCB6D35)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : cs.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 21)),
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
                      color: isSelected ? selectedTint : onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: isSelected ? 0.7 : 0.55),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFD63B6A),
                      size: 22,
                      key: ValueKey('check'),
                    )
                  : Icon(
                      Icons.circle_outlined,
                      color: onSurface.withValues(alpha: 0.20),
                      size: 22,
                      key: const ValueKey('uncheck'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
