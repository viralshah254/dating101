import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_mode.dart';
import 'mode_provider.dart';

/// Handles mode switching with optional profile-completion prompt.
/// Profile data is shared; user can complete mode-specific details in profile-setup.
Future<void> switchAppMode(
  BuildContext context,
  WidgetRef ref,
  AppMode newMode,
) async {
  final currentMode = ref.read(appModeProvider);
  if (currentMode == newMode) return;

  await ref.read(appModeProvider.notifier).setMode(newMode);

  if (!context.mounted) return;

  // Navigate to home so shell shows the correct mode (Discover vs Matches, etc.)
  context.go('/');

  if (!context.mounted) return;

  // Offer to complete/update profile for the new mode
  final shouldComplete = await _showCompletionDialog(context, newMode);
  if (shouldComplete && context.mounted) {
    context.push('/profile-setup');
  }
}

Future<bool> _showCompletionDialog(BuildContext context, AppMode newMode) async {
  final l = AppLocalizations.of(context)!;
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final isMatrimony = newMode == AppMode.matrimony;
  final accent = isMatrimony ? AppColors.indiaGreen : AppColors.saffron;
  final icon = isMatrimony ? Icons.diversity_3_rounded : Icons.favorite_rounded;
  final subtitle = isMatrimony
      ? l.modeSwitchCompleteSubtitle
      : 'Add or update your dating profile so we can show you better matches.';

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              l.modeSwitchCompleteTitle,
              style: AppTypography.titleLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  l.continueButton,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l.notNow,
                style: TextStyle(color: onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}
