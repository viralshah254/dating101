import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entitlements/entitlements.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/who_shortlisted_me_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
import '../../matches/widgets/match_profile_card.dart';
import '../../requests/providers/requests_providers.dart';
import '../providers/shortlist_providers.dart';

/// Matrimony: Shortlist with Received/Sent-style tabs — "Shortlisted" and "Shortlisted you".
class ShortlistScreen extends ConsumerWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navShortlist,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.indiaGreen,
            unselectedLabelColor: onSurface.withValues(alpha: 0.6),
            indicatorColor: AppColors.indiaGreen,
            tabs: const [
              Tab(text: 'Shortlisted'),
              Tab(text: 'Shortlisted you'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ShortlistedTab(),
            _ShortlistedYouTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab 1: Profiles I have shortlisted.
class _ShortlistedTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ShortlistedTab> createState() => _ShortlistedTabState();
}

class _ShortlistedTabState extends ConsumerState<_ShortlistedTab> {
  Future<void> _onLike(ProfileSummary p) async {
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressInterest(p.id, source: 'shortlist');
      if (!mounted) return;
      ref.invalidate(matchesRecommendedProvider);
      ref.invalidate(sentInteractionsProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('It\'s a match with ${p.name}!'), behavior: SnackBarBehavior.floating),
        );
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Interest sent to ${p.name}'), behavior: SnackBarBehavior.floating),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onSuperLike(ProfileSummary p) async {
    try {
      final result = await ref.read(interactionsRepositoryProvider).expressPriorityInterest(p.id, source: 'shortlist');
      if (!mounted) return;
      ref.invalidate(sentInteractionsProvider);
      if (result.mutualMatch && result.chatThreadId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('It\'s a match with ${p.name}!'), behavior: SnackBarBehavior.floating),
        );
        context.push('/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(p.id)}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority interest sent to ${p.name}'), behavior: SnackBarBehavior.floating),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _onMessage(ProfileSummary p) async {
    try {
      final mode = ref.read(appModeProvider) ?? AppMode.matrimony;
      final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
      final threadId = await ref.read(chatRepositoryProvider).createThread(p.id, mode: modeStr);
      if (!mounted) return;
      context.push('/chat/$threadId?otherUserId=${Uri.encodeComponent(p.id)}');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code == 'CONNECTION_REQUIRED' ? 'Send or accept an interest first' : e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/chats');
    } catch (_) {
      if (!mounted) return;
      context.push('/chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(shortlistProvider);

    return async.when(
      data: (profiles) {
        if (profiles.isEmpty) {
          final accent = Theme.of(context).colorScheme.primary;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star_border_rounded,
                      size: 52,
                      color: accent.withValues(alpha: isDark ? 0.9 : 0.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l.shortlistEmpty,
                    style: AppTypography.titleLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.shortlistEmptyHint,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shortlistProvider);
            ref.invalidate(shortlistedIdsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final p = profiles[index];
              final cardHeight = (MediaQuery.sizeOf(context).height * 0.78).clamp(380.0, 520.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: cardHeight,
                  child: MatchProfileCard(
                    profile: p,
                    isShortlisted: true,
                    onTap: () => context.push('/profile/${p.id}'),
                    onLike: () => _onLike(p),
                    onSuperLike: () => _onSuperLike(p),
                    onShortlist: () async {
                      await ref.read(shortlistRepositoryProvider).removeFromShortlist(p.id);
                      ref.invalidate(shortlistProvider);
                      ref.invalidate(shortlistedIdsProvider);
                    },
                    onMessage: () => _onMessage(p),
                    onUpgrade: () => context.push('/paywall'),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(err.toString(), style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(shortlistProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab 2: People who shortlisted me (premium section).
class _ShortlistedYouTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ent = ref.watch(entitlementsProvider);
    final whoAsync = ref.watch(whoShortlistedMeProvider);

    return RefreshIndicator(
      onRefresh: () async {
              ref.invalidate(whoShortlistedMeProvider);
              ref.invalidate(whoShortlistedMeCountProvider);
            },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: _WhoShortlistedMeContent(
          ent: ent,
          whoAsync: whoAsync,
          onUpgrade: () => context.push('/paywall'),
        ),
      ),
    );
  }
}

class _WhoShortlistedMeContent extends StatelessWidget {
  const _WhoShortlistedMeContent({
    required this.ent,
    required this.whoAsync,
    required this.onUpgrade,
  });
  final Entitlements ent;
  final AsyncValue<List<WhoShortlistedMeEntry>> whoAsync;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.indiaGreen;
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'People who shortlisted you',
                style: AppTypography.titleSmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!ent.canSeeWhoShortlistedYou) ...[
            _BlurredPreviewCard(firstName: 'S', age: 25, locked: true),
            const SizedBox(height: 10),
            _BlurredPreviewCard(firstName: 'A', age: 28, locked: true),
            const SizedBox(height: 14),
            _PremiumUpsellBanner(onUpgrade: onUpgrade),
          ] else
            whoAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 40, color: onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No one has shortlisted you yet.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: list
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _BlurredPreviewCard(
                              firstName: e.firstName,
                              age: e.age,
                              locked: false,
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _PremiumUpsellBanner extends StatelessWidget {
  const _PremiumUpsellBanner({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.indiaGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.14),
                accent.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.workspace_premium_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unlock who shortlisted you',
                      style: AppTypography.titleSmall.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See names, photos & reach out first',
                      style: AppTypography.caption.copyWith(
                        color: accent.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurredPreviewCard extends StatelessWidget {
  const _BlurredPreviewCard({
    required this.firstName,
    this.age,
    required this.locked,
  });
  final String firstName;
  final int? age;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    // When locked, show first letter + "..." and age as teaser (e.g. "S...", "25 yrs")
    final displayName = locked ? '$initial...' : firstName;
    final displayAge = age != null ? '$age yrs' : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: locked
            ? onSurface.withValues(alpha: 0.04)
            : surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked ? onSurface.withValues(alpha: 0.08) : onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Avatar circle with initial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: locked
                  ? onSurface.withValues(alpha: 0.08)
                  : onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.titleMedium.copyWith(
                  color: onSurface.withValues(alpha: locked ? 0.45 : 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: AppTypography.titleSmall.copyWith(
                    color: onSurface.withValues(alpha: locked ? 0.5 : 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (displayAge != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    displayAge,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (locked)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_rounded, size: 16, color: onSurface.withValues(alpha: 0.4)),
            ),
        ],
      ),
    );
  }
}
