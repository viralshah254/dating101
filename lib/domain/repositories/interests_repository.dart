import '../models/interaction_models.dart';

/// Matrimony: send interest, list received/sent, accept/decline/withdraw.
abstract class InterestsRepository {
  /// Send interest to a user.
  Future<Interest> sendInterest(String toUserId);

  /// List interests received (for current user).
  Future<List<Interest>> getReceivedInterests({int limit = 50});

  /// List interests sent.
  Future<List<Interest>> getSentInterests({int limit = 50});

  /// Accept an interest (received).
  Future<Interest> acceptInterest(String interestId);

  /// Decline an interest (received).
  Future<Interest> declineInterest(String interestId);

  /// Withdraw an interest (sent).
  Future<void> withdrawInterest(String interestId);
}
