import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/entitlements/entitlements.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/profile_summary.dart';

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
    this.isShortlisted = false,
    this.isInterested = false,
    this.isPriorityInterested = false,
  });

  final ProfileSummary profile;
  final VoidCallback? onTap;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onShortlist;
  final VoidCallback onMessage;
  final VoidCallback onUpgrade;
  final bool isShortlisted;
  final bool isInterested;
  final bool isPriorityInterested;

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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoHeader(profile: profile, accent: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NameRow(profile: profile, onSurface: onSurface),
                  if (profile.occupation != null || profile.city != null) ...[
                    const SizedBox(height: 4),
                    _SubtitleRow(profile: profile, onSurface: onSurface),
                  ],
                  if (_hasKeyDetails) ...[
                    const SizedBox(height: 10),
                    _QuickDetails(profile: profile, accent: accent, onSurface: onSurface),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InterestRow(
                      interests: profile.interests,
                      sharedInterests: profile.sharedInterests,
                      accent: accent,
                      onSurface: onSurface,
                    ),
                  ],
                ],
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
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasKeyDetails =>
      profile.religion != null ||
      profile.educationDegree != null ||
      profile.heightCm != null ||
      profile.maritalStatus != null;
}

// ── Photo header with match badge overlay ────────────────────────────────

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.profile, required this.accent});
  final ProfileSummary profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final score = profile.compatibilityScore != null
        ? (profile.compatibilityScore! * 100).round()
        : null;

    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: profile.imageUrl != null
                ? Image.network(
                    profile.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AvatarPlaceholder(profile: profile, accent: accent),
                  )
                : _AvatarPlaceholder(profile: profile, accent: accent),
          ),
          // Gradient overlay at bottom for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                ),
              ),
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
                    Text('Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          if (profile.photoCount > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${profile.photoCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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
      color: accent.withValues(alpha: 0.08),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: AppTypography.displayLarge.copyWith(
            color: accent.withValues(alpha: 0.3),
            fontSize: 64,
          ),
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
    final color = score >= 70 ? accent : (score >= 45 ? AppColors.saffron : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 6),
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
                style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Name and subtitle ────────────────────────────────────────────────────

class _NameRow extends StatelessWidget {
  const _NameRow({required this.profile, required this.onSurface});
  final ProfileSummary profile;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${profile.name}${profile.age != null ? ', ${profile.age}' : ''}',
      style: AppTypography.titleMedium.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({required this.profile, required this.onSurface});
  final ProfileSummary profile;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (profile.occupation != null) parts.add(profile.occupation!);
    if (profile.city != null) parts.add(profile.city!);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 14, color: onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            parts.join(' \u2022 '),
            style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.6)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Quick detail pills ───────────────────────────────────────────────────

class _QuickDetails extends StatelessWidget {
  const _QuickDetails({required this.profile, required this.accent, required this.onSurface});
  final ProfileSummary profile;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final pills = <_PillData>[];
    if (profile.religion != null) pills.add(_PillData(profile.religion!));
    if (profile.educationDegree != null) pills.add(_PillData(profile.educationDegree!));
    if (profile.heightCm != null) {
      final ft = profile.heightCm! ~/ 30.48;
      final inches = ((profile.heightCm! % 30.48) / 2.54).round();
      pills.add(_PillData('$ft\'$inches"'));
    }
    if (profile.maritalStatus != null) pills.add(_PillData(profile.maritalStatus!));
    if (profile.motherTongue != null) pills.add(_PillData(profile.motherTongue!));

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: pills.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
        ),
        child: Text(
          p.label,
          style: AppTypography.caption.copyWith(
            color: onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }
}

class _PillData {
  const _PillData(this.label);
  final String label;
}

// ── Interest chips ───────────────────────────────────────────────────────

class _InterestRow extends StatelessWidget {
  const _InterestRow({
    required this.interests,
    required this.sharedInterests,
    required this.accent,
    required this.onSurface,
  });
  final List<String> interests;
  final List<String> sharedInterests;
  final Color accent;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final sharedSet = sharedInterests.map((s) => s.toLowerCase()).toSet();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: interests.take(4).map((i) {
        final isShared = sharedSet.contains(i.toLowerCase());
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isShared
                ? accent.withValues(alpha: 0.12)
                : onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: isShared
                ? Border.all(color: accent.withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isShared) ...[
                Icon(Icons.favorite, size: 12, color: accent),
                const SizedBox(width: 4),
              ],
              Text(
                i,
                style: AppTypography.caption.copyWith(
                  color: isShared
                      ? accent
                      : onSurface.withValues(alpha: 0.65),
                  fontWeight: isShared ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _ActionButton(
            icon: isInterested ? Icons.favorite_rounded : Icons.favorite_border,
            label: isInterested ? 'Interested' : 'Interested',
            color: accent,
            onTap: onLike,
          ),
          _ActionButton(
            icon: isPriorityInterested ? Icons.chat_bubble_rounded : Icons.star_border_rounded,
            label: isPriorityInterested ? 'Message' : 'Priority interest',
            color: isPriorityInterested ? accent : AppColors.saffron,
            onTap: isPriorityInterested ? onMessage : onSuperLike,
          ),
          _ActionButton(
            icon: isShortlisted ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: isShortlisted ? 'Saved' : 'Save',
            color: isShortlisted ? accent : onSurface.withValues(alpha: 0.6),
            onTap: onShortlist,
          ),
          _ActionButton(
            icon: ent.canSendMessage ? Icons.chat_bubble_outline : Icons.lock_outline,
            label: ent.canSendMessage ? 'Message' : 'Premium',
            color: ent.canSendMessage ? accent : Colors.grey,
            onTap: ent.canSendMessage ? onMessage : onUpgrade,
            showBadge: !ent.canSendMessage,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showBadge = false,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.saffron,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
