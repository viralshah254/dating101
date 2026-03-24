import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/chat_repository.dart';

/// Persists the latest window of messages per thread (WhatsApp-style reopen).
/// Keys are scoped by viewer user id so accounts do not leak data.
class ChatThreadDiskCache {
  ChatThreadDiskCache._();

  static const _keyPrefix = 'chat_thread_msgs_v1_';
  static const _maxMessagesToStore = 120;
  static final Map<String, Timer?> _writeTimers = {};

  static String _storageKey(String viewerUserId, String threadId) =>
      '$_keyPrefix${viewerUserId}_$threadId';

  static List<ChatMessage> _trimNewest(List<ChatMessage> messages) {
    if (messages.length <= _maxMessagesToStore) return messages;
    return messages.sublist(messages.length - _maxMessagesToStore);
  }

  static Map<String, dynamic> _toJson(ChatMessage m) => {
        'id': m.id,
        'senderId': m.senderId,
        'text': m.text,
        'sentAt': m.sentAt.toUtc().toIso8601String(),
        'isVoiceNote': m.isVoiceNote,
        if (m.outboundSeq != null) 'outboundSeq': m.outboundSeq,
      };

  static ChatMessage? _fromJson(Map<String, dynamic> j) {
    try {
      final sentRaw = j['sentAt'];
      if (sentRaw is! String) return null;
      final sentAt = DateTime.tryParse(sentRaw);
      if (sentAt == null) return null;
      return ChatMessage(
        id: j['id'] as String? ?? '',
        senderId: j['senderId'] as String? ?? '',
        text: j['text'] as String? ?? '',
        sentAt: sentAt.toLocal(),
        isVoiceNote: j['isVoiceNote'] as bool? ?? false,
        outboundSeq: (j['outboundSeq'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Debounced write so rapid WS updates do not hammer disk.
  static void scheduleWrite(String viewerUserId, String threadId, List<ChatMessage> messages) {
    if (viewerUserId.isEmpty || threadId.isEmpty) return;
    final key = _storageKey(viewerUserId, threadId);
    _writeTimers[key]?.cancel();
    final snapshot = _trimNewest(List<ChatMessage>.from(messages));
    _writeTimers[key] = Timer(const Duration(milliseconds: 450), () {
      _writeTimers[key] = null;
      unawaited(_writeNow(key, snapshot));
    });
  }

  static Future<void> _writeNow(String key, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(messages.map(_toJson).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  static Future<List<ChatMessage>> read(String viewerUserId, String threadId) async {
    if (viewerUserId.isEmpty || threadId.isEmpty) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(viewerUserId, threadId));
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      final out = <ChatMessage>[];
      for (final e in list) {
        if (e is! Map) continue;
        final m = _fromJson(Map<String, dynamic>.from(e));
        if (m != null) out.add(m);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Call on logout / account switch.
  static Future<void> clearAll() async {
    try {
      for (final t in _writeTimers.values) {
        t?.cancel();
      }
      _writeTimers.clear();
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
