import '../../domain/models/city_option.dart';
import '../../domain/models/country_option.dart';
import '../../domain/repositories/location_repository.dart';

/// Fake implementation until backend implements GET /location/cities and /location/countries.
/// Returns mock cities with user counts; only cities with active users.
class FakeLocationRepository implements LocationRepository {
  static const _nearbyCities = [
    CityOption(
      id: 'city_london_gb',
      name: 'London',
      countryCode: 'GB',
      countryName: 'United Kingdom',
      userCount: 1247,
      isNearby: true,
      distanceKm: 12,
    ),
    CityOption(
      id: 'city_manchester_gb',
      name: 'Manchester',
      countryCode: 'GB',
      countryName: 'United Kingdom',
      userCount: 342,
      isNearby: true,
      distanceKm: 45,
    ),
    CityOption(
      id: 'city_birmingham_gb',
      name: 'Birmingham',
      countryCode: 'GB',
      countryName: 'United Kingdom',
      userCount: 218,
      isNearby: true,
      distanceKm: 85,
    ),
  ];

  static const _countries = [
    CountryOption(code: 'IN', name: 'India', cityCount: 15, userCount: 8450),
    CountryOption(code: 'GB', name: 'United Kingdom', cityCount: 8, userCount: 3200),
    CountryOption(code: 'US', name: 'United States', cityCount: 12, userCount: 2100),
    CountryOption(code: 'AE', name: 'United Arab Emirates', cityCount: 3, userCount: 890),
    CountryOption(code: 'SG', name: 'Singapore', cityCount: 1, userCount: 456),
  ];

  static final _citiesByCountry = <String, List<CityOption>>{
    'IN': [
      CityOption(id: 'city_mumbai_in', name: 'Mumbai', countryCode: 'IN', countryName: 'India', userCount: 2100),
      CityOption(id: 'city_delhi_in', name: 'Delhi', countryCode: 'IN', countryName: 'India', userCount: 1800),
      CityOption(id: 'city_bangalore_in', name: 'Bangalore', countryCode: 'IN', countryName: 'India', userCount: 1200),
      CityOption(id: 'city_chennai_in', name: 'Chennai', countryCode: 'IN', countryName: 'India', userCount: 890),
      CityOption(id: 'city_hyderabad_in', name: 'Hyderabad', countryCode: 'IN', countryName: 'India', userCount: 756),
    ],
    'GB': [
      CityOption(id: 'city_london_gb', name: 'London', countryCode: 'GB', countryName: 'United Kingdom', userCount: 1247),
      CityOption(id: 'city_manchester_gb', name: 'Manchester', countryCode: 'GB', countryName: 'United Kingdom', userCount: 342),
      CityOption(id: 'city_birmingham_gb', name: 'Birmingham', countryCode: 'GB', countryName: 'United Kingdom', userCount: 218),
      CityOption(id: 'city_leeds_gb', name: 'Leeds', countryCode: 'GB', countryName: 'United Kingdom', userCount: 156),
    ],
    'US': [
      CityOption(id: 'city_newyork_us', name: 'New York', countryCode: 'US', countryName: 'United States', userCount: 890),
      CityOption(id: 'city_losangeles_us', name: 'Los Angeles', countryCode: 'US', countryName: 'United States', userCount: 456),
      CityOption(id: 'city_sanfrancisco_us', name: 'San Francisco', countryCode: 'US', countryName: 'United States', userCount: 312),
    ],
    'AE': [
      CityOption(id: 'city_dubai_ae', name: 'Dubai', countryCode: 'AE', countryName: 'United Arab Emirates', userCount: 678),
      CityOption(id: 'city_abu_dhabi_ae', name: 'Abu Dhabi', countryCode: 'AE', countryName: 'United Arab Emirates', userCount: 212),
    ],
    'SG': [
      CityOption(id: 'city_singapore_sg', name: 'Singapore', countryCode: 'SG', countryName: 'Singapore', userCount: 456),
    ],
  };

  @override
  Future<List<CityOption>> getNearbyCities({
    required double lat,
    required double lng,
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _nearbyCities.take(limit).toList();
  }

  @override
  Future<List<CountryOption>> getCountries() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _countries;
  }

  @override
  Future<List<CityOption>> getCitiesByCountry(String countryCode) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _citiesByCountry[countryCode] ?? [];
  }
}
