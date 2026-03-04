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

/// Pending message request (from GET /chat/message-requests).
class MessageRequest {
  const MessageRequest({
    required this.requestId,
    required this.otherUserId,
    this.otherName,
    this.text,
    this.createdAt,
    this.threadId,
  });
  final String requestId;
  final String otherUserId;
  final String? otherName;
  final String? text;
  final DateTime? createdAt;
  final String? threadId;
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

  /// GET /chat/suggestions?mode=... — Icebreaker suggestion strings for first message. Returns empty list if 404.
  Future<List<String>> getSuggestions({String? mode});

  /// Create (or get existing) thread with another user for the given [mode]. Returns thread ID.
  Future<String> createThread(String otherUserId, {String? mode});

  Stream<List<ChatMessage>> watchMessages(String threadId);

  /// [adCompletionToken] — when provided (e.g. after free user watches ad), backend may create a message request instead of direct message.
  Future<void> sendMessage(
    String threadId,
    String text, {
    String? adCompletionToken,
  });

  Future<void> markThreadRead(String threadId);

  /// Message requests (GET /chat/message-requests). Pending messages from non-matches.
  Future<List<MessageRequest>> getMessageRequests({int limit = 20});

  /// Accept a message request (POST /chat/message-requests/:requestId/accept).
  Future<void> acceptMessageRequest(String requestId);

  /// Decline a message request (POST /chat/message-requests/:requestId/decline).
  Future<void> declineMessageRequest(String requestId);
}
