/// Single in-app notification (feed item).
class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });
  final String id;
  final String type;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}

/// Paginated result for notification list.
class NotificationsPage {
  const NotificationsPage({
    required this.notifications,
    this.nextCursor,
  });
  final List<InAppNotification> notifications;
  final String? nextCursor;
}

/// In-app notification feed (GET /notifications, unread count, mark read).
abstract class NotificationsRepository {
  /// List notifications (GET /notifications). [unreadOnly] filters to unread.
  Future<NotificationsPage> getNotifications({
    int limit = 20,
    String? cursor,
    bool unreadOnly = false,
  });

  /// Unread count for badge (GET /notifications/unread-count).
  Future<int> getUnreadCount();

  /// Mark one notification as read (PATCH /notifications/:id/read).
  Future<void> markRead(String id);

  /// Mark all as read (POST /notifications/mark-all-read).
  Future<void> markAllRead();
}
