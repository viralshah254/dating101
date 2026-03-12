import '../models/city_option.dart';
import '../models/country_option.dart';

/// Location and city/country data for discovery filters.
/// See docs/BACKEND_LOCATION_AND_GEOLOCATION.md for API spec.
abstract class LocationRepository {
  /// Nearby cities with active users, sorted by distance.
  /// Requires user's fuzzed location. Returns empty if no location.
  Future<List<CityOption>> getNearbyCities({
    required double lat,
    required double lng,
    int limit = 10,
  });

  /// Countries with at least one city that has active users.
  Future<List<CountryOption>> getCountries();

  /// Cities in a country with active users, sorted by user count.
  Future<List<CityOption>> getCitiesByCountry(String countryCode);
}
