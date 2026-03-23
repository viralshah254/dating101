import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/brand_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/discovery_providers.dart';

/// Calm, on-brand loading for Discover: stacked card silhouettes + soft shimmer.
class DiscoverFeedLoadingSurface extends StatelessWidget {
  const DiscoverFeedLoadingSurface({
    super.key,
    required this.cue,
  });

  final DiscoveryLoadingCue cue;

  String _message(AppLocalizations l) {
    switch (cue) {
      case DiscoveryLoadingCue.initial:
        return l.discoverLoadingInitial;
      case DiscoveryLoadingCue.filters:
        return l.discoverLoadingFilters;
      case DiscoveryLoadingCue.location:
        return l.discoverLoadingLocation;
      case DiscoveryLoadingCue.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brand = theme.extension<BrandTheme>()!;
    final l = AppLocalizations.of(context)!;
    final base = brand.shimmerBase;
    final highlight = brand.shimmerHighlight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cardW = (maxW - 40).clamp(280.0, 400.0);
        final cardH = cardW * 1.12;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              // Soft status line + decorative pulse (non-aggressive)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: cs.primary.withValues(alpha: 0.35),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        duration: 1800.ms,
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.08, 1.08),
                        curve: Curves.easeInOutCubic,
                      )
                      .fadeIn(duration: 400.ms),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _message(l),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: cardW + 24,
                    height: cardH + 36,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Back card (peek)
                        Positioned(
                          top: 10,
                          child: Transform.rotate(
                            angle: -0.03,
                            child: _ShimmerCard(
                              width: cardW * 0.92,
                              height: cardH * 0.94,
                              borderRadius: 22,
                              base: base,
                              highlight: highlight,
                              delayMs: 200,
                            ),
                          ),
                        ),
                        // Front card
                        Positioned(
                          top: 0,
                          child: _ShimmerCard(
                            width: cardW,
                            height: cardH,
                            borderRadius: 24,
                            base: base,
                            highlight: highlight,
                            delayMs: 0,
                          ),
                        ),
                        // Bottom meta bars (name / subtitle placeholders)
                        Positioned(
                          left: cardW * 0.08,
                          right: cardW * 0.08,
                          bottom: 28,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ShimmerBar(
                                width: cardW * 0.42,
                                height: 14,
                                base: base,
                                highlight: highlight,
                              ),
                              const SizedBox(height: 10),
                              _ShimmerBar(
                                width: cardW * 0.58,
                                height: 11,
                                base: base,
                                highlight: highlight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Action hints (ghost circles — matches pass / super / like rhythm)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: base,
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.12),
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          delay: (i * 150).ms,
                          duration: 1400.ms,
                          color: highlight,
                        ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.base,
    required this.highlight,
    required this.delayMs,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color base;
  final Color highlight;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          delay: delayMs.ms,
          duration: 1600.ms,
          color: highlight,
        );
  }
}

/// Replaces a harsh spinner when browsing countries/cities in sheets.
class DiscoverInlineListShimmer extends StatelessWidget {
  const DiscoverInlineListShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandTheme>()!;
    final base = brand.shimmerBase;
    final highlight = brand.shimmerHighlight;

    final mw = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: List.generate(itemCount, (i) {
          final w = (1.0 - (i % 3) * 0.08).clamp(0.55, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: (mw - 56) * w,
                height: 13,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(7),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    delay: (i * 100).ms,
                    duration: 1300.ms,
                    color: highlight,
                  ),
            ),
          );
        }),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.base,
    required this.highlight,
  });

  final double width;
  final double height;
  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(6),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: highlight);
  }
}
