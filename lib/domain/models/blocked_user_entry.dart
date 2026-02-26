import 'profile_summary.dart';

/// One entry from GET /safety/blocked — a user the current user has blocked.
class BlockedUserEntry {
  const BlockedUserEntry({
    required this.blockedUserId,
    required this.blockedAt,
    required this.profile,
  });
  final String blockedUserId;
  final DateTime blockedAt;
  final ProfileSummary profile;
}
