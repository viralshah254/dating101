/// VerificationNudgeService
///
/// Shows a bottom-sheet on every app open while the user is unverified:
/// - Before deadline: dismissable, countdown shown ("X days Y hours left").
/// - After deadline:  non-dismissable; only "Verify now" is shown.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/user_profile.dart';

class VerificationNudgeService {
  VerificationNudgeService._();

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.currentUserId == null) return;

    UserProfile? profile;
    try {
      profile = await ref.read(profileRepositoryProvider).getMyProfile();
    } catch (_) {
      return;
    }
    if (profile == null) return;

    final vs = profile.verificationStatus;
    if (vs.photoVerified || vs.score >= 0.5) return;

    if (!context.mounted) return;

    final deadline = profile.verificationDeadlineAt;
    final now = DateTime.now().toUtc();
    final pastDeadline = deadline != null && now.isAfter(deadline);
    final remaining = deadline != null && !pastDeadline ? deadline.difference(now) : Duration.zero;

    final router = GoRouter.of(context);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !pastDeadline,
      enableDrag: !pastDeadline,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VerificationNudgeSheet(
        pastDeadline: pastDeadline,
        remaining: remaining,
        onVerifyNow: () {
          Navigator.of(ctx).pop();
          router.push('/verification');
        },
        onDismiss: pastDeadline
            ? null
            : () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

class _VerificationNudgeSheet extends StatelessWidget {
  const _VerificationNudgeSheet({
    required this.pastDeadline,
    required this.remaining,
    required this.onVerifyNow,
    this.onDismiss,
  });

  final bool pastDeadline;
  final Duration remaining;
  final VoidCallback onVerifyNow;
  final VoidCallback? onDismiss;

  String _formatCountdown() {
    if (remaining <= Duration.zero) return '';
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days > 0) return '$days day${days == 1 ? '' : 's'} $hours hr left';
    if (hours > 0) return '$hours hr $minutes min left';
    return '$minutes min left';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final accent = pastDeadline ? cs.error : cs.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!pastDeadline)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Icon(
                pastDeadline ? Icons.lock_rounded : Icons.verified_user_outlined,
                size: 48,
                color: accent,
              ),
              const SizedBox(height: 16),
              Text(
                pastDeadline ? 'Account locked' : 'Verify your profile',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: pastDeadline ? cs.error : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                pastDeadline
                    ? 'Your verification deadline has passed. Please complete photo verification to continue using the app.'
                    : 'Verified profiles receive 3× more interest. Complete your photo verification to unlock all features.',
                style: AppTypography.bodyMedium.copyWith(
                  color: onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
              if (!pastDeadline && remaining > Duration.zero) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        _formatCountdown(),
                        style: AppTypography.bodySmall.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onVerifyNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Verify now'),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Maybe later',
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
