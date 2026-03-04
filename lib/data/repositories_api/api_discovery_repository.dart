import 'package:flutter/foundation.dart';

import '../../core/mode/app_mode.dart';
import '../../domain/models/filter_options.dart';
import '../../domain/models/profile_summary.dart';
import '../../domain/models/saved_search.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

class ApiDiscoveryRepository implements DiscoveryRepository {
  ApiDiscoveryRepository({required this.api});
  final ApiClient api;

  @override
  Future<List<ProfileSummary>> getRecommended({
    required AppMode mode,
    String? city,
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, String>{
      'mode': mode.isMatrimony ? 'matrimony' : 'dating',
      'limit': '$limit',
    };
    if (city != null) query['city'] = city;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final body = await api.get('/discovery/recommended', query: query);
    return _parseProfiles(body);
  }

  @override
  Future<DiscoveryPageResult> getRecommendedPage({
    required AppMode mode,
    String? city,
    int limit = 30,
    String? cursor,
  }) async {
    final query = <String, String>{
      'mode': mode.isMatrimony ? 'matrimony' : 'dating',
      'limit': '$limit',
    };
    if (city != null) query['city'] = city;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    final body = await api.get('/discovery/recommended', query: query);
    return _parsePage(body);
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
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, String>{
      'mode': mode.isMatrimony ? 'matrimony' : 'dating',
      'limit': '$limit',
    };
    if (ageMin != null) query['ageMin'] = '$ageMin';
    if (ageMax != null) query['ageMax'] = '$ageMax';
    if (city != null && city.isNotEmpty) query['city'] = city;
    if (religion != null && religion.isNotEmpty) query['religion'] = religion;
    if (education != null && education.isNotEmpty) {
      query['education'] = education;
    }
    if (heightMinCm != null) query['heightMinCm'] = '$heightMinCm';
    if (heightMaxCm != null) query['heightMaxCm'] = '$heightMaxCm';
    if (diet != null && diet.isNotEmpty) query['diet'] = diet;
    if (bodyType != null && bodyType.isNotEmpty) query['bodyType'] = bodyType;
    if (maritalStatus != null && maritalStatus.isNotEmpty)
      query['maritalStatus'] = maritalStatus;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final body = await api.get('/discovery/explore', query: query);
    return _parseProfiles(body);
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
    int limit = 30,
    String? cursor,
  }) async {
    final query = <String, String>{
      'mode': mode.isMatrimony ? 'matrimony' : 'dating',
      'limit': '$limit',
    };
    if (ageMin != null) query['ageMin'] = '$ageMin';
    if (ageMax != null) query['ageMax'] = '$ageMax';
    if (city != null && city.isNotEmpty) query['city'] = city;
    if (religion != null && religion.isNotEmpty) query['religion'] = religion;
    if (education != null && education.isNotEmpty) {
      query['education'] = education;
    }
    if (heightMinCm != null) query['heightMinCm'] = '$heightMinCm';
    if (heightMaxCm != null) query['heightMaxCm'] = '$heightMaxCm';
    if (diet != null && diet.isNotEmpty) query['diet'] = diet;
    if (bodyType != null && bodyType.isNotEmpty) query['bodyType'] = bodyType;
    if (maritalStatus != null && maritalStatus.isNotEmpty)
      query['maritalStatus'] = maritalStatus;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    final body = await api.get('/discovery/explore', query: query);
    return _parsePage(body);
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
    final query = <String, String>{'limit': '$limit'};
    if (ageMin != null) query['ageMin'] = '$ageMin';
    if (ageMax != null) query['ageMax'] = '$ageMax';
    if (city != null) query['city'] = city;
    if (religion != null) query['religion'] = religion;
    if (education != null) query['education'] = education;
    if (heightMinCm != null) query['heightMinCm'] = '$heightMinCm';
    if (diet != null && diet.isNotEmpty) query['diet'] = diet;
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final body = await api.get('/discovery/search', query: query);
    return _parseProfiles(body);
  }

  @override
  Future<List<ProfileSummary>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 50,
    String? cursor,
  }) async {
    final query = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
      'radiusKm': '$radiusKm',
      'limit': '$limit',
    };
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;

    final body = await api.get('/discovery/nearby', query: query);
    return _parseProfiles(body);
  }

  @override
  Future<CompatibilityDetail> getCompatibility(String candidateId) async {
    debugPrint('[Discovery] getCompatibility($candidateId)');
    final body = await api.get('/discovery/compatibility/$candidateId');
    final breakdown = (body['breakdown'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final alignment =
        (body['preferenceAlignment'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v as String),
        );
    return CompatibilityDetail(
      candidateId: body['candidateId'] as String? ?? candidateId,
      compatibilityScore: (body['compatibilityScore'] as num?)?.toDouble() ?? 0,
      compatibilityLabel: body['compatibilityLabel'] as String? ?? '',
      matchReasons: (body['matchReasons'] as List?)?.cast<String>() ?? [],
      breakdown: breakdown,
      preferenceAlignment: alignment,
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
  }) async {
    debugPrint(
      '[Discovery] sendFeedback($candidateId, $action, reason: $reason)',
    );
    final payload = <String, dynamic>{
      'candidateId': candidateId,
      'action': action,
    };
    if (timeSpentMs != null) payload['timeSpentMs'] = timeSpentMs;
    if (source != null) payload['source'] = source;
    if (reason != null) payload['reason'] = reason;
    if (details != null) payload['details'] = details;
    await api.post('/discovery/feedback', body: payload);
  }

  @override
  Future<DiscoveryPreferences> getDiscoveryPreferences() async {
    debugPrint('[Discovery] getDiscoveryPreferences()');
    final body = await api.get('/discovery/preferences');
    final current = body['current'] as Map<String, dynamic>? ?? {};
    final suggestions =
        (body['suggestions'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    return DiscoveryPreferences(current: current, suggestions: suggestions);
  }

  @override
  Future<FilterOptions> getFilterOptions() async {
    debugPrint('[Discovery] getFilterOptions()');
    final body = await api.get('/discovery/filter-options');
    return _parseFilterOptions(body);
  }

  @override
  Future<List<SavedSearch>> getSavedSearches() async {
    final body = await api.get('/discovery/saved-searches');
    final list = body['savedSearches'] as List? ?? [];
    return list
        .map((e) => _parseSavedSearch(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavedSearch> createSavedSearch(
    Map<String, dynamic> filters, {
    String? name,
    bool notifyOnNewMatch = true,
  }) async {
    final payload = <String, dynamic>{
      'filters': filters,
      'notifyOnNewMatch': notifyOnNewMatch,
    };
    if (name != null && name.isNotEmpty) payload['name'] = name;
    final body = await api.post('/discovery/saved-searches', body: payload);
    return _parseSavedSearch(body);
  }

  @override
  Future<SavedSearch> updateSavedSearch(
    String id, {
    String? name,
    bool? notifyOnNewMatch,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (notifyOnNewMatch != null)
      payload['notifyOnNewMatch'] = notifyOnNewMatch;
    if (payload.isEmpty) {
      final body = await api.get('/discovery/saved-searches');
      final list = (body['savedSearches'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .where((e) => e['id'] == id);
      if (list.isEmpty) throw StateError('Saved search $id not found');
      return _parseSavedSearch(list.first);
    }
    final body = await api.patch(
      '/discovery/saved-searches/$id',
      body: payload,
    );
    return _parseSavedSearch(body);
  }

  @override
  Future<void> deleteSavedSearch(String id) async {
    await api.delete('/discovery/saved-searches/$id');
  }

  @override
  Future<void> markSavedSearchViewed(String id) async {
    await api.post('/discovery/saved-searches/$id/viewed');
  }

  static SavedSearch _parseSavedSearch(Map<String, dynamic> j) {
    final filters = j['filters'] as Map<String, dynamic>? ?? {};
    DateTime? createdAt;
    final createdStr = j['createdAt'] as String?;
    if (createdStr != null) createdAt = DateTime.tryParse(createdStr);
    return SavedSearch(
      id: j['id'] as String? ?? '',
      name: j['name'] as String?,
      filters: Map<String, dynamic>.from(filters),
      createdAt: createdAt,
      notifyOnNewMatch: j['notifyOnNewMatch'] as bool? ?? true,
      newMatchCount: j['newMatchCount'] as int? ?? 0,
    );
  }

  static FilterOptions _parseFilterOptions(Map<String, dynamic> j) {
    // Support both shapes: (1) defaults + options (§4.4 API ref), (2) age/cities/religions/education (strict-preferences)
    final defaults = j['defaults'] as Map<String, dynamic>?;
    final options = j['options'] as Map<String, dynamic>?;
    if (defaults != null && options != null) {
      final ageMin = defaults['ageMin'] as int? ?? 21;
      final ageMax = defaults['ageMax'] as int? ?? 45;
      final defaultCity = defaults['city'] as String?;
      final defaultReligion = defaults['religion'] as String?;
      final defaultEducation = defaults['education'] as String?;
      return FilterOptions(
        age: FilterAgeRange(
          min: 18,
          max: 60,
          defaultMin: ageMin,
          defaultMax: ageMax,
          strict: false,
        ),
        cities: FilterDimension(
          options: (options['cities'] as List?)?.cast<String>() ?? [],
          strict: false,
          defaultSelected: defaultCity,
        ),
        religions: FilterDimension(
          options: (options['religions'] as List?)?.cast<String>() ?? [],
          strict: false,
          defaultSelected: defaultReligion,
        ),
        education: FilterDimension(
          options: (options['educationLevels'] as List?)?.cast<String>() ?? [],
          strict: false,
          defaultSelected: defaultEducation,
        ),
        height: null,
        diet: null,
        maritalStatus:
            (options['maritalStatuses'] as List?)?.cast<String>().isNotEmpty ==
                true
            ? FilterDimension(
                options: (options['maritalStatuses'] as List?)!.cast<String>(),
                strict: false,
              )
            : null,
      );
    }
    final ageMap = j['age'] as Map<String, dynamic>? ?? {};
    final citiesMap = j['cities'] as Map<String, dynamic>? ?? {};
    final religionsMap = j['religions'] as Map<String, dynamic>? ?? {};
    final educationMap = j['education'] as Map<String, dynamic>? ?? {};
    return FilterOptions(
      age: FilterAgeRange(
        min: ageMap['min'] as int? ?? 18,
        max: ageMap['max'] as int? ?? 60,
        defaultMin: ageMap['defaultMin'] as int? ?? 21,
        defaultMax: ageMap['defaultMax'] as int? ?? 45,
        strict: ageMap['strict'] as bool? ?? false,
      ),
      cities: _parseDimension(citiesMap),
      religions: _parseDimension(religionsMap),
      education: _parseDimension(educationMap),
      height: _parseHeight(j['height'] as Map<String, dynamic>?),
      diet: _parseDimensionOpt(j['diet'] as Map<String, dynamic>?),
      maritalStatus: _parseDimensionOpt(
        j['maritalStatus'] as Map<String, dynamic>?,
      ),
    );
  }

  static FilterDimension _parseDimension(Map<String, dynamic> m) {
    return FilterDimension(
      options: (m['options'] as List?)?.cast<String>() ?? [],
      strict: m['strict'] as bool? ?? false,
      defaultSelected: m['defaultSelected'] as String?,
    );
  }

  static FilterDimension? _parseDimensionOpt(Map<String, dynamic>? m) {
    if (m == null) return null;
    return _parseDimension(m);
  }

  static FilterHeightRange? _parseHeight(Map<String, dynamic>? m) {
    if (m == null) return null;
    return FilterHeightRange(
      minCm: m['minCm'] as int? ?? 140,
      maxCm: m['maxCm'] as int? ?? 220,
      defaultMinCm: m['defaultMinCm'] as int?,
      defaultMaxCm: m['defaultMaxCm'] as int?,
      strict: m['strict'] as bool? ?? false,
    );
  }

  static List<ProfileSummary> _parseProfiles(Map<String, dynamic> body) {
    final result = _parsePage(body);
    return result.profiles;
  }

  static DiscoveryPageResult _parsePage(Map<String, dynamic> body) {
    final list = body['profiles'] as List? ?? [];
    if (list.isEmpty && body.containsKey('count')) {
      debugPrint(
        '[Discovery] Backend returned {"count": ...} but no "profiles" array. '
        'GET /discovery/recommended and GET /discovery/explore must return {"profiles": [...], "nextCursor": "..."}.',
      );
    }
    final profiles = list.map((e) {
      final map = e as Map<String, dynamic>;
      final profileMap = map['profile'] is Map<String, dynamic>
          ? map['profile'] as Map<String, dynamic>
          : map;
      return ApiProfileRepository.parseSummaryPublic(profileMap);
    }).toList();
    final nextCursor = body['nextCursor'] as String?;
    return DiscoveryPageResult(profiles: profiles, nextCursor: nextCursor);
  }
}
