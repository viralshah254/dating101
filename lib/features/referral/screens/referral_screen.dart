import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/error_state.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/referral_info.dart';

final _referralProvider = FutureProvider<ReferralInfo>((ref) async {
  return ref.watch(referralRepositoryProvider).getReferral();
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final referralAsync = ref.watch(_referralProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context)!.inviteFriends),
      ),
      body: referralAsync.when(
        data: (info) => _ReferralBody(info: info, accent: accent, ref: ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          message: AppLocalizations.of(context)!.errorGeneric,
          onRetry: () => ref.invalidate(_referralProvider),
          retryLabel: AppLocalizations.of(context)!.retry,
        ),
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({
    required this.info,
    required this.accent,
    required this.ref,
  });
  final ReferralInfo info;
  final Color accent;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final repo = ref.read(referralRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurface.withValues(alpha: 0.8);
    final surfaceContainerHighest = colorScheme.surfaceContainerHighest;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Intro — clear contrast
          Text(
            l.inviteCopy,
            style: AppTypography.headlineSmall.copyWith(color: onSurface),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          Text(
            l.inviteReward,
            style: AppTypography.bodyMedium.copyWith(color: onSurfaceVariant),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 28),

          // Code card — elevated, clear hierarchy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l.yourInviteCode,
                  style: AppTypography.labelLarge.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  info.code,
                  style: AppTypography.headlineMedium.copyWith(
                    color: accent,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: info.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.codeCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: Text(l.copyCode),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 28),

          // Primary CTA — Share (hero)
          Text(
            l.shareVia,
            style: AppTypography.labelLarge.copyWith(
              color: onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await Share.share(l.referralShareMessage(info.code, info.inviteLink));
              repo.recordInvite(channel: 'share');
            },
            icon: const Icon(Icons.share_rounded, size: 22),
            label: Text(l.share),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final message = l.referralShareMessage(info.code, info.inviteLink);
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.linkCopied)),
                    );
                    repo.recordInvite(channel: 'copy_link');
                  },
                  icon: const Icon(Icons.link_rounded, size: 20),
                  label: Text(l.copyLink),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          if (info.pendingCount > 0) ...[
            const SizedBox(height: 20),
            Text(
              'Pending: ${info.pendingCount}',
              style: AppTypography.bodySmall.copyWith(color: onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 28),

          // Rewards section — clear contrast
          Text(
            l.rewards,
            style: AppTypography.labelLarge.copyWith(
              color: onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.referralBenefitReferred,
            style: AppTypography.bodyMedium.copyWith(color: onSurface),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: accent, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l.referralContestMessage,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Terms & conditions apply — clear, tappable
          Center(
            child: TextButton(
              onPressed: () => _showReferralTermsDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 18, color: onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    l.referralTermsApply,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurfaceVariant,
                      decoration: TextDecoration.underline,
                      decorationColor: onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static void _showReferralTermsDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.referralTermsTitle,
          style: AppTypography.titleLarge,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              l.referralTermsAndConditionsBody,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}
