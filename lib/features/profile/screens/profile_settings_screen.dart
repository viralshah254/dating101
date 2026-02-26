import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feature_flags/feature_flags.dart';
import '../../../core/locale/app_locale_provider.dart';
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
          'Profile & Settings',
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
                    profileName ?? 'My profile',
                    style: AppTypography.titleLarge.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'View profile',
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'saathi mode', onSurface: onSurface),
          _ModeSwitchTile(
            currentMode: mode,
            onSwitch: () => _showModeSwitch(context, ref, mode),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Account', onSurface: onSurface),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(
              'Invite friends',
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Referral rewards',
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
                'Boost profile',
                style: AppTypography.bodyLarge.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Appear more in discovery',
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
              'Verification',
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'ID, photo, LinkedIn',
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
              'Notifications',
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
              'Privacy & safety',
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
              'App language',
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Choose app language',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Account & data', onSurface: onSurface),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(
              'Download my data',
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Request a copy of your data',
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
              'Deactivate account',
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Temporarily disable your account',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeactivateConfirm(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete account',
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Permanently delete your account',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeleteAccountConfirm(context, ref),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Support', onSurface: onSurface),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(
              'Help centre',
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
              'Terms & Privacy',
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
            label: const Text('Sign out'),
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
    final loaded = await ref.read(profileRepositoryProvider).getNotificationPreferences();
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification preferences saved'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                  child: const Text('Save'),
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
                        if (ctx.mounted)
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('No FCM token (check permission)'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        return;
                      }
                      await Clipboard.setData(ClipboardData(text: token));
                      if (ctx.mounted)
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'FCM token copied. Use Firebase Console → Cloud Messaging to send a test.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 4),
                          ),
                        );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy FCM token'),
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
  Map<String, dynamic> privacy = {'showInVisitors': true, 'profileVisibility': 'everyone', 'hideFromDiscovery': false};
  try {
    privacy = await ref.read(profileRepositoryProvider).getPrivacy();
  } catch (_) {}
  bool showInVisitors = privacy['showInVisitors'] == true;
  String profileVisibility = (privacy['profileVisibility'] as String?) ?? 'everyone';
  bool hideFromDiscovery = privacy['hideFromDiscovery'] == true;

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => SafeArea(
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
                'Privacy & safety',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Blocked users'),
                subtitle: const Text('View and unblock people you\'ve blocked'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/blocked-users');
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Show in visitors'),
                subtitle: const Text(
                  'When off, your visits are still recorded but you won\'t appear in others\' visitor lists',
                ),
                value: showInVisitors,
                onChanged: (v) => setSheetState(() => showInVisitors = v),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Who can see my profile'),
                subtitle: Text(
                  profileVisibility == 'everyone'
                      ? 'Everyone'
                      : profileVisibility == 'only_matches'
                          ? 'Only my matches'
                          : 'Only after interest',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog<String>(
                    context: ctx,
                    builder: (dctx) => AlertDialog(
                      title: const Text('Who can see my profile'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: const Text('Everyone'),
                            value: 'everyone',
                            groupValue: profileVisibility,
                            onChanged: (v) {
                              setSheetState(() => profileVisibility = v!);
                              Navigator.pop(dctx, v);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Only my matches'),
                            value: 'only_matches',
                            groupValue: profileVisibility,
                            onChanged: (v) {
                              setSheetState(() => profileVisibility = v!);
                              Navigator.pop(dctx, v);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Only after interest'),
                            value: 'only_after_interest',
                            groupValue: profileVisibility,
                            onChanged: (v) {
                              setSheetState(() => profileVisibility = v!);
                              Navigator.pop(dctx, v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ).then((v) {
                    if (v != null) setSheetState(() => profileVisibility = v);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Hide from discovery'),
                subtitle: const Text(
                  'Temporarily hide your profile from discovery and recommendations',
                ),
                value: hideFromDiscovery,
                onChanged: (v) => setSheetState(() => hideFromDiscovery = v),
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
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy settings saved'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (_) {}
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showModeSwitch(BuildContext context, WidgetRef ref, AppMode currentMode) {
  final newMode = currentMode == AppMode.dating
      ? AppMode.matrimony
      : AppMode.dating;
  final newLabel = newMode == AppMode.dating ? 'Dating' : 'Matrimony';
  final onSurface = Theme.of(context).colorScheme.onSurface;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Switch to $newLabel?'),
      content: Text(
        'Your profile info is shared. You can complete or update $newLabel-specific details anytime.',
        style: AppTypography.bodyMedium.copyWith(
          color: onSurface.withValues(alpha: 0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
          ),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await switchAppMode(context, ref, newMode);
          },
          child: const Text('Switch'),
        ),
      ],
    ),
  );
}

void _showLanguagePicker(BuildContext context, WidgetRef ref) {
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'App language',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...locales.map((locale) {
              final code = locale.languageCode;
              final name = localeNames[code] ?? code;
              final isSelected = currentCode == code;
              return ListTile(
                title: Text(name),
                trailing: isSelected ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  ref.read(appLocaleProvider.notifier).setLocale(code);
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language set to $name'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}

Future<void> _requestDataExport(BuildContext context, WidgetRef ref) async {
  try {
    final result = await ref.read(accountRepositoryProvider).requestDataExport();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Export requested. We\'ll email you when ready.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request failed. Try again later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void _showDeactivateConfirm(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Deactivate account?'),
      content: const Text(
        'Your profile will be hidden and you won\'t receive matches or messages. You can reactivate later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
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
                const SnackBar(
                  content: Text('Deactivation failed. Try again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );
}

void _showDeleteAccountConfirm(BuildContext context, WidgetRef ref) {
  final errorColor = Theme.of(context).colorScheme.error;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete account permanently?'),
      content: const Text(
        'This cannot be undone. All your data will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
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
                const SnackBar(
                  content: Text('Delete failed. Try again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(backgroundColor: errorColor),
          child: const Text('Delete permanently'),
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
                      isDating ? 'Dating' : 'Matrimony',
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isDating ? 'Switch to Matrimony' : 'Switch to Dating',
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
