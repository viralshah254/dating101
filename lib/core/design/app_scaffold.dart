import 'package:flutter/material.dart';

/// Standard scaffold with consistent app bar styling.
/// Reads all styling from the current ThemeData — no hardcoded colors.
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: (title == null && titleWidget == null && actions == null && bottom == null)
          ? null
          : AppBar(
              title: titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
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
