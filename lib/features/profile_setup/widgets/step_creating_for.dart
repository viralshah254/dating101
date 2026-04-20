import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';
import 'wizard_step_shell.dart';

/// Step zero — only shown on first-time matrimony profile creation.
/// User picks who they are creating this profile for.
/// Selecting a non-self option activates parent-author mode (warmer copy).
class StepCreatingFor extends StatefulWidget {
  const StepCreatingFor({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  State<StepCreatingFor> createState() => _StepCreatingForState();
}

class _StepCreatingForState extends State<StepCreatingFor> {
  List<_ForOption> _options(AppLocalizations l) => [
        _ForOption(value: null, emoji: '🙋', label: l.creatingForMyself, subtitle: l.creatingForMyselfSubtitle),
        _ForOption(value: 'daughter', emoji: '👩', label: l.creatingForDaughter, subtitle: l.creatingForDaughterSubtitle),
        _ForOption(value: 'son', emoji: '👨', label: l.creatingForSon, subtitle: l.creatingForSonSubtitle),
        _ForOption(value: 'sister', emoji: '👩‍👧', label: l.creatingForSister, subtitle: l.creatingForSisterSubtitle),
        _ForOption(value: 'brother', emoji: '👨‍👦', label: l.creatingForBrother, subtitle: l.creatingForBrotherSubtitle),
        _ForOption(value: 'relative', emoji: '🏠', label: l.creatingForRelative, subtitle: l.creatingForRelativeSubtitle),
      ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final options = _options(l);

    return WizardStepShell(
      icon: Icons.favorite_rounded,
      headline: l.wizardStepCreatingFor,
      subtitle: l.creatingForScreenSubtitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          children: options.asMap().entries.map((e) {
            final opt = e.value;
            final selected = widget.formData.creatingFor == opt.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  widget.formData.creatingFor = opt.value;
                  widget.onChanged();
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withValues(alpha: 0.08)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.5)
                          : cs.outline.withValues(alpha: 0.15),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Emoji avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: 180.ms,
                        child: selected
                            ? Icon(Icons.check_circle_rounded, color: cs.primary, size: 22, key: const ValueKey('check'))
                            : Icon(Icons.radio_button_unchecked_rounded,
                                color: onSurface.withValues(alpha: 0.25),
                                size: 22,
                                key: const ValueKey('uncheck')),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: e.key * 60))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ForOption {
  const _ForOption({
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

/// Informational card shown at the end of a parent-author matrimony wizard,
/// letting the parent send a handover link to the real subject.
class HandoverInviteCard extends StatefulWidget {
  const HandoverInviteCard({
    super.key,
    required this.onGenerateLink,
    this.generatedLink,
    this.isLoading = false,
    this.subjectLabel,
  });

  final VoidCallback onGenerateLink;
  final String? generatedLink;
  final bool isLoading;
  final String? subjectLabel;

  @override
  State<HandoverInviteCard> createState() => _HandoverInviteCardState();
}

class _HandoverInviteCardState extends State<HandoverInviteCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.rosePrimary.withValues(alpha: 0.07),
            AppColors.saffron.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.rosePrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invite ${widget.subjectLabel ?? 'them'} to take over',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'When they\'re ready, send them this link. They\'ll sign up and the profile will transfer to their account automatically — you\'ll stay connected as a family member.',
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.generatedLink == null)
            FilledButton.icon(
              onPressed: widget.isLoading ? null : widget.onGenerateLink,
              icon: widget.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.link_rounded, size: 18),
              label: Text(widget.isLoading ? 'Generating…' : 'Generate handover link'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.generatedLink!,
                          style: AppTypography.bodySmall.copyWith(
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle_rounded, color: AppColors.indiaGreen, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Link expires in 7 days. Share it via WhatsApp or message.',
                  style: AppTypography.labelSmall.copyWith(
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0);
  }
}
