import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/auth_repository.dart';
import '../api/api_client.dart';
import '../api/token_storage.dart';

/// Auth repository backed by the real Saathi API.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required this.api, required this.tokenStorage}) {
    _authStateController = StreamController<String?>.broadcast();
    debugPrint('[Auth] ApiAuthRepository created, userId=${tokenStorage.userId}');
  }

  final ApiClient api;
  final TokenStorage tokenStorage;
  late final StreamController<String?> _authStateController;

  @override
  String? get currentUserId => tokenStorage.userId;

  @override
  Stream<String?> get authStateChanges => _authStateController.stream;

  Future<AuthResult> _saveTokensFromBody(Map<String, dynamic> body) async {
    final userId = body['userId'] as String;
    final isNewUser = body['isNewUser'] as bool? ?? false;
    final referralApplied = body['referralApplied'] as bool? ?? false;
    await tokenStorage.save(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
      userId: userId,
      isNewUser: isNewUser,
    );
    _authStateController.add(userId);
    return AuthSuccess(userId: userId, isNewUser: isNewUser, referralApplied: referralApplied);
  }

  @override
  Future<AuthResult> signUpWithPassword({
    required String countryCode,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    debugPrint('[Auth] signUpWithPassword → $countryCode $phone');
    try {
      final requestBody = <String, dynamic>{
        'countryCode': countryCode,
        'phone': phone,
        'password': password,
      };
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        requestBody['referralCode'] = referralCode.trim();
      }
      final body = await api.postNoAuth('/auth/register', body: requestBody);
      debugPrint('[Auth] signUpWithPassword ✓ userId=${body['userId']}');
      return _saveTokensFromBody(body);
    } on ApiException catch (e) {
      debugPrint('[Auth] signUpWithPassword ✗ ${e.code}: ${e.message}');
      return AuthFailure(_userFriendlyMessage(e), code: e.code);
    } catch (e) {
      debugPrint('[Auth] signUpWithPassword ✗ Connection error: $e');
      return AuthFailure(_connectionErrorMessage(e));
    }
  }

  @override
  Future<AuthResult> signInWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  }) async {
    debugPrint('[Auth] signInWithPassword → $countryCode $phone');
    try {
      final body = await api.postNoAuth('/auth/login', body: {
        'countryCode': countryCode,
        'phone': phone,
        'password': password,
      });
      debugPrint('[Auth] signInWithPassword ✓ userId=${body['userId']}');
      return _saveTokensFromBody(body);
    } on ApiException catch (e) {
      debugPrint('[Auth] signInWithPassword ✗ ${e.code}: ${e.message}');
      return AuthFailure(_userFriendlyMessage(e), code: e.code);
    } catch (e) {
      debugPrint('[Auth] signInWithPassword ✗ Connection error: $e');
      return AuthFailure(_connectionErrorMessage(e));
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return const AuthFailure('Google sign-in not yet implemented', code: 'NOT_IMPLEMENTED');
  }

  @override
  Future<AuthResult> signInWithApple() async {
    return const AuthFailure('Apple sign-in not yet implemented', code: 'NOT_IMPLEMENTED');
  }

  @override
  Future<void> signOut() async {
    debugPrint('[Auth] signOut');
    try {
      await api.post('/auth/sign-out', body: {
        if (tokenStorage.refreshToken != null) 'refreshToken': tokenStorage.refreshToken,
      });
    } catch (_) {}
    await tokenStorage.clear();
    _authStateController.add(null);
    debugPrint('[Auth] signOut ✓ cleared tokens');
  }

  static String _userFriendlyMessage(ApiException e) {
    switch (e.code) {
      case 'RATE_LIMITED':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'INVALID_CODE':
        return 'Incorrect code. Please check and try again.';
      case 'EXPIRED_OTP':
      case 'NOT_FOUND':
        return 'Code expired. Please request a new one.';
      case 'SEND_FAILED':
        return 'Could not send SMS. Please try again shortly.';
      case 'INVALID_PHONE':
      case 'INVALID_REQUEST':
      case 'VALIDATION_ERROR':
        return 'Invalid phone number or password. Please check and try again.';
      case 'ALREADY_EXISTS':
        return 'An account with this phone number already exists. Sign in instead.';
      case 'INVALID_CREDENTIALS':
        return 'Invalid phone number or password.';
      case 'PASSWORD_NOT_SET':
        return 'Password sign-in is not set up for this number. Create an account or contact support.';
      case 'SERVER_ERROR':
      case 'INTERNAL_ERROR':
        return 'Something went wrong on our end. Please try again.';
      default:
        if (e.statusCode >= 500) {
          return 'Something went wrong on our end. Please try again.';
        }
        return e.message;
    }
  }

  static String _connectionErrorMessage(Object e) {
    if (e is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (e is TimeoutException || e.toString().contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    return 'Could not reach the server. Please check your internet and try again.';
  }
}
