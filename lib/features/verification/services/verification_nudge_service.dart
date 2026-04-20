/// VerificationNudgeService
///
/// Shows a non-intrusive bottom-sheet nudge encouraging unverified users to
/// complete photo verification. Enforces a 1-per-day cap and a total dismiss
/// limit of 3 times, after which the nudge is permanently silenced.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/user_profile.dart';

const _kLastShownKey = 'verif_nudge_last_ms';
const _kDismissCountKey = 'verif_nudge_count';
const _kMaxDismissals = 3;

class VerificationNudgeService {
  VerificationNudgeService._();

  /// Call this after the user's profile is loaded (e.g. on app resume or after
  /// editing the profile). Silently no-ops if the nudge should not be shown.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    // Guard: only for logged-in users
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.currentUserId == null) return;

    // Read verification state from profile
    UserProfile? profile;
    try {
      profile = await ref.read(profileRepositoryProvider).getMyProfile();
    } catch (_) {
      return;
    }
    if (profile == null) return;

    // If the user is already photo-verified, nothing to nudge
    final vs = profile.verificationStatus;
    if (vs.photoVerified || vs.score >= 0.5) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissCount = prefs.getInt(_kDismissCountKey) ?? 0;
    if (dismissCount >= _kMaxDismissals) return;

    final lastShownMs = prefs.getInt(_kLastShownKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const oneDayMs = 24 * 60 * 60 * 1000;
    if (now - lastShownMs < oneDayMs) return;

    if (!context.mounted) return;

    // Capture router before the async gap
    final router = GoRouter.of(context);
    await prefs.setInt(_kLastShownKey, now);

    // Re-check mounted after the async gap
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VerificationNudgeSheet(
        onVerifyNow: () {
          Navigator.of(ctx).pop();
          router.push('/verification');
        },
        onDismiss: () async {
          final p = await SharedPreferences.getInstance();
          await p.setInt(_kDismissCountKey, (p.getInt(_kDismissCountKey) ?? 0) + 1);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _VerificationNudgeSheet extends StatelessWidget {
  const _VerificationNudgeSheet({
    required this.onVerifyNow,
    required this.onDismiss,
  });
  final VoidCallback onVerifyNow;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final accent = colorScheme.primary;

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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(Icons.verified_user_outlined, size: 48, color: accent),
              const SizedBox(height: 16),
              Text(
                'Get 3× more responses',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verified profiles receive significantly more interest. '
                'Complete your photo verification — it only takes a minute.',
                style: AppTypography.bodyMedium.copyWith(
                  color: onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onVerifyNow,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Verify now'),
                ),
              ),
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
          ),
        ),
      ),
    );
  }
}
