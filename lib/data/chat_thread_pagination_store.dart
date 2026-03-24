/// Cursor state for GET /chat/threads/:id/messages?cursor= (older pages).
class ChatThreadPaginationStore {
  ChatThreadPaginationStore._();

  static final Map<String, bool> _primed = {};
  static final Map<String, String?> _nextOlderCursor = {};

  static String _key(String viewerUserId, String threadId) =>
      '$viewerUserId::$threadId';

  /// Called after each first-page fetch (or poll) with API [nextCursor] (null = no older messages).
  static void setNextOlderCursor(String viewerUserId, String threadId, String? cursor) {
    if (viewerUserId.isEmpty) return;
    final k = _key(viewerUserId, threadId);
    _primed[k] = true;
    _nextOlderCursor[k] = cursor;
  }

  /// False until the repository has applied the first HTTP page for this thread.
  static bool isPaginationKnown(String viewerUserId, String threadId) {
    if (viewerUserId.isEmpty) return false;
    return _primed[_key(viewerUserId, threadId)] == true;
  }

  /// Non-null non-empty when more older pages exist; null when known exhausted.
  /// If [isPaginationKnown] is false, returns null (do not treat as exhausted).
  static String? getNextOlderCursor(String viewerUserId, String threadId) {
    if (viewerUserId.isEmpty) return null;
    final k = _key(viewerUserId, threadId);
    if (_primed[k] != true) return null;
    return _nextOlderCursor[k];
  }

  static void clearThread(String viewerUserId, String threadId) {
    final k = _key(viewerUserId, threadId);
    _primed.remove(k);
    _nextOlderCursor.remove(k);
  }

  static void clearAll() {
    _primed.clear();
    _nextOlderCursor.clear();
  }
}
