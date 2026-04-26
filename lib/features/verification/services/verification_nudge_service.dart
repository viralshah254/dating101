/// VerificationNudgeService
///
/// While the user is unverified:
/// - Before deadline: dismissable countdown; **at most once per local calendar day** per user
///   (avoids spam on resume / duplicate timers).
/// - After deadline: non-dismissable; may appear again on a later app open / resume until verified.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/user_profile.dart';

const String _kNudgeDayPrefix = 'verification_nudge_last_day_';

class VerificationNudgeService {
  VerificationNudgeService._();

  /// Prevents concurrent [maybeShow] calls from opening stacked sheets (async gap before sheet).
  static bool _busy = false;

  static String _prefsDayKey(String userId) => '$_kNudgeDayPrefix$userId';

  static String _dateStringLocal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (_busy) return;
    if (!context.mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final userId = authRepo.currentUserId;
    if (userId == null) return;

    _busy = true;
    try {
      UserProfile? profile;
      try {
        profile = await ref.read(profileRepositoryProvider).getMyProfile();
      } catch (_) {
        return;
      }
      if (profile == null) return;

      // Never interrupt profile setup or any onboarding screen.
      const setupPaths = [
        '/profile-setup',
        '/profile-for',
        '/mode-select',
        '/onboarding',
        '/location-required',
        '/profile-welcome',
      ];
      final router = ref.read(appRouterProvider);
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (setupPaths.any((p) => currentPath.startsWith(p))) return;

      final vs = profile.verificationStatus;
      if (vs.photoVerified || vs.score >= 0.5) return;
      if (vs.idVerificationStatus == 'pending') return;

      if (!context.mounted) return;

      final deadline = profile.verificationDeadlineAt;
      final nowUtc = DateTime.now().toUtc();
      final pastDeadline = deadline != null && nowUtc.isAfter(deadline);
      final remaining =
          deadline != null && !pastDeadline ? deadline.difference(nowUtc) : Duration.zero;
      final mode = ref.read(appModeProvider) ?? AppMode.dating;

      SharedPreferences? prefs;
      if (!pastDeadline) {
        prefs = await SharedPreferences.getInstance();
        final todayLocal = _dateStringLocal(DateTime.now());
        final last = prefs.getString(_prefsDayKey(userId));
        if (last == todayLocal) return;
      }

      // Same as GoRouter: [context] from ShubhmilanApp is above MaterialApp, so it has no
      // MaterialLocalizations. Use the navigator under MaterialApp.router.
      final sheetContext = rootNavigatorKey.currentContext;
      if (sheetContext == null || !sheetContext.mounted) return;

      if (!pastDeadline) {
        await prefs!.setString(_prefsDayKey(userId), _dateStringLocal(DateTime.now()));
      }

      if (!sheetContext.mounted) return;

      await showModalBottomSheet<void>(
        context: sheetContext,
        isScrollControlled: true,
        isDismissible: !pastDeadline,
        enableDrag: !pastDeadline,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _VerificationNudgeSheet(
          pastDeadline: pastDeadline,
          remaining: remaining,
          isMatrimony: mode.isMatrimony,
          onVerifyNow: () {
            Navigator.of(ctx).pop();
            router.push('/verification');
          },
          onDismiss: pastDeadline
              ? null
              : () => Navigator.of(ctx).pop(),
        ),
      );
    } finally {
      _busy = false;
    }
  }
}

class _VerificationNudgeSheet extends StatelessWidget {
  const _VerificationNudgeSheet({
    required this.pastDeadline,
    required this.remaining,
    required this.isMatrimony,
    required this.onVerifyNow,
    this.onDismiss,
  });

  final bool pastDeadline;
  final Duration remaining;
  final bool isMatrimony;
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
                    : isMatrimony
                        ? 'Verified profiles get 3× more interest from families. Complete your photo verification to unlock all features.'
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
