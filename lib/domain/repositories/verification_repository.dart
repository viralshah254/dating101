/// Verification: ID upload, photo, LinkedIn, education. See BACKEND_API_REFERENCE §8c.
abstract class VerificationRepository {
  /// POST /verification/id/upload-url — returns uploadUrl and key for ID image.
  Future<IdUploadUrlResult> getIdUploadUrl({String? type});

  /// POST /verification/id/submit — submit after uploading to presigned URL. Key from getIdUploadUrl.
  Future<void> submitIdVerification(String key);

  /// POST /verification/photo — set photoVerified (optional body: key).
  Future<void> submitPhotoVerification({String? key});

  /// GET /verification/linkedin/auth-url — OAuth URL to open in browser.
  Future<String> getLinkedInAuthUrl();

  /// POST /verification/linkedin/callback — exchange code for token, set linkedInVerified.
  Future<void> linkedInCallback(String code);

  /// POST /verification/education — set educationVerified.
  Future<void> submitEducationVerification({String? institutionName, String? degree, String? documentKey});
}

class IdUploadUrlResult {
  const IdUploadUrlResult({required this.uploadUrl, required this.key});
  final String uploadUrl;
  final String key;
}
