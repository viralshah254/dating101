/// Chat thread summary for list.
/// [mode] is optional; when set, threads are scoped to dating or matrimony (no mixing).
class ChatThreadSummary {
  ChatThreadSummary({
    required this.id,
    required this.otherUserId,
    required this.otherName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.mode,
    this.otherParticipantLastReadAt,
    this.otherUserOnline = false,
    this.otherLastActiveAt,
  });

  /// Parses GET /chat/threads row. Kept on the model so constructor + parser stay in sync (avoids hot-reload / partial rebuild mismatches).
  factory ChatThreadSummary.fromApiMap(Map<String, dynamic> j) {
    final unreadRaw = j['unreadCount'] ?? j['unread_count'];
    final unreadCount = _coerceInt(unreadRaw);
    final onlineRaw = j['otherUserOnline'] ?? j['other_user_online'];
    final otherUserOnline = _coerceBool(onlineRaw);
    return ChatThreadSummary(
      id: _coerceString(j['id']) ?? '',
      otherUserId:
          _coerceString(j['otherUserId']) ?? _coerceString(j['other_user_id']) ?? '',
      otherName:
          _coerceString(j['otherName']) ?? _coerceString(j['other_name']) ?? '',
      lastMessage:
          _coerceString(j['lastMessage']) ?? _coerceString(j['last_message']),
      lastMessageAt: _parseOptDateTime(j['lastMessageAt'] ?? j['last_message_at']),
      unreadCount: unreadCount,
      mode: _coerceString(j['mode']),
      otherParticipantLastReadAt: _parseOptDateTime(
        j['otherParticipantLastReadAt'] ?? j['other_participant_last_read_at'],
      ),
      otherUserOnline: otherUserOnline,
      otherLastActiveAt: _parseOptDateTime(j['otherLastActiveAt'] ?? j['other_last_active_at']),
    );
  }

  final String id;
  final String otherUserId;
  final String otherName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  /// `dating` or `matrimony`; used to separate chats by product mode.
  final String? mode;
  /// Other person's read cursor (for your sent message ticks).
  final DateTime? otherParticipantLastReadAt;
  final bool otherUserOnline;
  final DateTime? otherLastActiveAt;

  static String? _coerceString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static bool _coerceBool(dynamic v) {
    if (v == true || v == 1) return true;
    if (v == false || v == 0 || v == null) return false;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  static int _coerceInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static DateTime? _parseOptDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final p = DateTime.tryParse(v);
      if (p == null) return null;
      return p.isUtc ? p.toLocal() : p;
    }
    return null;
  }
}

/// Pending message request (from GET /chat/message-requests).
/// [isInbound] true = received by current user (show on top); false = sent by current user (outbound).
class MessageRequest {
  const MessageRequest({
    required this.requestId,
    required this.otherUserId,
    this.otherName,
    this.text,
    this.createdAt,
    this.threadId,
    this.isInbound = true,
  });
  final String requestId;
  final String otherUserId;
  final String? otherName;
  final String? text;
  final DateTime? createdAt;
  final String? threadId;
  /// true = inbound (received); false = outbound (sent). Used to sort inbound on top.
  final bool isInbound;
}

/// Single message in a thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isVoiceNote = false,
    /// Monotonic send order for the current user's lines in this session; preserved on WS/HTTP
    /// merge so rapid sends and refetches cannot reorder vs pending bubbles.
    this.outboundSeq,
  });
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isVoiceNote;
  final int? outboundSeq;
}

/// How [sendMessage] reached the server. HTTP path does not push to the live stream — caller should refetch thread messages.
enum ChatSendTransport { websocket, http }

/// Older page from GET /chat/threads/:id/messages?cursor=…
class ChatOlderMessagesPage {
  const ChatOlderMessagesPage({required this.messages, this.nextOlderCursor});
  final List<ChatMessage> messages;
  final String? nextOlderCursor;
}

/// Chat threads and messages. Dating and matrimony have separate threads (no mixing).
abstract class ChatRepository {
  /// List threads for the given [mode] (`dating` or `matrimony`). Only threads for that mode are returned.
  Future<List<ChatThreadSummary>> getThreads({int limit = 50, String? mode});

  /// GET /chat/suggestions?mode=... — Icebreaker suggestion strings for first message. Returns empty list if 404.
  Future<List<String>> getSuggestions({String? mode});

  /// Create (or get existing) thread with another user for the given [mode]. Returns thread ID.
  Future<String> createThread(String otherUserId, {String? mode});

  /// [viewerUserId] — when set, WS `message` frames from this user are ignored (own-send echo / misdelivery); `sent` + `message_persisted` still apply.
  Stream<List<ChatMessage>> watchMessages(String threadId, {String? viewerUserId});

  /// Loads the next older page using the cursor last reported for this thread (see API `nextCursor`).
  Future<ChatOlderMessagesPage> loadOlderChatMessages(
    String threadId, {
    required String viewerUserId,
  });

  /// [adCompletionToken] — when provided (e.g. after free user watches ad), backend may create a message request instead of direct message.
  ///
  /// Returns [ChatSendTransport.http] when the message was sent over REST; the UI should refresh the thread stream so pending bubbles clear.
  ///
  /// [outgoingTempId] — same id as the optimistic bubble and WebSocket `tempId` so server acks can clear [pendingSentMessagesProvider].
  ///
  /// [forceHttp] — skip WebSocket (idempotent HTTP retry with [outgoingTempId] as `clientDedupeKey` when set).
  Future<ChatSendTransport> sendMessage(
    String threadId,
    String text, {
    String? adCompletionToken,
    String? outgoingTempId,
    bool forceHttp = false,
  });

  Future<void> markThreadRead(String threadId);

  /// GET /chat/threads/:id/peer-read — when the other person last read this thread.
  Future<DateTime?> getPeerLastReadAt(String threadId);

  /// Message requests (GET /chat/message-requests). Pending messages from non-matches. [mode] = dating | matrimony.
  Future<List<MessageRequest>> getMessageRequests({int limit = 20, String? mode});

  /// Count of inbound message requests for current user (for recipient badge). [mode] = dating | matrimony.
  Future<int> getMessageRequestsCount({String? mode});

  /// Accept a message request (POST /chat/message-requests/:requestId/accept).
  Future<void> acceptMessageRequest(String requestId);

  /// Decline a message request (POST /chat/message-requests/:requestId/decline).
  Future<void> declineMessageRequest(String requestId);
}
