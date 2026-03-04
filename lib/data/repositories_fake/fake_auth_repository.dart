import 'dart:async';

import '../../domain/repositories/auth_repository.dart';

/// Fake auth for development. Any 6-digit code succeeds.
/// Simulates new vs returning user based on phone number.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository() {
    _userIdController = StreamController<String?>.broadcast();
    _userIdController.add(_currentUserId);
  }

  String? _currentUserId;
  late final StreamController<String?> _userIdController;
  bool _lastOtpIsNewUser = true;

  static const String _fakeUserId = 'me';

  /// Phones ending in 0000 are treated as "returning" users for testing.
  static bool _isReturningUser(String phone) {
    return phone.trim().endsWith('0000');
  }

  @override
  Future<SendOtpResult> sendOtp({
    required String countryCode,
    required String phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (phone.length < 7) {
      return const SendOtpFailure('Please enter a valid phone number');
    }
    _lastOtpIsNewUser = !_isReturningUser(phone);
    return const SendOtpSuccess(verificationId: 'fake-verification-id');
  }

  @override
  Future<AuthResult> verifyOtp({
    required String verificationId,
    required String code,
    String? referralCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (code.length != 4) {
      return const AuthFailure('Please enter a 4-digit code');
    }
    _currentUserId = _fakeUserId;
    _userIdController.add(_currentUserId);
    final referralApplied = _lastOtpIsNewUser &&
        referralCode != null &&
        referralCode.trim().isNotEmpty;
    return AuthSuccess(
      userId: _currentUserId,
      isNewUser: _lastOtpIsNewUser,
      referralApplied: referralApplied,
    );
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
