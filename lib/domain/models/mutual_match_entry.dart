import 'profile_summary.dart';

/// A mutual match (both users have expressed interest). Used for GET /matches.
class MutualMatchEntry {
  const MutualMatchEntry({
    required this.matchId,
    required this.profile,
    required this.matchedAt,
    this.chatThreadId,
    this.lastMessage,
    this.lastMessageAt,
  });
  final String matchId;
  final ProfileSummary profile;
  final DateTime matchedAt;
  final String? chatThreadId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
}
