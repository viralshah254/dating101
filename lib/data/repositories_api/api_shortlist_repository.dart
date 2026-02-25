import '../../domain/models/profile_summary.dart';
import '../../domain/models/who_shortlisted_me_entry.dart';
import '../../domain/repositories/shortlist_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

class ApiShortlistRepository implements ShortlistRepository {
  ApiShortlistRepository({required this.api});
  final ApiClient api;

  @override
  Future<List<ProfileSummary>> getShortlist({int limit = 100, int page = 1}) async {
    final body = await api.get('/shortlist', query: {'page': '$page', 'limit': '$limit'});
    final list = body['profiles'] as List? ?? [];
    return list
        .map((e) {
          final entry = e as Map<String, dynamic>;
          final profile = entry['profile'] as Map<String, dynamic>? ?? entry;
          return ApiProfileRepository.parseSummaryPublic(profile);
        })
        .toList();
  }

  @override
  Future<void> addToShortlist(String profileId, {String? note}) async {
    final payload = <String, dynamic>{'profileId': profileId};
    if (note != null && note.isNotEmpty) payload['note'] = note;
    await api.post('/shortlist', body: payload);
  }

  @override
  Future<void> removeFromShortlist(String userId) async {
    await api.delete('/shortlist/$userId');
  }

  @override
  Future<bool> isShortlisted(String userId) async {
    final body = await api.get('/shortlist/$userId/check');
    return body['shortlisted'] as bool? ?? false;
  }

  @override
  Future<List<WhoShortlistedMeEntry>> getWhoShortlistedMe({int page = 1, int limit = 20}) async {
    final body = await api.get('/shortlist/received', query: {'page': '$page', 'limit': '$limit'});
    final list = body['profiles'] as List? ?? [];
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final blurred = map['blurred'] as bool? ?? false;
      return WhoShortlistedMeEntry(
        profileId: map['profileId'] as String? ?? '',
        firstName: map['firstName'] as String? ?? '',
        age: map['age'] as int?,
        name: map['name'] as String?,
        imageUrl: map['imageUrl'] as String?,
        blurred: blurred,
      );
    }).toList();
  }

  @override
  Future<int> getWhoShortlistedMeCount() async {
    final body = await api.get('/shortlist/received/count');
    return body['count'] as int? ?? 0;
  }
}
