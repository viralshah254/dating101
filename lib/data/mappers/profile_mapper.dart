import '../../domain/models/profile_summary.dart';
import '../../domain/models/user_profile.dart';

/// Maps UserProfile to ProfileSummary for cards and lists.
ProfileSummary profileToSummary(
  UserProfile p, {
  double? distanceKm,
  String? matchReason,
  List<String>? matchReasons,
  List<String>? sharedInterests,
}) {
  final photoUrl = p.photoUrls.isNotEmpty ? p.photoUrls.first : null;
  final mat = p.matrimonyExtensions;
  final inc = mat?.incomeRange;
  String? incomeLabel;
  if (inc != null) {
    final parts = [inc.minLabel, inc.maxLabel].whereType<String>();
    if (parts.isNotEmpty) {
      incomeLabel = '${inc.currency ?? ''} ${parts.join(' – ')}'.trim();
    }
  }
  final reasons =
      matchReasons ?? (matchReason != null ? [matchReason] : <String>[]);

  return ProfileSummary(
    id: p.id,
    name: p.name,
    age: p.age,
    city: p.currentCity ?? p.displayLocation,
    imageUrl: photoUrl,
    imageUrls: p.photoUrls.isNotEmpty ? p.photoUrls : null,
    distanceKm: distanceKm,
    verified: p.isVerified,
    matchReason: matchReason,
    matchReasons: reasons,
    bio: p.aboutMe,
    promptAnswer: p.datingExtensions?.prompts?.isNotEmpty == true
        ? p.datingExtensions!.prompts!.first.answer
        : null,
    interests: p.interests,
    sharedInterests: sharedInterests ?? const [],
    motherTongue: p.motherTongue ?? mat?.motherTongue,
    occupation: mat?.occupation,
    heightCm: mat?.heightCm,
    religion: mat?.religion,
    community: mat?.casteOrCommunity,
    educationDegree: mat?.educationDegree,
    maritalStatus: mat?.maritalStatus,
    diet: mat?.diet,
    incomeLabel: incomeLabel,
    employer: mat?.employer,
    familyType: mat?.familyDetails?.familyType,
    photoCount: p.photoUrls.length,
    roleManagingProfile: mat?.roleManagingProfile,
  );
}
