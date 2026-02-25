import '../../domain/models/interaction_models.dart';
import '../../domain/repositories/interactions_repository.dart';
import '../api/api_client.dart';
import 'api_profile_repository.dart';

class ApiInteractionsRepository implements InteractionsRepository {
  ApiInteractionsRepository({required this.api});
  final ApiClient api;

  @override
  Future<ExpressInterestResult> expressInterest(
    String toUserId, {
    String? source,
  }) async {
    final body = <String, dynamic>{'toUserId': toUserId};
    if (source != null && source.isNotEmpty) body['source'] = source;
    final res = await api.post('/interactions/interest', body: body);
    return _parseResult(res);
  }

  @override
  Future<ExpressInterestResult> expressPriorityInterest(
    String toUserId, {
    String? message,
    String? source,
  }) async {
    final body = <String, dynamic>{'toUserId': toUserId};
    if (message != null && message.isNotEmpty) body['message'] = message;
    if (source != null && source.isNotEmpty) body['source'] = source;
    final res = await api.post('/interactions/priority-interest', body: body);
    return _parseResult(res);
  }

  @override
  Future<List<InteractionInboxItem>> getReceivedInteractions({
    String status = 'pending',
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final body = await api.get(
      '/interactions/received',
      query: {'status': status, 'type': type, 'page': '$page', 'limit': '$limit'},
    );
    return _parseInboxList(body['interactions'] as List? ?? [], isReceived: true);
  }

  @override
  Future<int> getReceivedInteractionsCount({String status = 'pending'}) async {
    final body = await api.get(
      '/interactions/received/count',
      query: {'status': status},
    );
    return body['count'] as int? ?? 0;
  }

  @override
  Future<List<InteractionInboxItem>> getSentInteractions({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    final body = await api.get(
      '/interactions/sent',
      query: {'status': status, 'page': '$page', 'limit': '$limit'},
    );
    return _parseInboxList(body['interactions'] as List? ?? [], isReceived: false);
  }

  @override
  Future<ExpressInterestResult> respondToInterest(String interactionId, {required bool accept}) async {
    final res = await api.patch(
      '/interactions/$interactionId',
      body: {'action': accept ? 'accept' : 'decline'},
    );
    return _parseResult(res);
  }

  @override
  Future<void> withdrawInteraction(String interactionId) async {
    await api.delete('/interactions/$interactionId');
  }

  List<InteractionInboxItem> _parseInboxList(List list, {required bool isReceived}) {
    return list.map((e) {
      final map = e as Map<String, dynamic>;
      final userKey = isReceived ? 'fromUser' : 'toUser';
      final userMap = map[userKey] as Map<String, dynamic>? ?? {};
      final other = ApiProfileRepository.parseSummaryPublic(userMap);
      return InteractionInboxItem(
        interactionId: map['interactionId'] as String? ?? map['id'] as String? ?? '',
        otherUser: other,
        message: map['message'] as String?,
        seenByRecipient: map['seenByRecipient'] as bool? ?? false,
        status: map['status'] as String? ?? 'pending',
        type: map['type'] as String? ?? 'interest',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  static ExpressInterestResult _parseResult(Map<String, dynamic> j) {
    return ExpressInterestResult(
      interactionId: j['interactionId'] as String? ?? j['id'] as String? ?? '',
      mutualMatch: j['mutualMatch'] as bool? ?? false,
      matchId: j['matchId'] as String?,
      chatThreadId: j['chatThreadId'] as String?,
      priorityRemaining: j['priorityRemaining'] as int?,
    );
  }
}
