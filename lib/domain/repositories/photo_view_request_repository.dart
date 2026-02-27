import '../models/photo_view_request.dart';
import '../models/profile_summary.dart';

/// Photo view requests: user A requests to view user B's hidden photos;
/// B sees the request in Requests and can accept/decline.
abstract class PhotoViewRequestRepository {
  /// Send a request to view [targetUserId]'s photos. They must have photos hidden.
  Future<void> sendRequest(String targetUserId);

  /// Get current user's status for viewing [targetUserId]'s photos.
  /// Returns null if target has not hidden photos or on error.
  Future<PhotoViewStatus?> getStatus(String targetUserId);

  /// List received photo view requests (people who want to view my photos).
  Future<List<ReceivedPhotoViewRequest>> getReceived({
    int page = 1,
    int limit = 20,
    String status = 'pending',
  });

  /// Count of pending received photo view requests (for badge).
  Future<int> getReceivedCount();

  /// Accept a received request. Caller must be the profile owner.
  Future<void> accept(String requestId);

  /// Decline a received request.
  Future<void> decline(String requestId);
}
