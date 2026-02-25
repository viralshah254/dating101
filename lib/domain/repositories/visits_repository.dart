import '../models/visitor_entry.dart';

/// Profile visitors (who viewed my profile). Saathi §6a.
abstract class VisitsRepository {
  /// Record that the current user viewed a profile.
  Future<void> recordVisit(
    String profileId, {
    String? source,
    int? durationMs,
  });

  /// List users who viewed my profile (Visitors tab).
  Future<VisitorsResult> getVisitors({int page = 1, int limit = 20});

  /// Mark visitors as seen (resets newCount).
  Future<void> markVisitorsSeen();
}
