import '../../core/mode/app_mode.dart';
import '../../domain/models/filter_options.dart';
import '../../domain/models/profile_summary.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeDiscoveryRepository implements DiscoveryRepository {
  FakeDiscoveryRepository(ProfileRepository profileRepo);

  final List<SavedSearch> _savedSearches = [];
  var _savedSearchIdCounter = 0;

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
      if (city != null && city.isNotEmpty) {
        final profileCity = (p.currentCity ?? '').trim().toLowerCase();
        final filterCity = city.trim().toLowerCase();
        if (profileCity != filterCity) continue;
      }
      final distanceKm = (i + 1) * 2.0;
      final reason = FakeData.matchReasons[id];
      final shared = _sharedInterests(
        FakeData.myProfile.interests,
        p.interests,
      );
      list.add(
        profileToSummary(
          p,
          distanceKm: distanceKm,
          matchReason: reason,
          matchReasons:
              FakeData.matchReasonsList[id] ?? (reason != null ? [reason] : []),
          sharedInterests: shared,
        ),
      );
    }
    return list;
  }

  @override
  Future<DiscoveryPageResult> getRecommendedPage({
    required AppMode mode,
    String? city,
    int limit = 30,
    String? cursor,
  }) async {
    final profiles = await getRecommended(mode: mode, city: city, limit: limit, cursor: cursor);
    final nextCursor = profiles.length >= limit ? 'cursor_${profiles.length}' : null;
    return DiscoveryPageResult(profiles: profiles, nextCursor: nextCursor);
  }

  @override
  Future<List<ProfileSummary>> getDailyMatches({int limit = 9}) async {
    return getRecommended(mode: AppMode.matrimony, limit: limit);
  }

  @override
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
    String? motherTongue,
    int limit = 20,
    String? cursor,
  }) async {
    final hasFilters =
        ageMin != null ||
        ageMax != null ||
        (city != null && city.isNotEmpty) ||
        (religion != null && religion.isNotEmpty) ||
        (education != null && education.isNotEmpty) ||
        heightMinCm != null ||
        heightMaxCm != null ||
        (diet != null && diet.isNotEmpty) ||
        (bodyType != null && bodyType.isNotEmpty) ||
        (maritalStatus != null && maritalStatus.isNotEmpty) ||
        (motherTongue != null && motherTongue.isNotEmpty);
    if (hasFilters) {
      return search(
        ageMin: ageMin,
        ageMax: ageMax,
        city: city,
        religion: religion,
        education: education,
        heightMinCm: heightMinCm,
        diet: diet,
        limit: limit,
        cursor: cursor,
      );
    }
    return getRecommended(mode: mode, limit: limit, cursor: cursor);
  }

  @override
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
    String? motherTongue,
    int limit = 30,
    String? cursor,
  }) async {
    final profiles = await getExplore(
      mode: mode,
      ageMin: ageMin,
      ageMax: ageMax,
      city: city,
      religion: religion,
      education: education,
      heightMinCm: heightMinCm,
      heightMaxCm: heightMaxCm,
      diet: diet,
      bodyType: bodyType,
      maritalStatus: maritalStatus,
      motherTongue: motherTongue,
      limit: limit,
      cursor: cursor,
    );
    final nextCursor = profiles.length >= limit ? 'cursor_${profiles.length}' : null;
    return DiscoveryPageResult(profiles: profiles, nextCursor: nextCursor);
  }

  @override
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = <ProfileSummary>[];
    for (final entry in FakeData.allProfiles.entries) {
      if (list.length >= limit) break;
      final p = entry.value;
      if (ageMin != null && (p.age == null || p.age! < ageMin)) continue;
      if (ageMax != null && (p.age == null || p.age! > ageMax)) continue;
      if (city != null && city.isNotEmpty) {
        final profileCity = (p.currentCity ?? '').trim().toLowerCase();
        final filterCity = city.trim().toLowerCase();
        if (profileCity != filterCity) continue;
      }
      if (diet != null && diet.isNotEmpty) {
        final profileDiet = p.matrimonyExtensions?.diet;
        if (profileDiet == null ||
            profileDiet.toLowerCase() != diet.toLowerCase()) {
          continue;
        }
      }
      final shared = _sharedInterests(
        FakeData.myProfile.interests,
        p.interests,
      );
      list.add(
        profileToSummary(
          p,
          matchReason: FakeData.matchReasons[entry.key],
          matchReasons: FakeData.matchReasonsList[entry.key] ?? const [],
          sharedInterests: shared,
        ),
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
    String? reason,
    String? details,
    AppMode? mode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<DiscoveryPreferences> getDiscoveryPreferences() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const DiscoveryPreferences(current: {'ageMin': 21, 'ageMax': 35});
  }

  @override
  Future<List<SavedSearch>> getSavedSearches() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return List.from(_savedSearches);
  }

  @override
  Future<SavedSearch> createSavedSearch(
    Map<String, dynamic> filters, {
    String? name,
    bool notifyOnNewMatch = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final id = 'ss_${++_savedSearchIdCounter}';
    final entry = SavedSearch(
      id: id,
      name: name,
      filters: Map<String, dynamic>.from(filters),
      createdAt: DateTime.now(),
      notifyOnNewMatch: notifyOnNewMatch,
      newMatchCount: 0,
    );
    _savedSearches.add(entry);
    return entry;
  }

  @override
  Future<SavedSearch> updateSavedSearch(
    String id, {
    String? name,
    bool? notifyOnNewMatch,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _savedSearches.indexWhere((e) => e.id == id);
    if (i < 0) throw StateError('Saved search $id not found');
    final old = _savedSearches[i];
    final updated = SavedSearch(
      id: old.id,
      name: name ?? old.name,
      filters: old.filters,
      createdAt: old.createdAt,
      notifyOnNewMatch: notifyOnNewMatch ?? old.notifyOnNewMatch,
      newMatchCount: old.newMatchCount,
    );
    _savedSearches[i] = updated;
    return updated;
  }

  @override
  Future<void> deleteSavedSearch(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _savedSearches.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> markSavedSearchViewed(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _savedSearches.indexWhere((e) => e.id == id);
    if (i >= 0) {
      final old = _savedSearches[i];
      _savedSearches[i] = SavedSearch(
        id: old.id,
        name: old.name,
        filters: old.filters,
        createdAt: old.createdAt,
        notifyOnNewMatch: old.notifyOnNewMatch,
        newMatchCount: 0,
      );
    }
  }

  @override
  Future<FilterOptions> getFilterOptions() async {
    await Future.delayed(const Duration(milliseconds: 80));
    FilterOption fo(String v, [int c = 0]) => FilterOption(value: v, count: c);
    return FilterOptions(
      age: const FilterAgeRange(
        min: 18,
        max: 60,
        defaultMin: 24,
        defaultMax: 35,
        strict: false,
      ),
      cities: FilterDimension(
        options: [
          fo('Mumbai', 120), fo('Delhi', 95), fo('Bangalore', 88),
          fo('Chennai', 62), fo('Hyderabad', 55), fo('Pune', 48),
          fo('London', 34), fo('Dubai', 29), fo('New York', 22), fo('Singapore', 17),
        ],
        strict: false,
      ),
      religions: FilterDimension(
        options: [
          fo('Hindu', 310), fo('Muslim', 85), fo('Christian', 60),
          fo('Sikh', 40), fo('Jain', 30), fo('Buddhist', 20), fo('Other', 15),
        ],
        strict: false,
      ),
      education: FilterDimension(
        options: [
          fo("Bachelor's", 180), fo("Master's", 140), fo('Diploma', 55),
          fo('High School', 40), fo('Doctorate', 30),
        ],
        strict: false,
      ),
      diet: FilterDimension(
        options: [
          fo('Vegetarian', 200), fo('Non-vegetarian', 150),
          fo('Eggetarian', 60), fo('Vegan', 25),
        ],
        strict: false,
      ),
      maritalStatus: FilterDimension(
        options: [
          fo('Never married', 280), fo('Divorced', 55),
          fo('Widowed', 20), fo('Separated', 15),
        ],
        strict: false,
      ),
      motherTongue: FilterDimension(
        options: [
          fo('Hindi', 180), fo('Tamil', 90), fo('Telugu', 75),
          fo('Marathi', 65), fo('Bengali', 55), fo('Gujarati', 50),
          fo('Kannada', 40), fo('Malayalam', 35), fo('Punjabi', 30),
        ],
        strict: false,
      ),
    );
  }
}

List<String> _sharedInterests(List<String> viewer, List<String> profile) {
  final set = profile.map((s) => s.toLowerCase()).toSet();
  return viewer.where((i) => set.contains(i.toLowerCase())).toList();
}
