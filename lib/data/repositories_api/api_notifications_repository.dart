import '../../domain/repositories/notifications_repository.dart';
import '../api/api_client.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository({required this.api});
  final ApiClient api;

  @override
  Future<NotificationsPage> getNotifications({
    int limit = 20,
    String? cursor,
    bool unreadOnly = false,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    if (unreadOnly) query['unreadOnly'] = 'true';
    final body = await api.get('/notifications', query: query);
    final list = body['notifications'] as List? ?? [];
    final notifications = list
        .whereType<Map<String, dynamic>>()
        .map(_parseNotification)
        .toList();
    final nextCursor = body['nextCursor'] as String?;
    return NotificationsPage(notifications: notifications, nextCursor: nextCursor);
  }

  @override
  Future<int> getUnreadCount() async {
    final body = await api.get('/notifications/unread-count');
    return body['count'] as int? ?? 0;
  }

  @override
  Future<void> markRead(String id) async {
    await api.patch('/notifications/$id/read', body: <String, dynamic>{});
  }

  @override
  Future<void> markAllRead() async {
    await api.post('/notifications/mark-all-read', body: <String, dynamic>{});
  }

  static InAppNotification _parseNotification(Map<String, dynamic> j) {
    final data = j['data'];
    return InAppNotification(
      id: j['id'] as String? ?? '',
      type: j['type'] as String? ?? 'unknown',
      title: j['title'] as String?,
      body: j['body'] as String?,
      data: data is Map<String, dynamic> ? data : const {},
      readAt: j['readAt'] != null ? DateTime.tryParse(j['readAt'] as String) : null,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
