import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/chat_thread_disk_cache.dart';
import '../../data/repositories_api/api_chat_repository.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/discovery/providers/discovery_providers.dart';
import '../../features/likes/providers/likes_screen_data_provider.dart';
import '../../features/matches/providers/matches_providers.dart';
import '../entitlements/entitlements.dart';
import '../providers/repository_providers.dart';
import '../shell/root_shell.dart' show navBadgesProvider;

/// Clears Riverpod-cached API results tied to the previous account.
///
/// [FutureProvider]s that are not `autoDispose` (e.g. [discoveryFeedProvider]) do not
/// refetch when [TokenStorage] gets new tokens—the repository providers keep the same
/// instance—so a prior [ApiException] (UNAUTHORIZED) can stick until the user taps Retry.
/// Call this on login and logout when session identity changes.
///
/// Also recreates chat/realtime WebSocket clients so the previous account's
/// connection is not left open alongside the new JWT (duplicate frames →
/// false "incoming" echoes in chat).
///
/// Accepts [WidgetRef] or [Ref] (same [invalidate] API).
void invalidateSessionScopedApiCaches(dynamic ref) {
  clearChatThreadMessageDisplayCache();
  unawaited(ChatThreadDiskCache.clearAll());
  ref.invalidate(chatWebSocketClientProvider);
  ref.invalidate(realtimeWebSocketClientProvider);
  ref.invalidate(pendingSentMessagesProvider);
  ref.invalidate(discoveryFeedProvider);
  ref.invalidate(filterOptionsProvider);
  ref.invalidate(mutualMatchesProvider);
  ref.invalidate(matchedUserIdsProvider);
  ref.invalidate(recommendedPaginatedProvider);
  ref.invalidate(explorePaginatedProvider);
  ref.invalidate(visitorsEntriesProvider);
  ref.invalidate(visitorsProvider);
  ref.invalidate(navBadgesProvider);
  ref.invalidate(navNotificationsUnreadCountProvider);
  ref.invalidate(subscriptionStateProvider);
  ref.invalidate(entitlementsAsyncProvider);
  ref.invalidate(likesScreenDataProvider);
  ref.invalidate(chatThreadsProvider);
  ref.invalidate(registerFcmTokenProvider);
}
