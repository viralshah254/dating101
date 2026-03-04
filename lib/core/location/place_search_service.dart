import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place suggestion from search (city, state, country).
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.displayName,
    required this.country,
    this.countryCode,
    this.state,
    this.city,
  });

  final String displayName;
  final String country;
  final String? countryCode;
  final String? state;
  final String? city;

  /// True if this place is in India (for currency: INR).
  bool get isIndia =>
      countryCode?.toLowerCase() == 'in' ||
      country.toLowerCase().contains('india');
}

/// Search for cities, states, and countries worldwide (India-focused).
/// Uses Nominatim (OpenStreetMap) - no API key required.
class PlaceSearchService {
  PlaceSearchService._();
  static const _base = 'https://nominatim.openstreetmap.org/search';
  static const _userAgent = 'Shubhmilan/1.0 (matrimony app)';

  static Future<List<PlaceSuggestion>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'q': q,
        'format': 'json',
        'addressdetails': '1',
        'limit': '12',
      },
    );
    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final list = json.decode(response.body) as List<dynamic>?;
      if (list == null) return [];
      final out = <PlaceSuggestion>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final addr = e['address'] as Map<String, dynamic>?;
        final country = addr?['country'] as String? ?? '';
        final countryCode = addr?['country_code'] as String?;
        final state =
            addr?['state'] as String? ?? addr?['state_district'] as String?;
        final city =
            addr?['city'] as String? ??
            addr?['town'] as String? ??
            addr?['village'] as String?;
        final displayName = e['display_name'] as String? ?? '';
        if (displayName.isEmpty) continue;
        out.add(
          PlaceSuggestion(
            displayName: displayName,
            country: country,
            countryCode: countryCode,
            state: state,
            city: city,
          ),
        );
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Search with India results first (bias by adding India to query when no country in query).
  static Future<List<PlaceSuggestion>> searchWithIndiaBias(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    // If query doesn't look like a country name, try with India to get Indian cities first
    final results = await search(q);
    if (results.isEmpty) return [];
    // Sort: India first, then others
    final sorted = List<PlaceSuggestion>.from(results)
      ..sort((a, b) {
        if (a.isIndia && !b.isIndia) return -1;
        if (!a.isIndia && b.isIndia) return 1;
        return 0;
      });
    return sorted;
  }
}
