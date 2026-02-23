import '../../domain/repositories/chat_repository.dart';
import 'fake_data.dart';

class FakeChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _threads = {};
  var _messageIdCounter = 0;

  String _nextMessageId() => 'msg-${++_messageIdCounter}';

  List<ChatThreadSummary> _threadSummaries() {
    final names = <String, String>{};
    for (final id in FakeData.allProfiles.keys) {
      names[id] = FakeData.allProfiles[id]!.name;
    }
    return [
      ChatThreadSummary(
        id: '1',
        otherUserId: '1',
        otherName: names['1'] ?? 'Priya',
        lastMessage: 'That sounds great! How about Saturday?',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
        unreadCount: 1,
      ),
      ChatThreadSummary(
        id: '2',
        otherUserId: '2',
        otherName: names['2'] ?? 'Ananya',
        lastMessage: "Sure, let's do the coffee spot you mentioned.",
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  @override
  Future<List<ChatThreadSummary>> getThreads({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _threadSummaries().take(limit).toList();
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) async* {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _threads[threadId] ?? [
      ChatMessage(id: 'm1', senderId: 'me', text: "Hey! Loved your prompt about Sundays.", sentAt: DateTime(2025, 1, 1, 10, 2)),
      ChatMessage(id: 'm2', senderId: threadId, text: "Thanks! What are you up to this weekend?", sentAt: DateTime(2025, 1, 1, 10, 5)),
      ChatMessage(id: 'm3', senderId: 'me', text: "Thinking of a walk and brunch. You?", sentAt: DateTime(2025, 1, 1, 10, 6)),
      ChatMessage(id: 'm4', senderId: threadId, text: "That sounds great! How about Saturday?", sentAt: DateTime(2025, 1, 1, 10, 8)),
    ];
    _threads[threadId] = list;
    yield list;
  }

  @override
  Future<void> sendMessage(String threadId, String text) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _threads[threadId] ?? [];
    list.add(ChatMessage(
      id: _nextMessageId(),
      senderId: 'me',
      text: text,
      sentAt: DateTime.now(),
    ));
    _threads[threadId] = list;
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 20));
  }
}
