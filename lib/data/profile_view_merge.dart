import '../domain/models/family_details.dart';
import '../domain/models/matrimony_extensions.dart';
import '../domain/models/profile_summary.dart';
import '../domain/models/user_profile.dart';
import 'repositories_api/api_profile_repository.dart';

/// Fills gaps from [GET /profile/:id] using [GET /profile/:id/summary] so the
/// matrimony full screen shows the same photo and headline fields as list cards.
UserProfile mergeFullUserProfileWithSummary(
  UserProfile full,
  ProfileSummary? summary,
) {
  if (summary == null) return full;

  final mergedPhotos = _mergedPhotoUrls(full, summary);
  final mergedMat = _mergedMatrimony(full.matrimonyExtensions, summary);

  return full.copyWith(
    photoUrls: mergedPhotos,
    aboutMe: full.aboutMe.trim().isEmpty && summary.bio.trim().isNotEmpty
        ? summary.bio
        : full.aboutMe,
    interests:
        full.interests.isEmpty && summary.interests.isNotEmpty
            ? summary.interests
            : full.interests,
    age: full.age ?? summary.age,
    currentCity: full.currentCity ?? summary.city,
    motherTongue: full.motherTongue ?? summary.motherTongue,
    matrimonyExtensions: mergedMat,
    isPremium: full.isPremium || summary.isPremium,
  );
}

List<String> _mergedPhotoUrls(UserProfile full, ProfileSummary summary) {
  if (full.photosHidden && full.canViewPhotos != true) {
    return full.photoUrls;
  }
  if (full.photoUrls.isNotEmpty) return full.photoUrls;

  final fromSummary = summary.imageUrls ??
      (summary.imageUrl != null && summary.imageUrl!.isNotEmpty
          ? [summary.imageUrl!]
          : <String>[]);
  return fromSummary
      .map(ApiProfileRepository.sanitizeImageUrl)
      .whereType<String>()
      .toList();
}

MatrimonyExtensions? _mergedMatrimony(
  MatrimonyExtensions? existing,
  ProfileSummary s,
) {
  MatrimonyExtensions? patchFromSummary() {
    bool nz(String? v) => v != null && v.trim().isNotEmpty;
    final has = nz(s.religion) ||
        nz(s.community) ||
        nz(s.educationDegree) ||
        nz(s.maritalStatus) ||
        nz(s.motherTongue) ||
        nz(s.occupation) ||
        nz(s.employer) ||
        nz(s.diet) ||
        nz(s.familyType) ||
        (s.heightCm != null && s.heightCm! > 0);
    if (!has) return null;
    return MatrimonyExtensions(
      roleManagingProfile: s.roleManagingProfile ?? ProfileRole.self,
      religion: s.religion,
      casteOrCommunity: s.community,
      motherTongue: s.motherTongue,
      maritalStatus: s.maritalStatus,
      heightCm: s.heightCm,
      educationDegree: s.educationDegree,
      occupation: s.occupation,
      employer: s.employer,
      diet: s.diet,
      familyDetails: s.familyType != null && s.familyType!.trim().isNotEmpty
          ? FamilyDetails(familyType: s.familyType)
          : null,
    );
  }

  final patch = patchFromSummary();
  if (existing == null) return patch;
  if (patch == null) return existing;

  return existing.copyWith(
    religion: existing.religion ?? patch.religion,
    casteOrCommunity: existing.casteOrCommunity ?? patch.casteOrCommunity,
    motherTongue: existing.motherTongue ?? patch.motherTongue,
    maritalStatus: existing.maritalStatus ?? patch.maritalStatus,
    heightCm: existing.heightCm ?? patch.heightCm,
    educationDegree: existing.educationDegree ?? patch.educationDegree,
    occupation: existing.occupation ?? patch.occupation,
    employer: existing.employer ?? patch.employer,
    diet: existing.diet ?? patch.diet,
    familyDetails: existing.familyDetails ?? patch.familyDetails,
    roleManagingProfile: existing.roleManagingProfile == ProfileRole.self &&
            s.roleManagingProfile != null
        ? s.roleManagingProfile!
        : existing.roleManagingProfile,
  );
}
