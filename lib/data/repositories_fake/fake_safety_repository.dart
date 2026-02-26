import '../../domain/models/blocked_user_entry.dart';
import '../../domain/repositories/safety_repository.dart';

class FakeSafetyRepository implements SafetyRepository {
  @override
  Future<void> block(
    String blockedUserId,
    String reason, {
    String? source,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
  }

  @override
  Future<void> report(
    String reportedUserId,
    String reason, {
    String? details,
    String? source,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
  }

  @override
  Future<List<BlockedUserEntry>> getBlockedUsers({
    int limit = 50,
    String? cursor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return [];
  }

  @override
  Future<void> unblock(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
