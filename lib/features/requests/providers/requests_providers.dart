import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/interaction_models.dart';

/// Received interest requests (inbox). Refetch to see new/updated items.
final receivedInteractionsProvider = FutureProvider.autoDispose<List<InteractionInboxItem>>((ref) async {
  final repo = ref.watch(interactionsRepositoryProvider);
  return repo.getReceivedInteractions(status: 'pending', type: 'all', limit: 50);
});

/// Sent interests. Refetch after sending or withdrawing.
final sentInteractionsProvider = FutureProvider.autoDispose<List<InteractionInboxItem>>((ref) async {
  final repo = ref.watch(interactionsRepositoryProvider);
  return repo.getSentInteractions(status: 'pending', limit: 50);
});

/// Count of received (pending) interest requests — for nav badge. Uses GET /interactions/received/count.
final receivedRequestsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(interactionsRepositoryProvider);
  return repo.getReceivedInteractionsCount(status: 'pending');
});

/// Profile IDs the current user has sent normal interest to (for highlighting on match cards).
final sentInterestProfileIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final list = await ref.watch(sentInteractionsProvider.future);
  return list.where((e) => e.type == 'interest').map((e) => e.otherUser.id).toSet();
});

/// Profile IDs the current user has sent priority interest to (for highlighting on match cards).
final sentPriorityInterestProfileIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final list = await ref.watch(sentInteractionsProvider.future);
  return list.where((e) => e.type == 'priority_interest').map((e) => e.otherUser.id).toSet();
});
