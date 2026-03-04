import '../../domain/repositories/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<NotificationsPage> getNotifications({
    int limit = 20,
    String? cursor,
    bool unreadOnly = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const NotificationsPage(notifications: [], nextCursor: null);
  }

  @override
  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 0;
  }

  @override
  Future<void> markRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> markAllRead() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
