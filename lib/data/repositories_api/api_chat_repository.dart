import 'dart:async';

import '../../domain/repositories/chat_repository.dart';
import '../api/api_client.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({required this.api});
  final ApiClient api;

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
  Future<void> sendMessage(String threadId, String text) async {
    await api.post('/chat/threads/$threadId/messages', body: {'text': text});
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    await api.post('/chat/threads/$threadId/read', body: <String, dynamic>{});
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
