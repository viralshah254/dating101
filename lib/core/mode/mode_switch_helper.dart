import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_mode.dart';
import 'mode_provider.dart';

/// Handles mode switching with profile-completion prompt.
/// When switching from dating to matrimony, shows a dialog
/// asking the user to complete their extended profile.
Future<void> switchAppMode(
  BuildContext context,
  WidgetRef ref,
  AppMode newMode,
) async {
  final currentMode = ref.read(appModeProvider);
  if (currentMode == newMode) return;

  await ref.read(appModeProvider.notifier).setMode(newMode);

  if (!context.mounted) return;

  if (newMode == AppMode.matrimony) {
    final shouldComplete = await _showCompletionDialog(context);
    if (shouldComplete && context.mounted) {
      context.push('/profile-setup');
    }
  }
}

Future<bool> _showCompletionDialog(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final onSurface = Theme.of(context).colorScheme.onSurface;

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
                color: AppColors.indiaGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.diversity_3_rounded,
                size: 40,
                color: AppColors.indiaGreen,
              ),
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
              l.modeSwitchCompleteSubtitle,
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
                  backgroundColor: AppColors.indiaGreen,
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
