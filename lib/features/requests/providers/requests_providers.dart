import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
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

/// Received interest requests (inbox). Refetch to see new/updated items. Scoped to current mode when backend supports it.
final receivedInteractionsProvider =
    FutureProvider.autoDispose<List<InteractionInboxItem>>((ref) async {
      final mode = ref.watch(appModeProvider) ?? AppMode.dating;
      final repo = ref.watch(interactionsRepositoryProvider);
      return repo.getReceivedInteractions(
        status: 'pending',
        type: 'all',
        limit: 50,
        mode: mode,
      );
    });

/// Sent interests per mode (dating vs matrimony are independent). Refetch after sending or withdrawing.
final sentInteractionsProvider =
    FutureProvider.autoDispose.family<List<InteractionInboxItem>, AppMode>((ref, mode) async {
      final repo = ref.watch(interactionsRepositoryProvider);
      return repo.getSentInteractions(status: 'pending', limit: 50, mode: mode);
    });

/// Requests tab badge: sum of pending interests + contact + photo view + inbound message requests.
/// If one of the count APIs fails (e.g. 500 from backend), we use 0 for that part so the badge and UI still work.
final receivedRequestsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final interactionsRepo = ref.watch(interactionsRepositoryProvider);
  final contactRequestRepo = ref.watch(contactRequestRepositoryProvider);
  final photoViewRepo = ref.watch(photoViewRequestRepositoryProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);
  int interactionsCount = 0;
  int contactRequestsCount = 0;
  int photoViewCount = 0;
  int messageRequestsCount = 0;
  try {
    interactionsCount = await interactionsRepo.getReceivedInteractionsCount(
      status: 'pending',
      mode: mode,
    );
  } catch (_) {}
  try {
    contactRequestsCount = await contactRequestRepo
        .getReceivedContactRequestsCount();
  } catch (_) {}
  try {
    photoViewCount = await photoViewRepo.getReceivedCount();
  } catch (_) {}
  try {
    final modeStr = mode.isMatrimony ? 'matrimony' : 'dating';
    messageRequestsCount = await chatRepo.getMessageRequestsCount(mode: modeStr);
  } catch (_) {}
  return interactionsCount + contactRequestsCount + photoViewCount + messageRequestsCount;
});

/// Pending received interests count — for "Received" tab label. Scoped to current mode.
final receivedInteractionsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final repo = ref.watch(interactionsRepositoryProvider);
  return repo.getReceivedInteractionsCount(status: 'pending', mode: mode);
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

/// Profile IDs the current user has sent normal interest to for [mode] (for highlighting on match cards).
final sentInterestProfileIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, AppMode>((ref, mode) async {
  final list = await ref.watch(sentInteractionsProvider(mode).future);
  return list
      .where((e) => e.type == 'interest')
      .map((e) => e.otherUser.id)
      .toSet();
});

/// Profile IDs the current user has sent priority interest to for [mode].
final sentPriorityInterestProfileIdsProvider =
    FutureProvider.autoDispose.family<Set<String>, AppMode>((ref, mode) async {
      final list = await ref.watch(sentInteractionsProvider(mode).future);
      return list
          .where((e) => e.type == 'priority_interest')
          .map((e) => e.otherUser.id)
          .toSet();
    });

/// Per-mode optimistic set: profile IDs we've sent interest/priority to this session before the sent list refetches.
/// Dating and matrimony are independent; add for current mode when user taps Like/Super like.
final optimisticSentInterestProfileIdsProvider =
    StateProvider<Map<AppMode, Set<String>>>((ref) => {});

/// Profile IDs the user has passed on (dating). Used to hide Pass/Super like/Like bar on full profile when already interacted.
final passedProfileIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Union of API sent (interest + priority) + optimistic for current mode; use to exclude profiles from Recommended.
final effectiveExcludedFromRecommendedIdsProvider = Provider<Set<String>>((ref) {
  final mode = ref.watch(appModeProvider) ?? AppMode.dating;
  final a = ref.watch(sentInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
  final b =
      ref.watch(sentPriorityInterestProfileIdsProvider(mode)).valueOrNull ?? <String>{};
  final c = ref.watch(optimisticSentInterestProfileIdsProvider)[mode] ?? <String>{};
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
