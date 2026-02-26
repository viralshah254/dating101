import '../../domain/repositories/account_repository.dart';

class FakeAccountRepository implements AccountRepository {
  @override
  Future<ExportDataResult> requestDataExport() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const ExportDataResult(
      requestId: 'exp_fake_001',
      status: 'pending',
      message: "We'll email you when your data is ready.",
    );
  }

  @override
  Future<void> deactivateAccount({String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> reactivateAccount() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> deleteAccount({String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
