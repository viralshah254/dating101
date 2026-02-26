import '../../domain/models/blocked_user_entry.dart';
import '../../domain/repositories/safety_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

class ApiSafetyRepository implements SafetyRepository {
  ApiSafetyRepository({required this.api});
  final ApiClient api;

  @override
  Future<void> block(
    String blockedUserId,
    String reason, {
    String? source,
  }) async {
    final body = <String, dynamic>{
      'blockedUserId': blockedUserId,
      'reason': reason,
    };
    if (source != null && source.isNotEmpty) body['source'] = source;
    await api.post('/safety/block', body: body);
  }

  @override
  Future<void> report(
    String reportedUserId,
    String reason, {
    String? details,
    String? source,
  }) async {
    final body = <String, dynamic>{
      'reportedUserId': reportedUserId,
      'reason': reason,
    };
    if (details != null && details.isNotEmpty) body['details'] = details;
    if (source != null && source.isNotEmpty) body['source'] = source;
    await api.post('/safety/report', body: body);
  }

  @override
  Future<List<BlockedUserEntry>> getBlockedUsers({
    int limit = 50,
    String? cursor,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    final body = await api.get('/safety/blocked', query: query);
    final list = body['blocked'] as List? ?? [];
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final profileMap = map['profile'] as Map<String, dynamic>? ?? {};
      return BlockedUserEntry(
        blockedUserId: map['blockedUserId'] as String? ?? '',
        blockedAt: DateTime.parse(map['blockedAt'] as String),
        profile: ApiProfileRepository.parseSummaryPublic(profileMap),
      );
    }).toList();
  }

  @override
  Future<void> unblock(String userId) async {
    await api.delete('/safety/blocked/$userId');
  }
}
