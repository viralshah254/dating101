import '../../domain/models/visitor_entry.dart';
import '../../domain/repositories/visits_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

class ApiVisitsRepository implements VisitsRepository {
  ApiVisitsRepository({required this.api});
  final ApiClient api;

  @override
  Future<void> recordVisit(
    String profileId, {
    String? source,
    int? durationMs,
  }) async {
    final body = <String, dynamic>{'profileId': profileId};
    if (source != null && source.isNotEmpty) body['source'] = source;
    if (durationMs != null) body['durationMs'] = durationMs;
    await api.post('/visits', body: body);
  }

  @override
  Future<VisitorsResult> getVisitors({int page = 1, int limit = 20}) async {
    final body = await api.get(
      '/visits/received',
      query: {'page': '$page', 'limit': '$limit'},
    );
    final list = body['visitors'] as List? ?? [];
    final visitors = list
        .map((e) {
          final map = e as Map<String, dynamic>;
          final visitorMap = map['visitor'] as Map<String, dynamic>? ?? map;
          return VisitorEntry(
            visitId: map['visitId'] as String? ?? '',
            visitor: ApiProfileRepository.parseSummaryPublic(visitorMap),
            visitedAt: DateTime.parse(map['visitedAt'] as String),
            source: map['source'] as String?,
          );
        })
        .toList();
    final newCount = body['newCount'] as int? ?? 0;
    return VisitorsResult(visitors: visitors, newCount: newCount);
  }

  @override
  Future<void> markVisitorsSeen() async {
    await api.post('/visits/mark-seen');
  }
}
