import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/ad_loading_dialog.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/design/design.dart';
import '../../../core/entitlements/entitlements.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/contact_request_status.dart';
import '../../../domain/models/interaction_models.dart';
import '../../../domain/models/photo_view_request.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/requests_providers.dart';
import '../../shortlist/providers/shortlist_providers.dart';

/// One card per user: user info + list of interactions (interest and/or priority_interest).
class _GroupedRequest {
  _GroupedRequest({required this.user, required this.items});
  final ProfileSummary user;
  final List<InteractionInboxItem> items;

  bool get hasInterest => items.any((e) => e.type == 'interest');
  bool get hasPriority => items.any((e) => e.type == 'priority_interest');
  InteractionInboxItem? get priorityItem {
    for (final e in items) {
      if (e.type == 'priority_interest') return e;
    }
    return null;
  }

  InteractionInboxItem? get interestItem {
    for (final e in items) {
      if (e.type == 'interest') return e;
    }
    return null;
  }

  String? get message => priorityItem?.message ?? interestItem?.message;
}

List<_GroupedRequest> _groupByUser(List<InteractionInboxItem> items) {
  final byId = <String, List<InteractionInboxItem>>{};
  for (final item in items) {
    byId.putIfAbsent(item.otherUser.id, () => []).add(item);
  }
  return byId.entries
      .map(
        (e) => _GroupedRequest(user: e.value.first.otherUser, items: e.value),
      )
      .toList();
}

/// Tab label with count, e.g. "Received (3)" or "Contact requests (0)".
String _tabLabel(String label, int count) {
  return '$label ($count)';
}

/// Matrimony: Interest requests — Received (inbox) and Sent. One card per user; both interest types shown.
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final receivedCount =
        ref.watch(receivedRequestsCountProvider).valueOrNull ?? 0;
    final sentList = ref.watch(sentInteractionsProvider).valueOrNull;
    final sentCount = sentList?.length ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.navRequests,
            style: AppTypography.headlineSmall.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.saffron,
            unselectedLabelColor: onSurface.withValues(alpha: 0.6),
            indicatorColor: AppColors.saffron,
            isScrollable: true,
            tabs: [
              Tab(text: _tabLabel(l.requestsReceived, receivedCount)),
              Tab(text: _tabLabel(l.requestsSent, sentCount)),
            ],
          ),
        ),
        body: TabBarView(children: [_ReceivedTab(), _SentTab()]),
      ),
    );
  }
}

/// Received tab: all received requests in one list (interest, contact, photo view). Premium only to see list.
class _ReceivedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ent = ref.watch(entitlementsProvider);
    if (!ent.canSeeRequestsInbox) {
      return _RequestsPremiumGate(onUpgrade: () => context.push('/paywall'));
    }
    final interactionsAsync = ref.watch(receivedInteractionsProvider);
    final contactAsync = ref.watch(receivedContactRequestsProvider);
    final photoViewAsync = ref.watch(receivedPhotoViewRequestsProvider);

    final isLoading =
        interactionsAsync.isLoading ||
        contactAsync.isLoading ||
        photoViewAsync.isLoading;
    final error = interactionsAsync.hasError
        ? interactionsAsync.error
        : contactAsync.hasError
        ? contactAsync.error
        : photoViewAsync.hasError
        ? photoViewAsync.error
        : null;

    void invalidateAll() {
      ref.invalidate(receivedInteractionsProvider);
      ref.invalidate(receivedContactRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ref.invalidate(receivedInteractionsCountProvider);
      ref.invalidate(receivedContactRequestsCountProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
    }

    if (isLoading) return loadingSpinner(context);
    if (error != null) {
      return ErrorState(
        message: l.errorGeneric,
        onRetry: invalidateAll,
        retryLabel: l.retry,
      );
    }

    final interestItems = interactionsAsync.valueOrNull ?? [];
    final contactRequests = contactAsync.valueOrNull ?? [];
    final photoViewRequests = photoViewAsync.valueOrNull ?? [];
    final groups = _groupByUser(interestItems);
    final totalCount =
        groups.length + contactRequests.length + photoViewRequests.length;

    if (totalCount == 0) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: l.requestsEmpty,
        body: l.requestsEmptyHint,
        ctaLabel: l.retry,
        onCta: invalidateAll,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => invalidateAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < groups.length) {
            final group = groups[index];
            return _GroupedRequestCard(
              group: group,
              isReceived: true,
              onAccept: () => _acceptAll(context, ref, group),
              onDecline: () => _declineAll(context, ref, group),
              onTap: () => context.push('/profile/${group.user.id}'),
            );
          }
          final contactIndex = index - groups.length;
          if (contactIndex < contactRequests.length) {
            final r = contactRequests[contactIndex];
            return _ContactRequestCard(
              request: r,
              onAccept: () => _acceptContact(context, ref, r.requestId),
              onDecline: () => _declineContact(context, ref, r.requestId),
              onTap: () => context.push('/profile/${r.fromUser.id}'),
            );
          }
          final photoIndex = index - groups.length - contactRequests.length;
          final r = photoViewRequests[photoIndex];
          return _PhotoViewRequestCard(
            request: r,
            onAccept: () => _acceptPhotoView(context, ref, r.requestId),
            onDecline: () => _declinePhotoView(context, ref, r.requestId),
            onTap: () => context.push('/profile/${r.fromUser.id}'),
          );
        },
      ),
    );
  }

  Future<void> _acceptAll(
    BuildContext context,
    WidgetRef ref,
    _GroupedRequest group,
  ) async {
    final ent = ref.read(entitlementsProvider);
    if (ent.requiresAdPerRequestToView) {
      final shown = await loadAndShowInterstitialWithLoading(
        context,
        ref,
        AdRewardReason.viewAndRespondToRequest,
      );
      if (!context.mounted) return;
      if (!shown) return;
    }
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      // Accept priority first if present, then interest (backend may create match on first accept).
      final priority = group.priorityItem;
      final interest = group.interestItem;
      ExpressInterestResult? result;
      if (priority != null) {
        result = await repo.respondToInterest(
          priority.interactionId,
          accept: true,
        );
      }
      if (interest != null) {
        result = await repo.respondToInterest(
          interest.interactionId,
          accept: true,
        );
      }
      if (!context.mounted) return;
      ref.invalidate(receivedInteractionsProvider);
      ref.invalidate(receivedContactRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ref.invalidate(receivedInteractionsCountProvider);
      ref.invalidate(receivedContactRequestsCountProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
      if (result != null && result.mutualMatch && result.chatThreadId != null) {
        ref.read(shortlistUnlockedEntriesProvider.notifier).update(
              (list) => list.where((e) => e.profileId != group.user.id).toList(),
            );
        context.push('/chat/${result.chatThreadId}');
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showErrorToast(context, e.message);
    }
  }

  Future<void> _declineAll(
    BuildContext context,
    WidgetRef ref,
    _GroupedRequest group,
  ) async {
    final result = await showDialog<_DeclineResult>(
      context: context,
      builder: (ctx) => _DeclineDialog(
        onDecline: (message, reasonId) => Navigator.pop(
          ctx,
          _DeclineResult(message: message, reasonId: reasonId),
        ),
        onCancel: () => Navigator.pop(ctx),
      ),
    );
    if (result == null || !context.mounted) return;
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      for (final item in group.items) {
        await repo.respondToInterest(
          item.interactionId,
          accept: false,
          declineMessage: result.message,
          declineReasonId: result.reasonId,
        );
      }
      if (!context.mounted) return;
      ref.invalidate(receivedInteractionsProvider);
      ref.invalidate(receivedContactRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ref.invalidate(receivedInteractionsCountProvider);
      ref.invalidate(receivedContactRequestsCountProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showErrorToast(context, e.message);
    }
  }

  Future<void> _acceptContact(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final ent = ref.read(entitlementsProvider);
    if (ent.requiresAdPerRequestToView) {
      final shown = await loadAndShowInterstitialWithLoading(
        context,
        ref,
        AdRewardReason.viewAndRespondToRequest,
      );
      if (!context.mounted) return;
      if (!shown) return;
    }
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(contactRequestRepositoryProvider)
          .acceptContactRequest(requestId);
      if (!context.mounted) return;
      ref.invalidate(receivedContactRequestsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ref.invalidate(receivedContactRequestsCountProvider);
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.contactShared),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.couldNotAccept('$e')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _declineContact(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(contactRequestRepositoryProvider)
          .declineContactRequest(requestId);
      if (!context.mounted) return;
      ref.invalidate(receivedContactRequestsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ref.invalidate(receivedContactRequestsCountProvider);
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.requestDeclined),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.couldNotDecline('$e')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _acceptPhotoView(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final ent = ref.read(entitlementsProvider);
    if (ent.requiresAdPerRequestToView) {
      final shown = await loadAndShowInterstitialWithLoading(
        context,
        ref,
        AdRewardReason.viewAndRespondToRequest,
      );
      if (!context.mounted) return;
      if (!shown) return;
    }
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(photoViewRequestRepositoryProvider).accept(requestId);
      if (!context.mounted) return;
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.photoViewRequestAccepted),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.couldNotAccept('$e')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _declinePhotoView(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(photoViewRequestRepositoryProvider).decline(requestId);
      if (!context.mounted) return;
      ref.invalidate(receivedPhotoViewRequestsProvider);
      ref.invalidate(receivedPhotoViewRequestsCountProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.requestDeclined),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.couldNotDecline('$e')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Sent tab: one card per user; withdraw interest and/or priority (withdrawing priority revokes both).
class _SentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(sentInteractionsProvider);

    return async.when(
      data: (items) {
        final groups = _groupByUser(items);
        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.send_outlined,
            title: l.requestsEmpty,
            body: l.requestsEmptyHint,
            ctaLabel: l.retry,
            onCta: () => ref.invalidate(sentInteractionsProvider),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sentInteractionsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupedRequestCard(
                group: group,
                isReceived: false,
                onWithdrawInterest: group.interestItem != null
                    ? () => _withdrawOne(
                        context,
                        ref,
                        group.interestItem!.interactionId,
                      )
                    : null,
                onWithdrawPriority: group.priorityItem != null
                    ? () => _withdrawPriorityAndInterest(context, ref, group)
                    : null,
                onTap: () => context.push('/profile/${group.user.id}'),
              );
            },
          ),
        );
      },
      loading: () => loadingSpinner(context),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(sentInteractionsProvider),
        retryLabel: l.retry,
      ),
    );
  }

  Future<void> _withdrawOne(
    BuildContext context,
    WidgetRef ref,
    String interactionId,
  ) async {
    try {
      await ref
          .read(interactionsRepositoryProvider)
          .withdrawInteraction(interactionId);
      if (!context.mounted) return;
      ref.invalidate(sentInteractionsProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Withdraw priority first, then interest (so both are revoked).
  Future<void> _withdrawPriorityAndInterest(
    BuildContext context,
    WidgetRef ref,
    _GroupedRequest group,
  ) async {
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      if (group.priorityItem != null) {
        await repo.withdrawInteraction(group.priorityItem!.interactionId);
      }
      if (group.interestItem != null) {
        await repo.withdrawInteraction(group.interestItem!.interactionId);
      }
      if (!context.mounted) return;
      ref.invalidate(sentInteractionsProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Premium gate for Requests (Received tab): free users cannot see the requests list.
class _RequestsPremiumGate extends StatelessWidget {
  const _RequestsPremiumGate({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = AppColors.saffron;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(
              'See who’s interested',
              style: AppTypography.titleLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to Premium to view and respond to your requests.',
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.workspace_premium_rounded, size: 20),
              label: const Text('Upgrade to Premium'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One card for a received photo view request: avatar, name, "Requested to view your photos", Accept / Decline.
class _PhotoViewRequestCard extends StatelessWidget {
  const _PhotoViewRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });
  final ReceivedPhotoViewRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = request.fromUser;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.saffron.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage:
                          p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? NetworkImage(p.imageUrl!)
                          : null,
                      child: p.imageUrl == null || p.imageUrl!.isEmpty
                          ? Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.saffron,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.requestedToViewYourPhotos,
                          style: AppTypography.bodySmall.copyWith(
                            color: onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onDecline,
                    child: Text(
                      l.decline,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(l.accept),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card for a received contact request: avatar, name, "Requested your contact", Accept / Decline.
class _ContactRequestCard extends StatelessWidget {
  const _ContactRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });
  final ReceivedContactRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = request.fromUser;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.saffron.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage:
                          p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? NetworkImage(p.imageUrl!)
                          : null,
                      child: p.imageUrl == null || p.imageUrl!.isEmpty
                          ? Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.saffron,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.requestedYourContact,
                          style: AppTypography.bodySmall.copyWith(
                            color: onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onDecline,
                    child: Text(
                      l.decline,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(l.accept),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card per user: avatar, name, age, badges (Interested / Priority interest), message, and actions.
class _GroupedRequestCard extends StatelessWidget {
  const _GroupedRequestCard({
    required this.group,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
    this.onWithdrawInterest,
    this.onWithdrawPriority,
    required this.onTap,
  });

  final _GroupedRequest group;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onWithdrawInterest;
  final VoidCallback? onWithdrawPriority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = group.user;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.indiaGreen.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage:
                          p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? NetworkImage(p.imageUrl!)
                          : null,
                      child: p.imageUrl == null || p.imageUrl!.isEmpty
                          ? Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.indiaGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (p.age != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l.yrs(p.age!),
                            style: AppTypography.bodySmall.copyWith(
                              color: onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _StatusChip(status: group.items.first.status),
                            if (group.hasInterest)
                              _Chip(
                                icon: Icons.favorite_border_rounded,
                                label: l.interested,
                                color: AppColors.indiaGreen,
                              ),
                            if (group.hasPriority)
                              _Chip(
                                icon: Icons.star_rounded,
                                label: l.priorityInterest,
                                color: AppColors.saffron,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.person_outline, size: 18),
                          label: Text(l.viewProfile),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.indiaGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (group.message != null && group.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    group.message!,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (isReceived && (onAccept != null || onDecline != null)) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (onAccept != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.indiaGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l.accept),
                        ),
                      ),
                    if (onAccept != null && onDecline != null)
                      const SizedBox(width: 10),
                    if (onDecline != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(l.decline),
                        ),
                      ),
                  ],
                ),
              ],
              if (!isReceived &&
                  (onWithdrawInterest != null ||
                      onWithdrawPriority != null)) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (onWithdrawInterest != null)
                      OutlinedButton.icon(
                        onPressed: onWithdrawInterest,
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: Text(l.withdrawInterest),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: AppColors.indiaGreen,
                          side: BorderSide(
                            color: AppColors.indiaGreen.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    if (onWithdrawPriority != null)
                      OutlinedButton.icon(
                        onPressed: onWithdrawPriority,
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: Text(
                          group.hasInterest && group.hasPriority
                              ? l.withdrawPriorityAndInterest
                              : l.withdrawPriority,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: AppColors.saffron,
                          side: BorderSide(
                            color: AppColors.saffron.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status label: Pending / Accepted / Declined / Withdrawn
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  static String _label(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = status.toLowerCase() == 'accepted'
        ? AppColors.indiaGreen
        : status.toLowerCase() == 'declined' ||
              status.toLowerCase() == 'withdrawn'
        ? Colors.grey
        : AppColors.saffron;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label(status),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeclineResult {
  _DeclineResult({this.message, this.reasonId});
  final String? message;
  final String? reasonId;
}

/// Optional decline message or canned reason to soften rejection.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog({required this.onDecline, required this.onCancel});
  final void Function(String? message, String? reasonId) onDecline;
  final VoidCallback onCancel;

  static const _cannedReasons = [
    ('not_right_match', 'Not the right match'),
    ('not_ready', 'Not ready to proceed'),
    ('family_decided', 'Family decided otherwise'),
    ('other', 'Other'),
  ];

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  String? _reasonId;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AlertDialog(
      title: Text(l.declineRequest),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can optionally add a message or choose a reason (they may not see it, depending on settings).',
              style: AppTypography.bodySmall.copyWith(
                color: onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _reasonId,
              onChanged: (v) => setState(() => _reasonId = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _DeclineDialog._cannedReasons
                    .map(
                      (e) => RadioListTile<String>(
                        title: Text(e.$2, style: AppTypography.bodyMedium),
                        value: e.$1,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Short message (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. Best wishes for your search',
              ),
              maxLines: 2,
              maxLength: 200,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            final msg = _messageController.text.trim();
            widget.onDecline(msg.isEmpty ? null : msg, _reasonId);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l.decline),
        ),
      ],
    );
  }
}
