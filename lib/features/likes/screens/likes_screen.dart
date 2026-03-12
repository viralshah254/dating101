import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/design/design.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/interaction_models.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/visitor_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../../matches/providers/matches_providers.dart';
import '../../requests/providers/requests_providers.dart';

/// Dating: Likes tab — Liked you | Visitors | You liked. Replaces Communities in nav.
class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final receivedAsync = ref.watch(receivedInteractionsProvider);
    final visitorsEntriesAsync = ref.watch(visitorsEntriesProvider);
    final sentAsync = ref.watch(sentInteractionsProvider(mode));

    final receivedCount = receivedAsync.valueOrNull?.length ?? 0;
    final visitorsCount = visitorsEntriesAsync.valueOrNull?.length ?? 0;
    final sentCount = sentAsync.valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navLikes,
            style: AppTypography.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            isScrollable: true,
            tabs: [
              Tab(text: _tabLabel(l.likesTabLikedYou, receivedCount)),
              Tab(text: _tabLabel(l.likesTabVisitors, visitorsCount)),
              Tab(text: _tabLabel(l.likesTabYouLiked, sentCount)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LikedYouTab(asyncItems: receivedAsync),
            _VisitorsTab(asyncEntries: visitorsEntriesAsync),
            _YouLikedTab(asyncItems: sentAsync),
          ],
        ),
      ),
    );
  }

  static String _tabLabel(String label, int count) {
    return '$label ($count)';
  }
}

class _LikedYouTab extends ConsumerWidget {
  const _LikedYouTab({required this.asyncItems});
  final AsyncValue<List<InteractionInboxItem>> asyncItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    // When backend returns 403 PREMIUM_REQUIRED, show friendly gate + unlocked items instead of raw error.
    final err = asyncItems.error;
    if (asyncItems.hasError &&
        err is ApiException &&
        err.code == 'PREMIUM_REQUIRED') {
      final initialRemaining = err.details?['inboxUnlocksRemainingThisWeek'] as int? ?? 2;
      final resetsAtStr = err.details?['inboxUnlocksResetAt'] as String?;
      return _LikedYouPremiumGate(
        initialRemaining: initialRemaining,
        initialResetsAt: resetsAtStr != null ? DateTime.tryParse(resetsAtStr) : null,
      );
    }

    return asyncItems.when(
      data: (items) {
        final profiles = items.map((e) => e.otherUser).toList();
        if (profiles.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border,
            title: l.likesEmptyLikedYou,
            body: l.likesEmptyLikedYouBody,
          );
        }
        return _ProfileListView(
          items: items,
          onInvalidate: null,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(receivedInteractionsProvider),
        retryLabel: l.retry,
      ),
    );
  }
}

/// Gate when backend returns 403 for "Liked you": show message, unlocked items, Upgrade + Watch ad to unlock one.
class _LikedYouPremiumGate extends ConsumerWidget {
  const _LikedYouPremiumGate({
    this.initialRemaining = 2,
    this.initialResetsAt,
  });
  final int initialRemaining;
  final DateTime? initialResetsAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    final unlocked = ref.watch(unlockedReceivedProvider);
    final quota = ref.watch(inboxUnlocksQuotaProvider);
    final remaining = quota?.remaining ?? initialRemaining;
    final canUnlockMore = remaining > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.favorite_border, size: 22, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.likesTabLikedYou,
                      style: AppTypography.titleSmall.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.likedYouPremiumGateMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: onSurface,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push('/paywall'),
                icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                label: Text(l.ctaUpgradeToPremium),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (canUnlockMore) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _onUnlockOne(context, ref),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: Text(l.watchAdToUnlockOne(remaining)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (unlocked.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l.likedYouUnlockedProfiles,
            style: AppTypography.titleSmall.copyWith(
              color: onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...unlocked.map((item) => _LikesProfileTile(item: item, onInvalidate: null)),
        ],
      ],
    );
  }

  static Future<void> _onUnlockOne(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final shown = await loadAndShowInterstitialWithLoading(
      context,
      ref,
      AdRewardReason.viewAndRespondToRequest,
    );
    if (!context.mounted) return;
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedToSendTryAgain),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final token = const Uuid().v4();
    try {
      final result = await ref.read(interactionsRepositoryProvider).unlockOneReceivedInteraction(
            adCompletionToken: token,
          );
      if (!context.mounted) return;
      if (result != null) {
        ref.read(unlockedReceivedProvider.notifier).update((list) => [...list, result.item]);
        ref.read(inboxUnlocksQuotaProvider.notifier).state = (
          remaining: result.unlocksRemainingThisWeek,
          resetsAt: result.resetsAt,
        );
        ref.invalidate(receivedInteractionsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.likedYouNoRequestToUnlock),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'INBOX_UNLOCKS_LIMIT_REACHED') {
        final resetsAtStr = e.details?['inboxUnlocksResetAt'] as String?;
        ref.read(inboxUnlocksQuotaProvider.notifier).state = (
          remaining: 0,
          resetsAt: resetsAtStr != null ? DateTime.tryParse(resetsAtStr) : null,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _VisitorsTab extends ConsumerWidget {
  const _VisitorsTab({required this.asyncEntries});
  final AsyncValue<List<VisitorEntry>> asyncEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ent = ref.watch(entitlementsProvider);
    final unlockedIds = ref.watch(unlockedVisitorIdsProvider);

    return asyncEntries.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.visibility_outlined,
            title: l.likesEmptyVisitors,
            body: l.likesEmptyVisitorsBody,
          );
        }
        return _VisitorsBlurredListView(
          entries: entries,
          isPremium: ent.isPremium,
          unlockedProfileIds: unlockedIds,
          onTap: (entry) => _onVisitorTap(context, ref, entry, ent.isPremium, unlockedIds),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _VisitorsErrorState(
        error: e,
        onRetry: () => ref.invalidate(visitorsEntriesProvider),
        l: l,
      ),
    );
  }

  static Future<void> _onVisitorTap(
    BuildContext context,
    WidgetRef ref,
    VisitorEntry entry,
    bool isPremium,
    Set<String> unlockedIds,
  ) async {
    final profileId = entry.visitor.id;
    if (isPremium || unlockedIds.contains(profileId)) {
      context.push('/profile/$profileId');
      return;
    }
    final l = AppLocalizations.of(context)!;
    final quota = ref.read(visitorUnlocksQuotaProvider);
    final remaining = quota?.remaining ?? 2;
    final canUnlockByAd = remaining > 0;

    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.visitorUnlockTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canUnlockByAd
                    ? l.visitorUnlockWatchAd(remaining)
                    : l.visitorUnlockLimitReached,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              if (canUnlockByAd)
                FilledButton.icon(
                  onPressed: () => Navigator.of(ctx).pop('watch_ad'),
                  icon: const Icon(Icons.play_circle_outline, size: 22),
                  label: Text(l.watchAdToUnlock),
                ),
              if (canUnlockByAd) const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.of(ctx).pop('upgrade'),
                icon: const Icon(Icons.workspace_premium_outlined, size: 22),
                label: Text(l.visitorUnlockUpgrade),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'upgrade') {
      context.push('/paywall');
      return;
    }
    if (choice == 'watch_ad') {
      final shown = await loadAndShowInterstitialWithLoading(
        context,
        ref,
        AdRewardReason.unlockVisitor,
      );
      if (!context.mounted) return;
      if (!shown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToSendTryAgain),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final token = const Uuid().v4();
      try {
        final result = await ref.read(visitsRepositoryProvider).unlockOneVisitor(
              visitId: entry.visitId,
              adCompletionToken: token,
            );
        if (!context.mounted) return;
        if (result != null) {
          ref.read(unlockedVisitorIdsProvider.notifier).update((s) => {...s, result.visitor.id});
          ref.read(visitorUnlocksQuotaProvider.notifier).state = (
            remaining: result.unlocksRemainingThisWeek,
            resetsAt: result.resetsAt,
          );
          ref.invalidate(visitorsEntriesProvider);
          context.push('/profile/${result.visitor.id}');
        }
      } on ApiException catch (e) {
        if (!context.mounted) return;
        if (e.code == 'VISITOR_UNLOCKS_LIMIT_REACHED') {
          final resetsAt = e.details?['visitorUnlocksResetAt'] as String?;
          ref.read(visitorUnlocksQuotaProvider.notifier).state = (
            remaining: 0,
            resetsAt: resetsAt != null ? DateTime.tryParse(resetsAt) : null,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _VisitorsErrorState extends StatelessWidget {
  const _VisitorsErrorState({required this.error, required this.onRetry, required this.l});
  final Object error;
  final VoidCallback onRetry;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final isPremiumRequired = error.toString().contains('403') && error.toString().contains('PREMIUM');
    return ErrorState(
      message: isPremiumRequired
          ? l.visitorUnlockPremiumRequired
          : error.toString(),
      onRetry: onRetry,
      retryLabel: l.retry,
    );
  }
}

class _VisitorsBlurredListView extends StatelessWidget {
  const _VisitorsBlurredListView({
    required this.entries,
    required this.isPremium,
    required this.unlockedProfileIds,
    required this.onTap,
  });
  final List<VisitorEntry> entries;
  final bool isPremium;
  final Set<String> unlockedProfileIds;
  final void Function(VisitorEntry) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final showUnblurred = isPremium || unlockedProfileIds.contains(entry.visitor.id);
        return _VisitorsBlurredTile(
          entry: entry,
          showUnblurred: showUnblurred,
          onTap: () => onTap(entry),
        );
      },
    );
  }
}

class _VisitorsBlurredTile extends StatelessWidget {
  const _VisitorsBlurredTile({
    required this.entry,
    required this.showUnblurred,
    required this.onTap,
  });
  final VisitorEntry entry;
  final bool showUnblurred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = entry.visitor;
    final imageUrl = profile.imageUrls?.isNotEmpty == true
        ? profile.imageUrls!.first
        : profile.imageUrl;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: showUnblurred && imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarPlaceholder(context),
                          errorWidget: (_, __, ___) => _avatarPlaceholder(context),
                        )
                      : _blurredAvatar(context, imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (profile.age != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${profile.age}',
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blurredAvatar(BuildContext context, String? imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarPlaceholder(context),
          )
        else
          _avatarPlaceholder(context),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          entry.visitor.name.isNotEmpty ? entry.visitor.name[0].toUpperCase() : '?',
          style: AppTypography.titleLarge.copyWith(color: primary),
        ),
      ),
    );
  }
}

class _YouLikedTab extends ConsumerWidget {
  const _YouLikedTab({required this.asyncItems});
  final AsyncValue<List<InteractionInboxItem>> asyncItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return asyncItems.when(
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_outline,
            title: l.likesEmptyYouLiked,
            body: l.likesEmptyYouLikedBody,
          );
        }
        return _ProfileListView(items: items, onInvalidate: () {
          final mode = ref.read(appModeProvider) ?? AppMode.dating;
          ref.invalidate(sentInteractionsProvider(mode));
        });
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        final mode = ref.read(appModeProvider) ?? AppMode.dating;
        return ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(sentInteractionsProvider(mode)),
          retryLabel: l.retry,
        );
      },
    );
  }
}

class _ProfileListView extends StatelessWidget {
  const _ProfileListView({
    required this.items,
    this.onInvalidate,
  });
  final List<InteractionInboxItem> items;
  final VoidCallback? onInvalidate;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LikesProfileTile(item: item, onInvalidate: onInvalidate);
      },
    );
  }
}

class _LikesProfileTile extends ConsumerWidget {
  const _LikesProfileTile({
    required this.item,
    this.onInvalidate,
  });
  final InteractionInboxItem item;
  final VoidCallback? onInvalidate;

  static const _reminderThreshold = Duration(days: 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = item.otherUser;
    final imageUrl = profile.imageUrls?.isNotEmpty == true
        ? profile.imageUrls!.first
        : profile.imageUrl;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final l = AppLocalizations.of(context)!;
    final canSendReminder = onInvalidate != null &&
        item.status == 'pending' &&
        DateTime.now().difference(item.createdAt) >= _reminderThreshold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/profile/${profile.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _avatarPlaceholder(context, profile),
                        errorWidget: (_, __, ___) => _avatarPlaceholder(context, profile),
                      )
                    : _avatarPlaceholder(context, profile),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (profile.city != null && profile.city!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.city!,
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (canSendReminder) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => _sendReminder(context, ref),
                        icon: const Icon(Icons.notifications_active_outlined, size: 16),
                        label: Text(l.sendReminder),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReminder(BuildContext context, WidgetRef ref) async {
    if (onInvalidate == null) return;
    final l = AppLocalizations.of(context)!;
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      await repo.sendReminder(item.interactionId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.reminderSentToast(item.otherUser.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onInvalidate!();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.errorGeneric),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _avatarPlaceholder(BuildContext context, ProfileSummary profile) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 56,
      height: 56,
      color: primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: AppTypography.titleLarge.copyWith(color: primary),
        ),
      ),
    );
  }
}

