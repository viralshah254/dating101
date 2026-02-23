import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_copy.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/profile_summary.dart';
import '../../ai/widgets/match_reason_chip.dart';
import '../../discovery/providers/discovery_providers.dart';

class FullProfileScreen extends ConsumerWidget {
  const FullProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(profileSummaryProvider(profileId));
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final l = AppLocalizations.of(context)!;

    return asyncProfile.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.profileTitle)),
            body: Center(child: Text(l.emptyStateGeneric)),
          );
        }
        return _ProfileContent(profile: profile, mode: mode);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l.profileTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.errorGeneric, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(profileSummaryProvider(profileId)),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.mode,
  });

  final ProfileSummary profile;
  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: primary.withValues(alpha: 0.15),
                child: Center(
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: primary.withValues(alpha: 0.3),
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: AppTypography.displayMedium.copyWith(color: primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        '${profile.name}, ${profile.age ?? ''}',
                        style: AppTypography.headlineSmall.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, size: 24, color: primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.city ?? ''}${profile.distanceKm != null ? ' · ${l.kmAway(profile.distanceKm!.toStringAsFixed(1))}' : ''}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  if (profile.matchReason != null && profile.matchReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MatchReasonChip(reason: profile.matchReason!),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l.about,
                    style: AppTypography.titleMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio,
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      l.interests,
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map<Widget>((i) => Chip(
                                label: Text(i),
                                backgroundColor: primary.withValues(alpha: 0.12),
                              ))
                          .toList(),
                    ),
                  ],
                  if ((profile.promptAnswer ?? '').isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      l.prompt,
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        profile.promptAnswer!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.push('/paywall'),
                    icon: const Icon(Icons.send, size: 20),
                    label: Text(AppCopy.ctaSendPrimary(context, mode)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
