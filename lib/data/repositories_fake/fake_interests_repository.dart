import '../../domain/models/interaction_models.dart';
import '../../domain/repositories/interests_repository.dart';

class FakeInterestsRepository implements InterestsRepository {
  final List<Interest> _received = [];
  final List<Interest> _sent = [];
  var _idCounter = 0;

  String _nextId() => 'interest-${++_idCounter}';

  @override
  Future<Interest> sendInterest(String toUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final interest = Interest(
      id: _nextId(),
      fromUserId: 'me',
      toUserId: toUserId,
      sentAt: DateTime.now(),
      status: InterestStatus.pending,
    );
    _sent.add(interest);
    return interest;
  }

  @override
  Future<List<Interest>> getReceivedInterests({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _received.take(limit).toList();
  }

  @override
  Future<List<Interest>> getSentInterests({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _sent.take(limit).toList();
  }

  @override
  Future<Interest> acceptInterest(String interestId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final i = _received.indexWhere((e) => e.id == interestId);
    if (i < 0) throw StateError('Interest not found');
    final updated = _received[i].copyWith(status: InterestStatus.accepted);
    _received[i] = updated;
    return updated;
  }

  @override
  Future<Interest> declineInterest(String interestId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final i = _received.indexWhere((e) => e.id == interestId);
    if (i < 0) throw StateError('Interest not found');
    final updated = _received[i].copyWith(status: InterestStatus.rejected);
    _received[i] = updated;
    return updated;
  }

  @override
  Future<void> withdrawInterest(String interestId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _sent.removeWhere((e) => e.id == interestId);
  }
}
