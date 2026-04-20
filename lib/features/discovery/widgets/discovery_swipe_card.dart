import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entitlements/entitlements.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/premium_badge.dart';
import '../../../domain/models/matrimony_extensions.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../features/moments/widgets/moment_viewer.dart';
import '../../../features/premium/widgets/photo_gate_overlay.dart';
import '../../../features/profile/widgets/voice_intro_player.dart';
import '../../../l10n/app_localizations.dart';

/// Deep Look overlay — slides up over the bottom half of the swipe card when
/// the user hovers in the curiosity zone (>90 px right drag, >800 ms).
class DeepLookLayer extends StatelessWidget {
  const DeepLookLayer({super.key, required this.profile});
  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPrompt =
        profile.promptAnswer != null && profile.promptAnswer!.trim().isNotEmpty;
    final hasCompat = profile.compatibilityScore != null;
    final hasIntent = profile.datingIntent != null && profile.datingIntent!.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle hint
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Label
              Row(
                children: [
                  Icon(Icons.remove_red_eye_rounded,
                      size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'DEEP LOOK',
                    style: AppTypography.labelSmall.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasPrompt) ...[
                _DeepLookRow(
                  icon: Icons.format_quote_rounded,
                  iconColor: cs.secondary,
                  text: '"${profile.promptAnswer!}"',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
              ],
              if (hasCompat) ...[
                _DeepLookRow(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.gold,
                  text:
                      '${(profile.compatibilityScore! * 100).round()}% compatible — ${profile.compatibilityLabel ?? profile.matchReasons.take(2).join(', ')}',
                ),
                const SizedBox(height: 10),
              ],
              if (hasIntent) ...[
                _DeepLookRow(
                  icon: Icons.favorite_border_rounded,
                  iconColor: AppColors.rosePrimary,
                  text: _intentLabel(profile.datingIntent!),
                ),
                const SizedBox(height: 10),
              ],
              if (!hasPrompt && !hasCompat && !hasIntent)
                Text(
                  profile.bio.trim().isNotEmpty
                      ? profile.bio
                      : '${profile.name} hasn\'t added details yet.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                'Keep dragging right to like · Release to spring back',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _intentLabel(String intent) {
    return switch (intent) {
      'serious' => 'Looking for something serious',
      'casual' => 'Open to casual connections',
      'marriage' => 'Here for marriage',
      'friends_first' || 'friends first' => 'Friends first',
      _ => intent,
    };
  }
}

class _DeepLookRow extends StatelessWidget {
  const _DeepLookRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.maxLines = 2,
  });
  final IconData icon;
  final Color iconColor;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Full-screen discovery card: photo-first, premium aesthetic.
class DiscoverySwipeCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final l = AppLocalizations.of(context)!;
    final entitlements = ref.watch(entitlementsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.black,
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
                photosVisibleCount: entitlements.photosVisibleCount,
                isAccepted: profile.isAccepted ?? false,
                onUpgradeNeeded: () => context.push('/premium?reason=photoLimit'),
              ),
              // Cinematic gradient — deep vignette, pure photo in top 60%
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.54),
                        Colors.black.withValues(alpha: 0.87),
                      ],
                      stops: const [0.0, 0.4, 0.65, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              // Frosted action bar — drawn first so profile text can sit above it in z-order
              Positioned(
                left: 32,
                right: 32,
                bottom: 40,
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
                          child: _ManagedByChip(role: profile.roleManagingProfile!),
                        ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _ActionButton(
                                  icon: Icons.close_rounded,
                                  variant: _ActionVariant.pass,
                                  onPressed: onPass,
                                ),
                                _ActionButton(
                                  icon: Icons.star_rounded,
                                  variant: _ActionVariant.superLike,
                                  onPressed: onSuperLike,
                                ),
                                _ActionButton(
                                  icon: Icons.favorite_rounded,
                                  variant: _ActionVariant.like,
                                  onPressed: onLike,
                                ),
                                _ActionButton(
                                  icon: Icons.expand_less_rounded,
                                  variant: _ActionVariant.info,
                                  onPressed: () => onTap?.call(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Profile text above the dock — IgnorePointer so taps still hit the buttons
              Positioned(
                left: 20,
                right: 80,
                bottom: 228,
                child: IgnorePointer(
                  child: _OverlayInfo(profile: profile, accent: accent),
                ),
              ),
              if (profile.voiceIntroUrl != null && profile.voiceIntroUrl!.isNotEmpty)
                Positioned(
                  left: 20,
                  bottom: 242,
                  child: VoiceIntroBadge(url: profile.voiceIntroUrl!),
                ),
              // Trust badge — top-left (only when not showing moment ring)
              if (!profile.hasActiveMoment && (profile.verificationScore ?? 0) > 0)
                Positioned(
                  left: 14,
                  top: 14,
                  child: _TrustBadge(profile: profile),
                ),
              // "NEW" badge — top-right (24-hour new profile flag)
              if (profile.isNew)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _NewProfileBadge(),
                ),
              // Moment story ring (top-left)
              if (profile.hasActiveMoment)
                Positioned(
                  left: 16,
                  top: 28,
                  child: MomentStoryRing(
                    hasActiveMoment: true,
                    ringWidth: 2.5,
                    child: ClipOval(
                      child: Container(
                        width: 44,
                        height: 44,
                        color: Colors.white24,
                        child: profile.momentImageUrl != null
                            ? Image.network(profile.momentImageUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.photo, color: Colors.white, size: 20))
                            : const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              // More menu — top right
              Positioned(
                top: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFFFFFFFF), size: 24),
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
      ),
    );
  }
}

enum _ActionVariant { pass, superLike, like, info }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.variant,
    required this.onPressed,
  });

  final IconData icon;
  final _ActionVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLike = variant == _ActionVariant.like;
    final isSuperLike = variant == _ActionVariant.superLike;
    final size = isLike ? 60.0 : (isSuperLike ? 52.0 : 46.0);
    final iconSize = isLike ? 28.0 : (isSuperLike ? 24.0 : 22.0);

    final Gradient? buttonGradient = switch (variant) {
      _ActionVariant.like => AppColors.heartGradient,
      _ActionVariant.superLike => AppColors.goldGradient,
      _ => null,
    };

    final iconColor = switch (variant) {
      _ActionVariant.pass => Colors.white.withValues(alpha: 0.9),
      _ActionVariant.superLike => AppColors.goldDark,
      _ActionVariant.like => Colors.white,
      _ActionVariant.info => Colors.white.withValues(alpha: 0.75),
    };

    final borderColor = switch (variant) {
      _ActionVariant.like => Colors.transparent,
      _ActionVariant.superLike => AppColors.gold.withValues(alpha: 0.4),
      _ActionVariant.pass => Colors.white.withValues(alpha: 0.3),
      _ActionVariant.info => Colors.white.withValues(alpha: 0.2),
    };

    final List<BoxShadow>? shadows = switch (variant) {
      _ActionVariant.like => [
          BoxShadow(
            color: AppColors.rosePrimary.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      _ActionVariant.superLike => [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      _ => null,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: buttonGradient,
            color: buttonGradient == null ? Colors.white.withValues(alpha: 0.12) : null,
            border: Border.all(color: borderColor),
            boxShadow: shadows,
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}

class _HeroImageCarousel extends StatefulWidget {
  const _HeroImageCarousel({
    required this.imageUrls,
    required this.name,
    required this.onTap,
    required this.photosVisibleCount,
    required this.isAccepted,
    required this.onUpgradeNeeded,
  });

  final List<String> imageUrls;
  final String name;
  final VoidCallback? onTap;
  final int photosVisibleCount;
  final bool isAccepted;
  final VoidCallback onUpgradeNeeded;

  @override
  State<_HeroImageCarousel> createState() => _HeroImageCarouselState();
}

class _HeroImageCarouselState extends State<_HeroImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  // Ad-unlocked photos for this session (0–2; photo 4+ always hard-gated)
  int _adUnlockedCount = 0;

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
            itemBuilder: (_, i) => GatedPhoto(
              photoIndex: i,
              photosVisibleCount: widget.photosVisibleCount,
              adUnlockedCount: _adUnlockedCount,
              isAccepted: widget.isAccepted,
              onAdUnlock: () {
                if (_adUnlockedCount < 2) {
                  setState(() => _adUnlockedCount++);
                }
              },
              onUpgradeNeeded: widget.onUpgradeNeeded,
              child: _HeroImage(imageUrl: urls[i], name: widget.name),
            ),
          ),
        // Tap zones for photo navigation
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
        // Top segmented progress bars
        if (hasMultiple)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                urls.length,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i == _currentIndex
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.35),
                    ),
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

/// Minimal info overlay — name, city/job, one contextual badge.
class _OverlayInfo extends StatelessWidget {
  const _OverlayInfo({required this.profile, required this.accent});
  final ProfileSummary profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    // Tier 3: pick first non-null contextual badge
    final sharedInterests = p.sharedInterests.isNotEmpty ? p.sharedInterests.take(2).join(', ') : null;
    final compatPct = p.compatibilityScore != null ? '${(p.compatibilityScore! * 100).round()}% match' : null;
    final intentLabel = _intentLabel(p.datingIntent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tier 1: Name, Age + verified/premium
        Row(
          children: [
            Flexible(
              child: Text(
                '${p.name}, ${p.age ?? ''}',
                style: AppTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.15,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (p.verified) ...[
              const SizedBox(width: 8),
              Icon(Icons.verified_rounded, size: 20, color: accent),
            ],
            if (p.isPremium) ...[
              const SizedBox(width: 6),
              PremiumBadge(isPremium: true, compact: true),
            ],
            if (p.requireVerifiedToContact) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Only verified users can contact',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_rounded, size: 11, color: Colors.white),
                      SizedBox(width: 3),
                      Text('Verified only', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        // Tier 2: City · Occupation
        if ((p.city != null && p.city!.isNotEmpty) ||
            (p.occupation != null && p.occupation!.isNotEmpty)) ...[
          const SizedBox(height: 6),
          Text(
            [
              if (p.city != null && p.city!.isNotEmpty) p.city!,
              if (p.occupation != null && p.occupation!.isNotEmpty) p.occupation!,
            ].join(' · '),
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Tier 3: one contextual badge
        if (sharedInterests != null || compatPct != null || intentLabel != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              sharedInterests ?? compatPct ?? intentLabel!,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String? _intentLabel(String? intent) {
    if (intent == null || intent.isEmpty) return null;
    return switch (intent) {
      'serious' => 'Serious relationship',
      'casual' => 'Casual',
      'marriage' => 'Open to marriage',
      'friends_first' || 'friends first' => 'Friends first',
      _ => intent,
    };
  }
}

/// Compact trust badge shown on the swipe card corner showing verification level.
class _NewProfileBadge extends StatelessWidget {
  const _NewProfileBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316), // warm orange accent
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.profile});
  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final score = profile.verificationScore ?? 0;
    final pct = (score * 100).round();

    // Determine tier color based on score
    final Color badgeColor;
    final String label;
    if (score >= 0.8) {
      badgeColor = const Color(0xFF00C853); // green
      label = 'Verified';
    } else if (score >= 0.5) {
      badgeColor = const Color(0xFF1565C0); // blue
      label = 'Verified';
    } else if (score >= 0.25) {
      badgeColor = const Color(0xFFF57C00); // amber
      label = '${pct}% trusted';
    } else {
      return const SizedBox.shrink();
    }

    // Show verification flags as tooltip/subtitle
    final flags = <String>[];
    if (profile.photoVerified) flags.add('📸');
    if (profile.idVerified) flags.add('🪪');
    if (profile.linkedInVerified) flags.add('💼');
    if (profile.educationVerified) flags.add('🎓');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              if (flags.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  flags.join(' '),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagedByChip extends StatelessWidget {
  const _ManagedByChip({required this.role});
  final ProfileRole role;

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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.family_restroom_rounded, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
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
