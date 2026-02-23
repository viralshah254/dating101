import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/profile_setup_screen.dart';

class StepPhotos extends StatelessWidget {
  const StepPhotos({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  final ProfileFormData formData;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final forSelf = formData.isForSelf;
    final subject = formData.subjectName;

    final subtitle = forSelf
        ? 'Add at least 2 photos. Clear face photos get 3x more responses.'
        : l.dynPhotosSubtitle(subject);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.profileBuilderPhotos,
            style: AppTypography.displayLarge.copyWith(
              color: onSurface,
              fontSize: 32,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
            children: List.generate(6, (i) {
              return _PhotoSlot(
                isPrimary: i == 0,
                index: i,
                onTap: onChanged,
              );
            }),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.04, end: 0),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Photo tips',
                      style: AppTypography.labelLarge.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TipRow(icon: Icons.check_circle_outline, text: 'Clear, well-lit face photo as main'),
                const SizedBox(height: 6),
                _TipRow(icon: Icons.check_circle_outline, text: 'Full-length photo shows personality'),
                const SizedBox(height: 6),
                _TipRow(icon: Icons.check_circle_outline, text: 'Avoid heavy filters or group shots'),
                const SizedBox(height: 6),
                _TipRow(icon: Icons.check_circle_outline, text: 'Smile — it genuinely helps'),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.isPrimary,
    required this.index,
    required this.onTap,
  });

  final bool isPrimary;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? accent : Theme.of(context).dividerColor,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPrimary ? 'Main' : '+',
                    style: AppTypography.caption.copyWith(
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Main',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
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

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
