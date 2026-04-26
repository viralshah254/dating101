import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/entitlements/entitlements.dart';
import '../../core/mode/app_mode.dart';
import '../../core/mode/mode_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/api/api_client.dart';
import '../../domain/models/user_profile.dart';
import '../../l10n/app_localizations.dart';

/// Pushes the user's chosen mode to the server so it survives logout and
/// device changes. Fire-and-forget (non-blocking); errors are swallowed.
Future<void> pushModeToServer(AppMode mode, WidgetRef ref) async {
  try {
    await ref.read(profileRepositoryProvider).saveProfileJson(
      {
        'modePreference': mode.name,
        'profileMode': mode.name,
      },
      create: false,
    );
  } catch (_) {}
}

/// Restores the app mode from the server profile so that users land on the
/// correct mode (dating/matrimony) after logout or a fresh install.
///
/// When the server has no [modePreference] (legacy accounts), the mode is
/// derived from the profile content: matrimony-only → matrimony,
/// dating-only → dating. The derived value is then written back to the server
/// so future logins are instant.
Future<void> syncModeFromProfile(UserProfile profile, WidgetRef ref) async {
  final serverPref = profile.modePreference;
  AppMode? mode;

  if (serverPref != null) {
    // Server has an explicit preference — use it directly.
    mode = AppMode.values.cast<AppMode?>().firstWhere(
      (m) => m?.name == serverPref,
      orElse: () => null,
    );
  } else {
    // Legacy account: derive mode from which profile extensions are present.
    final hasMat = profile.matrimonyExtensions != null;
    final hasDating = profile.datingExtensions != null;
    if (hasMat && !hasDating) {
      mode = AppMode.matrimony;
    } else if (hasDating && !hasMat) {
      mode = AppMode.dating;
    }
    // Both or neither: leave mode null and do not override local preference.
  }

  if (mode == null) return;

  final localPref = await ref.read(modeRepositoryProvider).getPreference();
  if (localPref != mode) {
    await ref.read(appModeProvider.notifier).setMode(mode);
  }

  // Backfill the server if modePreference was not set (one-time write).
  if (serverPref == null) {
    try {
      await ref.read(profileRepositoryProvider).saveProfileJson(
        {'modePreference': mode.name},
        create: false,
      );
    } catch (_) {
      // Best-effort: non-blocking. Will retry next login.
    }
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
    // Clear the stored install referrer code now that it has been used.
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove('pending_referral_code'),
    );
    if (referralApplied) {
      await _showReferralSuccessDialog(context);
      if (!context.mounted) return;
    }
    context.go('/profile-welcome');
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
