/// Chat thread summary for list.
/// [mode] is optional; when set, threads are scoped to dating or matrimony (no mixing).
class ChatThreadSummary {
  const ChatThreadSummary({
    required this.id,
    required this.otherUserId,
    required this.otherName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.mode,
  });
  final String id;
  final String otherUserId;
  final String otherName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  /// `dating` or `matrimony`; used to separate chats by product mode.
  final String? mode;
}

/// Single message in a thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isVoiceNote = false,
  });
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isVoiceNote;
}

/// Chat threads and messages. Dating and matrimony have separate threads (no mixing).
abstract class ChatRepository {
  /// List threads for the given [mode] (`dating` or `matrimony`). Only threads for that mode are returned.
  Future<List<ChatThreadSummary>> getThreads({int limit = 50, String? mode});

  /// Create (or get existing) thread with another user for the given [mode]. Returns thread ID.
  Future<String> createThread(String otherUserId, {String? mode});

  Stream<List<ChatMessage>> watchMessages(String threadId);

  Future<void> sendMessage(String threadId, String text);

  Future<void> markThreadRead(String threadId);
}
