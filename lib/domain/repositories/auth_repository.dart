/// Result of sign-in (phone/email/social).
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess({this.userId, this.isNewUser = false});
  final String? userId;
  final bool isNewUser;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Auth: phone/email/social sign-in, OTP verify, sign-out.
/// Implement with FakeAuthRepository for now; later FirebaseAuth.
abstract class AuthRepository {
  /// Send OTP to phone; returns success or error message.
  Future<AuthResult> sendOtp({required String countryCode, required String phone});

  /// Verify OTP and return auth result.
  Future<AuthResult> verifyOtp({required String verificationId, required String code});

  /// Sign in with email (for dev); no real email auth in fake.
  Future<AuthResult> signInWithEmail({required String email});

  /// Sign in with Google (placeholder).
  Future<AuthResult> signInWithGoogle();

  /// Sign in with Apple (placeholder).
  Future<AuthResult> signInWithApple();

  /// Current user id if logged in.
  Stream<String?> get currentUserId;

  /// Sign out.
  Future<void> signOut();
}
