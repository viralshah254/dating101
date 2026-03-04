import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/translatable_text.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../ai/widgets/match_reason_chip.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    required this.sendPrimaryLabel,
    this.onTap,
    required this.onSendIntro,
    required this.onBlock,
    required this.onReport,
  });

  final ProfileSummary profile;
  final String sendPrimaryLabel;
  final VoidCallback? onTap;
  final VoidCallback onSendIntro;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final l = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ProfileAvatar(
                    imageUrl: profile.imageUrl,
                    name: profile.name,
                    radius: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${profile.name}, ${profile.age ?? ''}',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (profile.verified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 18, color: accent),
                            ],
                          ],
                        ),
                        if (profile.roleManagingProfile != null &&
                            profile.roleManagingProfile !=
                                ProfileRole.self) ...[
                          const SizedBox(height: 6),
                          _ManagedByChip(
                            role: profile.roleManagingProfile!,
                            onSurface: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          profile.city ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        if (profile.distanceKm != null)
                          Text(
                            l.kmAway(profile.distanceKm!.toStringAsFixed(1)),
                            style: AppTypography.caption.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'block') onBlock();
                      if (v == 'report') onReport();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'block', child: Text(l.block)),
                      PopupMenuItem(value: 'report', child: Text(l.report)),
                    ],
                  ),
                ],
              ),
              if (profile.matchReasons.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.matchReasons
                      .take(3)
                      .map((r) => MatchReasonChip(reason: r))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ] else if (profile.matchReason != null &&
                  profile.matchReason!.isNotEmpty) ...[
                MatchReasonChip(reason: profile.matchReason!),
                const SizedBox(height: 12),
              ],
              _ProfileBio(
                bio: profile.bio,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
              if ((profile.promptAnswer ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.prompt,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.promptAnswer!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSendIntro,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(sendPrimaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact "Managed by parent/sibling/..." for discovery cards (matrimony).
class _ManagedByChip extends StatelessWidget {
  const _ManagedByChip({required this.role, required this.onSurface});
  final ProfileRole role;
  final Color onSurface;

  static String _label(BuildContext context, ProfileRole r) {
    final l = AppLocalizations.of(context)!;
    switch (r) {
      case ProfileRole.parent:
        return l.profileManagedByParent;
      case ProfileRole.guardian:
        return l.profileManagedByGuardian;
      case ProfileRole.sibling:
        return l.profileManagedBySibling;
      case ProfileRole.friend:
        return l.profileManagedByFriend;
      case ProfileRole.self:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label(context, role);
    if (label.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.family_restroom,
            size: 14,
            color: accent.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Avatar that shows profile image or falls back to initial letter on error (e.g. 403).
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });
  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTypography.headlineMedium,
        ),
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

/// Bio with fixed max lines, ellipsis, and "View more" (no scrollable description).
class _ProfileBio extends ConsumerWidget {
  const _ProfileBio({required this.bio, required this.onSurface});
  final String bio;
  final Color onSurface;

  static const int _maxLines = 3;
  static const int _showViewMoreThreshold = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bio.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final style = AppTypography.bodyMedium.copyWith(
      color: onSurface.withValues(alpha: 0.9),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TranslatableText(
          content: bio,
          textStyle: style,
          maxLines: _maxLines,
          showTranslateButton: true,
        ),
        if (bio.length > _showViewMoreThreshold) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showViewMoreDialog(context, bio),
            behavior: HitTestBehavior.opaque,
            child: Text(
              l.viewMore,
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static void _showViewMoreDialog(BuildContext context, String bio) {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.aboutMeSection),
        content: SingleChildScrollView(
          child: TranslatableText(
            content: bio,
            textStyle: AppTypography.bodyMedium.copyWith(height: 1.4),
            showTranslateButton: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}
