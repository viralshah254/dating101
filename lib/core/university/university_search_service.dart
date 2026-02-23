import 'dart:convert';

import 'package:http/http.dart' as http;

/// One university from the Hipo Labs API (free, no key).
class UniversitySuggestion {
  const UniversitySuggestion({
    required this.name,
    required this.country,
    this.stateProvince,
  });

  final String name;
  final String country;
  final String? stateProvince;

  String get displayName =>
      stateProvince != null && stateProvince!.isNotEmpty
          ? '$name, $stateProvince, $country'
          : '$name, $country';
}

/// Free university search via Hipo Labs API.
/// https://github.com/Hipo/university-domains-list
class UniversitySearchService {
  UniversitySearchService._();
  static const _base = 'http://universities.hipolabs.com/search';

  static final UniversitySearchService instance = UniversitySearchService._();

  Future<List<UniversitySuggestion>> search(String query) async {
    if (query.trim().length < 2) return [];
    final encoded = Uri.encodeQueryComponent(query.trim());
    try {
      final response = await http
          .get(Uri.parse('$_base?name=$encoded'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final list = json.decode(response.body) as List<dynamic>?;
      if (list == null) return [];
      final results = <UniversitySuggestion>[];
      for (final e in list.take(20)) {
        if (e is! Map<String, dynamic>) continue;
        final name = e['name'] as String?;
        final country = e['country'] as String?;
        if (name == null || name.isEmpty) continue;
        results.add(UniversitySuggestion(
          name: name,
          country: country ?? 'Unknown',
          stateProvince: e['state-province'] as String?,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }
}
