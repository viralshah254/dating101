/// Phone + password sign-in / sign-up (no OTP in current product flow).
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess({
    this.userId,
    this.isNewUser = false,
    this.referralApplied = false,
  });
  final String? userId;

  /// true = user has no profile yet → route to mode-select / signup flow
  final bool isNewUser;

  /// Referral benefit applied on register.
  final bool referralApplied;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Auth: phone + password, social sign-in, sign-out.
abstract class AuthRepository {
  /// New account: POST /auth/register
  Future<AuthResult> signUpWithPassword({
    required String countryCode,
    required String phone,
    required String password,
    String? referralCode,
  });

  /// Existing account: POST /auth/login (legacy OTP-only users: first password is saved, then login)
  Future<AuthResult> signInWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  });

  Future<AuthResult> signInWithGoogle();

  Future<AuthResult> signInWithApple();

  String? get currentUserId;

  Stream<String?> get authStateChanges;

  Future<void> signOut();
}
