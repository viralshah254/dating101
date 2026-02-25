import '../../domain/models/profile_summary.dart';
import '../../domain/models/who_shortlisted_me_entry.dart';
import '../../domain/repositories/shortlist_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeShortlistRepository implements ShortlistRepository {
  final Set<String> _ids = {};

  @override
  Future<List<ProfileSummary>> getShortlist({int limit = 100, int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = <ProfileSummary>[];
    for (final id in _ids) {
      if (list.length >= limit) break;
      final p = FakeData.allProfiles[id];
      if (p != null) list.add(profileToSummary(p));
    }
    return list;
  }

  @override
  Future<void> addToShortlist(String profileId, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _ids.add(profileId);
  }

  @override
  Future<void> removeFromShortlist(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _ids.remove(userId);
  }

  @override
  Future<bool> isShortlisted(String userId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _ids.contains(userId);
  }

  @override
  Future<List<WhoShortlistedMeEntry>> getWhoShortlistedMe({int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      const WhoShortlistedMeEntry(profileId: 'usr_fake1', firstName: 'Priya', age: 27, blurred: false),
      const WhoShortlistedMeEntry(profileId: 'usr_fake2', firstName: 'Ananya', age: 25, blurred: false),
    ];
  }

  @override
  Future<int> getWhoShortlistedMeCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = await getWhoShortlistedMe(limit: 100);
    return list.length;
  }
}
