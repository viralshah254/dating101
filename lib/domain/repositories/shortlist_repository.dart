import '../models/profile_summary.dart';
import '../models/who_shortlisted_me_entry.dart';

/// Matrimony: shortlist (saved profiles) and who shortlisted me.
abstract class ShortlistRepository {
  Future<List<ProfileSummary>> getShortlist({int limit = 100, int page = 1});

  /// [note] is an optional private note (matrimony).
  Future<void> addToShortlist(String profileId, {String? note});

  Future<void> removeFromShortlist(String userId);

  Future<bool> isShortlisted(String userId);

  /// People who shortlisted the current user (GET /shortlist/received).
  /// When not entitled, backend may return entries with [WhoShortlistedMeEntry.blurred] true.
  Future<List<WhoShortlistedMeEntry>> getWhoShortlistedMe({int page = 1, int limit = 20});

  /// Lightweight count of people who shortlisted you for nav badge. GET /shortlist/received/count.
  Future<int> getWhoShortlistedMeCount();
}
