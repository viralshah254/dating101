import '../models/visitor_entry.dart';
import '../models/visitor_unlock_result.dart';

/// Profile visitors (who viewed my profile). Saathi §6a.
abstract class VisitsRepository {
  /// Record that the current user viewed a profile.
  Future<void> recordVisit(
    String profileId, {
    String? source,
    int? durationMs,
  });

  /// List users who viewed my profile (Visitors tab).
  /// For free users backend may return minimal data (name, age, visitId; no/placeholder image).
  Future<VisitorsResult> getVisitors({int page = 1, int limit = 20});

  /// Mark visitors as seen (resets newCount).
  Future<void> markVisitorsSeen();

  /// Unlock one visitor after user watches an ad. Backend enforces 2 per week.
  /// Returns result with visitor and remaining quota, or null if limit reached.
  /// Throws ApiException with code VISITOR_UNLOCKS_LIMIT_REACHED when quota exhausted.
  Future<VisitorUnlockResult?> unlockOneVisitor({
    required String visitId,
    required String adCompletionToken,
  });
}
