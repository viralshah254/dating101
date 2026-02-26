import 'profile_summary.dart';

/// Status of the current user's contact request toward another profile.
enum ContactRequestState {
  /// No request sent.
  none,

  /// Request sent, awaiting their response.
  pending,

  /// They accepted; contact info is shared.
  accepted,

  /// They declined.
  declined,
}

/// Result of requesting contact or checking status for a profile.
class ContactRequestStatus {
  const ContactRequestStatus({
    required this.state,
    this.requestId,
    this.sharedPhone,
    this.sharedAt,
  });

  final ContactRequestState state;
  final String? requestId;
  /// When [state] is [ContactRequestState.accepted], the phone number shared for Call/WhatsApp.
  final String? sharedPhone;
  final DateTime? sharedAt;

  bool get canViewContacts => state == ContactRequestState.accepted && sharedPhone != null && sharedPhone!.isNotEmpty;
}

/// A received contact request (someone requested my contact). Shown in "Contact requests" for accept/decline.
class ReceivedContactRequest {
  const ReceivedContactRequest({
    required this.requestId,
    required this.fromUser,
    required this.requestedAt,
  });

  final String requestId;
  final ProfileSummary fromUser;
  final DateTime requestedAt;
}
