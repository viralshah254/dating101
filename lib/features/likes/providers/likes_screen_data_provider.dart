import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../requests/providers/requests_providers.dart';
import '../../../data/api/api_client.dart';
import '../../../data/repositories_api/api_interactions_repository.dart';
import '../../../data/repositories_api/api_profile_repository.dart';
import '../../../domain/models/interaction_models.dart';
import '../../../domain/models/visitor_entry.dart';

/// Prefetched data for the dating Likes screen (all three tabs + tab counts).
/// Loaded via WebSocket `likes_snapshot` when possible, else parallel HTTP.
class LikesScreenData {
  const LikesScreenData({
    required this.receivedItems,
    required this.visitorEntries,
    required this.sentItems,
    required this.likedYouCount,
    required this.visitorsCount,
    required this.youLikedCount,
    this.receivedError,
    this.inboxUnlocksRemainingThisWeek,
    this.inboxUnlocksResetAt,
  });

  final List<InteractionInboxItem> receivedItems;
  final List<VisitorEntry> visitorEntries;
  final List<InteractionInboxItem> sentItems;
  final int likedYouCount;
  final int visitorsCount;
  final int youLikedCount;
  final ApiException? receivedError;
  final int? inboxUnlocksRemainingThisWeek;
  final String? inboxUnlocksResetAt;

  static LikesScreenData fromWsPayload(Map<String, dynamic> raw) {
    final counts = raw['counts'] as Map<String, dynamic>?;
    final receivedMap = raw['received'] as Map<String, dynamic>?;
    final sentMap = raw['sent'] as Map<String, dynamic>?;
    final visitorsMap = raw['visitors'] as Map<String, dynamic>?;

    final receivedList = receivedMap?['interactions'] as List? ?? [];
    final sentList = sentMap?['interactions'] as List? ?? [];
    final visitorsList = visitorsMap?['visitors'] as List? ?? [];

    return LikesScreenData(
      receivedItems: ApiInteractionsRepository.parseInboxList(receivedList, isReceived: true),
      sentItems: ApiInteractionsRepository.parseInboxList(sentList, isReceived: false),
      visitorEntries: _parseVisitors(visitorsList),
      likedYouCount: (counts?['likedYou'] as num?)?.toInt() ?? 0,
      visitorsCount: (counts?['visitors'] as num?)?.toInt() ?? 0,
      youLikedCount: (counts?['youLiked'] as num?)?.toInt() ?? 0,
      receivedError: null,
      inboxUnlocksRemainingThisWeek: receivedMap?['inboxUnlocksRemainingThisWeek'] as int?,
      inboxUnlocksResetAt: receivedMap?['inboxUnlocksResetAt'] as String?,
    );
  }
}

List<VisitorEntry> _parseVisitors(List list) {
  return list.map((e) {
    final map = e as Map<String, dynamic>;
    final visitorMap = map['visitor'] as Map<String, dynamic>? ?? map;
    return VisitorEntry(
      visitId: map['visitId'] as String? ?? '',
      visitor: ApiProfileRepository.parseSummaryPublic(visitorMap),
      visitedAt: DateTime.parse(map['visitedAt'] as String),
      source: map['source'] as String?,
    );
  }).toList();
}

Future<void> _markVisitorsSeen(Ref ref) async {
  try {
    await ref.read(visitsRepositoryProvider).markVisitorsSeen();
  } catch (_) {}
}

Future<LikesScreenData> _loadViaHttp(Ref ref, AppMode mode) async {
  final interactions = ref.read(interactionsRepositoryProvider);
  final visits = ref.read(visitsRepositoryProvider);

  ApiException? receivedErr;
  List<InteractionInboxItem> received = [];
  try {
    received = await interactions.getReceivedInteractions(
      status: 'pending',
      type: 'all',
      limit: 50,
      mode: mode,
    );
  } on ApiException catch (e) {
    receivedErr = e;
  }

  final sent = await interactions.getSentInteractions(
    status: 'pending',
    limit: 50,
    mode: mode,
  );
  final visitorsResult = await visits.getVisitors(page: 1, limit: 50);

  unawaited(_markVisitorsSeen(ref));

  var likedYouCount = received.length;
  if (receivedErr != null) {
    try {
      likedYouCount = await interactions.getReceivedInteractionsCount(status: 'pending', mode: mode);
    } catch (_) {
      likedYouCount = 0;
    }
  }

  return LikesScreenData(
    receivedItems: received,
    visitorEntries: visitorsResult.visitors,
    sentItems: sent,
    likedYouCount: likedYouCount,
    visitorsCount: visitorsResult.visitors.length,
    youLikedCount: sent.length,
    receivedError: receivedErr,
  );
}

/// One-shot prefetch for Likes: try WebSocket snapshot first (counts + lists), then HTTP.
final likesScreenDataProvider = FutureProvider.autoDispose<LikesScreenData>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final config = ref.watch(apiConfigProvider);

  if (!config.useFakeBackend) {
    final rt = ref.read(realtimeWebSocketClientProvider);
    if (rt != null) {
      try {
        await rt.connect();
        final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
        final raw = await rt.requestLikesSnapshot(modeStr);
        if (raw != null && raw['type'] == 'likes_snapshot') {
          unawaited(_markVisitorsSeen(ref));
          final data = LikesScreenData.fromWsPayload(raw);
          final q = data.inboxUnlocksRemainingThisWeek;
          final reset = data.inboxUnlocksResetAt;
          if (q != null || reset != null) {
            ref.read(inboxUnlocksQuotaProvider.notifier).state = (
              remaining: q ?? ref.read(inboxUnlocksQuotaProvider)?.remaining ?? 2,
              resetsAt: reset != null ? DateTime.tryParse(reset) : ref.read(inboxUnlocksQuotaProvider)?.resetsAt,
            );
          }
          return data;
        }
      } catch (e) {
        debugPrint('[likesScreenData] ws: $e');
      }
    }
  }

  return _loadViaHttp(ref, mode);
});

/// Invalidate when interactions / visitors change so Likes refetches.
/// Accepts [Ref] or [WidgetRef] (both expose [invalidate]).
void invalidateLikesScreenData(dynamic ref) {
  ref.invalidate(likesScreenDataProvider);
}
