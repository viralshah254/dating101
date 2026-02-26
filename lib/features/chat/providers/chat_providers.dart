import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/repositories/chat_repository.dart';

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

