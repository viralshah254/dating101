import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/verification_status.dart';

final _myProfileForVerificationProvider = FutureProvider((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

/// Verification hub: ID, face match, LinkedIn, education. Uses [VerificationStatus]
/// from GET /profile/me for tile state and safety score. See docs/BACKEND_VERIFICATION.md.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final profileAsync = ref.watch(_myProfileForVerificationProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.verificationTitle),
      ),
      body: profileAsync.when(
        data: (profile) {
          final l = AppLocalizations.of(context)!;
          final vs = profile?.verificationStatus ?? const VerificationStatus();
          final score = vs.score.clamp(0.0, 1.0);
          final idRejected = vs.idVerificationStatus == 'rejected';
          final eduRejected = vs.educationVerificationStatus == 'rejected';
          final idPending = vs.idVerificationStatus == 'pending';
          final eduPending = vs.educationVerificationStatus == 'pending';
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_myProfileForVerificationProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── ID rejection banner ───────────────────────────────────
                  if (idRejected) ...[
                    _RejectionBanner(
                      title: 'ID Verification Not Approved',
                      reason: vs.idVerificationRejectionReason ??
                          'Your ID verification was not approved.',
                      onResubmit: () async {
                        await context.push('/photo-verification');
                        ref.invalidate(_myProfileForVerificationProvider);
                      },
                    ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                    const SizedBox(height: 16),
                  ],
                  // ── Education rejection banner ────────────────────────────
                  if (eduRejected) ...[
                    _RejectionBanner(
                      title: 'Education Verification Not Approved',
                      reason: vs.educationRejectionReason ??
                          'Your education verification was not approved.',
                      onResubmit: () => _showEducationVerification(context, ref),
                    ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    l.verifyPriority,
                    style: AppTypography.headlineMedium,
                  ).animate().fadeIn().slideY(begin: -0.05, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    l.verificationIntro,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 80.ms),
                  const SizedBox(height: 32),
                  // ID tile — shows pending/rejected status labels
                  _VerificationTile(
                    icon: Icons.badge_outlined,
                    title: AppLocalizations.of(context)!.idVerification,
                    subtitle: idPending
                        ? 'Under review — we\'ll notify you shortly.'
                        : idRejected
                            ? 'Rejected — tap to re-submit.'
                            : 'Take a selfie and upload your government ID.',
                    status: vs.idVerified
                        ? VerificationTileStatus.verified
                        : idPending
                            ? VerificationTileStatus.pending
                            : VerificationTileStatus.pending,
                    statusLabel: idPending
                        ? 'Pending'
                        : idRejected
                            ? 'Rejected'
                            : null,
                    onTap: vs.idVerified
                        ? null
                        : () async {
                            await context.push('/photo-verification');
                            ref.invalidate(_myProfileForVerificationProvider);
                          },
                    accent: accent,
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 12),
                  _VerificationTile(
                    icon: Icons.face_retouching_natural,
                    title: AppLocalizations.of(context)!.faceMatch,
                    subtitle: AppLocalizations.of(context)!.faceMatchSubtitle,
                    status: vs.photoVerified
                        ? VerificationTileStatus.verified
                        : VerificationTileStatus.pending,
                    onTap: vs.photoVerified
                        ? null
                        : () async {
                            await context.push('/photo-verification');
                            ref.invalidate(_myProfileForVerificationProvider);
                          },
                    accent: accent,
                  ).animate().fadeIn(delay: 160.ms),
                  const SizedBox(height: 12),
                  _VerificationTile(
                    icon: Icons.work_outline,
                    title: AppLocalizations.of(context)!.linkedIn,
                    subtitle: AppLocalizations.of(context)!.linkedInSubtitle,
                    status: vs.linkedInVerified
                        ? VerificationTileStatus.verified
                        : VerificationTileStatus.pending,
                    onTap: () => _startLinkedInVerification(context, ref),
                    accent: accent,
                    isComingSoon: !vs.linkedInVerified,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  // Education tile — shows pending/rejected status labels
                  _VerificationTile(
                    icon: Icons.school_outlined,
                    title: AppLocalizations.of(context)!.education,
                    subtitle: eduPending
                        ? 'Under review — we\'ll notify you shortly.'
                        : eduRejected
                            ? 'Rejected — tap to re-submit your degree.'
                            : AppLocalizations.of(context)!.educationSubtitle,
                    status: vs.educationVerified
                        ? VerificationTileStatus.verified
                        : VerificationTileStatus.pending,
                    statusLabel: eduPending
                        ? 'Pending'
                        : eduRejected
                            ? 'Rejected'
                            : null,
                    onTap: () => _showEducationVerification(context, ref),
                    accent: accent,
                  ).animate().fadeIn(delay: 240.ms),
                  const SizedBox(height: 32),
                  Text(
                    l.safetyScore,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.safetyScoreDescription,
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(_myProfileForVerificationProvider),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _startLinkedInVerification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(verificationRepositoryProvider);
      final url = await repo.getLinkedInAuthUrl();
      if (url.isEmpty) {
        throw Exception('auth-url-unavailable');
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('LinkedIn verification opened in browser.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> _showEducationVerification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context)!;
    final institutionController = TextEditingController();
    final degreeController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.education, style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: institutionController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'School or college',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: degreeController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l.education,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(verificationRepositoryProvider).submitEducationVerification(
                        institutionName: institutionController.text.trim().isEmpty
                            ? null
                            : institutionController.text.trim(),
                        degree: degreeController.text.trim().isEmpty
                            ? null
                            : degreeController.text.trim(),
                      );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ref.invalidate(_myProfileForVerificationProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.idSubmittedNotify),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (_) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(l.failedToSendTryAgain),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l.submit),
            ),
          ],
        ),
      ),
    );
    institutionController.dispose();
    degreeController.dispose();
  }


}

/// UI state for a single verification tile (not the domain VerificationStatus).
enum VerificationTileStatus { pending, verified }

// ── Rejection banner ──────────────────────────────────────────────────────────

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({
    required this.title,
    required this.reason,
    required this.onResubmit,
  });
  final String title;
  final String reason;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onResubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Re-submit'),
          ),
        ],
      ),
    );
  }
}

// ── Verification tile ─────────────────────────────────────────────────────────

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    required this.accent,
    this.isComingSoon = false,
    this.statusLabel,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VerificationTileStatus status;
  final VoidCallback? onTap;
  final Color accent;
  final bool isComingSoon;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final isRejected = statusLabel == 'Rejected';
    final isPending = statusLabel == 'Pending';
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRejected
                ? const Color(0xFFFEE2E2)
                : accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isRejected ? const Color(0xFFDC2626) : accent,
          ),
        ),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        trailing: status == VerificationTileStatus.verified
            ? Icon(Icons.check_circle, color: accent)
            : statusLabel != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? const Color(0xFFFEE2E2)
                          : isPending
                              ? const Color(0xFFFEF3C7)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isRejected
                            ? const Color(0xFFDC2626)
                            : isPending
                                ? const Color(0xFFD97706)
                                : null,
                      ),
                    ),
                  )
                : isComingSoon
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Soon',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
