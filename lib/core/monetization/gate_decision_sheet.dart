import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_typography.dart';

enum GateDecision { upgrade, watchAd, notNow }

Future<GateDecision?> showGateDecisionSheet(
  BuildContext context, {
  required String title,
  required String message,
  required bool canWatchAd,
  String? watchAdLabel,
}) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<GateDecision>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(GateDecision.upgrade),
              child: Text(l.ctaUpgradeToPremium),
            ),
            const SizedBox(height: 8),
            if (canWatchAd) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(GateDecision.watchAd),
                child: Text(watchAdLabel ?? l.watchAdToUnlock),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(GateDecision.notNow),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    ),
  );
}
