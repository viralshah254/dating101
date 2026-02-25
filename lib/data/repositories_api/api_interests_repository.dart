import '../../domain/models/interaction_models.dart';
import '../../domain/repositories/interests_repository.dart';
import '../api/api_client.dart';

class ApiInterestsRepository implements InterestsRepository {
  ApiInterestsRepository({required this.api});
  final ApiClient api;

  @override
  Future<Interest> sendInterest(String toUserId) async {
    final body = await api.post('/interests', body: {'toUserId': toUserId});
    return _parse(body);
  }

  @override
  Future<List<Interest>> getReceivedInterests({int limit = 50}) async {
    final body = await api.get('/interests/received', query: {'limit': '$limit'});
    return _parseList(body['interests'] as List? ?? []);
  }

  @override
  Future<List<Interest>> getSentInterests({int limit = 50}) async {
    final body = await api.get('/interests/sent', query: {'limit': '$limit'});
    return _parseList(body['interests'] as List? ?? []);
  }

  @override
  Future<Interest> acceptInterest(String interestId) async {
    final body = await api.post('/interests/$interestId/accept');
    return _parse(body);
  }

  @override
  Future<Interest> declineInterest(String interestId) async {
    final body = await api.post('/interests/$interestId/decline');
    return _parse(body);
  }

  @override
  Future<void> withdrawInterest(String interestId) async {
    await api.delete('/interests/$interestId');
  }

  static Interest _parse(Map<String, dynamic> j) {
    return Interest(
      id: j['id'] as String? ?? '',
      fromUserId: j['fromUserId'] as String? ?? '',
      toUserId: j['toUserId'] as String? ?? '',
      sentAt: DateTime.parse(j['sentAt'] as String),
      status: _parseStatus(j['status'] as String?),
    );
  }

  static List<Interest> _parseList(List list) =>
      list.map((e) => _parse(e as Map<String, dynamic>)).toList();

  static InterestStatus _parseStatus(String? s) => switch (s) {
        'accepted' => InterestStatus.accepted,
        'rejected' => InterestStatus.rejected,
        'withdrawn' => InterestStatus.withdrawn,
        _ => InterestStatus.pending,
      };
}
