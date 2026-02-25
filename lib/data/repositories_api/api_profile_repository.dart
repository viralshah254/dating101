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
    debugPrint('[Profile] Profile created ✓ id=${_cached!.id}, name=${_cached!.name}');
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
  Future<void> saveProfileJson(Map<String, dynamic> json, {bool create = false}) async {
    debugPrint('[Profile] saveProfileJson (create=$create) keys=${json.keys.toList()}');
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
  Future<PartnerPreferences> updatePartnerPreferences(PartnerPreferences prefs) async {
    final body = await api.put('/profile/me/preferences', body: _prefsToJson(prefs));
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
      return _parseProfile(body);
    } on ApiException {
      return null;
    }
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
    return UserProfile(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      gender: j['gender'] as String?,
      age: j['age'] as int?,
      dateOfBirth: j['dateOfBirth'] as String?,
      currentCity: j['currentCity'] as String?,
      currentCountry: j['currentCountry'] as String?,
      originCity: j['originCity'] as String?,
      originCountry: j['originCountry'] as String?,
      languagesSpoken: _strList(j['languagesSpoken']),
      motherTongue: j['motherTongue'] as String?,
      photoUrls: _strList(j['photoUrls']),
      aboutMe: j['aboutMe'] as String? ?? '',
      interests: _strList(j['interests']),
      verificationStatus: j['verificationStatus'] != null
          ? _parseVerification(j['verificationStatus'] as Map<String, dynamic>)
          : const VerificationStatus(),
      profileCompleteness: (j['profileCompleteness'] as num?)?.toDouble() ?? 0.0,
      privacySettings: j['privacySettings'] != null
          ? (j['privacySettings'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as bool))
          : null,
      datingExtensions: j['datingExtensions'] != null
          ? _parseDating(j['datingExtensions'] as Map<String, dynamic>)
          : null,
      matrimonyExtensions: j['matrimonyExtensions'] != null
          ? _parseMatrimony(j['matrimonyExtensions'] as Map<String, dynamic>)
          : null,
      partnerPreferences: j['partnerPreferences'] != null
          ? _parsePreferences(j['partnerPreferences'] as Map<String, dynamic>)
          : null,
      lastActiveAt: j['lastActiveAt'] != null ? DateTime.tryParse(j['lastActiveAt'] as String) : null,
      creationLat: (j['creationLat'] as num?)?.toDouble(),
      creationLng: (j['creationLng'] as num?)?.toDouble(),
      creationAt: j['creationAt'] != null ? DateTime.tryParse(j['creationAt'] as String) : null,
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
              maxDistanceKm: (j['discoveryPreferences']['maxDistanceKm'] as num?)?.toDouble() ?? 50,
              preferredCities: _strList(j['discoveryPreferences']['preferredCities']),
              travelModeEnabled: j['discoveryPreferences']['travelModeEnabled'] as bool? ?? false,
            )
          : null,
    );
  }

  static MatrimonyExtensions _parseMatrimony(Map<String, dynamic> j) {
    return MatrimonyExtensions(
      religion: j['religion'] as String?,
      casteOrCommunity: j['casteOrCommunity'] as String?,
      motherTongue: j['motherTongue'] as String?,
      maritalStatus: j['maritalStatus'] as String?,
      heightCm: j['heightCm'] as int?,
      educationDegree: j['educationDegree'] as String?,
      educationInstitution: j['educationInstitution'] as String?,
      occupation: j['occupation'] as String?,
      employer: j['employer'] as String?,
      industry: j['industry'] as String?,
      incomeRange: j['incomeRange'] != null
          ? IncomeRange(
              minLabel: (j['incomeRange'] as Map)['minLabel'] as String?,
              maxLabel: (j['incomeRange'] as Map)['maxLabel'] as String?,
              currency: (j['incomeRange'] as Map)['currency'] as String?,
            )
          : null,
      familyDetails: j['familyDetails'] != null
          ? FamilyDetails(
              familyType: (j['familyDetails'] as Map)['familyType'] as String?,
              familyValues: (j['familyDetails'] as Map)['familyValues'] as String?,
              fatherOccupation: (j['familyDetails'] as Map)['fatherOccupation'] as String?,
              motherOccupation: (j['familyDetails'] as Map)['motherOccupation'] as String?,
              siblingsCount: (j['familyDetails'] as Map)['siblingsCount'] as int?,
              siblingsMarried: (j['familyDetails'] as Map)['siblingsMarried'] as int?,
            )
          : null,
      diet: j['diet'] as String?,
      drinking: j['drinking'] as String?,
      smoking: j['smoking'] as String?,
      horoscope: j['horoscope'] != null
          ? HoroscopeDetails(
              dateOfBirth: (j['horoscope'] as Map)['dateOfBirth'] as String?,
              timeOfBirth: (j['horoscope'] as Map)['timeOfBirth'] as String?,
              birthPlace: (j['horoscope'] as Map)['birthPlace'] as String?,
              manglik: (j['horoscope'] as Map)['manglik'] as String?,
              nakshatra: (j['horoscope'] as Map)['nakshatra'] as String?,
              horoscopeDocUrl: (j['horoscope'] as Map)['horoscopeDocUrl'] as String?,
            )
          : null,
    );
  }

  static PartnerPreferences _parsePreferences(Map<String, dynamic> j) {
    return PartnerPreferences(
      genderPreference: j['genderPreference'] as String?,
      ageMin: j['ageMin'] as int? ?? 21,
      ageMax: j['ageMax'] as int? ?? 45,
      heightMinCm: j['heightMinCm'] as int?,
      heightMaxCm: j['heightMaxCm'] as int?,
      preferredLocations: _strList(j['preferredLocations']),
      preferredReligions: _strList(j['preferredReligions']),
      preferredCommunities: _strList(j['preferredCommunities']),
      preferredMotherTongues: _strList(j['preferredMotherTongues']),
      educationPreference: j['educationPreference'] as String?,
      occupationPreference: j['occupationPreference'] as String?,
      maritalStatusPreference: _strList(j['maritalStatusPreference']),
      dietPreference: j['dietPreference'] as String?,
      incomePreference: j['incomePreference'] as String?,
      drinkingPreference: j['drinkingPreference'] as String?,
      smokingPreference: j['smokingPreference'] as String?,
      settledAbroadPreference: j['settledAbroadPreference'] as String?,
      preferredCountries: _strList(j['preferredCountries']),
      cityPreferenceMode: j['cityPreferenceMode'] as String?,
      distanceMaxKm: (j['distanceMaxKm'] as num?)?.toDouble(),
      horoscopeMatchPreferred: j['horoscopeMatchPreferred'] as bool?,
    );
  }

  /// Public for reuse by other API repos (discovery, shortlist, etc.).
  static ProfileSummary parseSummaryPublic(Map<String, dynamic> j) => _parseSummary(j);

  static ProfileSummary _parseSummary(Map<String, dynamic> j) {
    Map<String, double>? breakdown;
    if (j['breakdown'] is Map) {
      breakdown = (j['breakdown'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    }

    return ProfileSummary(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      age: j['age'] as int?,
      city: j['city'] as String?,
      imageUrl: j['imageUrl'] as String?,
      distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      verified: j['verified'] as bool? ?? false,
      matchReason: j['matchReason'] as String?,
      bio: j['bio'] as String? ?? '',
      promptAnswer: j['promptAnswer'] as String?,
      interests: _strList(j['interests']),
      sharedInterests: _strList(j['sharedInterests']),
      motherTongue: j['motherTongue'] as String?,
      occupation: j['occupation'] as String?,
      heightCm: j['heightCm'] as int?,
      religion: j['religion'] as String?,
      community: j['community'] as String?,
      educationDegree: j['educationDegree'] as String?,
      maritalStatus: j['maritalStatus'] as String?,
      diet: j['diet'] as String?,
      incomeLabel: j['incomeLabel'] as String?,
      employer: j['employer'] as String?,
      familyType: j['familyType'] as String?,
      photoCount: j['photoCount'] as int? ?? 0,
      compatibilityScore: (j['compatibilityScore'] as num?)?.toDouble(),
      compatibilityLabel: j['compatibilityLabel'] as String?,
      matchReasons: _strList(j['matchReasons']),
      breakdown: breakdown,
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
        if (m.educationDegree != null) 'educationDegree': m.educationDegree,
        if (m.educationInstitution != null) 'educationInstitution': m.educationInstitution,
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
            'fatherOccupation': m.familyDetails!.fatherOccupation,
            'motherOccupation': m.familyDetails!.motherOccupation,
            'siblingsCount': m.familyDetails!.siblingsCount,
            'siblingsMarried': m.familyDetails!.siblingsMarried,
          },
        if (m.diet != null) 'diet': m.diet,
        if (m.drinking != null) 'drinking': m.drinking,
        if (m.smoking != null) 'smoking': m.smoking,
        if (m.horoscope != null)
          'horoscope': {
            'dateOfBirth': m.horoscope!.dateOfBirth,
            'timeOfBirth': m.horoscope!.timeOfBirth,
            'birthPlace': m.horoscope!.birthPlace,
            'manglik': m.horoscope!.manglik,
            'nakshatra': m.horoscope!.nakshatra,
            'horoscopeDocUrl': m.horoscope!.horoscopeDocUrl,
          },
      };

  static Map<String, dynamic> _datingToJson(DatingExtensions d) => {
        if (d.datingIntent != null) 'datingIntent': d.datingIntent,
        if (d.prompts != null)
          'prompts': d.prompts!
              .map((p) => {
                    'questionId': p.questionId,
                    'questionText': p.questionText,
                    'answer': p.answer,
                  })
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
        if (p.preferredLocations != null) 'preferredLocations': p.preferredLocations,
        if (p.preferredReligions != null) 'preferredReligions': p.preferredReligions,
        if (p.preferredCommunities != null) 'preferredCommunities': p.preferredCommunities,
        if (p.preferredMotherTongues != null) 'preferredMotherTongues': p.preferredMotherTongues,
        if (p.educationPreference != null) 'educationPreference': p.educationPreference,
        if (p.occupationPreference != null) 'occupationPreference': p.occupationPreference,
        if (p.maritalStatusPreference != null) 'maritalStatusPreference': p.maritalStatusPreference,
        if (p.dietPreference != null) 'dietPreference': p.dietPreference,
        if (p.incomePreference != null) 'incomePreference': p.incomePreference,
        if (p.drinkingPreference != null) 'drinkingPreference': p.drinkingPreference,
        if (p.smokingPreference != null) 'smokingPreference': p.smokingPreference,
        if (p.settledAbroadPreference != null) 'settledAbroadPreference': p.settledAbroadPreference,
        if (p.preferredCountries != null) 'preferredCountries': p.preferredCountries,
        if (p.cityPreferenceMode != null) 'cityPreferenceMode': p.cityPreferenceMode,
        if (p.distanceMaxKm != null) 'distanceMaxKm': p.distanceMaxKm,
        if (p.horoscopeMatchPreferred != null) 'horoscopeMatchPreferred': p.horoscopeMatchPreferred,
      };

  @override
  Future<Map<String, dynamic>> updatePrivacy(Map<String, dynamic> privacy) async {
    final body = await api.patch('/profile/me/privacy', body: privacy);
    return Map<String, dynamic>.from(body);
  }

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final body = await api.patch('/profile/me/notifications', body: preferences);
    return Map<String, dynamic>.from(body);
  }

  static List<String> _strList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
