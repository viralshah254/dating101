import 'dart:async';

import '../../domain/repositories/auth_repository.dart';

/// Fake auth for development. Any password with length ≥ 8 succeeds.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository() {
    _userIdController = StreamController<String?>.broadcast();
    _userIdController.add(_currentUserId);
  }

  String? _currentUserId;
  late final StreamController<String?> _userIdController;

  static const String _fakeUserId = 'me';

  static bool _isReturningUser(String phone) {
    return phone.trim().endsWith('0000');
  }

  @override
  Future<AuthResult> signUpWithPassword({
    required String countryCode,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (phone.length < 7) {
      return const AuthFailure('Please enter a valid phone number');
    }
    if (password.length < 8) {
      return const AuthFailure('Password must be at least 8 characters.');
    }
    if (phone.trim().endsWith('1111')) {
      return const AuthFailure(
        'An account with this phone number already exists. Sign in instead.',
        code: 'ALREADY_EXISTS',
      );
    }
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    final referralApplied = referralCode != null && referralCode.trim().isNotEmpty;
    return AuthSuccess(
      userId: _currentUserId,
      isNewUser: true,
      referralApplied: referralApplied,
    );
  }

  @override
  Future<AuthResult> signInWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (phone.length < 7) {
      return const AuthFailure('Please enter a valid phone number');
    }
    if (password.length < 8) {
      return const AuthFailure('Password must be at least 8 characters.');
    }
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    final isNewUser = !_isReturningUser(phone);
    return AuthSuccess(userId: _currentUserId, isNewUser: isNewUser);
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
  String? get currentUserId => _currentUserId;

  @override
  Stream<String?> get authStateChanges => _userIdController.stream;

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _userIdController.add(null);
  }
}
