import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens securely.
/// - Access/refresh tokens and userId: stored in flutter_secure_storage (KeyStore / Keychain).
/// - Non-sensitive metadata (pendingOnboarding): stored in SharedPreferences.
///
/// Notifies listeners when tokens change so GoRouter can redirect to login.
class TokenStorage extends ChangeNotifier {
  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';
  // Written as `auth_is_new_user` for backwards compatibility with existing installs.
  static const _keyPendingOnboarding = 'auth_is_new_user';

  // SharedPreferences keys that must survive sign-out (user preferences, not auth data).
  static const _keysToPreserveOnSignOut = [
    'app_locale',
    'auth_default_signup_shown',
  ];

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Listen to this (e.g. as GoRouter refreshListenable) to redirect to login when session is cleared.
  Listenable get authChangeListenable => this;

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  bool _pendingOnboarding = false;

  /// Bumped on every [save] / [clear] so [ApiClient] can ignore stale token-refresh
  /// completions that finish after sign-out or a new login.
  int _sessionGeneration = 0;
  int get sessionGeneration => _sessionGeneration;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  bool get isLoggedIn => _accessToken != null && _userId != null;

  /// True when the user has registered but has not yet completed the onboarding
  /// wizard (i.e. their profile does not exist yet). Persisted across restarts
  /// so that a cold start resumes the correct onboarding route.
  bool get hasPendingOnboarding => _pendingOnboarding;

  Future<void> load() async {
    _accessToken = await _secureStorage.read(key: _keyAccess);
    _refreshToken = await _secureStorage.read(key: _keyRefresh);
    _userId = await _secureStorage.read(key: _keyUserId);
    final prefs = await SharedPreferences.getInstance();
    _pendingOnboarding = prefs.getBool(_keyPendingOnboarding) ?? false;
    notifyListeners();
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    bool isNewUser = false,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _pendingOnboarding = isNewUser;

    await Future.wait([
      _secureStorage.write(key: _keyAccess, value: accessToken),
      _secureStorage.write(key: _keyRefresh, value: refreshToken),
      _secureStorage.write(key: _keyUserId, value: userId),
    ]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPendingOnboarding, isNewUser);

    _sessionGeneration++;
    notifyListeners();
  }

  Future<void> updateAccessToken(String token) async {
    _accessToken = token;
    await _secureStorage.write(key: _keyAccess, value: token);
    notifyListeners();
  }

  /// Persists the onboarding gate (e.g. profile row exists but identity is still placeholder).
  Future<void> setPendingOnboardingFlag(bool value) async {
    if (value) {
      if (_pendingOnboarding) return;
      _pendingOnboarding = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPendingOnboarding, true);
      notifyListeners();
    } else {
      final was = _pendingOnboarding;
      _pendingOnboarding = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingOnboarding);
      if (was) notifyListeners();
    }
  }

  /// Call this once the user has successfully completed their profile (onboarding done).
  /// Clears the pending-onboarding gate so shell routes are accessible.
  Future<void> clearPendingOnboarding() async {
    await setPendingOnboardingFlag(false);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _pendingOnboarding = false;

    await Future.wait([
      _secureStorage.delete(key: _keyAccess),
      _secureStorage.delete(key: _keyRefresh),
      _secureStorage.delete(key: _keyUserId),
    ]);

    // Delete only auth-related prefs; preserve user preferences (locale, first-install flag, etc.)
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys()
        .where((k) => !_keysToPreserveOnSignOut.contains(k))
        .toList();
    await Future.wait(keysToRemove.map((k) => prefs.remove(k)));

    _sessionGeneration++;
    notifyListeners();
  }
}
