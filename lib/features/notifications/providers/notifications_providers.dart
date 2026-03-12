import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/repositories/notifications_repository.dart';

final notificationsFeedProvider =
    FutureProvider.autoDispose<List<InAppNotification>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final page = await repo.getNotifications(limit: 50);
  return page.notifications;
});

final notificationsUnreadCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getUnreadCount();
});
