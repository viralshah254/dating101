import '../models/partner_preferences.dart';
import '../models/user_profile.dart';
import '../models/profile_summary.dart';

/// Current user's profile and partner preferences CRUD.
abstract class ProfileRepository {
  /// Get full profile for current user.
  Future<UserProfile?> getMyProfile();

  /// Stream my profile (for reactive UI).
  Stream<UserProfile?> watchMyProfile();

  /// Update my profile (partial update).
  Future<UserProfile> updateMyProfile(UserProfile profile);

  /// Get partner preferences (matrimony).
  Future<PartnerPreferences?> getMyPartnerPreferences();

  /// Update partner preferences.
  Future<PartnerPreferences> updatePartnerPreferences(PartnerPreferences prefs);

  /// Get a profile summary by id (for cards / detail).
  Future<ProfileSummary?> getProfileSummary(String userId);

  /// Get full profile by id.
  Future<UserProfile?> getProfile(String userId);

  /// Compute profile completeness 0.0–1.0.
  double computeCompleteness(UserProfile profile);
}
