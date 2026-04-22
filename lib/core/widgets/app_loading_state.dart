import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Standardized loading indicator used across the app.
/// Supports full-page, inline, and shimmer-list variants.
///
/// Usage:
/// ```dart
/// // Full-page spinner
/// const AppLoadingState()
///
/// // Shimmer list placeholder
/// AppLoadingState.shimmerList(itemCount: 6)
///
/// // Compact inline indicator
/// const AppLoadingState(compact: true)
/// ```
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.compact = false,
    this.message,
  });

  final bool compact;
  final String? message;

  /// Shimmer placeholder for a list of profile/thread cards.
  static Widget shimmerList({int itemCount = 6, double itemHeight = 80}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(height: itemHeight),
      ),
    );
  }

  /// Shimmer placeholder for a grid of profile cards.
  static Widget shimmerGrid({int itemCount = 6, double crossAxisSpacing = 8}) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: crossAxisSpacing,
        childAspectRatio: 0.7,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const _ShimmerCard(height: double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height == double.infinity ? null : height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: height == double.infinity
            ? const AspectRatio(aspectRatio: 0.7)
            : null,
      ),
    );
  }
}
