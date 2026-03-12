import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/entitlements/entitlements.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';

/// Treats obvious placeholder/junk data as hidden (e.g. "1111111", "n/a", all digits).
bool _isPlaceholder(String? s) {
  if (s == null || s.trim().isEmpty) return true;
  final t = s.trim();
  if (t.length < 2) return true;
  if (RegExp(r'^[\d\s]+$').hasMatch(t)) return true; // all digits
  if (RegExp(r'^(.)\1+$').hasMatch(t)) return true; // repeated char
  final lower = t.toLowerCase();
  if (lower == 'n/a' || lower == 'null' || lower == 'na') return true;
  return false;
}

class MatchProfileCard extends ConsumerWidget {
  const MatchProfileCard({
    super.key,
    required this.profile,
    this.onTap,
    required this.onLike,
    required this.onSuperLike,
    required this.onShortlist,
    required this.onMessage,
    required this.onUpgrade,
    required this.onBlock,
    required this.onReport,
    this.isShortlisted = false,
    this.isInterested = false,
    this.isPriorityInterested = false,
    this.messageUnlockedByMatch = false,
  });

  final ProfileSummary profile;
  final VoidCallback? onTap;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onShortlist;
  final VoidCallback onMessage;
  final VoidCallback onUpgrade;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final bool isShortlisted;
  final bool isInterested;
  final bool isPriorityInterested;

  /// When true (e.g. on Matches tab), Message is unlocked even without premium.
  final bool messageUnlockedByMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final ent = ref.watch(entitlementsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _PhotoHeader(
                profile: profile,
                accent: accent,
                onBlock: onBlock,
                onReport: onReport,
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ActionBar(
              ent: ent,
              accent: accent,
              onLike: onLike,
              onSuperLike: onSuperLike,
              onShortlist: onShortlist,
              onMessage: onMessage,
              onUpgrade: onUpgrade,
              isShortlisted: isShortlisted,
              isInterested: isInterested,
              isPriorityInterested: isPriorityInterested,
              messageUnlockedByMatch: messageUnlockedByMatch,
            ),
          ],
        ),
      ),
    );
  }

}

// ── Photo header with match badge overlay ────────────────────────────────

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.profile,
    required this.accent,
    required this.onBlock,
    required this.onReport,
  });
  final ProfileSummary profile;
  final Color accent;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final score = profile.compatibilityScore != null
        ? (profile.compatibilityScore! * 100).round()
        : null;
    final l = AppLocalizations.of(context)!;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: profile.imageUrl != null
                ? Image.network(
                    profile.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _AvatarPlaceholder(profile: profile, accent: accent),
                  )
                : _AvatarPlaceholder(profile: profile, accent: accent),
          ),
          // Gradient overlay at bottom for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(0),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Name, age, city, occupation — compact bio as one overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${profile.name}${profile.age != null ? ', ${profile.age}' : ''}',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isPremium)
                      PremiumBadge(isPremium: true, compact: true),
                  ],
                ),
                if (profile.roleManagingProfile != null &&
                    profile.roleManagingProfile != ProfileRole.self) ...[
                  const SizedBox(height: 4),
                  _ManagedByChip(
                    role: profile.roleManagingProfile!,
                    onSurface: Colors.white,
                  ),
                ],
                if ((profile.city != null && !_isPlaceholder(profile.city)) ||
                    (profile.occupation != null && !_isPlaceholder(profile.occupation))) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (profile.city != null && !_isPlaceholder(profile.city)) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.95)),
                        const SizedBox(width: 4),
                        Text(
                          profile.city!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (profile.city != null && !_isPlaceholder(profile.city) &&
                          profile.occupation != null && !_isPlaceholder(profile.occupation))
                        Text(
                          ' • ',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      if (profile.occupation != null && !_isPlaceholder(profile.occupation))
                        Flexible(
                          child: Text(
                            profile.occupation!,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (profile.verified)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Safety menu (3-dots) + optional photo count
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (profile.photoCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.photoCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Material(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (v) {
                      if (v == 'block') onBlock();
                      if (v == 'report') onReport();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(
                              Icons.block,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(l.block),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(l.report),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Positioned(
              bottom: 10,
              right: 12,
              child: _MatchBadge(score: score, accent: accent),
            ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.profile, required this.accent});
  final ProfileSummary profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 72,
          color: accent.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score, required this.accent});
  final int score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? accent
        : (score >= 45 ? AppColors.saffron : AppColors.lightTextTertiary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 2.5,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                'Match',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact "Managed by parent/sibling/..." for overlay on photo.
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
    final accent = AppColors.indiaGreen;
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

// ── Action bar with 4 actions ────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.ent,
    required this.accent,
    required this.onLike,
    required this.onSuperLike,
    required this.onShortlist,
    required this.onMessage,
    required this.onUpgrade,
    this.isShortlisted = false,
    this.isInterested = false,
    this.isPriorityInterested = false,
    this.messageUnlockedByMatch = false,
  });
  final Entitlements ent;
  final Color accent;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onShortlist;
  final VoidCallback onMessage;
  final VoidCallback onUpgrade;
  final bool isShortlisted;
  final bool isInterested;
  final bool isPriorityInterested;
  final bool messageUnlockedByMatch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canMessageWithoutAd = ent.canSendMessage || messageUnlockedByMatch;

    // Primary CTA: one clear action that changes by state (Express interest → Add priority → Priority sent)
    String primaryLabel;
    IconData primaryIcon;
    VoidCallback? primaryOnTap;
    bool primaryEnabled = true;
    Color primaryColor = accent;

    if (isPriorityInterested) {
      primaryLabel = l.prioritySent;
      primaryIcon = Icons.check_circle_rounded;
      primaryOnTap = null;
      primaryEnabled = false;
      primaryColor = onSurface.withValues(alpha: 0.5);
    } else if (isInterested) {
      primaryLabel = l.addPriority;
      primaryIcon = Icons.auto_awesome;
      primaryOnTap = onSuperLike;
      primaryColor = AppColors.saffron;
    } else {
      primaryLabel = l.ctaSendInterest;
      primaryIcon = Icons.favorite_border_rounded;
      primaryOnTap = onLike;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _PrimaryActionButton(
              icon: primaryIcon,
              label: primaryLabel,
              color: primaryColor,
              onTap: primaryOnTap,
              enabled: primaryEnabled,
            ),
          ),
          const SizedBox(width: 10),
          _CompactIconButton(
            icon: isShortlisted ? Icons.star_rounded : Icons.star_border_rounded,
            color: isShortlisted ? accent : onSurface.withValues(alpha: 0.6),
            onTap: onShortlist,
            tooltip: l.ctaShortlist,
          ),
          const SizedBox(width: 10),
          _CompactIconButton(
            icon: canMessageWithoutAd ? Icons.chat_bubble_outline_rounded : Icons.lock_outline,
            color: canMessageWithoutAd ? accent : onSurface.withValues(alpha: 0.5),
            onTap: onMessage,
            showBadge: !canMessageWithoutAd,
            tooltip: l.ctaSendMessage,
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isAccent = color == AppColors.indiaGreen || color == AppColors.saffron;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: enabled
                ? (isAccent ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.14))
                : color.withValues(alpha: 0.08),
            border: enabled && isAccent
                ? Border.all(color: color.withValues(alpha: 0.35), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.showBadge = false,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showBadge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          height: 52,
            child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              if (showBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.saffron,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

