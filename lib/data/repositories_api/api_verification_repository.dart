import '../../domain/repositories/verification_repository.dart';
import '../api/api_client.dart';

class ApiVerificationRepository implements VerificationRepository {
  ApiVerificationRepository({required this.api});
  final ApiClient api;

  @override
  Future<IdUploadUrlResult> getIdUploadUrl({String? type}) async {
    final body = await api.post(
      '/verification/id/upload-url',
      body: type != null ? {'type': type} : <String, dynamic>{},
    );
    return IdUploadUrlResult(
      uploadUrl: body['uploadUrl'] as String? ?? '',
      key: body['key'] as String? ?? '',
    );
  }

  @override
  Future<void> submitIdVerification(String key) async {
    await api.post('/verification/id/submit', body: {'key': key});
  }

  @override
  Future<void> submitPhotoVerification({String? key}) async {
    await api.post('/verification/photo', body: key != null ? {'key': key} : <String, dynamic>{});
  }

  @override
  Future<String> getLinkedInAuthUrl() async {
    final body = await api.get('/verification/linkedin/auth-url');
    return body['url'] as String? ?? '';
  }

  @override
  Future<void> linkedInCallback(String code) async {
    await api.post('/verification/linkedin/callback', body: {'code': code});
  }

  @override
  Future<void> submitEducationVerification({
    String? institutionName,
    String? degree,
    String? documentKey,
  }) async {
    final body = <String, dynamic>{};
    if (institutionName != null) body['institutionName'] = institutionName;
    if (degree != null) body['degree'] = degree;
    if (documentKey != null) body['documentKey'] = documentKey;
    await api.post('/verification/education', body: body);
  }
}
