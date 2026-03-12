import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/dating_extensions.dart';
import '../../domain/models/discovery_preferences.dart';
import '../../domain/models/family_details.dart';
import '../../domain/models/matrimony_extensions.dart';
import '../../domain/models/partner_preferences.dart';
import '../../domain/models/profile_summary.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/verification_status.dart';
import '../../domain/repositories/profile_repository.dart';
import '../api/api_client.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({required this.api});
  final ApiClient api;

  UserProfile? _cached;
  final _controller = StreamController<UserProfile?>.broadcast();

  @override
  Future<UserProfile?> getMyProfile() async {
    try {
      final body = await api.get('/profile/me');
      _cached = _parseProfile(body);
      _controller.add(_cached);
      return _cached;
    } on ApiException catch (e) {
      if (e.code == 'PROFILE_NOT_FOUND') return null;
      rethrow;
    }
  }

  @override
  Stream<UserProfile?> watchMyProfile() {
    getMyProfile();
    return _controller.stream;
  }

  @override
  Future<UserProfile> createMyProfile(UserProfile profile) async {
    debugPrint('[Profile] Creating profile (PUT /profile/me)...');
    final json = _profileToJson(profile);
    debugPrint('[Profile] Payload keys: ${json.keys.toList()}');
    final body = await api.put('/profile/me', body: json);
    _cached = _parseProfile(body);
    _controller.add(_cached);
    debugPrint(
      '[Profile] Profile created ✓ id=${_cached!.id}, name=${_cached!.name}',
    );
    return _cached!;
  }

  @override
  Future<UserProfile> updateMyProfile(UserProfile profile) async {
    debugPrint('[Profile] Updating profile...');
    final body = await api.patch('/profile/me', body: _profileToJson(profile));
    _cached = _parseProfile(body);
    _controller.add(_cached);
    debugPrint('[Profile] Profile updated ✓');
    return _cached!;
  }

  @override
  Future<void> saveProfileJson(
    Map<String, dynamic> json, {
    bool create = false,
  }) async {
    debugPrint(
      '[Profile] saveProfileJson (create=$create) keys=${json.keys.toList()}',
    );
    if (create) {
      final body = await api.put('/profile/me', body: json);
      _cached = _parseProfile(body);
    } else {
      final body = await api.patch('/profile/me', body: json);
      _cached = _parseProfile(body);
    }
    _controller.add(_cached);
    debugPrint('[Profile] saveProfileJson ✓ name=${_cached?.name}');
  }

  @override
  Future<PartnerPreferences?> getMyPartnerPreferences() async {
    try {
      final body = await api.get('/profile/me/preferences');
      return _parsePreferences(body);
    } on ApiException {
      return null;
    }
  }

  @override
  Future<PartnerPreferences> updatePartnerPreferences(
    PartnerPreferences prefs,
  ) async {
    final body = await api.put(
      '/profile/me/preferences',
      body: _prefsToJson(prefs),
    );
    return _parsePreferences(body);
  }

  @override
  Future<ProfileSummary?> getProfileSummary(String userId) async {
    try {
      final body = await api.get('/profile/$userId/summary');
      return _parseSummary(body);
    } on ApiException {
      return null;
    }
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final body = await api.get('/profile/$userId');
      try {
        return _parseProfile(body);
      } catch (e, st) {
        debugPrint('[Profile] Parse error for /profile/$userId: $e');
        debugPrint('$st');
        return _minimalProfileFromMap(body);
      }
    } on ApiException {
      return null;
    }
  }

  /// Build a minimal profile so the screen can open even when full parse fails.
  static UserProfile _minimalProfileFromMap(Map<String, dynamic> j) {
    final photosHidden = _safeBool(j['photosHidden'], false);
    final canViewPhotos = j['canViewPhotos'] as bool?;
    final rawUrls = _strList(
      j['photoUrls'],
    ).where((u) => !u.contains('/seed/')).toList();
    final photoUrls = (photosHidden && canViewPhotos != true)
        ? <String>[]
        : rawUrls;
    return UserProfile(
      id: (j['id'] as String?) ?? '',
      name: (j['name'] as String?) ?? 'Unknown',
      gender: j['gender'] as String?,
      age: _safeInt(j['age']),
      dateOfBirth: j['dateOfBirth'] as String?,
      currentCity: j['currentCity'] as String?,
      currentCountry: j['currentCountry'] as String?,
      originCity: j['originCity'] as String?,
      originCountry: j['originCountry'] as String?,
      languagesSpoken: _strList(j['languagesSpoken']),
      motherTongue: j['motherTongue'] as String?,
      photoUrls: photoUrls,
      photosHidden: photosHidden,
      canViewPhotos: canViewPhotos,
      aboutMe: (j['aboutMe'] as String?) ?? '',
      interests: _strList(j['interests']),
      verificationStatus: const VerificationStatus(),
      profileCompleteness: 0.0,
      privacySettings: null,
      datingExtensions: null,
      matrimonyExtensions: null,
      partnerPreferences: null,
      lastActiveAt: null,
      creationLat: null,
      creationLng: null,
      creationAt: null,
      creationAddress: null,
    );
  }

  @override
  double computeCompleteness(UserProfile profile) {
    int filled = 0;
    int total = 0;

    void check(Object? value) {
      total++;
      if (value != null) {
        if (value is String && value.isEmpty) return;
        if (value is List && value.isEmpty) return;
        filled++;
      }
    }

    check(profile.name);
    check(profile.gender);
    check(profile.dateOfBirth);
    check(profile.currentCity);
    check(profile.motherTongue);
    check(profile.photoUrls.isNotEmpty ? profile.photoUrls : null);
    check(profile.aboutMe.isNotEmpty ? profile.aboutMe : null);
    check(profile.interests.isNotEmpty ? profile.interests : null);

    if (profile.matrimonyExtensions != null) {
      final m = profile.matrimonyExtensions!;
      check(m.religion);
      check(m.maritalStatus);
      check(m.educationDegree);
      check(m.occupation);
      check(m.heightCm);
    }

    return total == 0 ? 0 : filled / total;
  }

  // ── JSON parsing ─────────────────────────────────────────────────────

  static UserProfile _parseProfile(Map<String, dynamic> j) {
    final photosHidden = j['photosHidden'] as bool? ?? false;
    final canViewPhotos = j['canViewPhotos'] as bool?;
    // When owner has hidden photos and viewer is not allowed, never expose photoUrls.
    final rawUrls = _strList(
      j['photoUrls'],
    ).where((u) => !u.contains('/seed/')).toList();
    final photoUrls = (photosHidden && canViewPhotos != true)
        ? <String>[]
        : rawUrls;

    VerificationStatus verificationStatus = const VerificationStatus();
    if (j['verificationStatus'] is Map<String, dynamic>) {
      try {
        verificationStatus = _parseVerification(
          j['verificationStatus'] as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return UserProfile(
      id: (j['id'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      gender: j['gender'] as String?,
      age: _safeInt(j['age']),
      dateOfBirth: j['dateOfBirth'] as String?,
      currentCity: j['currentCity'] as String?,
      currentCountry: j['currentCountry'] as String?,
      originCity: j['originCity'] as String?,
      originCountry: j['originCountry'] as String?,
      languagesSpoken: _strList(j['languagesSpoken']),
      motherTongue: j['motherTongue'] as String?,
      photoUrls: photoUrls,
      photosHidden: photosHidden,
      canViewPhotos: canViewPhotos,
      aboutMe: (j['aboutMe'] as String?) ?? '',
      interests: _strList(j['interests']),
      verificationStatus: verificationStatus,
      profileCompleteness: (j['profileCompleteness'] is num)
          ? (j['profileCompleteness'] as num).toDouble()
          : 0.0,
      privacySettings: _safePrivacySettings(j['privacySettings']),
      datingExtensions: j['datingExtensions'] is Map<String, dynamic>
          ? _parseDating(j['datingExtensions'] as Map<String, dynamic>)
          : null,
      matrimonyExtensions: j['matrimonyExtensions'] is Map<String, dynamic>
          ? _parseMatrimony(j['matrimonyExtensions'] as Map<String, dynamic>)
          : null,
      partnerPreferences: j['partnerPreferences'] is Map<String, dynamic>
          ? _parsePreferences(j['partnerPreferences'] as Map<String, dynamic>)
          : null,
      lastActiveAt: j['lastActiveAt'] != null
          ? DateTime.tryParse(j['lastActiveAt'] as String)
          : null,
      isPremium: _safeBool(j['isPremium'], false),
      creationLat: (j['creationLat'] as num?)?.toDouble(),
      creationLng: (j['creationLng'] as num?)?.toDouble(),
      creationAt: j['creationAt'] != null
          ? DateTime.tryParse(j['creationAt'] as String)
          : null,
      creationAddress: j['creationAddress'] as String?,
    );
  }

  static VerificationStatus _parseVerification(Map<String, dynamic> j) {
    return VerificationStatus(
      photoVerified: j['photoVerified'] as bool? ?? false,
      idVerified: j['idVerified'] as bool? ?? false,
      emailVerified: j['emailVerified'] as bool? ?? false,
      phoneVerified: j['phoneVerified'] as bool? ?? false,
      linkedInVerified: j['linkedInVerified'] as bool? ?? false,
      educationVerified: j['educationVerified'] as bool? ?? false,
      score: (j['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static DatingExtensions _parseDating(Map<String, dynamic> j) {
    return DatingExtensions(
      datingIntent: j['datingIntent'] as String?,
      prompts: (j['prompts'] as List?)?.map((p) {
        final m = p as Map<String, dynamic>;
        return PromptAnswer(
          questionId: m['questionId'] as String? ?? '',
          questionText: m['questionText'] as String? ?? '',
          answer: m['answer'] as String? ?? '',
        );
      }).toList(),
      voiceIntroUrl: j['voiceIntroUrl'] as String?,
      travelModeEnabled: j['travelModeEnabled'] as bool? ?? false,
      discoveryPreferences: j['discoveryPreferences'] != null
          ? DiscoveryPreferences(
              ageMin: j['discoveryPreferences']['ageMin'] as int? ?? 18,
              ageMax: j['discoveryPreferences']['ageMax'] as int? ?? 99,
              maxDistanceKm:
                  (j['discoveryPreferences']['maxDistanceKm'] as num?)
                      ?.toDouble() ??
                  50,
              preferredCities: _strList(
                j['discoveryPreferences']['preferredCities'],
              ),
              travelModeEnabled:
                  j['discoveryPreferences']['travelModeEnabled'] as bool? ??
                  false,
            )
          : null,
    );
  }

  static MatrimonyExtensions _parseMatrimony(Map<String, dynamic> j) {
    final roleStr =
        _roleString(j['roleManagingProfile']) ?? _roleString(j['managedBy']);
    final roleManagingProfile = _parseProfileRole(roleStr) ?? ProfileRole.self;
    return MatrimonyExtensions(
      roleManagingProfile: roleManagingProfile,
      religion: j['religion'] as String?,
      casteOrCommunity: j['casteOrCommunity'] as String?,
      motherTongue: j['motherTongue'] as String?,
      maritalStatus: j['maritalStatus'] as String?,
      heightCm: _safeInt(j['heightCm']),
      bodyType: j['bodyType'] as String?,
      complexion: j['complexion'] as String?,
      educationDegree: j['educationDegree'] as String?,
      educationInstitution: j['educationInstitution'] as String?,
      occupation: j['occupation'] as String?,
      employer: j['employer'] as String?,
      industry: j['industry'] as String?,
      incomeRange: j['incomeRange'] is Map
          ? IncomeRange(
              minLabel: (j['incomeRange'] as Map)['minLabel'] as String?,
              maxLabel: (j['incomeRange'] as Map)['maxLabel'] as String?,
              currency: (j['incomeRange'] as Map)['currency'] as String?,
            )
          : null,
      familyDetails: j['familyDetails'] is Map<String, dynamic>
          ? _parseFamilyDetails(j['familyDetails'] as Map<String, dynamic>)
          : null,
      diet: j['diet'] as String?,
      drinking: j['drinking'] as String?,
      smoking: j['smoking'] as String?,
      exercise: j['exercise'] as String?,
      aboutEducation: j['aboutEducation'] as String?,
      educationEntries: _parseEducationEntries(j['educationEntries']),
      horoscope: j['horoscope'] is Map
          ? HoroscopeDetails(
              dateOfBirth: (j['horoscope'] as Map)['dateOfBirth'] as String?,
              timeOfBirth: (j['horoscope'] as Map)['timeOfBirth'] as String?,
              birthPlace: (j['horoscope'] as Map)['birthPlace'] as String?,
              manglik: (j['horoscope'] as Map)['manglik'] as String?,
              rashi: (j['horoscope'] as Map)['rashi'] as String?,
              nakshatra: (j['horoscope'] as Map)['nakshatra'] as String?,
              gotra: (j['horoscope'] as Map)['gotra'] as String?,
              horoscopeDocUrl:
                  (j['horoscope'] as Map)['horoscopeDocUrl'] as String?,
            )
          : null,
    );
  }

  static List<EducationEntryDto>? _parseEducationEntries(dynamic value) {
    if (value is! List || value.isEmpty) return null;
    final list = <EducationEntryDto>[];
    for (final e in value) {
      if (e is! Map<String, dynamic>) continue;
      final year = e['graduationYear'];
      list.add(
        EducationEntryDto(
          degree: e['degree'] as String?,
          institution: e['institution'] as String?,
          graduationYear: year is int
              ? year
              : (year is num ? year.toInt() : null),
          scoreCountry: e['scoreCountry'] as String?,
          scoreType: e['scoreType'] as String?,
        ),
      );
    }
    return list.isEmpty ? null : list;
  }

  static FamilyDetails _parseFamilyDetails(Map<String, dynamic> j) {
    return FamilyDetails(
      familyType: j['familyType'] as String?,
      familyValues: j['familyValues'] as String?,
      familyLocation: j['familyLocation'] as String?,
      familyBasedOutOfCountry: j['familyBasedOutOfCountry'] as String?,
      householdIncome: j['householdIncome'] as String?,
      fatherOccupation: j['fatherOccupation'] as String?,
      motherOccupation: j['motherOccupation'] as String?,
      fatherAge: j['fatherAge']?.toString(),
      motherAge: j['motherAge']?.toString(),
      siblingsCount: _safeInt(j['siblingsCount']),
      siblingsMarried: _safeInt(j['siblingsMarried']),
      brothers: j['brothers'] as String?,
      sisters: j['sisters'] as String?,
      familyExpectations: j['familyExpectations'] as String?,
    );
  }

  static PartnerPreferences _parsePreferences(Map<String, dynamic> j) {
    return PartnerPreferences(
      genderPreference: j['genderPreference'] as String?,
      ageMin: _safeInt(j['ageMin']) ?? 21,
      ageMax: _safeInt(j['ageMax']) ?? 45,
      heightMinCm: _safeInt(j['heightMinCm']),
      heightMaxCm: _safeInt(j['heightMaxCm']),
      preferredLocations: _strList(j['preferredLocations']),
      preferredReligions: _strList(j['preferredReligions']),
      preferredCommunities: _strList(j['preferredCommunities']),
      preferredMotherTongues: _strList(j['preferredMotherTongues']),
      educationPreference: j['educationPreference'] as String?,
      occupationPreference: j['occupationPreference'] as String?,
      maritalStatusPreference: _strList(j['maritalStatusPreference']),
      dietPreference: j['dietPreference'] as String?,
      incomePreference: j['incomePreference'] as String?,
      preferredBodyTypes: _strList(j['preferredBodyTypes']),
      drinkingPreference: j['drinkingPreference'] as String?,
      smokingPreference: j['smokingPreference'] as String?,
      settledAbroadPreference: j['settledAbroadPreference'] as String?,
      preferredCountries: _strList(j['preferredCountries']),
      cityPreferenceMode: j['cityPreferenceMode'] as String?,
      distanceMaxKm: (j['distanceMaxKm'] as num?)?.toDouble(),
      horoscopeMatchPreferred: j['horoscopeMatchPreferred'] as bool?,
      strictFilters: j['strictFilters'] is Map<String, dynamic>
          ? (j['strictFilters'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v == true),
            )
          : null,
    );
  }

  /// Public for reuse by other API repos (discovery, shortlist, etc.).
  static ProfileSummary parseSummaryPublic(Map<String, dynamic> j) =>
      _parseSummary(j);

  /// URLs that often return 403 from CloudFront; treat as no image to avoid exceptions.
  static String? _sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.contains('/seed/')) return null;
    if (url.contains('daeidwfwa5d0x.cloudfront.net')) return null;
    return url;
  }

  /// Public for other repos that set imageUrl from API (e.g. shortlist).
  static String? sanitizeImageUrl(String? url) => _sanitizeImageUrl(url);

  static List<String>? _parseImageUrls(dynamic v) {
    if (v == null || v is! List) return null;
    final raw = v;
    final list = raw
        .map((e) => _sanitizeImageUrl(e is String ? e : e?.toString()))
        .whereType<String>()
        .toList();
    return list.isEmpty ? null : list;
  }

  static String? _roleString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map && v['value'] != null) return v['value'].toString();
    return v.toString();
  }

  static ProfileRole? _parseProfileRole(String? s) {
    if (s == null || s.isEmpty) return null;
    switch (s.toLowerCase()) {
      case 'parent':
        return ProfileRole.parent;
      case 'guardian':
        return ProfileRole.guardian;
      case 'sibling':
        return ProfileRole.sibling;
      case 'friend':
        return ProfileRole.friend;
      case 'self':
      default:
        return null; // treat self as null so we don't show "Managed by self"
    }
  }

  static ProfileSummary _parseSummary(Map<String, dynamic> j) {
    Map<String, double>? breakdown;
    if (j['breakdown'] is Map) {
      breakdown = (j['breakdown'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    }

    final mat = j['matrimonyExtensions'] is Map
        ? j['matrimonyExtensions'] as Map<String, dynamic>
        : null;
    final roleStr =
        _roleString(j['roleManagingProfile']) ??
        _roleString(j['managedBy']) ??
        _roleString(j['profileManagedBy']) ??
        _roleString(mat?['roleManagingProfile']) ??
        _roleString(mat?['managedBy']);
    final roleManagingProfile = _parseProfileRole(roleStr);
    if (kDebugMode && (roleStr != null || roleManagingProfile != null)) {
      debugPrint(
        '[Profile] Summary ${j['name']}: roleManagingProfile raw=$roleStr parsed=$roleManagingProfile',
      );
    }

    final imageUrls = _parseImageUrls(j['photoUrls'] ?? j['imageUrls']);
    final singleImage = _sanitizeImageUrl(j['imageUrl'] as String?);
    return ProfileSummary(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      age: _safeInt(j['age']),
      city: j['city'] as String?,
      imageUrl: singleImage ?? (imageUrls?.isNotEmpty == true ? imageUrls!.first : null),
      imageUrls: imageUrls,
      distanceKm: (j['distanceKm'] is num)
          ? (j['distanceKm'] as num).toDouble()
          : null,
      verified: _safeBool(j['verified'], false),
      matchReason: j['matchReason'] as String?,
      bio: (j['bio'] as String?) ?? '',
      promptAnswer: j['promptAnswer'] as String?,
      interests: _strList(j['interests']),
      sharedInterests: _strList(j['sharedInterests']),
      motherTongue: j['motherTongue'] as String?,
      occupation: j['occupation'] as String?,
      heightCm: _safeInt(j['heightCm']),
      religion: j['religion'] as String?,
      community: j['community'] as String?,
      educationDegree: j['educationDegree'] as String?,
      maritalStatus: j['maritalStatus'] as String?,
      diet: j['diet'] as String?,
      incomeLabel: j['incomeLabel'] as String?,
      employer: j['employer'] as String?,
      familyType: j['familyType'] as String?,
      photoCount: _safeInt(j['photoCount']) ?? 0,
      isPremium: _safeBool(j['isPremium'], false),
      compatibilityScore: (j['compatibilityScore'] as num?)?.toDouble(),
      compatibilityLabel: j['compatibilityLabel'] as String?,
      matchReasons: _strList(j['matchReasons']),
      breakdown: breakdown,
      roleManagingProfile: roleManagingProfile,
    );
  }

  // ── JSON serialization ───────────────────────────────────────────────

  static Map<String, dynamic> _profileToJson(UserProfile p) {
    final j = <String, dynamic>{
      'name': p.name,
      if (p.gender != null) 'gender': p.gender,
      if (p.age != null) 'age': p.age,
      if (p.dateOfBirth != null) 'dateOfBirth': p.dateOfBirth,
      if (p.currentCity != null) 'currentCity': p.currentCity,
      if (p.currentCountry != null) 'currentCountry': p.currentCountry,
      if (p.originCity != null) 'originCity': p.originCity,
      if (p.originCountry != null) 'originCountry': p.originCountry,
      if (p.languagesSpoken.isNotEmpty) 'languagesSpoken': p.languagesSpoken,
      if (p.motherTongue != null) 'motherTongue': p.motherTongue,
      if (p.photoUrls.isNotEmpty) 'photoUrls': p.photoUrls,
      if (p.aboutMe.isNotEmpty) 'aboutMe': p.aboutMe,
      if (p.interests.isNotEmpty) 'interests': p.interests,
      if (p.creationLat != null) 'creationLat': p.creationLat,
      if (p.creationLng != null) 'creationLng': p.creationLng,
      if (p.creationAt != null) 'creationAt': p.creationAt!.toIso8601String(),
      if (p.creationAddress != null) 'creationAddress': p.creationAddress,
    };

    if (p.matrimonyExtensions != null) {
      j['matrimonyExtensions'] = _matrimonyToJson(p.matrimonyExtensions!);
    }
    if (p.datingExtensions != null) {
      j['datingExtensions'] = _datingToJson(p.datingExtensions!);
    }
    if (p.partnerPreferences != null) {
      j['partnerPreferences'] = _prefsToJson(p.partnerPreferences!);
    }

    return j;
  }

  static Map<String, dynamic> _matrimonyToJson(MatrimonyExtensions m) => {
    if (m.religion != null) 'religion': m.religion,
    if (m.casteOrCommunity != null) 'casteOrCommunity': m.casteOrCommunity,
    if (m.motherTongue != null) 'motherTongue': m.motherTongue,
    if (m.maritalStatus != null) 'maritalStatus': m.maritalStatus,
    if (m.heightCm != null) 'heightCm': m.heightCm,
    if (m.bodyType != null) 'bodyType': m.bodyType,
    if (m.complexion != null) 'complexion': m.complexion,
    if (m.educationDegree != null) 'educationDegree': m.educationDegree,
    if (m.educationInstitution != null)
      'educationInstitution': m.educationInstitution,
    if (m.occupation != null) 'occupation': m.occupation,
    if (m.employer != null) 'employer': m.employer,
    if (m.industry != null) 'industry': m.industry,
    if (m.incomeRange != null)
      'incomeRange': {
        'minLabel': m.incomeRange!.minLabel,
        'maxLabel': m.incomeRange!.maxLabel,
        'currency': m.incomeRange!.currency,
      },
    if (m.familyDetails != null)
      'familyDetails': {
        'familyType': m.familyDetails!.familyType,
        'familyValues': m.familyDetails!.familyValues,
        'familyLocation': m.familyDetails!.familyLocation,
        'familyBasedOutOfCountry': m.familyDetails!.familyBasedOutOfCountry,
        'householdIncome': m.familyDetails!.householdIncome,
        'fatherOccupation': m.familyDetails!.fatherOccupation,
        'motherOccupation': m.familyDetails!.motherOccupation,
        'fatherAge': m.familyDetails!.fatherAge,
        'motherAge': m.familyDetails!.motherAge,
        'siblingsCount': m.familyDetails!.siblingsCount,
        'siblingsMarried': m.familyDetails!.siblingsMarried,
        'brothers': m.familyDetails!.brothers,
        'sisters': m.familyDetails!.sisters,
        'familyExpectations': m.familyDetails!.familyExpectations,
      },
    if (m.diet != null) 'diet': m.diet,
    if (m.drinking != null) 'drinking': m.drinking,
    if (m.smoking != null) 'smoking': m.smoking,
    if (m.exercise != null) 'exercise': m.exercise,
    if (m.aboutEducation != null) 'aboutEducation': m.aboutEducation,
    if (m.educationEntries != null && m.educationEntries!.isNotEmpty)
      'educationEntries': m.educationEntries!
          .map(
            (e) => {
              if (e.degree != null) 'degree': e.degree,
              if (e.institution != null) 'institution': e.institution,
              if (e.graduationYear != null) 'graduationYear': e.graduationYear,
              if (e.scoreCountry != null) 'scoreCountry': e.scoreCountry,
              if (e.scoreType != null) 'scoreType': e.scoreType,
            },
          )
          .toList(),
    if (m.horoscope != null)
      'horoscope': {
        'dateOfBirth': m.horoscope!.dateOfBirth,
        'timeOfBirth': m.horoscope!.timeOfBirth,
        'birthPlace': m.horoscope!.birthPlace,
        'manglik': m.horoscope!.manglik,
        'rashi': m.horoscope!.rashi,
        'nakshatra': m.horoscope!.nakshatra,
        'gotra': m.horoscope!.gotra,
        'horoscopeDocUrl': m.horoscope!.horoscopeDocUrl,
      },
  };

  static Map<String, dynamic> _datingToJson(DatingExtensions d) => {
    if (d.datingIntent != null) 'datingIntent': d.datingIntent,
    if (d.prompts != null)
      'prompts': d.prompts!
          .map(
            (p) => {
              'questionId': p.questionId,
              'questionText': p.questionText,
              'answer': p.answer,
            },
          )
          .toList(),
    if (d.voiceIntroUrl != null) 'voiceIntroUrl': d.voiceIntroUrl,
    'travelModeEnabled': d.travelModeEnabled,
    if (d.discoveryPreferences != null)
      'discoveryPreferences': {
        'ageMin': d.discoveryPreferences!.ageMin,
        'ageMax': d.discoveryPreferences!.ageMax,
        'maxDistanceKm': d.discoveryPreferences!.maxDistanceKm,
        'preferredCities': d.discoveryPreferences!.preferredCities,
        'travelModeEnabled': d.discoveryPreferences!.travelModeEnabled,
      },
  };

  static Map<String, dynamic> _prefsToJson(PartnerPreferences p) => {
    if (p.genderPreference != null) 'genderPreference': p.genderPreference,
    'ageMin': p.ageMin,
    'ageMax': p.ageMax,
    if (p.heightMinCm != null) 'heightMinCm': p.heightMinCm,
    if (p.heightMaxCm != null) 'heightMaxCm': p.heightMaxCm,
    if (p.preferredLocations != null)
      'preferredLocations': p.preferredLocations,
    if (p.preferredReligions != null)
      'preferredReligions': p.preferredReligions,
    if (p.preferredCommunities != null)
      'preferredCommunities': p.preferredCommunities,
    if (p.preferredMotherTongues != null)
      'preferredMotherTongues': p.preferredMotherTongues,
    if (p.educationPreference != null)
      'educationPreference': p.educationPreference,
    if (p.occupationPreference != null)
      'occupationPreference': p.occupationPreference,
    if (p.maritalStatusPreference != null)
      'maritalStatusPreference': p.maritalStatusPreference,
    if (p.dietPreference != null) 'dietPreference': p.dietPreference,
    if (p.incomePreference != null) 'incomePreference': p.incomePreference,
    if (p.preferredBodyTypes != null && p.preferredBodyTypes!.isNotEmpty)
      'preferredBodyTypes': p.preferredBodyTypes,
    if (p.drinkingPreference != null)
      'drinkingPreference': p.drinkingPreference,
    if (p.smokingPreference != null) 'smokingPreference': p.smokingPreference,
    if (p.settledAbroadPreference != null)
      'settledAbroadPreference': p.settledAbroadPreference,
    if (p.preferredCountries != null)
      'preferredCountries': p.preferredCountries,
    if (p.cityPreferenceMode != null)
      'cityPreferenceMode': p.cityPreferenceMode,
    if (p.distanceMaxKm != null) 'distanceMaxKm': p.distanceMaxKm,
    if (p.horoscopeMatchPreferred != null)
      'horoscopeMatchPreferred': p.horoscopeMatchPreferred,
    if (p.strictFilters != null && p.strictFilters!.isNotEmpty)
      'strictFilters': p.strictFilters,
  };

  static Map<String, dynamic> _defaultPrivacy() => {
    'showInVisitors': true,
    'profileVisibility': 'everyone',
    'hideFromDiscovery': false,
    'photosHidden': false,
  };

  @override
  Future<Map<String, dynamic>> getPrivacy() async {
    try {
      final body = await api.get('/profile/me/privacy');
      final map = Map<String, dynamic>.from(body);
      return _defaultPrivacy()..addAll(map);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return _defaultPrivacy();
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updatePrivacy(
    Map<String, dynamic> privacy,
  ) async {
    final body = await api.patch('/profile/me/privacy', body: privacy);
    return Map<String, dynamic>.from(body);
  }

  @override
  Future<DateTime?> startProfileBoost({int durationHours = 24}) async {
    final body = await api.post(
      '/profile/me/boost',
      body: {'durationHours': durationHours},
    );
    final until = body['boostedUntil'] as String?;
    return until != null ? DateTime.tryParse(until) : null;
  }

  static Map<String, dynamic> _defaultNotificationPreferences() => {
    'interestReceived': true,
    'priorityInterestReceived': true,
    'interestAccepted': true,
    'interestDeclined': false,
    'mutualMatch': true,
    'profileVisited': true,
    'newMessage': true,
    'contactRequestAccepted': true,
    'contactRequestDeclined': false,
  };

  @override
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final body = await api.get('/profile/me/notifications');
      final map = Map<String, dynamic>.from(body);
      return _defaultNotificationPreferences()..addAll(map);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return _defaultNotificationPreferences();
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    final body = await api.patch(
      '/profile/me/notifications',
      body: preferences,
    );
    return Map<String, dynamic>.from(body);
  }

  @override
  Future<void> registerFcmToken(String fcmToken) async {
    await api.post('/profile/me/fcm-token', body: {'fcmToken': fcmToken});
  }

  @override
  Future<void> deleteFcmToken() async {
    try {
      await api.delete('/profile/me/fcm-token');
    } on ApiException catch (_) {
      // Optional: backend may not implement DELETE; ignore so sign-out still completes
    }
  }

  static List<String> _strList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  static int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static bool _safeBool(dynamic v, [bool defaultValue = false]) {
    if (v is bool) return v;
    return defaultValue;
  }

  static Map<String, bool>? _safePrivacySettings(dynamic v) {
    if (v == null || v is! Map) return null;
    final map = <String, bool>{};
    // ignore: unnecessary_cast - v is Map after is! check
    for (final e in (v as Map).entries) {
      final k = e.key;
      final val = e.value;
      if (k is String && val is bool) map[k] = val;
    }
    return map.isEmpty ? null : map;
  }
}
