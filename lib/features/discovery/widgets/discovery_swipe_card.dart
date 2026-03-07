import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../core/widgets/translatable_text.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen discovery card: one profile per swipe, large hero image, like/pass/super like.
class DiscoverySwipeCard extends StatelessWidget {
  /// When non-null, multiple images are shown with left/right tap to navigate.
  /// When null, uses [profile.imageUrl] as single image.
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
  /// When false (e.g. dating), managed-by chip is hidden since only self-managed are shown.
  final bool showManagedByChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final l = AppLocalizations.of(context)!;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero: image carousel (tap left/right for prev/next) + overlays
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroImageCarousel(
                    imageUrls: profile.imageUrls != null && profile.imageUrls!.isNotEmpty
                        ? profile.imageUrls!
                        : (profile.imageUrl != null && profile.imageUrl!.isNotEmpty
                            ? [profile.imageUrl!]
                            : []),
                    name: profile.name,
                    onTap: onTap,
                  ),
                  // Gradient overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Compatibility pill on image (sleek overlay)
                  if (profile.compatibilityScore != null ||
                      (profile.compatibilityLabel != null &&
                          profile.compatibilityLabel!.isNotEmpty))
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 88,
                      child: _CompatibilityPill(
                        score: profile.compatibilityScore,
                        label: profile.compatibilityLabel,
                      ),
                    ),
                  // Name, age, location on image
                  Positioned(
                    left: 20,
                    right: 52,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${profile.name}, ${profile.age ?? ''}',
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
                            if (profile.verified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 22, color: accent),
                            ],
                            if (profile.isPremium) ...[
                              const SizedBox(width: 6),
                              PremiumBadge(isPremium: true, compact: true),
                            ],
                          ],
                        ),
                        if (profile.city != null && profile.city!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.white.withValues(alpha: 0.95)),
                              const SizedBox(width: 4),
                              Text(
                                profile.city!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Overflow menu
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert, color: Colors.white, size: 28),
                          color: theme.colorScheme.surfaceContainerHighest,
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
                ],
              ),
            ),
            // Content: minimal fixed block — no scroll, no extra info (rest is on profile page)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      _ProfileBio(
                        bio: profile.bio,
                        onSurface: onSurface,
                        showViewMore: false,
                      ),
                      const SizedBox(height: 24),
                    // Pass | Super like | Like — main actions (super like in the middle)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionButton(
                          icon: Icons.close_rounded,
                          label: l.discoverPass,
                          color: const Color(0xFFE53935),
                          onPressed: onPass,
                        ),
                        const SizedBox(width: 28),
                        _ActionButton(
                          icon: Icons.star_rounded,
                          label: l.discoverSuperLike,
                          color: const Color(0xFF7C4DFF),
                          onPressed: onSuperLike,
                        ),
                        const SizedBox(width: 28),
                        _ActionButton(
                          icon: Icons.favorite_rounded,
                          label: l.discoverLike,
                          color: const Color(0xFF00E676),
                          onPressed: onLike,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline_rounded, size: 20, color: accent),
                                const SizedBox(width: 8),
                                Text(
                                  l.viewProfile,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            splashColor: color.withValues(alpha: 0.2),
            highlightColor: color.withValues(alpha: 0.08),
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Image carousel with tap-left = previous, tap-right = next, center = open profile.
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
        // Tap zones: left = previous, right = next, center = open profile
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
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, __, ___) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: AppTypography.displayLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sleek compatibility pill overlay on the hero image.
class _CompatibilityPill extends StatelessWidget {
  const _CompatibilityPill({this.score, this.label});

  final double? score;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final hasLabel = label != null && label!.isNotEmpty;
    if (!hasScore && !hasLabel) return const SizedBox.shrink();
    final scoreText = hasScore ? '${(score! * 100).round()}%' : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          if (scoreText != null)
            Text(
              scoreText,
              style: AppTypography.titleSmall.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (scoreText != null && hasLabel) const SizedBox(width: 6),
          if (hasLabel)
            Flexible(
              child: Text(
                label!,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.family_restroom, size: 14, color: accent.withValues(alpha: 0.9)),
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

class _ProfileBio extends ConsumerWidget {
  const _ProfileBio({
    required this.bio,
    required this.onSurface,
    this.showViewMore = true,
  });
  final String bio;
  final Color onSurface;
  final bool showViewMore;

  static const int _maxLines = 3;
  static const int _showViewMoreThreshold = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bio.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final accent = Theme.of(context).colorScheme.primary;
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
        if (showViewMore && bio.length > _showViewMoreThreshold) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showViewMoreDialog(context, bio),
            behavior: HitTestBehavior.opaque,
            child: Text(
              l.viewMore,
              style: AppTypography.labelMedium.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: accent.withValues(alpha: 0.7),
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
