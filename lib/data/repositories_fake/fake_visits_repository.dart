import '../../domain/models/visitor_entry.dart';
import '../../domain/repositories/visits_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeVisitsRepository implements VisitsRepository {
  @override
  Future<void> recordVisit(
    String profileId, {
    String? source,
    int? durationMs,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<VisitorsResult> getVisitors({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = <VisitorEntry>[];
    var count = 0;
    for (final entry in FakeData.allProfiles.entries) {
      if (entry.key == FakeData.myProfile.id) continue;
      if (count >= limit) break;
      final p = entry.value;
      list.add(VisitorEntry(
        visitId: 'vis_$count',
        visitor: profileToSummary(p),
        visitedAt: DateTime.now().subtract(Duration(hours: count + 1)),
        source: 'recommended',
      ));
      count++;
    }
    return VisitorsResult(visitors: list, newCount: list.length);
  }

  @override
  Future<void> markVisitorsSeen() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
