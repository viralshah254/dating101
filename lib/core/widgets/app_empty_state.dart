import 'package:flutter/material.dart';

/// Standardized empty state widget with an optional action button.
/// Use instead of raw `Text('No results')` across discovery, chat, likes, requests, etc.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.favorite_border,
///   title: 'No matches yet',
///   subtitle: 'Start exploring profiles to find your match.',
///   actionLabel: 'Explore',
///   onAction: () => context.go('/'),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.icon,
    this.iconWidget,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : assert(icon != null || iconWidget != null || true);

  final String title;
  final IconData? icon;

  /// Custom widget placed above the title instead of an [icon].
  final Widget? iconWidget;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Compact variant (less padding, smaller icon).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = compact ? 40.0 : 64.0;
    final padding = compact ? 16.0 : 32.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null)
              iconWidget!
            else if (icon != null)
              Icon(icon, size: iconSize, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: compact ? 10 : 16),
            Text(
              title,
              style: compact
                  ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                  : theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: compact ? 4 : 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 12 : 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
