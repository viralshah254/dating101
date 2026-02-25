import '../../domain/models/mutual_match_entry.dart';
import '../../domain/repositories/matches_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeMatchesRepository implements MatchesRepository {
  @override
  Future<List<MutualMatchEntry>> getMatches({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = <MutualMatchEntry>[];
    var i = 0;
    for (final entry in FakeData.allProfiles.entries) {
      if (entry.key == FakeData.myProfile.id) continue;
      if (i >= limit) break;
      list.add(MutualMatchEntry(
        matchId: 'match_$i',
        profile: profileToSummary(entry.value),
        matchedAt: DateTime.now().subtract(Duration(days: i)),
        chatThreadId: 'thread_$i',
        lastMessage: i == 0 ? 'Hi!' : null,
      ));
      i++;
    }
    return list;
  }

  @override
  Future<void> unmatch(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
