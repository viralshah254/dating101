import '../../domain/models/photo_view_request.dart';
import '../../domain/repositories/photo_view_request_repository.dart';

/// Fake implementation: no photo view requests; all operations no-op.
class FakePhotoViewRequestRepository implements PhotoViewRequestRepository {
  @override
  Future<void> sendRequest(String targetUserId) async {}

  @override
  Future<PhotoViewStatus?> getStatus(String targetUserId) async => null;

  @override
  Future<List<ReceivedPhotoViewRequest>> getReceived({
    int page = 1,
    int limit = 20,
    String status = 'pending',
  }) async => [];

  @override
  Future<int> getReceivedCount() async => 0;

  @override
  Future<void> accept(String requestId) async {}

  @override
  Future<void> decline(String requestId) async {}
}
