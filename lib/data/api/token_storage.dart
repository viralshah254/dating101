import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens to disk via SharedPreferences.
/// Notifies listeners when tokens are cleared so the router can redirect to login.
class TokenStorage extends ChangeNotifier {
  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyIsNew = 'auth_is_new_user';

  /// Listen to this (e.g. as GoRouter refreshListenable) to redirect to login when session is cleared.
  Listenable get authChangeListenable => this;

  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  bool get isLoggedIn => _accessToken != null && _userId != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccess);
    _refreshToken = prefs.getString(_keyRefresh);
    _userId = prefs.getString(_keyUserId);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, accessToken);
    await prefs.setString(_keyRefresh, refreshToken);
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyIsNew, isNewUser);
    notifyListeners();
  }

  Future<void> updateAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, token);
    notifyListeners();
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyIsNew);
    notifyListeners();
  }
}
