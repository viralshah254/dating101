import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_typography.dart';

/// Full-screen loading: centered spinner. Use when content is a single block.
Widget loadingSpinner(BuildContext context) {
  final l = AppLocalizations.of(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l?.loading ?? 'Loading',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );
}

/// Skeleton list for profile/match-style cards. Use on discovery, matches,
/// requests, shortlist while data loads.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 160,
    this.padding,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListView.builder(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: onSurface.withValues(alpha: 0.06)),
      ),
    );
  }
}

/// Inline small loading (e.g. inside a section).
Widget loadingInline(BuildContext context) {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: SizedBox(
        height: 32,
        width: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
