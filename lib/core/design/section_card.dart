import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Card for grouping content into sections (e.g. settings groups, list headers).
/// Uses theme surface, 20px radius, and optional leading icon/title.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.leading,
    this.leadingIcon,
    required this.child,
    this.padding,
    this.borderRadius = 20,
  });

  final String? title;
  final Widget? leading;
  final IconData? leadingIcon;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(borderRadius),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || leading != null || leadingIcon != null) ...[
            Row(
              children: [
                if (leading != null) leading!,
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 20, color: onSurface.withValues(alpha: 0.8)),
                  const SizedBox(width: 10),
                ],
                if (title != null)
                  Text(
                    title!,
                    style: AppTypography.titleSmall.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}
