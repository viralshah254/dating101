import '../../domain/models/photo_view_request.dart';
import '../../domain/repositories/photo_view_request_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

/// Photo view request API. Backend contract: see docs/BACKEND_PHOTO_VISIBILITY_AND_REQUESTS.md.
class ApiPhotoViewRequestRepository implements PhotoViewRequestRepository {
  ApiPhotoViewRequestRepository({required this.api});
  final ApiClient api;

  @override
  Future<void> sendRequest(String targetUserId) async {
    await api.post(
      '/photo-view-requests',
      body: {'targetUserId': targetUserId},
    );
  }

  @override
  Future<PhotoViewStatus?> getStatus(String targetUserId) async {
    try {
      final body = await api.get('/profile/$targetUserId/photo-view-status');
      final statusStr = body['status'] as String? ?? 'none';
      return _parseStatus(statusStr);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static PhotoViewStatus _parseStatus(String s) {
    switch (s) {
      case 'pending':
        return PhotoViewStatus.pending;
      case 'accepted':
        return PhotoViewStatus.accepted;
      case 'declined':
        return PhotoViewStatus.declined;
      default:
        return PhotoViewStatus.none;
    }
  }

  @override
  Future<List<ReceivedPhotoViewRequest>> getReceived({
    int page = 1,
    int limit = 20,
    String status = 'pending',
  }) async {
    final body = await api.get(
      '/photo-view-requests/received',
      query: {'page': '$page', 'limit': '$limit', 'status': status},
    );
    final list = body['requests'] as List? ?? [];
    return list.map((e) => _parseReceived(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> getReceivedCount() async {
    final body = await api.get('/photo-view-requests/received/count');
    final n = body['count'];
    if (n is int) return n;
    if (n is num) return n.toInt();
    return 0;
  }

  @override
  Future<void> accept(String requestId) async {
    await api.post('/photo-view-requests/$requestId/accept');
  }

  @override
  Future<void> decline(String requestId) async {
    await api.post('/photo-view-requests/$requestId/decline');
  }

  static ReceivedPhotoViewRequest _parseReceived(Map<String, dynamic> j) {
    final from = j['fromUser'] as Map<String, dynamic>? ?? {};
    return ReceivedPhotoViewRequest(
      requestId: j['requestId'] as String? ?? '',
      fromUser: ApiProfileRepository.parseSummaryPublic(from),
      status: j['status'] as String? ?? 'pending',
      requestedAt:
          DateTime.tryParse(j['requestedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
