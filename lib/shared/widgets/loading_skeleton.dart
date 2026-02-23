import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Week 13 — Loading skeleton components for lists and cards.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;
    final highlightColor = isDark
        ? AppColors.darkSurfaceVariant.withValues(alpha: 0.6)
        : AppColors.lightSurface.withValues(alpha: 0.8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton for a discovery profile card.
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LoadingSkeleton(width: 64, height: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LoadingSkeleton(width: 120, height: 20),
                      const SizedBox(height: 8),
                      const LoadingSkeleton(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const LoadingSkeleton(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const LoadingSkeleton(width: 200, height: 14),
            const SizedBox(height: 16),
            const LoadingSkeleton(width: double.infinity, height: 44),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a chat list item.
class ChatListTileSkeleton extends StatelessWidget {
  const ChatListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const LoadingSkeleton(width: 48, height: 48),
      title: const LoadingSkeleton(width: 100, height: 16),
      subtitle: const LoadingSkeleton(width: 180, height: 12),
    );
  }
}
