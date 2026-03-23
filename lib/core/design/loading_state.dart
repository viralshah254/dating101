import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../theme/brand_theme.dart';

/// Full-screen loading: centered spinner with label.
Widget loadingSpinner(BuildContext context) {
  final l = AppLocalizations.of(context);
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: theme.colorScheme.primary),
        const SizedBox(height: AppTokens.space16),
        Text(
          l?.loading ?? 'Loading',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    ),
  );
}

/// Skeleton list for profile/match-style cards. Shimmer colors from BrandTheme.
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
    final brand = Theme.of(context).extension<BrandTheme>();
    final base = brand?.shimmerBase ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04);
    final highlight = brand?.shimmerHighlight ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06);

    return ListView.builder(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(AppTokens.radius16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: highlight),
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
