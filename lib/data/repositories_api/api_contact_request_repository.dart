import '../../domain/models/contact_request_status.dart';
import '../../domain/repositories/contact_request_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

/// Contact request API. Backend contract: see docs/BACKEND_CONTACT_REQUESTS.md.
class ApiContactRequestRepository implements ContactRequestRepository {
  ApiContactRequestRepository({required this.api});
  final ApiClient api;

  @override
  Future<ContactRequestStatus> getStatusForProfile(String profileId) async {
    final body = await api.get('/contact-requests/status/$profileId');
    return _parseStatus(body);
  }

  @override
  Future<void> sendContactRequest(String profileId) async {
    await api.post('/contact-requests', body: {'toUserId': profileId});
  }

  @override
  Future<List<ReceivedContactRequest>> getReceivedContactRequests({
    int page = 1,
    int limit = 20,
  }) async {
    final body = await api.get(
      '/contact-requests/received',
      query: {'page': '$page', 'limit': '$limit'},
    );
    final list = body['requests'] as List? ?? [];
    return list.map((e) => _parseReceived(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> getReceivedContactRequestsCount() async {
    final body = await api.get('/contact-requests/received/count');
    final n = body['count'];
    if (n is int) return n;
    if (n is num) return n.toInt();
    return 0;
  }

  @override
  Future<void> acceptContactRequest(String requestId) async {
    await api.post('/contact-requests/$requestId/accept');
  }

  @override
  Future<void> declineContactRequest(String requestId) async {
    await api.post('/contact-requests/$requestId/decline');
  }

  static ContactRequestStatus _parseStatus(Map<String, dynamic> j) {
    final stateStr = j['state'] as String? ?? 'none';
    ContactRequestState state;
    switch (stateStr) {
      case 'pending':
        state = ContactRequestState.pending;
        break;
      case 'accepted':
        state = ContactRequestState.accepted;
        break;
      case 'declined':
        state = ContactRequestState.declined;
        break;
      default:
        state = ContactRequestState.none;
    }
    DateTime? sharedAt;
    final at = j['sharedAt'] as String?;
    if (at != null) sharedAt = DateTime.tryParse(at);
    return ContactRequestStatus(
      state: state,
      requestId: j['requestId'] as String?,
      sharedPhone: j['sharedPhone'] as String?,
      sharedAt: sharedAt,
    );
  }

  static ReceivedContactRequest _parseReceived(Map<String, dynamic> j) {
    final from = j['fromUser'] as Map<String, dynamic>? ?? {};
    return ReceivedContactRequest(
      requestId: j['requestId'] as String? ?? '',
      fromUser: ApiProfileRepository.parseSummaryPublic(from),
      requestedAt:
          DateTime.tryParse(j['requestedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
