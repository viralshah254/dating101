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
  Future<void> submitIdVerification(String key, {String? selfieKey}) async {
    final body = <String, dynamic>{'key': key};
    if (selfieKey != null) body['selfieKey'] = selfieKey;
    await api.post('/verification/id/submit', body: body);
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

  @override
  Future<LivenessSession> createLivenessSession() async {
    final body = await api.post('/verification/liveness/session');
    return LivenessSession(
      provider: body['provider'] as String? ?? 'persona',
      sessionId: body['sessionId'] as String? ?? '',
      hostedUrl: body['hostedUrl'] as String?,
    );
  }

  @override
  Future<LivenessResult> confirmLivenessSession(String sessionId, {String? provider}) async {
    final reqBody = <String, dynamic>{'sessionId': sessionId};
    if (provider != null) reqBody['provider'] = provider;
    final body = await api.post('/verification/liveness/confirm', body: reqBody);
    return LivenessResult(
      verified: body['verified'] as bool? ?? false,
      idVerified: body['idVerified'] as bool? ?? false,
    );
  }
}
