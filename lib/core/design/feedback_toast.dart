import 'package:flutter/material.dart';

/// Shows a floating success (green) or error (red) toast. Use instead of
/// generic SnackBar for "Interest sent", "Added to shortlist", etc.
void showSuccessToast(BuildContext context, String message) {
  _showColoredSnackBar(
    context,
    message: message,
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
    icon: Icons.check_circle_outline,
  );
}

void showErrorToast(BuildContext context, String message) {
  _showColoredSnackBar(
    context,
    message: message,
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
    icon: Icons.error_outline_rounded,
  );
}

void _showColoredSnackBar(
  BuildContext context, {
  required String message,
  required Color backgroundColor,
  required Color foregroundColor,
  IconData? icon,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    ),
  );
}
