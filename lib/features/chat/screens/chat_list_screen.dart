import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/api/api_client.dart';
import '../../../domain/models/interaction_models.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../discovery/providers/discovery_providers.dart';
import '../../requests/providers/requests_providers.dart';
import '../providers/chat_providers.dart';

/// Chat screen: Chats (threads by mode) + Chat requests (received interests). Dating and matrimony separate.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider) ?? AppMode.dating;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final modeLabel = mode.isMatrimony ? 'Matrimony' : 'Dating';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chats',
                style: AppTypography.headlineSmall.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                modeLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: onSurface.withValues(alpha: 0.8),
              ),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.saffron,
            unselectedLabelColor: onSurface.withValues(alpha: 0.6),
            indicatorColor: AppColors.saffron,
            labelStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: TabBarView(children: [_ChatsTab(), _ChatRequestsTab()]),
      ),
    );
  }
}

/// Chats tab: threads for current mode only (no mixing dating/matrimony).
class _ChatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(chatThreadsProvider);

    return async.when(
      data: (threads) {
        if (threads.isEmpty) {
          return EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: l.noConversationsYet,
            body: l.noConversationsYetBody,
            ctaLabel: l.retry,
            onCta: () => ref.invalidate(chatThreadsProvider),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(chatThreadsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            itemCount: threads.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              endIndent: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.06),
            ),
            itemBuilder: (context, i) {
              final t = threads[i];
              return _ChatThreadTile(
                thread: t,
                onTap: () async {
                  await context.push(
                    '/chat/${t.id}?otherUserId=${Uri.encodeComponent(t.otherUserId)}',
                  );
                  if (context.mounted) ref.invalidate(chatThreadsProvider);
                },
              );
            },
          ),
        );
      },
      loading: () => loadingSpinner(context),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () => ref.invalidate(chatThreadsProvider),
        retryLabel: l.retry,
      ),
    );
  }
}

/// Chat requests tab: received interests (accept to open chat).
class _ChatRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(receivedInteractionsProvider);

    return async.when(
      data: (items) {
        final groups = _groupByUser(items);
        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.mail_outline_rounded,
            title: l.noChatRequests,
            body: l.noChatRequestsBody,
            ctaLabel: l.retry,
            onCta: () {
              ref.invalidate(receivedInteractionsProvider);
              ref.invalidate(receivedRequestsCountProvider);
            },
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(receivedInteractionsProvider);
            ref.invalidate(receivedRequestsCountProvider);
            ref.invalidate(chatThreadsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i];
              return _ChatRequestCard(
                group: group,
                onAccept: () => _acceptAndMaybeOpenChat(context, ref, group),
                onDecline: () => _declineAll(context, ref, group),
                onTap: () => context.push('/profile/${group.user.id}'),
              );
            },
          ),
        );
      },
      loading: () => loadingSpinner(context),
      error: (_, __) => ErrorState(
        message: l.errorGeneric,
        onRetry: () {
          ref.invalidate(receivedInteractionsProvider);
          ref.invalidate(receivedRequestsCountProvider);
        },
        retryLabel: l.retry,
      ),
    );
  }

  Future<void> _acceptAndMaybeOpenChat(
    BuildContext context,
    WidgetRef ref,
    _GroupedRequest group,
  ) async {
    final repo = ref.read(interactionsRepositoryProvider);
    try {
      ExpressInterestResult? result;
      if (group.priorityItem != null) {
        result = await repo.respondToInterest(
          group.priorityItem!.interactionId,
          accept: true,
        );
      }
      if (group.interestItem != null) {
        result = await repo.respondToInterest(
          group.interestItem!.interactionId,
          accept: true,
        );
      }
      if (!context.mounted) return;
      ref.invalidate(receivedInteractionsProvider);
      ref.invalidate(receivedRequestsCountProvider);
      ref.invalidate(chatThreadsProvider);
      if (result != null && result.mutualMatch && result.chatThreadId != null) {
        context.push(
          '/chat/${result.chatThreadId}?otherUserId=${Uri.encodeComponent(group.user.id)}',
        );
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
      showErrorToast(context, e.message);
    }
  }
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

class _GroupedRequest {
  _GroupedRequest({required this.user, required this.items});
  final ProfileSummary user;
  final List<InteractionInboxItem> items;
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
}

// ─── Thread tile (chats tab) ───────────────────────────────────────────────

class _ChatThreadTile extends ConsumerWidget {
  const _ChatThreadTile({required this.thread, required this.onTap});
  final ChatThreadSummary thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final timeStr = _timeAgo(thread.lastMessageAt);
    final profileAsync = ref.watch(profileSummaryProvider(thread.otherUserId));
    final imageUrl = profileAsync.valueOrNull?.imageUrl;
    final initial = thread.otherName.isNotEmpty
        ? thread.otherName[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.saffron.withValues(alpha: 0.2),
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        initial,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.saffron,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.otherName,
                      style: AppTypography.titleMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessage ?? 'No messages yet',
                      style: AppTypography.bodySmall.copyWith(
                        color: onSurface.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (timeStr != null)
                    Text(
                      timeStr,
                      style: AppTypography.caption.copyWith(
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  if (thread.unreadCount > 0) ...[
                    if (timeStr != null) const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.saffron,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${thread.unreadCount}',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _timeAgo(DateTime? d) {
    if (d == null) return null;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${d.day}/${d.month}';
  }
}

// ─── Request card (requests tab) ────────────────────────────────────────────

class _ChatRequestCard extends StatelessWidget {
  const _ChatRequestCard({
    required this.group,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });
  final _GroupedRequest group;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = group.user;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.indiaGreen.withValues(alpha: 0.15),
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.indiaGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: AppTypography.titleSmall.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.hasPriority)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.saffron.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: AppColors.saffron,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l.priority,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.saffron,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (p.age != null)
                      Text(
                        l.yrs(p.age!),
                        style: AppTypography.bodySmall.copyWith(
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.indiaGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: Text(l.accept),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            side: BorderSide(
                              color: onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(l.decline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
