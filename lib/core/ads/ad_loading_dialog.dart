import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
import '../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import 'ad_service.dart';

/// Shows a non-dismissible "Loading ad…" dialog, runs [loadAndShowInterstitial],
/// then pops the dialog. Use whenever the user taps "Watch ad" so they see
/// feedback while the ad loads.
Future<bool> loadAndShowInterstitialWithLoading(
  BuildContext context,
  WidgetRef ref,
  AdRewardReason reason,
) async {
  final l = AppLocalizations.of(context)!;
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
    if (context.mounted) Navigator.of(context).pop();
    return result;
  } catch (_) {
    if (context.mounted) Navigator.of(context).pop();
    return false;
  }
}
