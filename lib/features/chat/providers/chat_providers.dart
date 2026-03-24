import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/api/chat_websocket_client.dart';
import '../../../domain/repositories/chat_repository.dart';

/// Pending sent messages per thread (survives navigation). Backend may return messageRequestId and not include message in GET; we keep these until server list includes them so the thread does not look blank on re-entry.
final pendingSentMessagesProvider =
    StateProvider.family<List<ChatMessage>, String>((ref, threadId) => []);

/// Chat threads for the current app mode (dating or matrimony). No mixing.
final chatThreadsProvider = FutureProvider.autoDispose<List<ChatThreadSummary>>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final repo = ref.watch(chatRepositoryProvider);
  final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
  return repo.getThreads(limit: 50, mode: modeStr);
});

/// Total unread messages across all threads — for nav badge.
/// Sync [Provider] (not [FutureProvider]) reading [chatThreadsProvider]'s [AsyncValue] — avoids
/// awaiting [.future] on error, and avoids hot-reload crashes when this used to be a FutureProvider.
final chatNavUnreadCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(chatThreadsProvider);
  return async.when(
    data: (threads) => threads.fold<int>(0, (sum, t) => sum + t.unreadCount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Other participant's read cursor for a thread (for ✓✓ on your messages). Updated from WS `thread_read` and on open.
final threadPeerReadAtProvider = StateProvider.family<DateTime?, String>((ref, _) => null);

/// Live messages for one thread: initial GET + WebSocket deltas. Used by [ChatThreadScreen].
final threadMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) {
  ref.keepAlive();
  final viewerId = ref.watch(authRepositoryProvider).currentUserId;
  return ref.watch(chatRepositoryProvider).watchMessages(threadId, viewerUserId: viewerId);
});

/// Connects chat WebSocket app-wide and refreshes thread lists / peer-read on events.
final chatRealtimeHubProvider = Provider<void>((ref) {
  final client = ref.watch(chatWebSocketClientProvider);
  if (client == null) return;

  Future.microtask(() => client.connect());

  final sub = client.incoming.listen((ev) {
    void stripOutboundPendingByTempId() {
      final tid = ev.threadId?.trim();
      final tmp = ev.tempId?.trim();
      if (tid == null || tid.isEmpty || tmp == null || tmp.isEmpty) return;
      ref.read(pendingSentMessagesProvider(tid).notifier).update(
            (list) => list.where((p) => p.id != tmp).toList(),
          );
    }

    switch (ev.type) {
      case IncomingEventType.message:
      case IncomingEventType.threadRead:
        ref.invalidate(chatThreadsProvider);
        break;
      case IncomingEventType.sent:
      case IncomingEventType.messagePersisted:
        stripOutboundPendingByTempId();
        ref.invalidate(chatThreadsProvider);
        break;
      case IncomingEventType.messageRequestCreated:
        stripOutboundPendingByTempId();
        ref.invalidate(chatThreadsProvider);
        ref.invalidate(messageRequestsProvider);
        ref.invalidate(messageRequestsCountProvider);
        break;
      case IncomingEventType.error:
        final tid = ev.threadId?.trim();
        final tmp = ev.tempId?.trim();
        if (tid != null &&
            tid.isNotEmpty &&
            tmp != null &&
            tmp.isNotEmpty &&
            ev.code != null &&
            ev.code != 'INVALID_TOKEN' &&
            ev.code != 'UNAUTHORIZED') {
          ref.read(pendingSentMessagesProvider(tid).notifier).update(
                (list) => list
                    .map(
                      (p) => p.id == tmp
                          ? ChatMessage(
                              id: 'failed-$tmp',
                              senderId: p.senderId,
                              text: p.text,
                              sentAt: p.sentAt,
                              outboundSeq: p.outboundSeq,
                            )
                          : p,
                    )
                    .toList(),
              );
          ref.invalidate(threadMessagesProvider(tid));
          ref.invalidate(chatThreadsProvider);
        }
        break;
      default:
        break;
    }
    if (ev.type == IncomingEventType.threadRead &&
        ev.threadId != null &&
        ev.readAt != null) {
      ref.read(threadPeerReadAtProvider(ev.threadId!).notifier).state = ev.readAt;
    }
  });

  ref.onDispose(sub.cancel);
});

/// GET /chat/suggestions?mode=... — icebreaker chips. Fallback to static list if empty.
final chatSuggestionsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
  final repo = ref.watch(chatRepositoryProvider);
  final list = await repo.getSuggestions(mode: modeStr);
  return list.isNotEmpty ? list : ['Hi!', 'How are you?', 'What brings you here?', 'Tell me about yourself'];
});

/// Message requests (chat) for current mode. Sorted with inbound first, then outbound.
final messageRequestsProvider = FutureProvider.autoDispose<List<MessageRequest>>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
  final repo = ref.watch(chatRepositoryProvider);
  final list = await repo.getMessageRequests(limit: 50, mode: modeStr);
  list.sort((a, b) => (a.isInbound == b.isInbound) ? 0 : (a.isInbound ? -1 : 1));
  return list;
});

/// Count of inbound message requests for current user (recipient badge).
final messageRequestsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessageRequestsCount(mode: modeStr);
});

// ── Focus Mode ────────────────────────────────────────────────────────────

/// A resolved Focus Mode entry with display-ready data (name, days, nudge flag).
class FocusModeDisplayEntry {
  const FocusModeDisplayEntry({
    required this.threadId,
    required this.otherPersonName,
    required this.daysConnected,
    required this.messageCount,
    required this.showMeetNudge,
  });
  final String threadId;
  final String otherPersonName;
  final int daysConnected;
  final int messageCount;
  final bool showMeetNudge;
}

/// Fetches active Focus Mode sessions from GET /focus-mode and enriches each
/// with `otherPersonName` from the chat threads list. Returns an empty list
/// when the backend is unavailable or the user has no active focus modes.
final focusModeProvider =
    FutureProvider.autoDispose<List<FocusModeDisplayEntry>>((ref) async {
  final api = ref.watch(apiClientProvider);

  // Do not await chatThreadsProvider.future — on error it would fail this provider too.
  final modesBodyFuture = api.get('/focus-mode');
  final threads =
      ref.watch(chatThreadsProvider).valueOrNull ?? <ChatThreadSummary>[];

  final modesBody = await modesBodyFuture;

  final threadMap = {for (final t in threads) t.id: t};
  final raw = (modesBody['focusModes'] as List<dynamic>? ?? []);

  final entries = <FocusModeDisplayEntry>[];
  for (final item in raw) {
    final m = item as Map<String, dynamic>;
    final threadId = m['threadId'] as String? ?? '';
    final thread = threadMap[threadId];
    final activatedAt = m['activatedAt'] != null
        ? DateTime.tryParse(m['activatedAt'] as String) ?? DateTime.now()
        : DateTime.now();
    final daysConnected =
        DateTime.now().difference(activatedAt).inDays.clamp(1, 999);
    entries.add(FocusModeDisplayEntry(
      threadId: threadId,
      otherPersonName: thread?.otherName ?? 'your match',
      daysConnected: daysConnected,
      messageCount: (m['messageCount'] as int?) ?? 20,
      showMeetNudge: (m['shouldNudge'] as bool?) ?? false,
    ));
  }
  return entries;
});

