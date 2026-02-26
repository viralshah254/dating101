import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/interaction_models.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/requests_providers.dart';
import '../../../core/providers/repository_providers.dart';

/// One card per user: user info + list of interactions (interest and/or priority_interest).
class _GroupedRequest {
  _GroupedRequest({required this.user, required this.items});
  final ProfileSummary user;
  final List<InteractionInboxItem> items;

  bool get hasInterest => items.any((e) => e.type == 'interest');
  bool get hasPriority => items.any((e) => e.type == 'priority_interest');
  InteractionInboxItem? get priorityItem {
    for (final e in items) if (e.type == 'priority_interest') return e;
    return null;
  }
  InteractionInboxItem? get interestItem {
    for (final e in items) if (e.type == 'interest') return e;
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
      .map((e) => _GroupedRequest(user: e.value.first.otherUser, items: e.value))
      .toList();
}

/// Matrimony: Interest requests — Received (inbox) and Sent. One card per user; both interest types shown.
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
            tabs: [
              Tab(text: l.requestsReceived),
              Tab(text: l.requestsSent),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReceivedTab(),
            _SentTab(),
          ],
        ),
      ),
    );
  }
}

/// Received tab: one card per user; Accept/Decline apply to the request(s).
class _ReceivedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(receivedInteractionsProvider);

    return async.when(
      data: (items) {
        final groups = _groupByUser(items);
        if (groups.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_outlined,
            title: l.requestsEmpty,
            hint: l.requestsEmptyHint,
            onRetry: () {
              ref.invalidate(receivedInteractionsProvider);
              ref.invalidate(receivedRequestsCountProvider);
            },
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(receivedInteractionsProvider);
            ref.invalidate(receivedRequestsCountProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupedRequestCard(
                group: group,
                isReceived: true,
                onAccept: () => _acceptAll(context, ref, group),
                onDecline: () => _declineAll(context, ref, group),
                onTap: () => context.push('/profile/${group.user.id}'),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: err.toString(),
        onRetry: () {
          ref.invalidate(receivedInteractionsProvider);
          ref.invalidate(receivedRequestsCountProvider);
        },
      ),
    );
  }

  Future<void> _acceptAll(BuildContext context, WidgetRef ref, _GroupedRequest group) async {
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      // Accept priority first if present, then interest (backend may create match on first accept).
      final priority = group.priorityItem;
      final interest = group.interestItem;
      ExpressInterestResult? result;
      if (priority != null) {
        result = await repo.respondToInterest(priority.interactionId, accept: true);
      }
      if (interest != null) {
        result = await repo.respondToInterest(interest.interactionId, accept: true);
      }
      if (!context.mounted) return;
      ref.invalidate(receivedInteractionsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      if (result != null && result.mutualMatch && result.chatThreadId != null) {
        context.push('/chat/${result.chatThreadId}');
      }
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

  Future<void> _declineAll(BuildContext context, WidgetRef ref, _GroupedRequest group) async {
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      for (final item in group.items) {
        await repo.respondToInterest(item.interactionId, accept: false);
      }
      if (!context.mounted) return;
      ref.invalidate(receivedInteractionsProvider);
      ref.invalidate(receivedRequestsCountProvider);
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
          return _EmptyState(
            icon: Icons.send_outlined,
            title: l.requestsEmpty,
            hint: l.requestsEmptyHint,
            onRetry: () => ref.invalidate(sentInteractionsProvider),
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
                    ? () => _withdrawOne(context, ref, group.interestItem!.interactionId)
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(sentInteractionsProvider),
      ),
    );
  }

  Future<void> _withdrawOne(BuildContext context, WidgetRef ref, String interactionId) async {
    try {
      await ref.read(interactionsRepositoryProvider).withdrawInteraction(interactionId);
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
  Future<void> _withdrawPriorityAndInterest(BuildContext context, WidgetRef ref, _GroupedRequest group) async {
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
                      backgroundColor: AppColors.indiaGreen.withValues(alpha: 0.15),
                      backgroundImage: p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? NetworkImage(p.imageUrl!)
                          : null,
                      child: p.imageUrl == null || p.imageUrl!.isEmpty
                          ? Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: AppTypography.titleLarge.copyWith(color: AppColors.indiaGreen, fontWeight: FontWeight.w600),
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
                          style: AppTypography.titleMedium.copyWith(color: onSurface, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (p.age != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${p.age} yrs',
                            style: AppTypography.bodySmall.copyWith(color: onSurface.withValues(alpha: 0.65)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (group.hasInterest)
                              _Chip(
                                icon: Icons.favorite_border_rounded,
                                label: 'Interested',
                                color: AppColors.indiaGreen,
                              ),
                            if (group.hasPriority)
                              _Chip(
                                icon: Icons.star_rounded,
                                label: 'Priority interest',
                                color: AppColors.saffron,
                              ),
                          ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    if (onAccept != null && onDecline != null) const SizedBox(width: 10),
                    if (onDecline != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: onSurface.withValues(alpha: 0.3)),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                  ],
                ),
              ],
              if (!isReceived && (onWithdrawInterest != null || onWithdrawPriority != null)) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (onWithdrawInterest != null)
                      OutlinedButton.icon(
                        onPressed: onWithdrawInterest,
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('Withdraw interest'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: AppColors.indiaGreen,
                          side: BorderSide(color: AppColors.indiaGreen.withValues(alpha: 0.5)),
                        ),
                      ),
                    if (onWithdrawPriority != null)
                      OutlinedButton.icon(
                        onPressed: onWithdrawPriority,
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: Text(group.hasInterest && group.hasPriority ? 'Withdraw priority (and interest)' : 'Withdraw priority'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: AppColors.saffron,
                          side: BorderSide(color: AppColors.saffron.withValues(alpha: 0.5)),
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
            style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.hint,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
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
                icon,
                size: 52,
                color: accent.withValues(alpha: isDark ? 0.9 : 0.7),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              style: AppTypography.bodyMedium.copyWith(
                color: onSurface.withValues(alpha: 0.65),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
