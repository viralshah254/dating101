/// Result of an OTP send attempt.
sealed class SendOtpResult {
  const SendOtpResult();
}

class SendOtpSuccess extends SendOtpResult {
  const SendOtpSuccess({required this.verificationId, this.expiresInSeconds = 300});
  final String verificationId;
  final int expiresInSeconds;
}

class SendOtpFailure extends SendOtpResult {
  const SendOtpFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Result of OTP verification / sign-in.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess({this.userId, this.isNewUser = false});
  final String? userId;

  /// true = user has no profile yet → route to mode-select / signup flow
  /// false = returning user → route to home
  final bool isNewUser;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Auth: phone OTP sign-in, social sign-in, sign-out.
abstract class AuthRepository {
  /// Send OTP to phone. Returns verificationId on success.
  Future<SendOtpResult> sendOtp({required String countryCode, required String phone});

  /// Verify OTP code. Returns auth tokens + whether user is new or returning.
  Future<AuthResult> verifyOtp({required String verificationId, required String code});

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
