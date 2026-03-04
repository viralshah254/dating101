import 'package:freezed_annotation/freezed_annotation.dart';

import 'matrimony_extensions.dart';

part 'profile_summary.freezed.dart';

/// Lightweight profile for cards and lists (derived from UserProfile or API).
@freezed
class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({
    required String id,
    required String name,
    required int? age,
    required String? city,
    String? imageUrl,
    /// When set, discovery card shows multiple photos with left/right tap to navigate.
    List<String>? imageUrls,
    double? distanceKm,
    @Default(false) bool verified,
    String? matchReason,
    @Default('') String bio,
    String? promptAnswer,
    @Default([]) List<String> interests,

    /// Interests this profile shares with the current viewer (from backend).
    @Default([]) List<String> sharedInterests,
    String? motherTongue,
    String? occupation,
    int? heightCm,
    String? religion,
    String? community,
    String? educationDegree,
    String? maritalStatus,
    String? diet,
    String? incomeLabel,
    String? employer,
    String? familyType,
    @Default(0) int photoCount,
    /// Whether this user has an active premium subscription (for badge on profile/cards).
    @Default(false) bool isPremium,
    // ML compatibility scoring
    double? compatibilityScore,
    String? compatibilityLabel,
    @Default([]) List<String> matchReasons,
    Map<String, double>? breakdown,

    /// Who manages this profile (matrimony). Only shown when not self.
    ProfileRole? roleManagingProfile,
  }) = _ProfileSummary;
}
