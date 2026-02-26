import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../domain/models/profile_summary.dart';
import '../../ai/widgets/match_reason_chip.dart';
import '../../../l10n/app_localizations.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    required this.sendPrimaryLabel,
    this.onTap,
    required this.onSendIntro,
    required this.onBlock,
    required this.onReport,
  });

  final ProfileSummary profile;
  final String sendPrimaryLabel;
  final VoidCallback? onTap;
  final VoidCallback onSendIntro;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final l = AppLocalizations.of(context)!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: profile.imageUrl != null
                        ? NetworkImage(profile.imageUrl!)
                        : null,
                    child: profile.imageUrl == null
                        ? Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                            style: AppTypography.headlineMedium,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${profile.name}, ${profile.age ?? ''}',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (profile.verified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 18, color: accent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.city ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        if (profile.distanceKm != null)
                          Text(
                            l.kmAway(profile.distanceKm!.toStringAsFixed(1)),
                            style: AppTypography.caption.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'block') onBlock();
                      if (v == 'report') onReport();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'block', child: Text(l.block)),
                      PopupMenuItem(value: 'report', child: Text(l.report)),
                    ],
                  ),
                ],
              ),
              if (profile.matchReasons.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.matchReasons
                      .take(3)
                      .map((r) => MatchReasonChip(reason: r))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ] else if (profile.matchReason != null && profile.matchReason!.isNotEmpty) ...[
                MatchReasonChip(reason: profile.matchReason!),
                const SizedBox(height: 12),
              ],
              Text(
                profile.bio,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              if ((profile.promptAnswer ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.prompt,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.promptAnswer!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSendIntro,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(sendPrimaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
