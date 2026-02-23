import '../../core/mode/app_mode.dart';
import '../../domain/models/profile_summary.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeDiscoveryRepository implements DiscoveryRepository {
  FakeDiscoveryRepository(this._profileRepo);

  final ProfileRepository _profileRepo;

  @override
  Future<List<ProfileSummary>> getRecommended({
    required AppMode mode,
    String? city,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = <ProfileSummary>[];
    final ids = FakeData.allProfiles.keys.toList();
    for (var i = 0; i < ids.length && list.length < limit; i++) {
      final id = ids[i];
      final p = FakeData.allProfiles[id]!;
      final distanceKm = (i + 1) * 2.0;
      final reason = FakeData.matchReasons[id];
      list.add(profileToSummary(p, distanceKm: distanceKm, matchReason: reason));
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = <ProfileSummary>[];
    for (final entry in FakeData.allProfiles.entries) {
      if (list.length >= limit) break;
      final p = entry.value;
      if (ageMin != null && (p.age == null || p.age! < ageMin)) continue;
      if (ageMax != null && (p.age == null || p.age! > ageMax)) continue;
      if (city != null && !(p.currentCity ?? '').toLowerCase().contains(city.toLowerCase())) continue;
      list.add(profileToSummary(p, matchReason: FakeData.matchReasons[entry.key]));
    }
    return list;
  }

  @override
  Future<List<ProfileSummary>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return getRecommended(mode: AppMode.dating, limit: limit);
  }
}
