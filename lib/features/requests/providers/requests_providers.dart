import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/contact_request_status.dart';
import '../../../domain/models/interaction_models.dart'
    hide ContactRequestStatus;
import '../../../domain/models/photo_view_request.dart';

/// Free users who unlocked one request via watch-ad: list of that item so we can show it without refetching full inbox.
final unlockedReceivedProvider =
    StateProvider<List<InteractionInboxItem>>((ref) => []);

/// Inbox (message requests) ad-unlock quota: remaining unlocks this week and reset time. Backend limit 2/week. Set from 403 body or from unlock-one response.
final inboxUnlocksQuotaProvider =
    StateProvider.autoDispose<({int remaining, DateTime? resetsAt})?>((ref) => null);

/// Received interest requests (inbox). Refetch to see new/updated items.
final receivedInteractionsProvider =
    FutureProvider.autoDispose<List<InteractionInboxItem>>((ref) async {
      final repo = ref.watch(interactionsRepositoryProvider);
      return repo.getReceivedInteractions(
        status: 'pending',
        type: 'all',
        limit: 50,
      );
    });

/// Sent interests. Refetch after sending or withdrawing.
final sentInteractionsProvider =
    FutureProvider.autoDispose<List<InteractionInboxItem>>((ref) async {
      final repo = ref.watch(interactionsRepositoryProvider);
      return repo.getSentInteractions(status: 'pending', limit: 50);
    });

/// Requests tab badge: sum of pending interests + pending contact + pending photo view requests.
/// If one of the count APIs fails (e.g. 500 from backend), we use 0 for that part so the badge and UI still work.
final receivedRequestsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final interactionsRepo = ref.watch(interactionsRepositoryProvider);
  final contactRequestRepo = ref.watch(contactRequestRepositoryProvider);
  final photoViewRepo = ref.watch(photoViewRequestRepositoryProvider);
  int interactionsCount = 0;
  int contactRequestsCount = 0;
  int photoViewCount = 0;
  try {
    interactionsCount = await interactionsRepo.getReceivedInteractionsCount(
      status: 'pending',
    );
  } catch (_) {}
  try {
    contactRequestsCount = await contactRequestRepo
        .getReceivedContactRequestsCount();
  } catch (_) {}
  try {
    photoViewCount = await photoViewRepo.getReceivedCount();
  } catch (_) {}
  return interactionsCount + contactRequestsCount + photoViewCount;
});

/// Pending received interests count — for "Received" tab label.
final receivedInteractionsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repo = ref.watch(interactionsRepositoryProvider);
  return repo.getReceivedInteractionsCount(status: 'pending');
});

/// Pending received contact requests count — for "Contact requests" tab label.
/// If the API fails (e.g. 500 when InboxAdUnlock table is missing), returns 0 so the UI does not break.
final receivedContactRequestsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  try {
    final repo = ref.watch(contactRequestRepositoryProvider);
    return await repo.getReceivedContactRequestsCount();
  } catch (_) {
    return 0;
  }
});

/// Profile IDs the current user has sent normal interest to (for highlighting on match cards).
final sentInterestProfileIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final list = await ref.watch(sentInteractionsProvider.future);
  return list
      .where((e) => e.type == 'interest')
      .map((e) => e.otherUser.id)
      .toSet();
});

/// Profile IDs the current user has sent priority interest to (for highlighting on match cards).
final sentPriorityInterestProfileIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
      final list = await ref.watch(sentInteractionsProvider.future);
      return list
          .where((e) => e.type == 'priority_interest')
          .map((e) => e.otherUser.id)
          .toSet();
    });

/// Profile IDs we've sent interest/priority interest to this session, before the sent list refetches.
/// Add to this when user taps Express Interest (from full profile or feed) so Recommended hides them immediately.
final optimisticSentInterestProfileIdsProvider =
    StateProvider<Set<String>>((ref) => {});

/// Union of API sent (interest + priority) + optimistic; use this to exclude profiles from Recommended.
final effectiveExcludedFromRecommendedIdsProvider = Provider<Set<String>>((ref) {
  final a = ref.watch(sentInterestProfileIdsProvider).valueOrNull ?? <String>{};
  final b =
      ref.watch(sentPriorityInterestProfileIdsProvider).valueOrNull ?? <String>{};
  final c = ref.watch(optimisticSentInterestProfileIdsProvider);
  return {...a, ...b, ...c};
});

// ── Contact requests ─────────────────────────────────────────────────────

/// Contact request status toward a profile (for full profile "Request contact" / "View contacts").
final contactRequestStatusProvider = FutureProvider.autoDispose
    .family<ContactRequestStatus, String>((ref, profileId) async {
      final repo = ref.watch(contactRequestRepositoryProvider);
      return repo.getStatusForProfile(profileId);
    });

/// Received contact requests (people who want my contact). For "Contact requests" tab.
final receivedContactRequestsProvider =
    FutureProvider.autoDispose<List<ReceivedContactRequest>>((ref) async {
      final repo = ref.watch(contactRequestRepositoryProvider);
      return repo.getReceivedContactRequests(page: 1, limit: 50);
    });

// ── Photo view requests ───────────────────────────────────────────────────

/// Photo view status for the current user toward [profileId] (none, pending, accepted, declined).
final photoViewStatusProvider = FutureProvider.autoDispose
    .family<PhotoViewStatus?, String>((ref, profileId) async {
      final repo = ref.watch(photoViewRequestRepositoryProvider);
      return repo.getStatus(profileId);
    });

/// Received photo view requests (people who want to view my photos). For "Photo view" tab.
final receivedPhotoViewRequestsProvider =
    FutureProvider.autoDispose<List<ReceivedPhotoViewRequest>>((ref) async {
      final repo = ref.watch(photoViewRequestRepositoryProvider);
      return repo.getReceived(page: 1, limit: 50, status: 'pending');
    });

/// Pending received photo view requests count (for "Photo view" tab label).
final receivedPhotoViewRequestsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repo = ref.watch(photoViewRequestRepositoryProvider);
  return repo.getReceivedCount();
});
