import '../models/contact_request_status.dart';

/// Contact request flow: A requests B's contact → B accepts/declines → A sees "View contacts" (Call/WhatsApp) when accepted.
abstract class ContactRequestRepository {
  /// Status of my contact request toward [profileId]. Use for full profile "Request contact" / "View contacts" UI.
  Future<ContactRequestStatus> getStatusForProfile(String profileId);

  /// Send a contact request to [profileId]. They will see it in their "Contact requests" and can accept/decline.
  Future<void> sendContactRequest(String profileId);

  /// Received contact requests (people who want my contact). For "Contact requests" tab — accept/decline.
  Future<List<ReceivedContactRequest>> getReceivedContactRequests({int page = 1, int limit = 20});

  /// Accept a contact request. Requester gets to see my shared contact (phone) and can Call/WhatsApp.
  /// Backend should notify the requester (e.g. push / in-app).
  Future<void> acceptContactRequest(String requestId);

  /// Decline a contact request. Backend should notify the requester (e.g. push / in-app).
  Future<void> declineContactRequest(String requestId);
}
