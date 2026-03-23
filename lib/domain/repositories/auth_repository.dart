/// Result of phone + password sign-in / sign-up.
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
  /// false = returning user → route to home
  final bool isNewUser;

  /// true when backend applied a valid referral code and granted 30 days Premium (response field referralApplied).
  final bool referralApplied;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Auth: phone + password, social sign-in, sign-out.
abstract class AuthRepository {
  /// Create account with phone + password. Fails if the number is already registered.
  Future<AuthResult> signUpWithPassword({
    required String countryCode,
    required String phone,
    required String password,
    String? referralCode,
  });

  /// Sign in with phone + password.
  Future<AuthResult> signInWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  });

  /// Sign in with Google.
  Future<AuthResult> signInWithGoogle();

  /// Sign in with Apple.
  Future<AuthResult> signInWithApple();

  /// Current user id (null = not logged in). Synchronous check.
  String? get currentUserId;

  /// Stream of auth state changes.
  Stream<String?> get authStateChanges;

  /// Sign out.
  Future<void> signOut();
}
