/// Chat thread summary for list.
class ChatThreadSummary {
  const ChatThreadSummary({
    required this.id,
    required this.otherUserId,
    required this.otherName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });
  final String id;
  final String otherUserId;
  final String otherName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
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

/// Chat threads and messages (shared dating/matrimony).
abstract class ChatRepository {
  Future<List<ChatThreadSummary>> getThreads({int limit = 50});

  Stream<List<ChatMessage>> watchMessages(String threadId);

  Future<void> sendMessage(String threadId, String text);

  Future<void> markThreadRead(String threadId);
}
