import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
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
final chatUnreadTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final threads = await ref.watch(chatThreadsProvider.future);
  return threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
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

