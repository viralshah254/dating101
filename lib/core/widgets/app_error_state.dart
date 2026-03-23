import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';

/// Standardized error state widget used across the app.
/// Displays a user-safe message, an optional retry button, and hides technical details.
///
/// Usage:
/// ```dart
/// AppErrorState(
///   error: e,
///   onRetry: () => ref.invalidate(someProvider),
/// )
/// ```
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  /// The raw exception (typically [ApiException] or [Exception]).
  final Object? error;

  /// Override message shown to the user. Falls back to [_friendlyMessage].
  final String? message;

  /// If provided, shows a "Try again" button that calls this on tap.
  final VoidCallback? onRetry;

  /// When true, renders a smaller inline variant (no icon, minimal padding).
  final bool compact;

  String _friendlyMessage(BuildContext context) {
    if (message != null) return message!;
    if (error is ApiException) {
      final e = error as ApiException;
      // Return user-safe messages for known backend error codes
      switch (e.code) {
        case 'RATE_LIMITED':
          return 'Too many attempts. Please wait a moment.';
        case 'NETWORK_ERROR':
        case 'CONNECTION_REFUSED':
          return 'No internet connection. Check your network and try again.';
        case 'UNAUTHORIZED':
        case 'INVALID_TOKEN':
          return 'Your session has expired. Please sign in again.';
        case 'PREMIUM_REQUIRED':
          return 'This feature requires a premium subscription.';
        case 'BLOCKED':
          return 'This action is not available.';
        case 'SERVICE_UNAVAILABLE':
          return 'Service is temporarily unavailable. Please try again shortly.';
        default:
          return e.message.isNotEmpty ? e.message : 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = _friendlyMessage(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              msg,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
