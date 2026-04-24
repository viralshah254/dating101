import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../ads/ad_budget_provider.dart';
import '../theme/app_typography.dart';

enum GateDecision { upgrade, watchAd, notNow }

/// Shows a bottom sheet giving the user a choice: Upgrade, Watch Ad (if budget allows), or Not Now.
///
/// [canWatchAd]     Whether the feature supports ad-unlock at all.
/// [adActionType]   Backend action key (e.g. `AdActionType.photoUnlock`). When set with no
///                  [adsRemaining] override, remaining count is read for that feature only.
/// [adsRemaining]   Override remaining for this gate. Pass 0 to force-hide the ad option.
Future<GateDecision?> showGateDecisionSheet(
  BuildContext context, {
  required String title,
  required String message,
  required bool canWatchAd,
  String? watchAdLabel,
  String? adActionType,
  int? adsRemaining,
}) {
  return showModalBottomSheet<GateDecision>(
    context: context,
    builder: (ctx) => _GateDecisionSheetContent(
      title: title,
      message: message,
      canWatchAd: canWatchAd,
      watchAdLabel: watchAdLabel,
      adActionType: adActionType,
      adsRemainingOverride: adsRemaining,
    ),
  );
}

class _GateDecisionSheetContent extends ConsumerWidget {
  const _GateDecisionSheetContent({
    required this.title,
    required this.message,
    required this.canWatchAd,
    this.watchAdLabel,
    this.adActionType,
    this.adsRemainingOverride,
  });

  final String title;
  final String message;
  final bool canWatchAd;
  final String? watchAdLabel;
  final String? adActionType;
  final int? adsRemainingOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    final budgetAsync = ref.watch(adBudgetProvider);
    final map = budgetAsync.valueOrNull;
    final limit = map?.limitPerAction ?? 2;
    final remaining = adsRemainingOverride ??
        (adActionType != null ? map?.forType(adActionType!).remaining : null) ??
        limit;

    final budgetExhausted = remaining <= 0;
    final showAdOption = canWatchAd && !budgetExhausted;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (canWatchAd && budgetExhausted) ...[
              const SizedBox(height: 12),
              Text(
                'Daily ad limit reached — upgrade or try again tomorrow.',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(GateDecision.upgrade),
              child: Text(l.ctaUpgradeToPremium),
            ),
            const SizedBox(height: 8),
            if (showAdOption) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(GateDecision.watchAd),
                child: Text(watchAdLabel ?? l.watchAdToUnlock),
              ),
              const SizedBox(height: 4),
              Text(
                '$remaining of $limit ad unlocks remaining today (this action)',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(GateDecision.notNow),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
