import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/shortlist_entry.dart';
import '../../../domain/models/who_shortlisted_me_entry.dart';

/// Current sort for shortlist: 'recent' or 'most_interested' (when backend supports).
final shortlistSortProvider = StateProvider.autoDispose<String>((ref) => 'recent');

final shortlistProvider =
    FutureProvider.autoDispose<List<ShortlistEntry>>((ref) async {
  final repo = ref.watch(shortlistRepositoryProvider);
  final sort = ref.watch(shortlistSortProvider);
  return repo.getShortlist(limit: 50, sort: sort);
});

/// Set of profile IDs currently in the user's shortlist. Use to highlight Save on cards.
/// Invalidated when adding/removing from shortlist so Matches tab and Shortlist tab stay in sync.
final shortlistedIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final list = await ref.watch(shortlistProvider.future);
  return list.map((e) => e.profile.id).toSet();
});

/// People who shortlisted the current user (GET /shortlist/received).
/// For free users backend may return 403 PREMIUM_REQUIRED with count + quota.
final whoShortlistedMeProvider =
    FutureProvider.autoDispose<List<WhoShortlistedMeEntry>>((ref) async {
  final repo = ref.watch(shortlistRepositoryProvider);
  return repo.getWhoShortlistedMe(limit: 50);
});

/// Entries unlocked via "Watch ad" on Shortlisted you tab (backend enforces 5/week).
/// Not autoDispose so unlocked entries remain visible for the session; remove when user matches.
final shortlistUnlockedEntriesProvider =
    StateProvider<List<WhoShortlistedMeEntry>>((ref) => []);

/// Remaining ad-unlocks this week and when they reset. Set from 403 body or from unlock-one response.
final shortlistUnlocksQuotaProvider =
    StateProvider.autoDispose<({int remaining, DateTime? resetsAt})?>((ref) => null);

/// Count of people who shortlisted you — for nav badge. Uses GET /shortlist/received/count.
final whoShortlistedMeCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(shortlistRepositoryProvider);
  return repo.getWhoShortlistedMeCount();
});
