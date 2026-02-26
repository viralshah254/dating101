import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/app_location_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/mode_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../domain/models/mutual_match_entry.dart';
import '../../../domain/models/profile_summary.dart';

final matchesRecommendedProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
  final mode = ref.watch(appModeProvider) ?? AppMode.matrimony;
  final repo = ref.watch(discoveryRepositoryProvider);
  debugPrint('[Matches] Fetching recommended profiles (mode=$mode)...');
  final results = await repo.getRecommended(mode: mode, limit: 20);
  debugPrint('[Matches] Got ${results.length} recommended profiles');
  return results;
});

/// Mutual matches (GET /matches). Used for Matches tab and to exclude from Explore.
final mutualMatchesProvider =
    FutureProvider.autoDispose<List<MutualMatchEntry>>((ref) async {
  final repo = ref.watch(matchesRepositoryProvider);
  return repo.getMatches(page: 1, limit: 100);
});

/// Set of user IDs we are already matched with. Use to hide them from Explore.
final matchedUserIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final list = await ref.watch(mutualMatchesProvider.future);
  return list.map((e) => e.profile.id).toSet();
});

/// Explore tab: GET /discovery/explore with mode + optional filters. No filters = everyone in mode.
final matchesExploreProvider = FutureProvider.autoDispose
    .family<List<ProfileSummary>, ({AppMode mode, MatchesSearchFilters filters})>((ref, args) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  debugPrint('[Matches] Fetching explore (mode=${args.mode}, hasFilters=${_hasFilters(args.filters)})...');
  final results = await repo.getExplore(
    mode: args.mode,
    ageMin: args.filters.ageMin,
    ageMax: args.filters.ageMax,
    city: args.filters.city,
    religion: args.filters.religion,
    education: args.filters.education,
    heightMinCm: args.filters.heightMinCm,
    limit: 20,
  );
  debugPrint('[Matches] Explore got ${results.length} profiles');
  return results;
});

bool _hasFilters(MatchesSearchFilters f) =>
    f.ageMin != null ||
    f.ageMax != null ||
    (f.city != null && f.city!.isNotEmpty) ||
    (f.religion != null && f.religion!.isNotEmpty) ||
    (f.education != null && f.education!.isNotEmpty) ||
    f.heightMinCm != null;

final matchesSearchProvider = FutureProvider.autoDispose
    .family<List<ProfileSummary>, MatchesSearchFilters>((ref, filters) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  return repo.search(
    ageMin: filters.ageMin,
    ageMax: filters.ageMax,
    city: filters.city,
    religion: filters.religion,
    education: filters.education,
    heightMinCm: filters.heightMinCm,
    limit: 20,
  );
});

final matchesNearbyProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  final loc = await AppLocationService.instance.getCurrentCreationLocation();
  final lat = loc?.latitude ?? 19.076;
  final lng = loc?.longitude ?? 72.877;
  return repo.getNearby(lat: lat, lng: lng, radiusKm: 25, limit: 20);
});

/// Visitors (who viewed my profile). Uses GET /visits/received and marks as seen on load.
final visitorsProvider =
    FutureProvider.autoDispose<List<ProfileSummary>>((ref) async {
  final repo = ref.watch(visitsRepositoryProvider);
  final result = await repo.getVisitors(page: 1, limit: 50);
  await repo.markVisitorsSeen();
  return result.visitors.map((e) => e.visitor).toList();
});

/// Records a profile visit when viewing someone's full profile (POST /visits). Fire-and-forget.
final recordProfileVisitProvider =
    FutureProvider.autoDispose.family<void, String>((ref, profileId) async {
  final repo = ref.read(visitsRepositoryProvider);
  await repo.recordVisit(profileId, source: 'profile_view');
});

class MatchesSearchFilters {
  const MatchesSearchFilters({
    this.ageMin,
    this.ageMax,
    this.city,
    this.religion,
    this.education,
    this.heightMinCm,
  });

  final int? ageMin;
  final int? ageMax;
  final String? city;
  final String? religion;
  final String? education;
  final int? heightMinCm;

  MatchesSearchFilters copyWith({
    int? ageMin,
    int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
  }) {
    return MatchesSearchFilters(
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      city: city ?? this.city,
      religion: religion ?? this.religion,
      education: education ?? this.education,
      heightMinCm: heightMinCm ?? this.heightMinCm,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchesSearchFilters &&
          ageMin == other.ageMin &&
          ageMax == other.ageMax &&
          city == other.city &&
          religion == other.religion &&
          education == other.education &&
          heightMinCm == other.heightMinCm;

  @override
  int get hashCode => Object.hash(ageMin, ageMax, city, religion, education, heightMinCm);
}
