import '../../core/mode/app_mode.dart';
import '../models/filter_options.dart';
import '../models/profile_summary.dart';
import '../models/saved_search.dart';

/// Full compatibility breakdown for a specific candidate.
class CompatibilityDetail {
  const CompatibilityDetail({
    required this.candidateId,
    required this.compatibilityScore,
    required this.compatibilityLabel,
    required this.matchReasons,
    required this.breakdown,
    required this.preferenceAlignment,
  });
  final String candidateId;
  final double compatibilityScore;
  final String compatibilityLabel;
  final List<String> matchReasons;
  final Map<String, double> breakdown;
  final Map<String, String> preferenceAlignment;
}

/// Current discovery preferences + AI suggestions.
class DiscoveryPreferences {
  const DiscoveryPreferences({
    required this.current,
    this.suggestions = const [],
  });
  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> suggestions;
}

/// One page of discovery results (profiles + cursor for next page).
class DiscoveryPageResult {
  const DiscoveryPageResult({
    required this.profiles,
    this.nextCursor,
  });
  final List<ProfileSummary> profiles;
  final String? nextCursor;
}

/// Discovery (dating) / Matches (matrimony) feed and search.
abstract class DiscoveryRepository {
  /// Recommended profiles with ML compatibility scores (uses saved preferences).
  Future<List<ProfileSummary>> getRecommended({
    required AppMode mode,
    String? city,
    int limit = 20,
    String? cursor,
  });

  /// Daily matches for matrimony (9 smart-selected profiles). Matrimony-only.
  Future<List<ProfileSummary>> getDailyMatches({int limit = 9});

  /// One page of recommended profiles; use [nextCursor] for pagination.
  Future<DiscoveryPageResult> getRecommendedPage({
    required AppMode mode,
    String? city,
    int limit = 30,
    String? cursor,
  });

  /// Explore: everyone in mode, optionally filtered. No filters = show everyone. Same response shape as recommended.
  Future<List<ProfileSummary>> getExplore({
    required AppMode mode,
    int? ageMin,
    int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    int? heightMaxCm,
    String? diet,
    String? bodyType,
    String? maritalStatus,
    int limit = 20,
    String? cursor,
  });

  /// One page of explore results; use [nextCursor] for pagination.
  Future<DiscoveryPageResult> getExplorePage({
    required AppMode mode,
    int? ageMin,
    int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    int? heightMaxCm,
    String? diet,
    String? bodyType,
    String? maritalStatus,
    int limit = 30,
    String? cursor,
  });

  /// Search with filters (age, city, religion, etc.). Prefer [getExplore] when backend supports it.
  Future<List<ProfileSummary>> search({
    required int? ageMin,
    required int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    String? diet,
    int limit = 20,
    String? cursor,
  });

  /// Nearby by radius (for map / dating).
  Future<List<ProfileSummary>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 50,
    String? cursor,
  });

  /// Full compatibility breakdown for a specific candidate.
  Future<CompatibilityDetail> getCompatibility(String candidateId);

  /// Record a user interaction (like, pass, superlike, block, report, view).
  /// [mode] scopes the action to dating or matrimony so passes/likes are independent.
  /// For action 'block' or 'report', pass [reason] (required by backend for safety). For report, [details] is optional.
  Future<void> sendFeedback({
    required String candidateId,
    required String action,
    int? timeSpentMs,
    String? source,
    String? reason,
    String? details,
    AppMode? mode,
  });

  /// Current matching preferences + AI suggestions.
  Future<DiscoveryPreferences> getDiscoveryPreferences();

  /// Filter options and defaults for Explore tab (respects strict preferences).
  Future<FilterOptions> getFilterOptions();

  // --- Saved searches (matrimony) ---

  /// List saved searches; each may include [SavedSearch.newMatchCount] for badge.
  Future<List<SavedSearch>> getSavedSearches();

  /// Create a saved search from current filters. [filters] same shape as explore (ageMin, ageMax, city, religion, education, heightMinCm, diet, etc.).
  Future<SavedSearch> createSavedSearch(
    Map<String, dynamic> filters, {
    String? name,
    bool notifyOnNewMatch = true,
  });

  /// Update name and/or notify flag.
  Future<SavedSearch> updateSavedSearch(
    String id, {
    String? name,
    bool? notifyOnNewMatch,
  });

  /// Delete a saved search.
  Future<void> deleteSavedSearch(String id);

  /// Mark saved search as viewed; resets new-match count for that search.
  Future<void> markSavedSearchViewed(String id);
}
