import '../../core/mode/app_mode.dart';
import '../models/filter_options.dart';
import '../models/profile_summary.dart';

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

/// Discovery (dating) / Matches (matrimony) feed and search.
abstract class DiscoveryRepository {
  /// Recommended profiles with ML compatibility scores (uses saved preferences).
  Future<List<ProfileSummary>> getRecommended({
    required AppMode mode,
    String? city,
    int limit = 20,
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
    int limit = 20,
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
  Future<void> sendFeedback({
    required String candidateId,
    required String action,
    int? timeSpentMs,
    String? source,
  });

  /// Current matching preferences + AI suggestions.
  Future<DiscoveryPreferences> getDiscoveryPreferences();

  /// Filter options and defaults for Explore tab (respects strict preferences).
  Future<FilterOptions> getFilterOptions();
}
