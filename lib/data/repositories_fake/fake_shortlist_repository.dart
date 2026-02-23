import '../../domain/models/profile_summary.dart';
import '../../domain/repositories/shortlist_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeShortlistRepository implements ShortlistRepository {
  final Set<String> _ids = {};
  List<ProfileSummary>? _cached;

  @override
  Future<List<ProfileSummary>> getShortlist({int limit = 100}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = <ProfileSummary>[];
    for (final id in _ids) {
      if (list.length >= limit) break;
      final p = FakeData.allProfiles[id];
      if (p != null) list.add(profileToSummary(p));
    }
    _cached = list;
    return list;
  }

  @override
  Future<void> addToShortlist(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _ids.add(userId);
    _cached = null;
  }

  @override
  Future<void> removeFromShortlist(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _ids.remove(userId);
    _cached = null;
  }

  @override
  Future<bool> isShortlisted(String userId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _ids.contains(userId);
  }
}
