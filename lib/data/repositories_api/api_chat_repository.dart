import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/datetime/app_time_format.dart';
import '../../domain/repositories/chat_repository.dart';
import '../api/api_client.dart';
import '../api/chat_websocket_client.dart';
import '../chat_thread_pagination_store.dart';
import '../local/chat_thread_disk_cache.dart';

/// Last list shown per thread — re-seeded when [watchMessages] restarts after invalidation so the UI
/// does not briefly show loading/empty (dating and matrimony use the same stream).
final Map<String, List<ChatMessage>> _threadMessageDisplayCache = {};

void clearChatThreadMessageDisplayCache() {
  _threadMessageDisplayCache.clear();
  ChatThreadPaginationStore.clearAll();
}

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
    final out = <ChatThreadSummary>[];
    for (final e in list) {
      if (e is! Map) continue;
      try {
        out.add(ChatThreadSummary.fromApiMap(Map<String, dynamic>.from(e)));
      } catch (err, st) {
        debugPrint('[Chat] Skipping malformed thread row: $err');
        debugPrint('$st');
      }
    }
    return out;
  }

  @override
  Future<String> createThread(String otherUserId, {String? mode}) async {
    assert(mode != null && mode.isNotEmpty, 'mode is required for createThread (must be "dating" or "matrimony")');
    final safeMode = (mode != null && mode.isNotEmpty) ? mode : 'dating';
    final res = await api.post('/chat/threads', body: {'otherUserId': otherUserId, 'mode': safeMode});
    return (res['id'] ?? res['threadId']) as String;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId, {String? viewerUserId}) {
    final controller = StreamController<List<ChatMessage>>();
    List<ChatMessage> latest = [];
    StreamSubscription? wsSub;
    Timer? pollTimer;

    void emit(List<ChatMessage> msgs) {
      latest = msgs;
      _threadMessageDisplayCache[threadId] = List<ChatMessage>.from(msgs);
      final uid = viewerUserId;
      if (uid != null && uid.isNotEmpty) {
        ChatThreadDiskCache.scheduleWrite(uid, threadId, msgs);
      }
      if (!controller.isClosed) controller.add(List<ChatMessage>.from(msgs));
    }

    final cached = _threadMessageDisplayCache[threadId];
    if (cached != null && cached.isNotEmpty) {
      latest = List<ChatMessage>.from(cached);
      controller.add(List<ChatMessage>.from(cached));
    }

    Future<void> seedFromDisk() async {
      final uid = viewerUserId;
      if (uid == null || uid.isEmpty) return;
      final disk = await ChatThreadDiskCache.read(uid, threadId);
      if (controller.isClosed) return;
      if (latest.isNotEmpty) return;
      if (disk.isEmpty) return;
      latest = List<ChatMessage>.from(disk);
      _threadMessageDisplayCache[threadId] = latest;
      if (!controller.isClosed) controller.add(List<ChatMessage>.from(disk));
    }

    unawaited(seedFromDisk());

    bool isNearDuplicate(ChatMessage msg) {
      return latest.any(
        (e) =>
            e.senderId == msg.senderId &&
            e.text == msg.text &&
            e.sentAt.difference(msg.sentAt).inSeconds.abs() < 8,
      );
    }

    List<ChatMessage> reconcileFetchWithPrior(
      List<ChatMessage> remote,
      List<ChatMessage> prior,
    ) {
      if (prior.isEmpty) return remote;
      final byId = {for (final p in prior) p.id: p};
      return remote.map((m) {
        final prev = byId[m.id];
        if (prev != null && prev.outboundSeq != null) {
          return ChatMessage(
            id: m.id,
            senderId: m.senderId,
            text: m.text,
            sentAt: prev.sentAt,
            outboundSeq: prev.outboundSeq,
            isVoiceNote: m.isVoiceNote,
          );
        }
        return m;
      }).toList();
    }

    _fetchMessagePage(threadId).then((page) {
      if (controller.isClosed) return;
      final uid = viewerUserId;
      if (uid != null && uid.isNotEmpty) {
        ChatThreadPaginationStore.setNextOlderCursor(uid, threadId, page.nextOlderCursor);
      }
      emit(reconcileFetchWithPrior(page.messages, latest));
    }).catchError((e) {
      if (!controller.isClosed) controller.addError(e);
    });

    if (wsClient != null) {
      if (!wsClient!.isConnected) wsClient!.connect();
      wsSub = wsClient!.incoming.listen((event) {
        // Real-time `message` is for the recipient only; if it ever hits the sender's socket,
        // it would duplicate `sent` / `message_persisted` and show as a false "incoming" line.
        if (event.type == IncomingEventType.message &&
            event.threadId == threadId &&
            event.message != null &&
            viewerUserId != null &&
            event.message!.senderId == viewerUserId) {
          return;
        }

        if ((event.type == IncomingEventType.message ||
                event.type == IncomingEventType.sent ||
                event.type == IncomingEventType.messagePersisted) &&
            event.threadId == threadId &&
            event.message != null) {
          final m = event.message!;
          final msg = ChatMessage(
            id: m.id,
            senderId: m.senderId,
            text: m.text,
            sentAt: m.sentAt,
            isVoiceNote: m.isVoiceNote,
            outboundSeq: null,
          );
          // Dedup: replace matching temp_ bubble with real-id version, or append if new
          final tempId = event.tempId;
          final existingTempIdx = tempId != null ? latest.indexWhere((e) => e.id == tempId) : -1;
          if (existingTempIdx >= 0) {
            final updated = [...latest];
            final prev = updated[existingTempIdx];
            // Keep the optimistic bubble's [sentAt] so [_mergeMessages] sort matches tap order
            // while sends are in flight (server timestamps can reorder rapid outbound lines).
            updated[existingTempIdx] = ChatMessage(
              id: msg.id,
              senderId: msg.senderId,
              text: msg.text,
              sentAt: prev.sentAt,
              isVoiceNote: msg.isVoiceNote,
              outboundSeq: prev.outboundSeq,
            );
            emit(updated);
          } else {
            final byId = latest.indexWhere((e) => e.id == msg.id);
            if (byId >= 0) {
              final updated = [...latest];
              final prev = updated[byId];
              // `message_persisted` (and similar) often follows `sent` after the row already has a
              // real id. Do not replace [sentAt] with the server value or rapid sends reorder in UI.
              updated[byId] = ChatMessage(
                id: msg.id,
                senderId: msg.senderId,
                text: msg.text,
                sentAt: prev.sentAt,
                isVoiceNote: msg.isVoiceNote,
                outboundSeq: prev.outboundSeq,
              );
              emit(updated);
            } else if (!latest.any((e) => e.id == msg.id) && !isNearDuplicate(msg)) {
              emit([...latest, msg]);
            }
          }
        }
        // messageRequestCreated: swap temp bubble for synthetic pending-req row (no provider invalidation).
        if (event.type == IncomingEventType.messageRequestCreated &&
            event.threadId == threadId &&
            event.tempId != null &&
            viewerUserId != null) {
          final rid = event.messageRequestId;
          final tempId = event.tempId!;
          var body = event.messageRequestText?.trim();
          final tempIdx = latest.indexWhere((e) => e.id == tempId);
          if ((body == null || body.isEmpty) && tempIdx >= 0) {
            body = latest[tempIdx].text;
          }
          var updated = latest.where((e) => e.id != tempId).toList();
          final willAddSynthetic =
              rid != null && body != null && body.isNotEmpty;
          if (willAddSynthetic) {
            updated = [
              ...updated,
              ChatMessage(
                id: 'pending-req:$rid',
                senderId: viewerUserId,
                text: body,
                sentAt: DateTime.now(),
              ),
            ];
            updated.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          }
          final hadTempBubble = tempIdx >= 0;
          if (hadTempBubble || willAddSynthetic) {
            emit(updated);
          }
        }
      });
    } else {
      pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final page = await _fetchMessagePage(threadId);
          if (!controller.isClosed) {
            final uid = viewerUserId;
            if (uid != null && uid.isNotEmpty) {
              ChatThreadPaginationStore.setNextOlderCursor(uid, threadId, page.nextOlderCursor);
            }
            emit(reconcileFetchWithPrior(page.messages, latest));
          }
        } catch (_) {}
      });
    }

    controller.onCancel = () {
      wsSub?.cancel();
      pollTimer?.cancel();
    };
    return controller.stream;
  }

  Future<({List<ChatMessage> messages, String? nextOlderCursor})> _fetchMessagePage(
    String threadId, {
    String? cursor,
    int limit = 50,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    final body = await api.get('/chat/threads/$threadId/messages', query: query);
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
    final next = body['nextCursor'] as String?;
    return (messages: out, nextOlderCursor: next);
  }

  @override
  Future<ChatOlderMessagesPage> loadOlderChatMessages(
    String threadId, {
    required String viewerUserId,
  }) async {
    if (!ChatThreadPaginationStore.isPaginationKnown(viewerUserId, threadId)) {
      return const ChatOlderMessagesPage(messages: [], nextOlderCursor: null);
    }
    final cur = ChatThreadPaginationStore.getNextOlderCursor(viewerUserId, threadId);
    if (cur == null || cur.isEmpty) {
      return const ChatOlderMessagesPage(messages: [], nextOlderCursor: null);
    }
    final page = await _fetchMessagePage(threadId, cursor: cur, limit: 50);
    ChatThreadPaginationStore.setNextOlderCursor(viewerUserId, threadId, page.nextOlderCursor);
    return ChatOlderMessagesPage(
      messages: page.messages,
      nextOlderCursor: page.nextOlderCursor,
    );
  }

  @override
  Future<ChatSendTransport> sendMessage(
    String threadId,
    String text, {
    String? adCompletionToken,
    String? outgoingTempId,
    bool forceHttp = false,
  }) async {
    if (!forceHttp && wsClient != null) {
      if (!wsClient!.isConnected) await wsClient!.connect();
      final ready = await wsClient!.waitUntilSessionReady(timeout: const Duration(seconds: 10));
      if (ready) {
        final tempId = await wsClient!.send(
          threadId,
          text,
          adCompletionToken: adCompletionToken,
          outgoingTempId: outgoingTempId,
        );
        if (tempId != null) return ChatSendTransport.websocket;
      }
    }
    final body = <String, dynamic>{'text': text};
    if (adCompletionToken != null && adCompletionToken.isNotEmpty) {
      body['adCompletionToken'] = adCompletionToken;
    }
    if (outgoingTempId != null && outgoingTempId.isNotEmpty) {
      body['clientDedupeKey'] = outgoingTempId;
    }
    await api.post('/chat/threads/$threadId/messages', body: body);
    return ChatSendTransport.http;
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    await api.post('/chat/threads/$threadId/read', body: <String, dynamic>{});
  }

  @override
  Future<DateTime?> getPeerLastReadAt(String threadId) async {
    final body = await api.get('/chat/threads/$threadId/peer-read');
    final s = body['otherParticipantLastReadAt'] as String?;
    if (s == null || s.isEmpty) return null;
    return parseApiDateTime(s);
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
      createdAt: j['createdAt'] != null ? parseApiDateTime(j['createdAt'] as String) : null,
      threadId: j['threadId'] as String?,
      isInbound: isInbound,
    );
  }

  static ChatMessage _parseMessage(Map<String, dynamic> j) {
    final sentAtRaw = j['sentAt'] ?? j['createdAt'] ?? j['timestamp'];
    final sentAt = sentAtRaw is String
        ? (parseApiDateTime(sentAtRaw) ?? DateTime.now())
        : DateTime.now();
    final sentByFamilyMemberId = j['sentByFamilyMemberId'] as String?;
    final senderType = (j['senderType'] as String?) ??
        (sentByFamilyMemberId != null ? 'family_member' : 'owner');
    return ChatMessage(
      id: j['id'] as String? ?? '',
      senderId: j['senderId'] as String? ?? j['sender_id'] as String? ?? '',
      text: j['text'] as String? ?? j['content'] as String? ?? '',
      sentAt: sentAt,
      isVoiceNote: j['isVoiceNote'] as bool? ?? j['is_voice_note'] as bool? ?? false,
      senderType: senderType,
      sentByFamilyMemberId: sentByFamilyMemberId,
    );
  }
}
