import 'package:flutter/foundation.dart';

import '../../domain/models/mutual_match_entry.dart';
import '../../domain/repositories/matches_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

class ApiMatchesRepository implements MatchesRepository {
  ApiMatchesRepository({required this.api});
  final ApiClient api;

  @override
  Future<List<MutualMatchEntry>> getMatches({
    int page = 1,
    int limit = 20,
  }) async {
    final body = await api.get(
      '/matches',
      query: {'page': '$page', 'limit': '$limit'},
    );
    final list = body['matches'] as List? ?? [];
    if (kDebugMode && list.isNotEmpty) {
      debugPrint('[Matches] GET /matches returned ${list.length} match(es)');
    }
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final profileMap = map['profile'] as Map<String, dynamic>? ?? {};
      final lastMessageAtStr = map['lastMessageAt'] as String?;
      return MutualMatchEntry(
        matchId: map['matchId'] as String? ?? '',
        profile: ApiProfileRepository.parseSummaryPublic(profileMap),
        matchedAt: DateTime.parse(map['matchedAt'] as String),
        chatThreadId: map['chatThreadId'] as String?,
        lastMessage: map['lastMessage'] as String?,
        lastMessageAt: lastMessageAtStr != null
            ? DateTime.tryParse(lastMessageAtStr)
            : null,
      );
    }).toList();
  }

  @override
  Future<void> unmatch(String matchId) async {
    await api.delete('/matches/$matchId');
  }
}
