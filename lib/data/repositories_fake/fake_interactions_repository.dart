import '../../core/mode/app_mode.dart';
import '../../domain/models/interaction_models.dart';
import '../../domain/repositories/interactions_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeInteractionsRepository implements InteractionsRepository {
  @override
  Future<ExpressInterestResult> expressInterest(
    String toUserId, {
    String? source,
    AppMode? mode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return ExpressInterestResult(
      interactionId: 'int_fake_${DateTime.now().millisecondsSinceEpoch}',
      mutualMatch: false,
    );
  }

  @override
  Future<ExpressInterestResult> expressPriorityInterest(
    String toUserId, {
    String? message,
    String? source,
    String? adCompletionToken,
    AppMode? mode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return ExpressInterestResult(
      interactionId:
          'int_fake_priority_${DateTime.now().millisecondsSinceEpoch}',
      mutualMatch: false,
      priorityRemaining: 4,
    );
  }

  @override
  Future<List<InteractionInboxItem>> getReceivedInteractions({
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int limit = 20,
    AppMode? mode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = <InteractionInboxItem>[];
    var i = 0;
    for (final entry in FakeData.allProfiles.entries) {
      if (entry.key == FakeData.myProfile.id) continue;
      if (i >= limit) break;
      list.add(
        InteractionInboxItem(
          interactionId: 'int_rec_$i',
          otherUser: profileToSummary(entry.value),
          message: type == 'priority_interest' ? 'Hi!' : null,
          seenByRecipient: false,
          status: status == 'all'
              ? (i % 2 == 0 ? 'pending' : 'accepted')
              : status,
          type: i == 0 ? 'priority_interest' : 'interest',
          createdAt: DateTime.now().subtract(Duration(hours: i)),
        ),
      );
      i++;
    }
    return list;
  }

  @override
  Future<InboxUnlockResult?> unlockOneReceivedInteraction({
    required String adCompletionToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = await getReceivedInteractions(limit: 1);
    if (list.isEmpty) return null;
    return InboxUnlockResult(
      item: list.first,
      unlocksRemainingThisWeek: 1,
      resetsAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  @override
  Future<int> getReceivedInteractionsCount({String status = 'pending', AppMode? mode}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = await getReceivedInteractions(status: status, limit: 1000, mode: mode);
    return list.length;
  }

  @override
  Future<List<InteractionInboxItem>> getSentInteractions({
    String status = 'pending',
    int page = 1,
    int limit = 20,
    AppMode? mode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = <InteractionInboxItem>[];
    var i = 0;
    for (final entry in FakeData.allProfiles.entries) {
      if (entry.key == FakeData.myProfile.id) continue;
      if (i >= 5) break;
      list.add(
        InteractionInboxItem(
          interactionId: 'int_sent_$i',
          otherUser: profileToSummary(entry.value),
          status: status,
          type: i == 0 ? 'priority_interest' : 'interest',
          createdAt: DateTime.now().subtract(Duration(days: i + 3)),
        ),
      );
      i++;
    }
    return list;
  }

  @override
  Future<ExpressInterestResult> respondToInterest(
    String interactionId, {
    required bool accept,
    String? declineMessage,
    String? declineReasonId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return ExpressInterestResult(
      interactionId: interactionId,
      mutualMatch: accept,
      chatThreadId: accept ? 'thread_fake' : null,
    );
  }

  @override
  Future<void> withdrawInteraction(String interactionId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> sendReminder(String interactionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<String>> getOpenerSuggestions({
    required String toUserId,
    AppMode? mode,
    String context = 'mutual_match',
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final profile = FakeData.allProfiles[toUserId];
    final name = (profile?.name ?? 'there').split(' ').first;
    final shared = (profile?.interests.isNotEmpty ?? false)
        ? profile!.interests.first
        : null;
    return [
      'Hi $name, great to match with you!',
      if (shared != null) 'I noticed you like $shared. What do you enjoy most about it?',
      'What does your ideal weekend look like?',
    ];
  }
}
