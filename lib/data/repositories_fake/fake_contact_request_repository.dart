import '../../domain/models/contact_request_status.dart';
import '../../domain/repositories/contact_request_repository.dart';
import '../mappers/profile_mapper.dart';
import 'fake_data.dart';

class FakeContactRequestRepository implements ContactRequestRepository {
  final List<_FakeRequest> _requests = [];
  var _idCounter = 0;

  String get _me => FakeData.myProfile.id;

  @override
  Future<ContactRequestStatus> getStatusForProfile(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _FakeRequest? r;
    for (final x in _requests) {
      if (x.fromUserId == _me && x.toUserId == profileId) {
        r = x;
        break;
      }
    }
    if (r == null)
      return const ContactRequestStatus(state: ContactRequestState.none);
    if (r.state == ContactRequestState.accepted) {
      return ContactRequestStatus(
        state: ContactRequestState.accepted,
        requestId: r.requestId,
        sharedPhone: r.sharedPhone ?? '+919876543210',
        sharedAt: r.updatedAt,
      );
    }
    if (r.state == ContactRequestState.declined) {
      return ContactRequestStatus(
        state: ContactRequestState.declined,
        requestId: r.requestId,
      );
    }
    return ContactRequestStatus(
      state: ContactRequestState.pending,
      requestId: r.requestId,
    );
  }

  @override
  Future<void> sendContactRequest(String profileId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final exists = _requests.any(
      (r) => r.fromUserId == _me && r.toUserId == profileId,
    );
    if (exists) return;
    _requests.add(
      _FakeRequest(
        requestId: 'cr_${++_idCounter}',
        fromUserId: _me,
        toUserId: profileId,
        state: ContactRequestState.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<ReceivedContactRequest>> getReceivedContactRequests({
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final pending = _requests
        .where(
          (r) => r.toUserId == _me && r.state == ContactRequestState.pending,
        )
        .toList();
    final start = (page - 1) * limit;
    if (start >= pending.length) return [];
    final slice = pending.sublist(
      start,
      (start + limit).clamp(0, pending.length),
    );
    final result = <ReceivedContactRequest>[];
    for (final r in slice) {
      final from = FakeData.allProfiles[r.fromUserId];
      if (from != null) {
        result.add(
          ReceivedContactRequest(
            requestId: r.requestId,
            fromUser: profileToSummary(from),
            requestedAt: r.createdAt,
          ),
        );
      }
    }
    return result;
  }

  @override
  Future<int> getReceivedContactRequestsCount() async {
    await Future.delayed(const Duration(milliseconds: 30));
    return _requests
        .where(
          (r) => r.toUserId == _me && r.state == ContactRequestState.pending,
        )
        .length;
  }

  @override
  Future<void> acceptContactRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _FakeRequest? r;
    for (final x in _requests) {
      if (x.requestId == requestId) {
        r = x;
        break;
      }
    }
    if (r != null) {
      r.state = ContactRequestState.accepted;
      r.sharedPhone = '+919876543210'; // fake "my" phone shared with requester
      r.updatedAt = DateTime.now();
    }
  }

  @override
  Future<void> declineContactRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _FakeRequest? r;
    for (final x in _requests) {
      if (x.requestId == requestId) {
        r = x;
        break;
      }
    }
    if (r != null) {
      r.state = ContactRequestState.declined;
      r.updatedAt = DateTime.now();
    }
  }

  /// Seed a few received requests so the Contact requests tab has something to show.
  void seedReceivedRequests() {
    var i = 0;
    for (final id in FakeData.allProfiles.keys) {
      if (id == _me) continue;
      if (i >= 2) break;
      if (_requests.any((r) => r.fromUserId == id && r.toUserId == _me))
        continue;
      _requests.add(
        _FakeRequest(
          requestId: 'cr_rec_${++_idCounter}',
          fromUserId: id,
          toUserId: _me,
          state: ContactRequestState.pending,
          createdAt: DateTime.now().subtract(Duration(hours: i + 1)),
          updatedAt: DateTime.now(),
        ),
      );
      i++;
    }
  }
}

class _FakeRequest {
  _FakeRequest({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });
  final String requestId;
  final String fromUserId;
  final String toUserId;
  ContactRequestState state;
  final DateTime createdAt;
  DateTime updatedAt;
  String? sharedPhone;
}
