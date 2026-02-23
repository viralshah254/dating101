import 'package:freezed_annotation/freezed_annotation.dart';

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
    double? distanceKm,
    @Default(false) bool verified,
    String? matchReason,
    @Default('') String bio,
    String? promptAnswer,
    @Default([]) List<String> interests,
    String? motherTongue,
    String? occupation,
    int? heightCm,
  }) = _ProfileSummary;
}
