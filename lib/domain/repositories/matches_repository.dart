import '../models/mutual_match_entry.dart';

/// Mutual matches (both users have expressed interest). GET /matches, DELETE /matches/:matchId.
abstract class MatchesRepository {
  Future<List<MutualMatchEntry>> getMatches({int page = 1, int limit = 20});
  Future<void> unmatch(String matchId);
}
