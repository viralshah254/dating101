import 'package:freezed_annotation/freezed_annotation.dart';

import 'dating_extensions.dart';
import 'matrimony_extensions.dart';
import 'partner_preferences.dart';
import 'verification_status.dart';

part 'user_profile.freezed.dart';

/// Unified user profile: core fields + optional dating/matrimony sections.
@freezed
class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    required String name,
    String? gender,
    int? age,
    String? dateOfBirth,
    String? currentCity,
    String? currentCountry,
    String? originCity,
    String? originCountry,
    @Default([]) List<String> languagesSpoken,
    String? motherTongue,
    @Default([]) List<String> photoUrls,

    /// When true, profile owner has hidden photos; others must request to view.
    @Default(false) bool photosHidden,

    /// When viewing another user: true if caller is allowed to see their photos.
    bool? canViewPhotos,
    @Default('') String aboutMe,
    @Default([]) List<String> interests,
    @Default(VerificationStatus()) VerificationStatus verificationStatus,
    @Default(0.0) double profileCompleteness,
    Map<String, bool>? privacySettings,
    DatingExtensions? datingExtensions,
    MatrimonyExtensions? matrimonyExtensions,
    PartnerPreferences? partnerPreferences,
    DateTime? lastActiveAt,

    /// Where the profile was created (lat/lng/timestamp) for safety and support tracking.
    double? creationLat,
    double? creationLng,
    DateTime? creationAt,
    String? creationAddress,
  }) = _UserProfile;

  /// For discovery cards: display location (city or city, country).
  String get displayLocation {
    if (currentCity != null && currentCity!.isNotEmpty) {
      return currentCountry != null && currentCountry!.isNotEmpty
          ? '$currentCity, $currentCountry'
          : currentCity!;
    }
    return currentCountry ?? '';
  }

  bool get isVerified =>
      verificationStatus.photoVerified || verificationStatus.idVerified;
}
