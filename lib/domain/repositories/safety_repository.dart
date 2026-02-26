import '../models/blocked_user_entry.dart';

/// Safety API: block, report, list blocked, unblock.
/// POST /safety/block, POST /safety/report, GET /safety/blocked, DELETE /safety/blocked/:userId.
abstract class SafetyRepository {
  /// Block a user with a reason. POST /safety/block.
  Future<void> block(
    String blockedUserId,
    String reason, {
    String? source,
  });

  /// Report a user with a reason and optional details. POST /safety/report.
  Future<void> report(
    String reportedUserId,
    String reason, {
    String? details,
    String? source,
  });

  /// List users the current user has blocked (for Privacy & safety screen).
  Future<List<BlockedUserEntry>> getBlockedUsers({
    int limit = 50,
    String? cursor,
  });

  /// Remove a user from the blocked list.
  Future<void> unblock(String userId);
}
