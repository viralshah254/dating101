import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/contact_request_status.dart';
import '../../../domain/models/interaction_models.dart'
    hide ContactRequestStatus;
import '../../../domain/models/photo_view_request.dart';

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
final receivedRequestsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final interactionsRepo = ref.watch(interactionsRepositoryProvider);
  final contactRequestRepo = ref.watch(contactRequestRepositoryProvider);
  final photoViewRepo = ref.watch(photoViewRequestRepositoryProvider);
  final interactionsCount = await interactionsRepo.getReceivedInteractionsCount(
    status: 'pending',
  );
  final contactRequestsCount = await contactRequestRepo
      .getReceivedContactRequestsCount();
  final photoViewCount = await photoViewRepo.getReceivedCount();
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
final receivedContactRequestsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repo = ref.watch(contactRequestRepositoryProvider);
  return repo.getReceivedContactRequestsCount();
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
