import '../../domain/repositories/verification_repository.dart';

class FakeVerificationRepository implements VerificationRepository {
  @override
  Future<IdUploadUrlResult> getIdUploadUrl({String? type}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const IdUploadUrlResult(
      uploadUrl: 'https://fake.s3.amazonaws.com/verification/id/fake-key',
      key: 'verification/id/fake-key',
    );
  }

  @override
  Future<IdUploadUrlResult> getEducationUploadUrl({String contentType = 'image/jpeg'}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const IdUploadUrlResult(
      uploadUrl: 'https://fake.s3.amazonaws.com/verification/education/fake-key',
      key: 'verification/fake-user/education/fake.jpg',
    );
  }

  @override
  Future<void> submitIdVerification(String key, {String? selfieKey}) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> submitPhotoVerification({String? key}) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<String> getLinkedInAuthUrl() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 'https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=fake';
  }

  @override
  Future<void> linkedInCallback(String code) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> submitEducationVerification({
    String? institutionName,
    String? degree,
    String? documentKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<LivenessSession> createLivenessSession() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const LivenessSession(
      provider: 'persona',
      sessionId: 'inq_fake_sandbox_000',
      hostedUrl: 'https://verify.withpersona.com/verify?inquiry-id=inq_fake&session-token=fake',
    );
  }

  @override
  Future<LivenessResult> confirmLivenessSession(String sessionId, {String? provider}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const LivenessResult(verified: true, idVerified: true);
  }
}
