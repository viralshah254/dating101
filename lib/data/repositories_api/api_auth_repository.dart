import 'dart:async';

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

  @override
  Future<SendOtpResult> sendOtp({
    required String countryCode,
    required String phone,
  }) async {
    debugPrint('[Auth] sendOtp → $countryCode $phone');
    try {
      final body = await api.postNoAuth('/auth/send-otp', body: {
        'countryCode': countryCode,
        'phone': phone,
      });
      debugPrint('[Auth] sendOtp ✓ verificationId=${body['verificationId']}');
      return SendOtpSuccess(
        verificationId: body['verificationId'] as String,
        expiresInSeconds: body['expiresInSeconds'] as int? ?? 300,
      );
    } on ApiException catch (e) {
      debugPrint('[Auth] sendOtp ✗ ${e.code}: ${e.message}');
      return SendOtpFailure(e.message, code: e.code);
    } catch (e) {
      debugPrint('[Auth] sendOtp ✗ Connection error: $e');
      return SendOtpFailure('Connection error: $e');
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    debugPrint('[Auth] verifyOtp → vid=$verificationId, code=$code');
    try {
      final body = await api.postNoAuth('/auth/verify-otp', body: {
        'verificationId': verificationId,
        'code': code,
      });
      final userId = body['userId'] as String;
      final isNewUser = body['isNewUser'] as bool? ?? false;
      debugPrint('[Auth] verifyOtp ✓ userId=$userId, isNewUser=$isNewUser');
      await tokenStorage.save(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
        userId: userId,
        isNewUser: isNewUser,
      );
      _authStateController.add(userId);
      return AuthSuccess(userId: userId, isNewUser: isNewUser);
    } on ApiException catch (e) {
      debugPrint('[Auth] verifyOtp ✗ ${e.code}: ${e.message}');
      return AuthFailure(e.message, code: e.code);
    } catch (e) {
      debugPrint('[Auth] verifyOtp ✗ Connection error: $e');
      return AuthFailure('Connection error: $e');
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
      await api.post('/auth/sign-out');
    } catch (_) {}
    await tokenStorage.clear();
    _authStateController.add(null);
    debugPrint('[Auth] signOut ✓ cleared tokens');
  }
}
