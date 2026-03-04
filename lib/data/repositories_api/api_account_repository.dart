import '../../domain/repositories/account_repository.dart';
import '../api/api_client.dart';

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository({required this.api});
  final ApiClient api;

  @override
  Future<ExportDataResult> requestDataExport() async {
    final body = await api.post('/account/export', body: <String, dynamic>{});
    return ExportDataResult(
      requestId: body['requestId'] as String? ?? '',
      status: body['status'] as String? ?? 'pending',
      message: body['message'] as String?,
    );
  }

  @override
  Future<void> deactivateAccount({String? reason}) async {
    await api.post(
      '/account/deactivate',
      body: reason != null ? {'reason': reason} : <String, dynamic>{},
    );
  }

  @override
  Future<void> reactivateAccount() async {
    await api.post('/account/reactivate', body: <String, dynamic>{});
  }

  @override
  Future<void> deleteAccount({String? reason}) async {
    await api.post(
      '/account/delete',
      body: reason != null ? {'reason': reason} : <String, dynamic>{},
    );
  }
}
