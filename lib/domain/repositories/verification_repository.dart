/// Verification: ID upload, photo, LinkedIn, education. See BACKEND_API_REFERENCE §8c.
abstract class VerificationRepository {
  /// POST /verification/id/upload-url — returns uploadUrl and key for ID image.
  Future<IdUploadUrlResult> getIdUploadUrl({String? type});

  /// POST /verification/id/submit — submit after uploading to presigned URL.
  /// [key] is the ID document key; [selfieKey] is the selfie key (both from getIdUploadUrl).
  Future<void> submitIdVerification(String key, {String? selfieKey});

  /// POST /verification/photo — set photoVerified (optional body: key).
  Future<void> submitPhotoVerification({String? key});

  /// GET /verification/linkedin/auth-url — OAuth URL to open in browser.
  Future<String> getLinkedInAuthUrl();

  /// POST /verification/linkedin/callback — exchange code for token, set linkedInVerified.
  Future<void> linkedInCallback(String code);

  /// POST /verification/education — set educationVerified.
  Future<void> submitEducationVerification({String? institutionName, String? degree, String? documentKey});

  // ── Liveness / Identity Verification ─────────────────────────────────────

  /// POST /verification/liveness/session — creates a Persona or Rekognition session.
  /// Persona: returns hostedUrl to open in WebView + sessionId (inquiry ID).
  /// Rekognition: returns sessionId only (used with FaceLivenessDetector widget).
  Future<LivenessSession> createLivenessSession();

  /// POST /verification/liveness/confirm — verifies the completed session with the provider.
  /// On success, backend sets photoVerified = true (and idVerified = true for Persona).
  /// [provider] is optional; backend auto-detects from sessionId format if omitted.
  Future<LivenessResult> confirmLivenessSession(String sessionId, {String? provider});
}

class IdUploadUrlResult {
  const IdUploadUrlResult({required this.uploadUrl, required this.key});
  final String uploadUrl;
  final String key;
}

/// Result from POST /verification/liveness/session.
class LivenessSession {
  const LivenessSession({
    required this.provider,
    required this.sessionId,
    this.hostedUrl,
  });

  /// "persona" or "rekognition"
  final String provider;

  /// Persona: inquiry ID (inq_xxx). Rekognition: session ID (UUID).
  final String sessionId;

  /// Persona only: full URL to load in WebView.
  final String? hostedUrl;

  bool get isPersona => provider == 'persona';
  bool get isRekognition => provider == 'rekognition';
}

/// Result from POST /verification/liveness/confirm.
class LivenessResult {
  const LivenessResult({required this.verified, required this.idVerified});

  /// Selfie / liveness verified.
  final bool verified;

  /// Government ID also verified (true for Persona, false for Rekognition-only).
  final bool idVerified;
}
