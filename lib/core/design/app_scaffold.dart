import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Standard scaffold for app screens with consistent app bar styling.
/// Use when you need a simple screen layout; for custom app bars (e.g. SliverAppBar)
/// use a plain [Scaffold] and apply theme manually.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: (title == null && titleWidget == null && actions == null && bottom == null)
          ? null
          : AppBar(
              title: titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: AppTypography.headlineSmall.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null),
              actions: actions,
              bottom: bottom,
            ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
