import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entitlements/entitlements.dart';
import '../../core/mode/app_mode.dart';
import '../../core/mode/mode_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/api/api_client.dart';
import '../../domain/models/user_profile.dart';
import '../../l10n/app_localizations.dart';

/// Restores the locally-stored app mode from the server profile so that users
/// land on the correct mode (dating/matrimony) after logout or a fresh install.
Future<void> syncModeFromProfile(UserProfile profile, WidgetRef ref) async {
  final serverPref = profile.modePreference;
  if (serverPref == null) return;
  final mode = AppMode.values.cast<AppMode?>().firstWhere(
    (m) => m?.name == serverPref,
    orElse: () => null,
  );
  if (mode == null) return;
  final repo = ref.read(modeRepositoryProvider);
  final localPref = await repo.getPreference();
  if (localPref != mode) {
    await ref.read(appModeProvider.notifier).setMode(mode);
  }
}

/// Shows referral premium dialog, then routes after password sign-in / sign-up (same as OTP flow).
Future<void> navigateAfterAuthSuccess(
  BuildContext context,
  WidgetRef ref, {
  required bool isNewUser,
  required bool referralApplied,
}) async {
  ref.read(subscriptionAccessRefreshProvider)();
  if (isNewUser) {
    if (referralApplied) {
      await _showReferralSuccessDialog(context);
      if (!context.mounted) return;
    }
    context.go('/profile-for');
    return;
  }

  try {
    final profile = await ref.read(profileRepositoryProvider).getMyProfile();
    if (!context.mounted) return;
    if (profile != null) {
      await syncModeFromProfile(profile, ref);
      if (!context.mounted) return;
      context.go('/');
    } else {
      context.go('/profile-for');
    }
  } catch (e) {
    if (e is ApiException && e.code == 'ACCOUNT_DEACTIVATED') {
      if (!context.mounted) return;
      final reactivate = await _showReactivatePrompt(context);
      if (!context.mounted) return;
      if (reactivate == true) {
        try {
          await ref.read(accountRepositoryProvider).reactivateAccount();
          if (!context.mounted) return;
          final profile = await ref.read(profileRepositoryProvider).getMyProfile();
          if (!context.mounted) return;
          if (profile != null) await syncModeFromProfile(profile, ref);
          if (!context.mounted) return;
          context.go(profile != null ? '/' : '/profile-for');
        } catch (err) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.requestFailedTryAgain),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        await ref.read(authRepositoryProvider).signOut();
        if (context.mounted) context.go('/login');
      }
    } else {
      if (context.mounted) context.go('/profile-for');
    }
  }
}

Future<void> _showReferralSuccessDialog(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l.referralPremiumTitle),
      content: Text(l.referralPremiumMessage),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.continueButton),
        ),
      ],
    ),
  );
}

Future<bool?> _showReactivatePrompt(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l.reactivateAccountPromptTitle),
      content: Text(l.reactivateAccountPromptBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.reactivateAccountNo),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.reactivateAccountYes),
        ),
      ],
    ),
  );
}
