import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
                  onPressed: () => ref.invalidate(_referralProvider),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
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
    final repo = ref.read(referralRepositoryProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.inviteCopy,
            style: AppTypography.headlineMedium,
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.inviteReward,
            style: AppTypography.bodyMedium,
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.yourInviteCode,
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    info.code,
                    style: AppTypography.headlineMedium.copyWith(
                      color: accent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: info.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.codeCopied,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(AppLocalizations.of(context)!.copyCode),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.shareVia,
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Share.share(
                      'Join me on saathi — sophisticated dating, globally. Use my code: ${info.code} or link: ${info.inviteLink}',
                    );
                    repo.recordInvite(channel: 'share');
                  },
                  icon: const Icon(Icons.share),
                  label: Text(AppLocalizations.of(context)!.share),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: info.inviteLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.linkCopied),
                      ),
                    );
                    repo.recordInvite(channel: 'copy_link');
                  },
                  icon: const Icon(Icons.link),
                  label: Text(AppLocalizations.of(context)!.copyLink),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
          if (info.pendingCount > 0) ...[
            const SizedBox(height: 24),
            Text(
              'Pending: ${info.pendingCount}',
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: 32),
          Text('Rewards', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Text(
            'You: 1 month Premium when they sign up. Them: 2 weeks free Premium.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
