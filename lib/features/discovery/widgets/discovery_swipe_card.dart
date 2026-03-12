import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';

bool _hasDescriptionOrInterests(ProfileSummary p) {
  final hasBio = (p.bio).trim().isNotEmpty;
  final hasPrompt = (p.promptAnswer ?? '').trim().isNotEmpty;
  final hasInterests = p.interests.isNotEmpty || p.sharedInterests.isNotEmpty;
  return hasBio || hasPrompt || hasInterests;
}

/// Full-screen discovery card: photo-first, premium aesthetic.
class DiscoverySwipeCard extends StatelessWidget {
  const DiscoverySwipeCard({
    super.key,
    required this.profile,
    this.onTap,
    required this.onPass,
    required this.onLike,
    required this.onSuperLike,
    required this.onBlock,
    required this.onReport,
    this.showManagedByChip = false,
  });

  final ProfileSummary profile;
  final VoidCallback? onTap;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final bool showManagedByChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final l = AppLocalizations.of(context)!;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen photo
            _HeroImageCarousel(
              imageUrls: profile.imageUrls != null && profile.imageUrls!.isNotEmpty
                  ? profile.imageUrls!
                  : (profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                      ? [profile.imageUrl!]
                      : []),
              name: profile.name,
              onTap: onTap,
            ),
            // Semi-transparent gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            // Info overlay — name, location, bio, interests
            Positioned(
              left: 20,
              right: 72,
              bottom: 140,
              child: _OverlayInfo(profile: profile, accent: accent),
            ),
            // Info button — opens full profile (bottom-right, above action bar)
            Positioned(
              right: 20,
              bottom: 120,
              child: _InfoButton(onTap: onTap, accent: accent),
            ),
            // Action buttons — over the image at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showManagedByChip &&
                        profile.roleManagingProfile != null &&
                        profile.roleManagingProfile != ProfileRole.self)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ManagedByChip(
                          role: profile.roleManagingProfile!,
                          onSurface: onSurface,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionButton(
                          icon: Icons.close_rounded,
                          label: l.discoverPass,
                          variant: _ActionVariant.pass,
                          onPressed: onPass,
                        ),
                        const SizedBox(width: 28),
                        _ActionButton(
                          icon: Icons.star_rounded,
                          label: l.discoverSuperLike,
                          variant: _ActionVariant.superLike,
                          onPressed: onSuperLike,
                          isPrimary: true,
                        ),
                        const SizedBox(width: 28),
                        _ActionButton(
                          icon: Icons.favorite_rounded,
                          label: l.discoverLike,
                          variant: _ActionVariant.like,
                          onPressed: onLike,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // More menu — top right
            Positioned(
              top: 12,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
                      color: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (v) {
                        if (v == 'block') onBlock();
                        if (v == 'report') onReport();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'block', child: Text(l.block)),
                        PopupMenuItem(value: 'report', child: Text(l.report)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onTap, required this.accent});
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

enum _ActionVariant { pass, superLike, like }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.variant,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final _ActionVariant variant;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    // Tinder-style: vibrant green Like, bright pink Pass, blue Super Like
    final (color, gradient, shadowColor) = switch (variant) {
      _ActionVariant.pass => (
          const Color(0xFFFF6B6B),
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8E8E), Color(0xFFFF4757)],
          ),
          const Color(0xFFFF4757).withValues(alpha: 0.45),
        ),
      _ActionVariant.superLike => (
          const Color(0xFF00A8FF),
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
          ),
          const Color(0xFF0288D1).withValues(alpha: 0.45),
        ),
      _ActionVariant.like => (
          const Color(0xFF07D170),
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4ADE80), Color(0xFF00C853)],
          ),
          const Color(0xFF00C853).withValues(alpha: 0.45),
        ),
    };

    final size = isPrimary ? 68.0 : 60.0;
    final iconSize = isPrimary ? 30.0 : 26.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            splashColor: color.withValues(alpha: 0.25),
            highlightColor: color.withValues(alpha: 0.12),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: isPrimary ? 24 : 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: iconSize, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _HeroImageCarousel extends StatefulWidget {
  const _HeroImageCarousel({
    required this.imageUrls,
    required this.name,
    required this.onTap,
  });

  final List<String> imageUrls;
  final String name;
  final VoidCallback? onTap;

  @override
  State<_HeroImageCarousel> createState() => _HeroImageCarouselState();
}

class _HeroImageCarouselState extends State<_HeroImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls.isEmpty ? <String>[] : widget.imageUrls;
    final hasMultiple = urls.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (urls.isEmpty)
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                style: AppTypography.displayLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                ),
              ),
            ),
          )
        else
          PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => _HeroImage(imageUrl: urls[i], name: widget.name),
          ),
        if (urls.isNotEmpty)
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (hasMultiple && _currentIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: const SizedBox(width: 80),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onTap,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (hasMultiple && _currentIndex < urls.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: const SizedBox(width: 80),
              ),
            ],
          ),
        if (hasMultiple)
          Positioned(
            left: 0,
            right: 0,
            bottom: 155,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == _currentIndex ? 8 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTypography.displayLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTypography.displayLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}

/// Info overlay on the photo — Tinder-style semi-transparent.
class _OverlayInfo extends StatelessWidget {
  const _OverlayInfo({required this.profile, required this.accent});
  final ProfileSummary profile;
  final Color accent;

  static const _white = Color(0xFFFFFFFF);
  static const _whiteMuted = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasCompat = profile.compatibilityScore != null ||
        (profile.compatibilityLabel != null && profile.compatibilityLabel!.isNotEmpty);
    final trust = _computeTrust(profile);
    final reasons = _topReasons(profile, l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrustPill(
          score: trust,
          label: _trustLabel(l, trust),
        ),
        const SizedBox(height: 8),
        if (hasCompat) ...[
          _CompatibilityPill(
            score: profile.compatibilityScore,
            label: profile.compatibilityLabel,
            onDark: false,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Flexible(
              child: Text(
                '${profile.name}, ${profile.age ?? ''}',
                style: AppTypography.headlineSmall.copyWith(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.verified) ...[
              const SizedBox(width: 8),
              Icon(Icons.verified_rounded, size: 20, color: accent),
            ],
            if (profile.isPremium) ...[
              const SizedBox(width: 6),
              PremiumBadge(isPremium: true, compact: true),
            ],
          ],
        ),
        if ((profile.city != null && profile.city!.isNotEmpty) ||
            (profile.occupation != null && profile.occupation!.isNotEmpty)) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (profile.city != null && profile.city!.isNotEmpty) ...[
                Icon(Icons.location_on_rounded, size: 14, color: _whiteMuted),
                const SizedBox(width: 4),
                Text(
                  profile.city!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (profile.city != null && profile.city!.isNotEmpty &&
                  profile.occupation != null && profile.occupation!.isNotEmpty)
                Text(
                  ' · ',
                  style: AppTypography.bodyMedium.copyWith(color: _whiteMuted),
                ),
              if (profile.occupation != null && profile.occupation!.isNotEmpty)
                Flexible(
                  child: Text(
                    profile.occupation!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
        if (_hasDescriptionOrInterests(profile)) ...[
          const SizedBox(height: 10),
          _DescriptionAndInterests(profile: profile, onDark: false),
        ],
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l.whyMatch,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: reasons.map((r) => _ReasonChip(text: r)).toList(),
          ),
        ],
      ],
    );
  }
}

double _computeTrust(ProfileSummary p) {
  var score = 0.15;
  if (p.verified) score += 0.35;
  if (p.photoCount >= 3 || (p.imageUrls?.length ?? 0) >= 3) score += 0.2;
  if (p.bio.trim().isNotEmpty || (p.promptAnswer ?? '').trim().isNotEmpty) score += 0.15;
  if (p.interests.isNotEmpty) score += 0.1;
  if (p.isPremium) score += 0.05;
  return score.clamp(0.0, 1.0);
}

String _trustLabel(AppLocalizations l, double score) {
  if (score >= 0.8) return l.trustBadgeStrong;
  if (score >= 0.6) return l.trustBadgeGood;
  return l.trustBadgeBasic;
}

List<String> _topReasons(ProfileSummary p, AppLocalizations l) {
  final out = <String>[];
  for (final r in p.matchReasons) {
    final t = r.trim();
    if (t.isNotEmpty) out.add(t);
    if (out.length >= 3) return out;
  }
  if (out.isEmpty && p.matchReason != null && p.matchReason!.trim().isNotEmpty) {
    out.add(p.matchReason!.trim());
  }
  if (out.length < 3 && p.sharedInterests.isNotEmpty) {
    out.add(l.sharedInterestsReason(p.sharedInterests.take(2).join(', ')));
  }
  return out.take(3).toList();
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.score, required this.label});
  final double score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$label $percent%',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompatibilityPill extends StatelessWidget {
  const _CompatibilityPill({this.score, this.label, this.onDark = false});

  final double? score;
  final String? label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final hasLabel = label != null && label!.isNotEmpty;
    if (!hasScore && !hasLabel) return const SizedBox.shrink();
    final scoreText = hasScore ? '${(score! * 100).round()}%' : null;

    final bgColor = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.2);
    final borderColor = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: onDark ? const Color(0xFFE8E6E3) : Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 6),
          if (scoreText != null)
            Text(
              scoreText,
              style: AppTypography.labelLarge.copyWith(
                color: onDark ? const Color(0xFFE8E6E3) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          if (scoreText != null && hasLabel) const SizedBox(width: 4),
          if (hasLabel)
            Flexible(
              child: Text(
                label!,
                style: AppTypography.bodySmall.copyWith(
                  color: onDark ? const Color(0xFFB8B5B0) : Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _DescriptionAndInterests extends StatelessWidget {
  const _DescriptionAndInterests({required this.profile, this.onDark = false});
  final ProfileSummary profile;
  final bool onDark;

  static const _textColor = Color(0xFFE8E6E3);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final desc = _buildDescription();
    final interests = profile.sharedInterests.isNotEmpty
        ? profile.sharedInterests
        : profile.interests;
    final hasDesc = desc != null && desc.isNotEmpty;
    final hasInterests = interests.isNotEmpty;

    if (!hasDesc && !hasInterests) return const SizedBox.shrink();

    final descText = desc ?? '';
    final textColor = onDark ? _textColor : Colors.white.withValues(alpha: 0.9);
    final chipBg = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.2);
    final chipBorder = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDesc) ...[
          Text(
            descText,
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasInterests) const SizedBox(height: 12),
        ],
        if (hasInterests)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: interests.take(4).map((i) {
              final isShared = profile.sharedInterests.contains(i);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isShared ? accent.withValues(alpha: 0.3) : chipBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: chipBorder, width: 1),
                ),
                child: Text(
                  i,
                  style: AppTypography.labelSmall.copyWith(
                    color: onDark ? _textColor : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String? _buildDescription() {
    final prompt = (profile.promptAnswer ?? '').trim();
    final bio = (profile.bio).trim();
    if (prompt.isNotEmpty) return prompt.length > 80 ? '${prompt.substring(0, 80)}…' : prompt;
    if (bio.isNotEmpty) return bio.length > 80 ? '${bio.substring(0, 80)}…' : bio;
    return null;
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.family_restroom_rounded, size: 14, color: accent),
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
