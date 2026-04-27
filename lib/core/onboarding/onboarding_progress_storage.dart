import 'package:shared_preferences/shared_preferences.dart';

/// Persists profile-wizard progress so cold starts / shell redirects resume
/// at the correct step rather than restarting at the welcome flow.
///
/// Keys are scoped to the current user id so switching accounts is safe.
class OnboardingProgressStorage {
  OnboardingProgressStorage._();

  // ── Keys ────────────────────────────────────────────────────────────────
  static String _kStepKey(String uid) => 'profile_setup_step_key_v2_$uid';
  static String _kCreatingFor(String uid) => 'profile_setup_creating_for_v1_$uid';
  static String _kCreatingForAnswered(String uid) =>
      'profile_setup_creating_for_answered_v1_$uid';

  // ── Step (analytics key) ─────────────────────────────────────────────────

  /// Save the current wizard step as an analytics key string
  /// (e.g. `"identity_location"`, `"photos"`, `"milestone_phase1"`).
  static Future<void> saveStep(String? userId, String analyticsKey) async {
    if (userId == null || userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStepKey(userId), analyticsKey);
  }

  /// Returns the saved analytics key, or null if never saved / cleared.
  static Future<String?> readStepKey(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    // Migrate legacy int key if present.
    final legacyKey = 'profile_setup_step_v1_$userId';
    if (prefs.containsKey(legacyKey)) {
      await prefs.remove(legacyKey);
    }
    return prefs.getString(_kStepKey(userId));
  }

  static Future<void> clearForUser(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kStepKey(userId)),
      prefs.remove('profile_setup_step_v1_$userId'),
      prefs.remove(_kCreatingFor(userId)),
      prefs.remove(_kCreatingForAnswered(userId)),
    ]);
  }

  // ── Creating-for ─────────────────────────────────────────────────────────

  /// Persist the "who is this profile for?" selection.
  /// [value] is the UI string (`"son"`, `"daughter"`, etc.) or null for "Myself".
  /// [answered] is true once the user has confirmed on the profile-for screen.
  static Future<void> saveCreatingFor(
    String? userId, {
    required String? value,
    required bool answered,
  }) async {
    if (userId == null || userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      answered
          ? prefs.setBool(_kCreatingForAnswered(userId), true)
          : prefs.remove(_kCreatingForAnswered(userId)),
      if (value != null)
        prefs.setString(_kCreatingFor(userId), value)
      else
        prefs.remove(_kCreatingFor(userId)),
    ]);
  }

  /// Read back the persisted creating-for state.
  /// Returns `(answered: false, value: null)` when nothing has been stored.
  static Future<({bool answered, String? value})> readCreatingFor(
      String? userId) async {
    if (userId == null || userId.isEmpty) {
      return (answered: false, value: null);
    }
    final prefs = await SharedPreferences.getInstance();
    final answered =
        prefs.getBool(_kCreatingForAnswered(userId)) ?? false;
    final value = prefs.getString(_kCreatingFor(userId));
    return (answered: answered, value: value);
  }
}
