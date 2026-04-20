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
    /// Trust score 0.0–1.0 derived from verification flags.
    double? verificationScore,
    @Default(false) bool idVerified,
    @Default(false) bool photoVerified,
    @Default(false) bool linkedInVerified,
    @Default(false) bool educationVerified,
    /// Response rate 0.0–1.0 (interests replied / received, last 30 days).
    double? responseRate,
    /// Marriage readiness timeline: "3_6" | "6_12" | "12_24" | "exploring"
    String? readyInMonths,
    /// Whether this user requires verified profiles to contact them.
    @Default(false) bool requireVerifiedToContact,
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

    /// Dating intent from DatingExtensions: serious / casual / marriage / friends_first.
    String? datingIntent,

    /// Whether this user has posted an active Moment (within 24h).
    @Default(false) bool hasActiveMoment,
    /// URL of the active moment image (used for story-ring preview).
    String? momentImageUrl,

    /// Voice intro URL (if recorded).
    String? voiceIntroUrl,

    /// Server `Profile.lastActiveAt` (ISO); for last-seen when chat thread omits it.
    DateTime? lastActiveAt,

    /// True if the viewing user's interest was accepted by this profile.
    /// Free male users bypass the photo gate on all photos when this is true.
    @Default(false) bool? isAccepted,

    /// True if the profile was created within the last 24 hours.
    @Default(false) bool isNew,
  }) = _ProfileSummary;
}
