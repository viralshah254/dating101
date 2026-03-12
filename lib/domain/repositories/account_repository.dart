/// Account lifecycle: export data, deactivate, delete.
/// See docs/BACKEND_CROSS_CUTTING.md §5.3.
abstract class AccountRepository {
  /// Request a copy of the user's data (POST /account/export).
  /// Returns requestId and status; backend emails when ready.
  Future<ExportDataResult> requestDataExport();

  /// Deactivate account (reversible). POST /account/deactivate.
  Future<void> deactivateAccount({String? reason});

  /// Reactivate account. POST /account/reactivate. Callable when deactivated.
  Future<void> reactivateAccount();

  /// Permanently delete account. POST /account/delete.
  /// [confirmation] — when the app requires "Type DELETE", send "DELETE" so backend can verify.
  Future<void> deleteAccount({String? reason, String? confirmation});
}

class ExportDataResult {
  const ExportDataResult({
    required this.requestId,
    this.status = 'pending',
    this.message,
  });
  final String requestId;
  final String status;
  final String? message;
}
