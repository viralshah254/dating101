import 'dart:async';

import '../../domain/repositories/auth_repository.dart';

/// Fake auth: no real OTP; succeeds after "verify" for testing.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository() {
    _userIdController = StreamController<String?>.broadcast();
    _userIdController.add(_currentUserId);
  }

  String? _currentUserId;
  late final StreamController<String?> _userIdController;

  static const String _fakeUserId = 'fake-user-1';

  @override
  Future<AuthResult> sendOtp({
    required String countryCode,
    required String phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (phone.length < 10) {
      return const AuthFailure('Please enter a valid phone number');
    }
    return const AuthSuccess(userId: null, isNewUser: true);
  }

  @override
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (code.length != 6) {
      return const AuthFailure('Please enter a 6-digit code');
    }
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    return AuthSuccess(userId: _currentUserId, isNewUser: true);
  }

  @override
  Future<AuthResult> signInWithEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    return AuthSuccess(userId: _currentUserId, isNewUser: false);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    return AuthSuccess(userId: _currentUserId, isNewUser: false);
  }

  @override
  Future<AuthResult> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    return AuthSuccess(userId: _currentUserId, isNewUser: false);
  }

  @override
  Stream<String?> get currentUserId => _userIdController.stream;

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _userIdController.add(null);
  }
}
