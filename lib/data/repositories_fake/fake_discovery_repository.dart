import '../../core/mode/app_mode.dart';
import '../../domain/models/filter_options.dart';
import '../../domain/models/profile_summary.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeDiscoveryRepository implements DiscoveryRepository {
  FakeDiscoveryRepository(ProfileRepository profileRepo);

  @override
  Future<List<ProfileSummary>> getRecommended({
    required AppMode mode,
    String? city,
    int limit = 20,
    String? cursor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = <ProfileSummary>[];
    final ids = FakeData.allProfiles.keys.toList();
    for (var i = 0; i < ids.length && list.length < limit; i++) {
      final id = ids[i];
      final p = FakeData.allProfiles[id]!;
      final distanceKm = (i + 1) * 2.0;
      final reason = FakeData.matchReasons[id];
      final shared = _sharedInterests(FakeData.myProfile.interests, p.interests);
      list.add(
        profileToSummary(p, distanceKm: distanceKm, matchReason: reason, sharedInterests: shared),
      );
    }
    return list;
  }

  @override
  Future<List<ProfileSummary>> search({
    required int? ageMin,
    required int? ageMax,
    String? city,
    String? religion,
    String? education,
    int? heightMinCm,
    int limit = 20,
    String? cursor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = <ProfileSummary>[];
    for (final entry in FakeData.allProfiles.entries) {
      if (list.length >= limit) break;
      final p = entry.value;
      if (ageMin != null && (p.age == null || p.age! < ageMin)) continue;
      if (ageMax != null && (p.age == null || p.age! > ageMax)) continue;
      if (city != null &&
          !(p.currentCity ?? '').toLowerCase().contains(city.toLowerCase()))
        continue;
      final shared = _sharedInterests(FakeData.myProfile.interests, p.interests);
      list.add(
        profileToSummary(p, matchReason: FakeData.matchReasons[entry.key], sharedInterests: shared),
      );
    }
    return list;
  }

  @override
  Future<List<ProfileSummary>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 50,
    String? cursor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return getRecommended(mode: AppMode.dating, limit: limit);
  }

  @override
  Future<CompatibilityDetail> getCompatibility(String candidateId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return CompatibilityDetail(
      candidateId: candidateId,
      compatibilityScore: 0.78,
      compatibilityLabel: 'Great match',
      matchReasons: ['Shares 2 interests with you', 'Lives nearby'],
      breakdown: {
        'basics': 0.85,
        'culture': 0.70,
        'lifestyle': 0.80,
        'career': 0.75,
        'interests': 0.72,
        'family': 0.90,
        'location': 0.82,
      },
      preferenceAlignment: {
        'age': 'within_range',
        'religion': 'match',
        'location': 'same_city',
      },
    );
  }

  @override
  Future<void> sendFeedback({
    required String candidateId,
    required String action,
    int? timeSpentMs,
    String? source,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<DiscoveryPreferences> getDiscoveryPreferences() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const DiscoveryPreferences(current: {'ageMin': 21, 'ageMax': 35});
  }

  @override
  Future<FilterOptions> getFilterOptions() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return const FilterOptions(
      age: FilterAgeRange(
        min: 18,
        max: 60,
        defaultMin: 24,
        defaultMax: 35,
        strict: false,
      ),
      cities: FilterDimension(
        options: [
          'Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Hyderabad', 'Pune',
          'London', 'Dubai', 'New York', 'Singapore',
        ],
        strict: false,
      ),
      religions: FilterDimension(
        options: ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Jain', 'Buddhist', 'Other'],
        strict: false,
      ),
      education: FilterDimension(
        options: ["High School", "Diploma", "Bachelor's", "Master's", "Doctorate"],
        strict: false,
      ),
    );
  }
}

List<String> _sharedInterests(List<String> viewer, List<String> profile) {
  final set = profile.map((s) => s.toLowerCase()).toSet();
  return viewer.where((i) => set.contains(i.toLowerCase())).toList();
}
