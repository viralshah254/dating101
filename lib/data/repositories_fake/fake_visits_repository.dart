import '../../domain/models/visitor_entry.dart';
import '../../domain/models/visitor_unlock_result.dart';
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

  @override
  Future<VisitorUnlockResult?> unlockOneVisitor({
    required String visitId,
    required String adCompletionToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final result = await getVisitors(limit: 50);
    VisitorEntry? entry;
    for (final e in result.visitors) {
      if (e.visitId == visitId) {
        entry = e;
        break;
      }
    }
    if (entry == null) return null;
    return VisitorUnlockResult(
      visitId: entry.visitId,
      visitor: entry.visitor,
      unlocksRemainingThisWeek: 1,
      resetsAt: DateTime.now().add(const Duration(days: 7)),
    );
  }
}
