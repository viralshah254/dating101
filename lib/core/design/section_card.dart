import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/brand_theme.dart';

/// Card for grouping content into sections (e.g. settings groups, list headers).
/// Uses theme surface, subtle border from BrandTheme, and refined shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.leading,
    this.leadingIcon,
    required this.child,
    this.padding,
    this.borderRadius = AppTokens.radius20,
  });

  final String? title;
  final Widget? leading;
  final IconData? leadingIcon;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<BrandTheme>();
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: brand?.cardBorder ?? theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: AppTokens.shadowSubtle(isDark),
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
                  Icon(
                    leadingIcon,
                    size: AppTokens.iconMD,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: AppTokens.space10),
                ],
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space14),
          ],
          child,
        ],
      ),
    );
  }
}
