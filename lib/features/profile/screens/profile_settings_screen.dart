import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';

/// Profile & Settings — user's own profile and app settings.
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

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
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person, size: 48, color: primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'My profile',
                  style: AppTypography.titleLarge.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap to edit',
                  style: AppTypography.bodySmall.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
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
            onTap: () {},
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
            onTap: () {},
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
            onPressed: () {},
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign out'),
          ),
        ],
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
