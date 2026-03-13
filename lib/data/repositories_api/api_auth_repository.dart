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
      return SendOtpFailure(_userFriendlyMessage(e), code: e.code);
    } catch (e) {
      debugPrint('[Auth] sendOtp ✗ Connection error: $e');
      return SendOtpFailure(_connectionErrorMessage(e));
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String code,
    String? referralCode,
  }) async {
    debugPrint('[Auth] verifyOtp → vid=$verificationId, code=$code, referralCode=${referralCode != null ? "***" : null}');
    try {
      final requestBody = <String, dynamic>{
        'verificationId': verificationId,
        'code': code,
      };
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        requestBody['referralCode'] = referralCode.trim();
      }
      final body = await api.postNoAuth('/auth/verify-otp', body: requestBody);
      final userId = body['userId'] as String;
      final isNewUser = body['isNewUser'] as bool? ?? false;
      final referralApplied = body['referralApplied'] as bool? ?? false;
      debugPrint('[Auth] verifyOtp ✓ userId=$userId, isNewUser=$isNewUser, referralApplied=$referralApplied');
      await tokenStorage.save(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
        userId: userId,
        isNewUser: isNewUser,
      );
      _authStateController.add(userId);
      return AuthSuccess(userId: userId, isNewUser: isNewUser, referralApplied: referralApplied);
    } on ApiException catch (e) {
      debugPrint('[Auth] verifyOtp ✗ ${e.code}: ${e.message}');
      return AuthFailure(_userFriendlyMessage(e), code: e.code);
    } catch (e) {
      debugPrint('[Auth] verifyOtp ✗ Connection error: $e');
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
        if (tokenStorage.refreshToken != null)
          'refreshToken': tokenStorage.refreshToken,
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
        return 'Invalid phone number. Please check and try again.';
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
