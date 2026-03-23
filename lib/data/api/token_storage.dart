import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens securely.
/// - Access/refresh tokens and userId: stored in flutter_secure_storage (KeyStore / Keychain).
/// - Non-sensitive metadata (isNewUser): stored in SharedPreferences.
///
/// Notifies listeners when tokens change so GoRouter can redirect to login.
class TokenStorage extends ChangeNotifier {
  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyIsNew = 'auth_is_new_user';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

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
    _accessToken = await _secureStorage.read(key: _keyAccess);
    _refreshToken = await _secureStorage.read(key: _keyRefresh);
    _userId = await _secureStorage.read(key: _keyUserId);
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

    await Future.wait([
      _secureStorage.write(key: _keyAccess, value: accessToken),
      _secureStorage.write(key: _keyRefresh, value: refreshToken),
      _secureStorage.write(key: _keyUserId, value: userId),
    ]);

    // isNewUser is non-sensitive — SharedPreferences is fine
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsNew, isNewUser);

    notifyListeners();
  }

  Future<void> updateAccessToken(String token) async {
    _accessToken = token;
    await _secureStorage.write(key: _keyAccess, value: token);
    notifyListeners();
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;

    await Future.wait([
      _secureStorage.delete(key: _keyAccess),
      _secureStorage.delete(key: _keyRefresh),
      _secureStorage.delete(key: _keyUserId),
    ]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
