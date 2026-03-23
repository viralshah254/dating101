import 'dart:async';

import '../../domain/repositories/chat_repository.dart';
import '../api/api_client.dart';
import '../api/chat_websocket_client.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({required this.api, this.wsClient});
  final ApiClient api;
  final ChatWebSocketClient? wsClient;

  @override
  Future<List<String>> getSuggestions({String? mode}) async {
    try {
      final query = mode != null && mode.isNotEmpty ? {'mode': mode} : null;
      final body = await api.get('/chat/suggestions', query: query);
      final list = body['suggestions'] as List? ?? [];
      return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  @override
  Future<List<ChatThreadSummary>> getThreads({int limit = 50, String? mode}) async {
    assert(mode != null && mode.isNotEmpty, 'mode is required for getThreads (must be "dating" or "matrimony")');
    final safeMode = (mode != null && mode.isNotEmpty) ? mode : 'dating';
    final query = <String, String>{'limit': '$limit', 'mode': safeMode};
    final body = await api.get('/chat/threads', query: query);
    final list = body['threads'] as List? ?? [];
    return list.map((e) => _parseThread(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> createThread(String otherUserId, {String? mode}) async {
    assert(mode != null && mode.isNotEmpty, 'mode is required for createThread (must be "dating" or "matrimony")');
    final safeMode = (mode != null && mode.isNotEmpty) ? mode : 'dating';
    final res = await api.post('/chat/threads', body: {'otherUserId': otherUserId, 'mode': safeMode});
    return (res['id'] ?? res['threadId']) as String;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    final controller = StreamController<List<ChatMessage>>();
    List<ChatMessage> latest = [];
    StreamSubscription? wsSub;
    Timer? pollTimer;

    void emit(List<ChatMessage> msgs) {
      latest = msgs;
      if (!controller.isClosed) controller.add(msgs);
    }

    _fetchMessages(threadId).then(emit).catchError((e) {
      if (!controller.isClosed) controller.addError(e);
    });

    if (wsClient != null) {
      if (!wsClient!.isConnected) wsClient!.connect();
      wsSub = wsClient!.incoming.listen((event) {
        // Incoming message pushed from server to recipient
        if ((event.type == IncomingEventType.message || event.type == IncomingEventType.sent) &&
            event.threadId == threadId &&
            event.message != null) {
          final m = event.message!;
          final msg = ChatMessage(
            id: m.id,
            senderId: m.senderId,
            text: m.text,
            sentAt: m.sentAt,
            isVoiceNote: m.isVoiceNote,
          );
          // Dedup: replace matching temp_ bubble with real-id version, or append if new
          final tempId = event.tempId;
          final existingTempIdx = tempId != null ? latest.indexWhere((e) => e.id == tempId) : -1;
          if (existingTempIdx >= 0) {
            final updated = [...latest];
            updated[existingTempIdx] = msg;
            emit(updated);
          } else if (!latest.any((e) => e.id == msg.id)) {
            emit([...latest, msg]);
          }
        }
        // messageRequestCreated: ad-gated send became a request — remove the pending temp bubble
        if (event.type == IncomingEventType.messageRequestCreated &&
            event.threadId == threadId &&
            event.tempId != null) {
          final updated = latest.where((e) => e.id != event.tempId).toList();
          if (updated.length != latest.length) emit(updated);
        }
      });
    } else {
      pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final msgs = await _fetchMessages(threadId);
          if (!controller.isClosed) emit(msgs);
        } catch (_) {}
      });
    }

    controller.onCancel = () {
      wsSub?.cancel();
      pollTimer?.cancel();
    };
    return controller.stream;
  }

  Future<List<ChatMessage>> _fetchMessages(String threadId) async {
    final body = await api.get('/chat/threads/$threadId/messages', query: {'limit': '50'});
    final raw = body['messages'] ?? body['data'];
    final list = raw is List ? raw : <dynamic>[];
    final out = <ChatMessage>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      try {
        out.add(_parseMessage(e));
      } catch (_) {
        // skip malformed message
      }
    }
    return out;
  }

  @override
  Future<void> sendMessage(
    String threadId,
    String text, {
    String? adCompletionToken,
  }) async {
    // Try WS first — returns tempId string if successfully queued, null if not connected
    if (wsClient != null) {
      if (!wsClient!.isConnected) await wsClient!.connect();
      final tempId = await wsClient!.send(threadId, text, adCompletionToken: adCompletionToken);
      if (tempId != null) return; // WS path: server will echo 'sent' frame with real id
    }
    // HTTP fallback — backend will broadcastToUser for the recipient's WS
    final body = <String, dynamic>{'text': text};
    if (adCompletionToken != null && adCompletionToken.isNotEmpty) {
      body['adCompletionToken'] = adCompletionToken;
    }
    await api.post('/chat/threads/$threadId/messages', body: body);
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    await api.post('/chat/threads/$threadId/read', body: <String, dynamic>{});
  }

  @override
  Future<List<MessageRequest>> getMessageRequests({int limit = 20, String? mode}) async {
    try {
      final query = <String, String>{'limit': '$limit'};
      if (mode != null && mode.isNotEmpty) query['mode'] = mode;
      final body = await api.get('/chat/message-requests', query: query);
      final list = body['requests'] ?? body['messageRequests'] ?? body;
      final items = list is List ? list : <dynamic>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(_parseMessageRequest)
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  @override
  Future<int> getMessageRequestsCount({String? mode}) async {
    try {
      final query = mode != null && mode.isNotEmpty ? {'mode': mode} : null;
      final body = await api.get('/chat/message-requests/count', query: query);
      final n = body['count'] ?? body['total'];
      return n is int ? n : (int.tryParse('$n') ?? 0);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return 0;
      rethrow;
    }
  }

  @override
  Future<void> acceptMessageRequest(String requestId) async {
    await api.post('/chat/message-requests/$requestId/accept', body: <String, dynamic>{});
  }

  @override
  Future<void> declineMessageRequest(String requestId) async {
    await api.post('/chat/message-requests/$requestId/decline', body: <String, dynamic>{});
  }

  static MessageRequest _parseMessageRequest(Map<String, dynamic> j) {
    final other = j['otherUser'] ?? j['fromUser'] ?? j;
    final otherMap = other is Map<String, dynamic> ? other : <String, dynamic>{};
    final isInbound = j['isInbound'] as bool? ?? (j['direction'] != 'outbound');
    return MessageRequest(
      requestId: j['requestId'] ?? j['id'] ?? '',
      otherUserId: otherMap['id'] ?? j['otherUserId'] ?? '',
      otherName: otherMap['name'] ?? j['otherName'] as String?,
      text: j['text'] ?? j['message'] as String?,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      threadId: j['threadId'] as String?,
      isInbound: isInbound,
    );
  }

  static ChatThreadSummary _parseThread(Map<String, dynamic> j) {
    final unreadRaw = j['unreadCount'] ?? j['unread_count'];
    final unreadCount = unreadRaw is int ? unreadRaw : (int.tryParse('$unreadRaw') ?? 0);
    return ChatThreadSummary(
      id: j['id'] as String? ?? '',
      otherUserId: j['otherUserId'] as String? ?? j['other_user_id'] as String? ?? '',
      otherName: j['otherName'] as String? ?? j['other_name'] as String? ?? '',
      lastMessage: j['lastMessage'] as String? ?? j['last_message'] as String?,
      lastMessageAt: _parseOptDateTime(j['lastMessageAt'] ?? j['last_message_at']),
      unreadCount: unreadCount,
      mode: j['mode'] as String?,
    );
  }

  static DateTime? _parseOptDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static ChatMessage _parseMessage(Map<String, dynamic> j) {
    final sentAtRaw = j['sentAt'] ?? j['createdAt'] ?? j['timestamp'];
    final sentAt = sentAtRaw is String
        ? DateTime.tryParse(sentAtRaw) ?? DateTime.now()
        : DateTime.now();
    return ChatMessage(
      id: j['id'] as String? ?? '',
      senderId: j['senderId'] as String? ?? j['sender_id'] as String? ?? '',
      text: j['text'] as String? ?? j['content'] as String? ?? '',
      sentAt: sentAt,
      isVoiceNote: j['isVoiceNote'] as bool? ?? j['is_voice_note'] as bool? ?? false,
    );
  }
}
