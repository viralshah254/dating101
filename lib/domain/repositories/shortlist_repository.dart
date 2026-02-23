import '../models/profile_summary.dart';

/// Matrimony: shortlist (saved profiles).
abstract class ShortlistRepository {
  Future<List<ProfileSummary>> getShortlist({int limit = 100});

  Future<void> addToShortlist(String userId);

  Future<void> removeFromShortlist(String userId);

  Future<bool> isShortlisted(String userId);
}
