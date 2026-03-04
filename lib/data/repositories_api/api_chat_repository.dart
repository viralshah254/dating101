import 'dart:async';

import '../../domain/repositories/chat_repository.dart';
import '../api/api_client.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({required this.api});
  final ApiClient api;

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
    final query = <String, String>{'limit': '$limit'};
    if (mode != null && mode.isNotEmpty) query['mode'] = mode;
    final body = await api.get('/chat/threads', query: query);
    final list = body['threads'] as List? ?? [];
    return list.map((e) => _parseThread(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> createThread(String otherUserId, {String? mode}) async {
    final body = <String, dynamic>{'otherUserId': otherUserId};
    if (mode != null && mode.isNotEmpty) body['mode'] = mode;
    final res = await api.post('/chat/threads', body: body);
    return (res['id'] ?? res['threadId']) as String;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    final controller = StreamController<List<ChatMessage>>();

    _fetchMessages(threadId).then((msgs) {
      if (!controller.isClosed) controller.add(msgs);
    }).catchError((e) {
      if (!controller.isClosed) controller.addError(e);
    });

    // Poll every 5 seconds for new messages (replace with WebSocket later)
    final timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final msgs = await _fetchMessages(threadId);
        if (!controller.isClosed) controller.add(msgs);
      } catch (_) {}
    });

    controller.onCancel = () => timer.cancel();
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
  Future<List<MessageRequest>> getMessageRequests({int limit = 20}) async {
    try {
      final body = await api.get('/chat/message-requests', query: {'limit': '$limit'});
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
    return MessageRequest(
      requestId: j['requestId'] ?? j['id'] ?? '',
      otherUserId: otherMap['id'] ?? j['otherUserId'] ?? '',
      otherName: otherMap['name'] ?? j['otherName'] as String?,
      text: j['text'] ?? j['message'] as String?,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'] as String) : null,
      threadId: j['threadId'] as String?,
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
