import '../../core/mode/app_mode.dart';
import '../models/profile_summary.dart';

/// Discovery (dating) / Matches (matrimony) feed and search.
abstract class DiscoveryRepository {
  /// Dating: daily curated set for a city.
  /// Matrimony: recommended list (algorithm placeholder).
  Future<List<ProfileSummary>> getRecommended({
    required AppMode mode,
    String? city,
    int limit = 20,
  });

  /// Matrimony: search with filters (age, city, religion, etc.).
  Future<List<ProfileSummary>> search({
    required int? ageMin,
    required int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    int limit = 20,
  });

  /// Dating: nearby by radius (for map).
  Future<List<ProfileSummary>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 50,
  });
}
