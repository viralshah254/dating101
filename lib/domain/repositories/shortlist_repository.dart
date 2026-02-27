import '../models/shortlist_entry.dart';
import '../models/who_shortlisted_me_entry.dart';

/// Matrimony: shortlist (saved profiles) and who shortlisted me.
abstract class ShortlistRepository {
  /// [sort] e.g. 'recent' (default) or 'most_interested' when backend supports.
  Future<List<ShortlistEntry>> getShortlist({
    int limit = 100,
    int page = 1,
    String? sort,
  });

  /// [note] is an optional private note (matrimony).
  Future<void> addToShortlist(String profileId, {String? note});

  /// Update note and/or sortOrder for an entry (PATCH /shortlist/:shortlistId). No-op if backend does not support.
  Future<void> updateShortlistEntry(
    String shortlistId, {
    String? note,
    int? sortOrder,
  });

  Future<void> removeFromShortlist(String userId);

  Future<bool> isShortlisted(String userId);

  /// People who shortlisted the current user (GET /shortlist/received).
  /// When not entitled, backend may return entries with [WhoShortlistedMeEntry.blurred] true.
  Future<List<WhoShortlistedMeEntry>> getWhoShortlistedMe({
    int page = 1,
    int limit = 20,
  });

  /// Lightweight count of people who shortlisted you for nav badge. GET /shortlist/received/count.
  Future<int> getWhoShortlistedMeCount();
}
