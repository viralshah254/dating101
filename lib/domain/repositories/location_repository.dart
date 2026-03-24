import '../../core/mode/app_mode.dart';
import '../models/city_option.dart';
import '../models/country_option.dart';

/// Location and city/country data for discovery filters.
/// See docs/BACKEND_LOCATION_AND_GEOLOCATION.md for API spec.
abstract class LocationRepository {
  /// Nearby cities with active users, sorted by distance.
  /// Requires user's fuzzed location. Returns empty if no location.
  ///
  /// When [forDiscoveryMode] is set, [CityOption.userCount] matches what
  /// [GET /discovery/explore?city=…] would return for that mode (your prefs, blocks, etc.).
  Future<List<CityOption>> getNearbyCities({
    required double lat,
    required double lng,
    int limit = 10,
    AppMode? forDiscoveryMode,
  });

  /// Countries with at least one city that has active users.
  Future<List<CountryOption>> getCountries();

  /// Cities in a country with active users, sorted by user count.
  ///
  /// When [forDiscoveryMode] is set, counts are aligned with explore for that mode.
  Future<List<CityOption>> getCitiesByCountry(
    String countryCode, {
    AppMode? forDiscoveryMode,
  });
}
