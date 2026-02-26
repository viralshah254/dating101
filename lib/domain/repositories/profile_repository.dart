import '../models/partner_preferences.dart';
import '../models/user_profile.dart';
import '../models/profile_summary.dart';

/// Current user's profile and partner preferences CRUD.
abstract class ProfileRepository {
  /// Get full profile for current user.
  Future<UserProfile?> getMyProfile();

  /// Stream my profile (for reactive UI).
  Stream<UserProfile?> watchMyProfile();

  /// Create profile for the first time.
  Future<UserProfile> createMyProfile(UserProfile profile);

  /// Update my profile (partial update).
  Future<UserProfile> updateMyProfile(UserProfile profile);

  /// Save profile from raw JSON (all form fields, bypasses model).
  Future<void> saveProfileJson(
    Map<String, dynamic> json, {
    bool create = false,
  });

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

  /// Get current privacy flags (GET /profile/me/privacy). Returns defaults if 404.
  Future<Map<String, dynamic>> getPrivacy();

  /// Update privacy settings (PATCH /profile/me/privacy). e.g. { "showInVisitors": false }.
  Future<Map<String, dynamic>> updatePrivacy(Map<String, dynamic> privacy);

  /// Start or extend profile boost (POST /profile/me/boost). Returns boostedUntil.
  Future<DateTime?> startProfileBoost({int durationHours = 24});

  /// Get current notification preferences (GET /profile/me/notifications).
  /// Returns default map if endpoint not implemented (404).
  Future<Map<String, dynamic>> getNotificationPreferences();

  /// Update notification preferences (PATCH /profile/me/notifications).
  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, dynamic> preferences,
  );

  /// Register FCM device token for push (POST /profile/me/fcm-token).
  Future<void> registerFcmToken(String fcmToken);

  /// Remove FCM token on sign out (DELETE /profile/me/fcm-token). Optional; call before sign-out while still authenticated.
  Future<void> deleteFcmToken();
}
