import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feature_flags/feature_flags.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/mode/mode_switch_helper.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/user_profile.dart';

final _myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  debugPrint('[ProfileSettings] Fetching my profile...');
  final repo = ref.watch(profileRepositoryProvider);
  try {
    final profile = await repo.getMyProfile();
    debugPrint(
      '[ProfileSettings] Got profile: name=${profile?.name}, photos=${profile?.photoUrls.length ?? 0}',
    );
    return profile;
  } catch (e) {
    debugPrint('[ProfileSettings] Error fetching profile: $e');
    rethrow;
  }
});

/// Profile & Settings — user's own profile and app settings.
class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final flags = ref.watch(featureFlagsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final profileAsync = ref.watch(_myProfileProvider);

    final profileName = profileAsync.whenOrNull(data: (p) => p?.name);
    final profilePhoto = profileAsync.whenOrNull(
      data: (p) => p?.photoUrls.isNotEmpty == true ? p!.photoUrls.first : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.profileSettings,
          style: AppTypography.headlineSmall.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              await context.push('/profile-view');
              ref.invalidate(_myProfileProvider);
            },
            child: Center(
              child: Column(
                children: [
                  _buildAvatar(profilePhoto, primary, 48),
                  const SizedBox(height: 12),
                  Text(
                    profileName ?? l.myProfile,
                    style: AppTypography.titleLarge.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l.viewProfile,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: l.saathiMode, onSurface: onSurface),
          _ModeSwitchTile(
            currentMode: mode,
            onSwitch: () => _showModeSwitch(context, ref, mode),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l.account, onSurface: onSurface),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(
              l.inviteFriends,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l.rewards,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/referral'),
          ),
          if (flags.profileBoost)
            ListTile(
              leading: const Icon(Icons.rocket_launch_outlined),
              title: Text(
                l.boostProfile,
                style: AppTypography.bodyLarge.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                l.appearMoreInDiscovery,
                style: AppTypography.bodySmall.copyWith(
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/paywall'),
            ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(
              l.verification,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l.verificationSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/verification'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(
              l.notifications,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNotificationSettings(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(
              l.privacyAndSafety,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacySettings(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              l.appLanguage,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l.chooseAppLanguage,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l.accountAndData, onSurface: onSurface),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(
              l.downloadMyData,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l.requestDataCopy,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _requestDataExport(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.pause_circle_outline),
            title: Text(
              l.deactivateAccount,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l.deactivateAccountSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeactivateConfirm(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l.deleteAccount,
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l.deleteAccountSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeleteAccountConfirm(context, ref),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l.support, onSurface: onSurface),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(
              l.helpCentre,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(
              l.termsAndPrivacy,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(notificationServiceProvider).onLogout();
              try {
                await ref.read(profileRepositoryProvider).deleteFcmToken();
              } catch (_) {}
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 20),
            label: Text(l.signOut),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, Color primary, double radius) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isLocal = !photoUrl.startsWith('http');
      return CircleAvatar(
        radius: radius,
        backgroundImage: isLocal
            ? FileImage(File(photoUrl))
            : NetworkImage(photoUrl),
        backgroundColor: primary.withValues(alpha: 0.1),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.2),
      child: Icon(Icons.person, size: radius, color: primary),
    );
  }
}

void _showNotificationSettings(BuildContext context, WidgetRef ref) async {
  final defaultPrefs = <String, bool>{
    'interestReceived': true,
    'priorityInterestReceived': true,
    'interestAccepted': true,
    'interestDeclined': false,
    'mutualMatch': true,
    'profileVisited': true,
    'newMessage': true,
    'contactRequestAccepted': true,
    'contactRequestDeclined': false,
  };
  Map<String, bool> prefs = Map.from(defaultPrefs);
  try {
    final loaded = await ref
        .read(profileRepositoryProvider)
        .getNotificationPreferences();
    for (final e in loaded.entries) {
      if (e.value is bool) prefs[e.key] = e.value as bool;
    }
  } catch (_) {}

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final labels = {
          'interestReceived': 'Interest received',
          'priorityInterestReceived': 'Priority interest received',
          'interestAccepted': 'Interest accepted',
          'interestDeclined': 'Interest declined',
          'mutualMatch': 'Mutual match',
          'profileVisited': 'Profile visited',
          'newMessage': 'New message',
          'contactRequestAccepted': 'Contact request accepted',
          'contactRequestDeclined': 'Contact request declined',
        };
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notification preferences',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ...prefs.entries.map(
                  (e) => SwitchListTile(
                    title: Text(labels[e.key] ?? e.key),
                    value: e.value,
                    onChanged: (v) => setSheetState(() => prefs[e.key] = v),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(profileRepositoryProvider)
                          .updateNotificationPreferences(
                            prefs.map((k, v) => MapEntry(k, v)),
                          );
                      if (context.mounted) {
                        final loc = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.notificationPreferencesSaved),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Text(AppLocalizations.of(ctx)!.save),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Test push (debug)',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final token = await ref
                          .read(notificationServiceProvider)
                          .getToken();
                      if (token == null) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(ctx)!.noFcmToken,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }
                      await Clipboard.setData(ClipboardData(text: token));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'FCM token copied. Use Firebase Console → Cloud Messaging to send a test.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(AppLocalizations.of(ctx)!.copyFcmToken),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showPrivacySettings(BuildContext context, WidgetRef ref) async {
  Map<String, dynamic> privacy = {
    'showInVisitors': true,
    'profileVisibility': 'everyone',
    'hideFromDiscovery': false,
    'photosHidden': false,
  };
  try {
    privacy = await ref.read(profileRepositoryProvider).getPrivacy();
  } catch (_) {}
  bool showInVisitors = privacy['showInVisitors'] == true;
  String profileVisibility =
      (privacy['profileVisibility'] as String?) ?? 'everyone';
  bool hideFromDiscovery = privacy['hideFromDiscovery'] == true;
  bool photosHidden = privacy['photosHidden'] == true;

  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final loc = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.privacyAndSafety,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: Text(loc.blockedUsers),
                  subtitle: Text(loc.blockedUsersSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/blocked-users');
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(loc.showInVisitors),
                  subtitle: Text(loc.showInVisitorsSubtitle),
                  value: showInVisitors,
                  onChanged: (v) => setSheetState(() => showInVisitors = v),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(loc.whoCanSeeMyProfile),
                  subtitle: Text(
                    profileVisibility == 'everyone'
                        ? loc.everyone
                        : profileVisibility == 'only_matches'
                        ? loc.onlyMyMatches
                        : loc.onlyAfterInterest,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog<String>(
                      context: ctx,
                      builder: (dctx) {
                        final dloc = AppLocalizations.of(dctx)!;
                        return AlertDialog(
                          title: Text(dloc.whoCanSeeMyProfile),
                          content: RadioGroup<String>(
                            groupValue: profileVisibility,
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => profileVisibility = v);
                                Navigator.pop(dctx, v);
                              }
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RadioListTile<String>(
                                  title: Text(dloc.everyone),
                                  value: 'everyone',
                                ),
                                RadioListTile<String>(
                                  title: Text(dloc.onlyMyMatches),
                                  value: 'only_matches',
                                ),
                                RadioListTile<String>(
                                  title: Text(dloc.onlyAfterInterest),
                                  value: 'only_after_interest',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).then((v) {
                      if (v != null) setSheetState(() => profileVisibility = v);
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(loc.hideFromDiscovery),
                  subtitle: Text(loc.hideFromDiscoverySubtitle),
                  value: hideFromDiscovery,
                  onChanged: (v) => setSheetState(() => hideFromDiscovery = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(loc.hideMyPhotos),
                  subtitle: Text(loc.hideMyPhotosSubtitle),
                  value: photosHidden,
                  onChanged: (v) => setSheetState(() => photosHidden = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(profileRepositoryProvider).updatePrivacy({
                        'showInVisitors': showInVisitors,
                        'profileVisibility': profileVisibility,
                        'hideFromDiscovery': hideFromDiscovery,
                        'photosHidden': photosHidden,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l.privacySettingsSaved),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Text(l.save),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showModeSwitch(BuildContext context, WidgetRef ref, AppMode currentMode) {
  final l = AppLocalizations.of(context)!;
  final newMode = currentMode == AppMode.dating
      ? AppMode.matrimony
      : AppMode.dating;
  final newLabel = newMode == AppMode.dating ? l.modeDating : l.modeMatrimony;
  final onSurface = Theme.of(context).colorScheme.onSurface;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.switchToMode(newLabel)),
      content: Text(
        l.switchToModeBody(newLabel),
        style: AppTypography.bodyMedium.copyWith(
          color: onSurface.withValues(alpha: 0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l.cancel,
            style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
          ),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await switchAppMode(context, ref, newMode);
          },
          child: Text(l.switchButton),
        ),
      ],
    ),
  );
}

void _showLanguagePicker(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context)!;
  final currentCode = ref.read(appLocaleProvider);
  final locales = supportedAppLocales;
  final localeNames = <String, String>{
    'en': 'English',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'te': 'తెలుగు',
    'mr': 'मराठी',
    'ta': 'தமிழ்',
    'ur': 'اردو',
    'gu': 'ગુજરાતી',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'pa': 'ਪੰਜਾਬੀ',
  };
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.appLanguage,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locales.length,
                  itemBuilder: (_, index) {
                    final locale = locales[index];
                    final code = locale.languageCode;
                    final name = localeNames[code] ?? code;
                    final isSelected = currentCode == code;
                    return ListTile(
                      title: Text(name),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () {
                        ref.read(appLocaleProvider.notifier).setLocale(code);
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l.languageSetTo(name)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _requestDataExport(BuildContext context, WidgetRef ref) async {
  try {
    final result = await ref
        .read(accountRepositoryProvider)
        .requestDataExport();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? AppLocalizations.of(context)!.exportRequested,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.requestFailedTryAgain),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void _showDeactivateConfirm(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deactivateAccountConfirm),
      content: Text(l.deactivateAccountConfirmBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref.read(accountRepositoryProvider).deactivateAccount();
              if (!context.mounted) return;
              await ref.read(profileRepositoryProvider).deleteFcmToken();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.deactivationFailed),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Text(l.deactivate),
        ),
      ],
    ),
  );
}

void _showDeleteAccountConfirm(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context)!;
  final errorColor = Theme.of(context).colorScheme.error;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteAccountConfirm),
      content: Text(l.deleteAccountConfirmBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref.read(accountRepositoryProvider).deleteAccount();
              if (!context.mounted) return;
              await ref.read(profileRepositoryProvider).deleteFcmToken();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.deleteFailed),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(backgroundColor: errorColor),
          child: Text(l.deletePermanently),
        ),
      ],
    ),
  );
}

class _ModeSwitchTile extends StatelessWidget {
  const _ModeSwitchTile({required this.currentMode, required this.onSwitch});
  final AppMode currentMode;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDating = currentMode == AppMode.dating;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSwitch,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDating ? AppColors.saffron : AppColors.indiaGreen)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDating ? Icons.favorite_rounded : Icons.diversity_3_rounded,
                  size: 24,
                  color: isDating ? AppColors.saffron : AppColors.indiaGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDating ? l.modeDating : l.modeMatrimony,
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isDating
                          ? l.switchToModeLabel(l.modeMatrimony)
                          : l.switchToModeLabel(l.modeDating),
                      style: AppTypography.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSurface});
  final String title;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
