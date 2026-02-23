import '../../domain/models/profile_summary.dart';
import '../../domain/models/user_profile.dart';

/// Maps UserProfile to ProfileSummary for cards and lists.
ProfileSummary profileToSummary(UserProfile p, {double? distanceKm, String? matchReason}) {
  final photoUrl = p.photoUrls.isNotEmpty ? p.photoUrls.first : null;
  final occupation = p.matrimonyExtensions?.occupation;
  final heightCm = p.matrimonyExtensions?.heightCm;
  return ProfileSummary(
    id: p.id,
    name: p.name,
    age: p.age,
    city: p.currentCity ?? p.displayLocation,
    imageUrl: photoUrl,
    distanceKm: distanceKm,
    verified: p.isVerified,
    matchReason: matchReason,
    bio: p.aboutMe,
    promptAnswer: p.datingExtensions?.prompts?.isNotEmpty == true
        ? p.datingExtensions!.prompts!.first.answer
        : null,
    interests: p.interests,
    motherTongue: p.motherTongue ?? p.matrimonyExtensions?.motherTongue,
    occupation: occupation,
    heightCm: heightCm,
  );
}
