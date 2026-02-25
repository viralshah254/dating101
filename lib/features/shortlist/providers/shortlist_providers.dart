import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/profile_summary.dart';
import '../../../domain/models/who_shortlisted_me_entry.dart';

final shortlistProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
  final repo = ref.watch(shortlistRepositoryProvider);
  return repo.getShortlist(limit: 50);
});

/// Set of profile IDs currently in the user's shortlist. Use to highlight Save on cards.
/// Invalidated when adding/removing from shortlist so Matches tab and Shortlist tab stay in sync.
final shortlistedIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final list = await ref.watch(shortlistProvider.future);
  return list.map((p) => p.id).toSet();
});

/// People who shortlisted the current user (GET /shortlist/received).
/// When not entitled, backend may return blurred entries.
final whoShortlistedMeProvider =
    FutureProvider.autoDispose<List<WhoShortlistedMeEntry>>((ref) async {
  final repo = ref.watch(shortlistRepositoryProvider);
  return repo.getWhoShortlistedMe(limit: 50);
});

/// Count of people who shortlisted you — for nav badge. Uses GET /shortlist/received/count.
final whoShortlistedMeCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(shortlistRepositoryProvider);
  return repo.getWhoShortlistedMeCount();
});
