import '../models/interaction_models.dart' show ExpressInterestResult, InteractionInboxItem, InboxUnlockResult;

/// Shubhmilan §5a: express interest, priority interest, requests inbox, respond, withdraw.
abstract class InteractionsRepository {
  /// Express interest in a user. If they already liked you, creates mutual match.
  Future<ExpressInterestResult> expressInterest(
    String toUserId, {
    String? source,
  });

  /// Express priority (boosted) interest. Rate-limited per day (premium: 10/day). Free: pass [adCompletionToken] after user watches ad to allow one send.
  Future<ExpressInterestResult> expressPriorityInterest(
    String toUserId, {
    String? message,
    String? source,
    String? adCompletionToken,
  });

  /// Get received interests (requests inbox). Query: status, type, page, limit.
  /// For free users backend may return 403 PREMIUM_REQUIRED (see backend doc).
  Future<List<InteractionInboxItem>> getReceivedInteractions({
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int limit = 20,
  });

  /// Unlock one received interaction after user watches an ad. Backend enforces 2 per week. Returns result with item and quota, or null if none to unlock. Throws on 403 INBOX_UNLOCKS_LIMIT_REACHED.
  Future<InboxUnlockResult?> unlockOneReceivedInteraction({
    required String adCompletionToken,
  });

  /// Lightweight count of received (pending) requests for nav badge. GET /interactions/received/count.
  Future<int> getReceivedInteractionsCount({String status = 'pending'});

  /// Get sent interests.
  Future<List<InteractionInboxItem>> getSentInteractions({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  });

  /// Accept or decline an interest (PATCH /interactions/:id). Returns result with mutualMatch/chatThreadId on accept.
  /// When [accept] is false, optionally pass [declineMessage] or [declineReasonId] to soften rejection.
  Future<ExpressInterestResult> respondToInterest(
    String interactionId, {
    required bool accept,
    String? declineMessage,
    String? declineReasonId,
  });

  /// Withdraw a pending interest (DELETE /interactions/:id). Only sender, only when pending.
  Future<void> withdrawInteraction(String interactionId);
}
