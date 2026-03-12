import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/notifications_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(notificationsFeedProvider);
    final unread = ref.watch(notificationsUnreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await ref.read(notificationsRepositoryProvider).markAllRead();
                ref.invalidate(notificationsFeedProvider);
                ref.invalidate(notificationsUnreadCountProvider);
                ref.invalidate(navNotificationsUnreadCountProvider);
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_rounded,
              title: l.notifications,
              body: 'You are all caught up.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsFeedProvider);
              ref.invalidate(notificationsUnreadCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _NotificationTile(item: items[i]),
            ),
          );
        },
        loading: () => loadingSpinner(context),
        error: (_, __) => ErrorState(
          message: l.errorGeneric,
          onRetry: () {
            ref.invalidate(notificationsFeedProvider);
            ref.invalidate(notificationsUnreadCountProvider);
          },
          retryLabel: l.retry,
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final InAppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final path = notificationDataToPath(item.data);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: item.isUnread
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : onSurface.withValues(alpha: 0.08),
          child: Icon(
            item.isUnread ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
            color: item.isUnread
                ? Theme.of(context).colorScheme.primary
                : onSurface.withValues(alpha: 0.75),
          ),
        ),
        title: Text(
          item.title ?? item.type,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: item.isUnread ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item.body ?? '',
          style: AppTypography.bodySmall.copyWith(
            color: onSurface.withValues(alpha: 0.72),
          ),
        ),
        trailing: item.isUnread
            ? Icon(
                Icons.brightness_1,
                size: 10,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () async {
          if (item.isUnread) {
            await ref.read(notificationsRepositoryProvider).markRead(item.id);
            ref.invalidate(notificationsFeedProvider);
            ref.invalidate(notificationsUnreadCountProvider);
            ref.invalidate(navNotificationsUnreadCountProvider);
          }
          if (!context.mounted || path == null || path.isEmpty) return;
          context.push(path);
        },
      ),
    );
  }
}
