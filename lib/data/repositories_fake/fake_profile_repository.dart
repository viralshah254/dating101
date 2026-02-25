import 'dart:async';

import '../../domain/models/partner_preferences.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/profile_summary.dart';
import '../../domain/repositories/profile_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository() {
    _myProfile = FakeData.myProfile;
    _controller = StreamController<UserProfile?>.broadcast();
    _controller.add(_myProfile);
  }

  UserProfile? _myProfile;
  late StreamController<UserProfile?> _controller;

  @override
  Future<UserProfile?> getMyProfile() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _myProfile;
  }

  @override
  Stream<UserProfile?> watchMyProfile() {
    return _controller.stream;
  }

  @override
  Future<UserProfile> createMyProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _myProfile = profile;
    _controller.add(_myProfile);
    return profile;
  }

  @override
  Future<UserProfile> updateMyProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _myProfile = profile;
    _controller.add(_myProfile);
    return profile;
  }

  @override
  Future<void> saveProfileJson(Map<String, dynamic> json, {bool create = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<PartnerPreferences?> getMyPartnerPreferences() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _myProfile?.partnerPreferences ?? FakeData.defaultPartnerPreferences;
  }

  @override
  Future<PartnerPreferences> updatePartnerPreferences(PartnerPreferences prefs) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_myProfile != null) {
      _myProfile = _myProfile!.copyWith(partnerPreferences: prefs);
      _controller.add(_myProfile);
    }
    return prefs;
  }

  @override
  Future<ProfileSummary?> getProfileSummary(String userId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final all = FakeData.allProfiles;
    final p = all[userId] ?? (all.isEmpty ? null : all.values.first);
    if (p == null) return null;
    final distanceKm = userId == '2' ? 2.1 : (userId == '3' ? 4.2 : 5.0);
    final reason = FakeData.matchReasons[userId];
    return profileToSummary(p, distanceKm: distanceKm, matchReason: reason);
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return FakeData.allProfiles[userId];
  }

  @override
  double computeCompleteness(UserProfile profile) {
    double score = 0.0;
    if (profile.name.isNotEmpty) score += 0.15;
    if (profile.aboutMe.isNotEmpty) score += 0.15;
    if (profile.photoUrls.length >= 2) score += 0.2;
    if (profile.currentCity != null && profile.currentCity!.isNotEmpty) score += 0.1;
    if (profile.age != null) score += 0.05;
    if (profile.interests.isNotEmpty) score += 0.1;
    if (profile.datingExtensions != null) score += 0.1;
    if (profile.matrimonyExtensions != null) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  @override
  Future<Map<String, dynamic>> updatePrivacy(Map<String, dynamic> privacy) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Map<String, dynamic>.from(privacy);
  }

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Map<String, dynamic>.from(preferences);
  }
}
