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
  Future<void> submitIdVerification(String key) async {
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
}
