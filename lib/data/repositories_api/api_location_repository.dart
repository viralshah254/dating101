import '../../core/mode/app_mode.dart';
import '../../domain/models/city_option.dart';
import '../../domain/models/country_option.dart';
import '../../domain/repositories/location_repository.dart';
import '../api/api_client.dart';

class ApiLocationRepository implements LocationRepository {
  ApiLocationRepository({required this.api});
  final ApiClient api;

  static String? _discoverModeQuery(AppMode? mode) {
    if (mode == null) return null;
    return mode.isMatrimony ? 'matrimony' : 'dating';
  }

  @override
  Future<List<CityOption>> getNearbyCities({
    required double lat,
    required double lng,
    int limit = 10,
    AppMode? forDiscoveryMode,
  }) async {
    final query = <String, String>{
      'nearby': 'true',
      'limit': '$limit',
      'lat': '$lat',
      'lng': '$lng',
    };
    final dm = _discoverModeQuery(forDiscoveryMode);
    if (dm != null) {
      query['discoverCounts'] = 'true';
      query['mode'] = dm;
    }
    final body = await api.get('/location/cities', query: query);
    final list = body['cities'] as List? ?? [];
    return list
        .map((e) => _parseCity(e as Map<String, dynamic>, isNearby: true))
        .toList();
  }

  @override
  Future<List<CountryOption>> getCountries() async {
    final body = await api.get('/location/countries');
    final list = body['countries'] as List? ?? [];
    return list
        .map((e) => _parseCountry(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CityOption>> getCitiesByCountry(
    String countryCode, {
    AppMode? forDiscoveryMode,
  }) async {
    final query = <String, String>{'countryCode': countryCode};
    final dm = _discoverModeQuery(forDiscoveryMode);
    if (dm != null) {
      query['discoverCounts'] = 'true';
      query['mode'] = dm;
    }
    final body = await api.get(
      '/location/cities',
      query: query,
    );
    final list = body['cities'] as List? ?? [];
    return list
        .map((e) => _parseCity(e as Map<String, dynamic>))
        .toList();
  }

  static CityOption _parseCity(Map<String, dynamic> j, {bool isNearby = false}) {
    return CityOption(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      countryCode: j['countryCode'] as String? ?? '',
      countryName: j['countryName'] as String? ?? '',
      userCount: j['userCount'] as int? ?? 0,
      isNearby: isNearby || (j['isNearby'] as bool? ?? false),
      distanceKm: (j['distanceKm'] as num?)?.toDouble(),
    );
  }

  static CountryOption _parseCountry(Map<String, dynamic> j) {
    return CountryOption(
      code: j['code'] as String? ?? '',
      name: j['name'] as String? ?? '',
      cityCount: j['cityCount'] as int? ?? 0,
      userCount: j['userCount'] as int? ?? 0,
    );
  }
}
