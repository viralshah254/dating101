import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
import '../theme/app_typography.dart';
import '../analytics/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import 'ad_service.dart';

/// Pops the route after the current frame so we never call [Navigator.pop] while
/// the navigator is locked (e.g. right after an interstitial dismisses).
Future<void> _popAdLoadingDialog(BuildContext context) async {
  if (!context.mounted) return;
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (!completer.isCompleted) completer.complete();
  });
  await completer.future;
}

/// Shows a non-dismissible "Loading ad…" dialog, runs [loadAndShowInterstitial],
/// then pops the dialog. Use whenever the user taps "Watch ad" so they see
/// feedback while the ad loads.
Future<bool> loadAndShowInterstitialWithLoading(
  BuildContext context,
  WidgetRef ref,
  AdRewardReason reason,
) async {
  final l = AppLocalizations.of(context)!;
  final analytics = AnalyticsService.instance;
  analytics.log(AnalyticsEvent.adLoadStarted, {'reason': reason.name});
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  l.loadingAd,
                  style: AppTypography.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    final result = await ref.read(adServiceProvider).loadAndShowInterstitial(reason);
    analytics.log(AnalyticsEvent.adLoadResult, {'reason': reason.name, 'loaded': result});
    if (result) {
      analytics.log(AnalyticsEvent.adShown, {'reason': reason.name});
    }
    if (context.mounted) await _popAdLoadingDialog(context);
    return result;
  } catch (_) {
    analytics.log(AnalyticsEvent.adLoadResult, {'reason': reason.name, 'loaded': false});
    if (context.mounted) await _popAdLoadingDialog(context);
    return false;
  }
}
