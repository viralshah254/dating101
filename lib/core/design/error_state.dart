import 'package:flutter/material.dart';

import 'package:shubhmilan/l10n/app_localizations.dart';
import '../../data/api/api_client.dart';
import '../theme/app_tokens.dart';

/// Standard error state with message and retry. Reads all colors from theme.
///
/// Pass either [message] (pre-formatted string) or [error] (raw exception — automatically
/// converted to a user-safe message for known [ApiException] codes).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message,
    this.error,
    required this.onRetry,
    this.retryLabel,
  }) : assert(message != null || error != null, 'Provide message or error');

  final String? message;

  /// Raw exception. If [ApiException], its code is translated to a user-safe string.
  final Object? error;
  final VoidCallback onRetry;
  final String? retryLabel;

  String _resolveMessage(BuildContext context) {
    if (message != null && message!.isNotEmpty) return message!;
    final l = AppLocalizations.of(context);
    final fallback = l?.errorGeneric ?? 'Something went wrong. Please try again.';
    if (error is ApiException) {
      final e = error as ApiException;
      switch (e.code) {
        case 'RATE_LIMITED':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'UNAUTHORIZED':
        case 'INVALID_TOKEN':
          return 'Your session has expired. Please sign in again.';
        case 'PREMIUM_REQUIRED':
          return 'This feature requires a premium subscription.';
        case 'SERVICE_UNAVAILABLE':
          return 'Service temporarily unavailable. Please try again shortly.';
        case 'NOT_FOUND':
          return 'This content is no longer available.';
        case 'CONNECTION_REQUIRED':
          return 'Send or accept an interest first to access this feature.';
        default:
          return e.message.isNotEmpty ? e.message : fallback;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedMessage = _resolveMessage(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: AppTokens.iconHero,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppTokens.space20),
            Text(
              resolvedMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space24),
            FilledButton(
              onPressed: onRetry,
              child: Text(
                retryLabel ?? AppLocalizations.of(context)?.retry ?? 'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
