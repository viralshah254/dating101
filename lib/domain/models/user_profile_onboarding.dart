import 'user_profile.dart';

/// Same rules as [ProfileFormData._normalizeNameFromServer] — API placeholder
/// must not count as a completed identity.
bool isPlaceholderProfileName(String? raw) {
  final t = (raw ?? '').trim();
  if (t.isEmpty) return true;
  final lower = t.toLowerCase();
  return lower == 'unknown' || lower == 'user' || lower == 'member';
}

extension UserProfileOnboarding on UserProfile {
  /// `getMyProfile` can return a non-null row before the user has finished
  /// onboarding (e.g. placeholder name, no DOB). Shell routes should stay gated.
  bool get needsOnboardingCompletion {
    if (isPlaceholderProfileName(name)) return true;
    if ((gender ?? '').trim().isEmpty) return true;
    if ((dateOfBirth ?? '').trim().isEmpty) return true;

    // A dating extensions row with any content means dating onboarding is done.
    if (datingExtensions != null) return false;

    // A matrimony extensions row is created early by draft saves (it may only
    // have roleManagingProfile set). Require at least one substantive field —
    // maritalStatus (set at identity_physical) or a meaningful bio
    // (set at matrimony_about) — before the gate is lifted.
    if (matrimonyExtensions != null) {
      final hasMarital =
          (matrimonyExtensions!.maritalStatus ?? '').trim().isNotEmpty;
      final hasBio = aboutMe.trim().length >= 20;
      if (hasMarital || hasBio) return false;
      // Skeleton row only → still needs onboarding
      return true;
    }

    if (modePreference == null || modePreference!.trim().isEmpty) {
      return true;
    }
    return false;
  }
}
