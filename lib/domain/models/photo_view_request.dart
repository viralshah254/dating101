import 'profile_summary.dart';

/// Status of the current user's photo view request toward another profile.
enum PhotoViewStatus { none, pending, accepted, declined }

/// A received photo view request (someone requested to view my photos).
class ReceivedPhotoViewRequest {
  const ReceivedPhotoViewRequest({
    required this.requestId,
    required this.fromUser,
    required this.status,
    required this.requestedAt,
  });

  final String requestId;
  final ProfileSummary fromUser;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime requestedAt;
}
