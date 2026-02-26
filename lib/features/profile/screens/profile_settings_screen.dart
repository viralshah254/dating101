import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    debugPrint('[ProfileSettings] Got profile: name=${profile?.name}, photos=${profile?.photoUrls.length ?? 0}');
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final profileAsync = ref.watch(_myProfileProvider);

    final profileName = profileAsync.whenOrNull(data: (p) => p?.name);
    final profilePhoto = profileAsync.whenOrNull(data: (p) => p?.photoUrls.isNotEmpty == true ? p!.photoUrls.first : null);

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
        backgroundImage: isLocal ? FileImage(File(photoUrl)) : NetworkImage(photoUrl),
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

void _showNotificationSettings(BuildContext context, WidgetRef ref) {
  final prefs = <String, bool>{
    'interestReceived': true,
    'priorityInterestReceived': true,
    'interestAccepted': true,
    'interestDeclined': false,
    'mutualMatch': true,
    'profileVisited': true,
    'newMessage': true,
  };

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
        };
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Notification preferences', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ...prefs.entries.map((e) => SwitchListTile(
                      title: Text(labels[e.key] ?? e.key),
                      value: e.value,
                      onChanged: (v) => setSheetState(() => prefs[e.key] = v),
                    )),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(profileRepositoryProvider).updateNotificationPreferences(
                        prefs.map((k, v) => MapEntry(k, v)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification preferences saved'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (_) {}
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showPrivacySettings(BuildContext context, WidgetRef ref) {
  bool showInVisitors = true;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Privacy & safety', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show in visitors'),
                subtitle: const Text('When off, your visits are still recorded but you won\'t appear in others\' visitor lists'),
                value: showInVisitors,
                onChanged: (v) => setSheetState(() => showInVisitors = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref.read(profileRepositoryProvider).updatePrivacy({'showInVisitors': showInVisitors});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy settings saved'), behavior: SnackBarBehavior.floating),
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
