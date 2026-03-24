import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/datetime/app_time_format.dart';
import 'token_storage.dart';

/// Real-time chat over WebSocket. Connects with JWT, receives messages, sends via WS.
class ChatWebSocketClient {
  ChatWebSocketClient({
    required this.wsBaseUrl,
    required this.tokenStorage,
  });

  final String wsBaseUrl;
  final TokenStorage tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  bool _connecting = false;
  bool _disposed = false;
  Completer<void>? _sessionReadyCompleter;

  final _incomingController = StreamController<IncomingChatEvent>.broadcast();

  /// Stream of incoming messages and connection events.
  Stream<IncomingChatEvent> get incoming => _incomingController.stream;

  bool get isConnected => _channel != null;

  /// Drop the active socket without marking the client [dispose]d (allows reconnect).
  void _tearDownConnection() {
    final c = _sessionReadyCompleter;
    if (c != null && !c.isCompleted) {
      c.completeError(StateError('chat_ws_disconnected'));
    }
    _sessionReadyCompleter = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Wait until server sends `{ "type": "connected" }` (JWT accepted), or [timeout].
  Future<bool> waitUntilSessionReady({Duration timeout = const Duration(seconds: 10)}) async {
    if (_disposed || _channel == null) return false;
    final c = _sessionReadyCompleter;
    if (c == null || c.isCompleted) return true;
    try {
      await c.future.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Connect to WebSocket. Call when user opens chat (or app-wide hub connects).
  Future<void> connect() async {
    if (_connecting || _disposed) return;
    final token = tokenStorage.accessToken;
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
      // New JWT (e.g. account switch): close old socket first. Otherwise a second
      // [StreamSubscription] keeps receiving on the old channel → duplicate events.
      if (_channel != null) {
        _tearDownConnection();
      }

      final wsUrl = wsBaseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final base = wsUrl.endsWith('/') ? wsUrl.substring(0, wsUrl.length - 1) : wsUrl;
      final uri = Uri.parse('$base/chat/ws').replace(
        queryParameters: {'token': token},
      );

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _connecting = false;
      _sessionReadyCompleter = Completer<void>();

      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) => sendPing());

      _subscription = channel.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint('[ChatWS] stream error: $e');
          final g = _sessionReadyCompleter;
          if (g != null && !g.isCompleted) {
            g.completeError(e);
          }
          _channel = null;
          _subscription = null;
          _pingTimer?.cancel();
          _pingTimer = null;
          _sessionReadyCompleter = null;
          _incomingController.add(IncomingChatEvent(type: IncomingEventType.error, error: e.toString()));
        },
        onDone: () {
          final g = _sessionReadyCompleter;
          if (g != null && !g.isCompleted) {
            g.completeError(StateError('chat_ws_done'));
          }
          _sessionReadyCompleter = null;
          _channel = null;
          _subscription = null;
          _pingTimer?.cancel();
          _pingTimer = null;
        },
      );
    } catch (e) {
      _connecting = false;
      final g = _sessionReadyCompleter;
      if (g != null && !g.isCompleted) {
        g.completeError(e);
      }
      _sessionReadyCompleter = null;
      debugPrint('[ChatWS] connect error: $e');
      _incomingController.add(IncomingChatEvent(type: IncomingEventType.error, error: e.toString()));
    }
  }

  void _onMessage(dynamic data) {
    try {
      final text = data is String ? data : String.fromCharCodes(data as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>?;
      if (json == null) return;

      final type = json['type'] as String?;

      if (type == 'connected') {
        final g = _sessionReadyCompleter;
        if (g != null && !g.isCompleted) {
          g.complete();
        }
        _incomingController.add(IncomingChatEvent(type: IncomingEventType.connected));
        return;
      }

      if (type == 'message') {
        final threadId = json['threadId'] as String?;
        final senderId = json['senderId'] as String?;
        final textMsg = json['text'] as String?;
        final sentAt =
            json['sentAt'] != null ? parseApiDateTime(json['sentAt'] as String) : null;
        final id = json['id'] as String? ?? json['tempId'] as String?;
        if (threadId != null && senderId != null && textMsg != null) {
          _incomingController.add(IncomingChatEvent(
            type: IncomingEventType.message,
            threadId: threadId,
            message: IncomingMessage(
              id: id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
              senderId: senderId,
              text: textMsg,
              sentAt: sentAt ?? DateTime.now(),
              isVoiceNote: json['isVoiceNote'] as bool? ?? false,
            ),
          ));
        }
      } else if (type == 'sent') {
        final threadId = json['threadId'] as String?;
        final senderId = json['senderId'] as String?;
        final textMsg = json['text'] as String?;
        final sentAt =
            json['sentAt'] != null ? parseApiDateTime(json['sentAt'] as String) : null;
        final id = json['id'] as String?;
        final tempId = json['tempId'] as String?;
        if (threadId != null && senderId != null && textMsg != null) {
          _incomingController.add(IncomingChatEvent(
            type: IncomingEventType.sent,
            threadId: threadId,
            tempId: tempId,
            message: IncomingMessage(
              id: id ?? tempId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
              senderId: senderId,
              text: textMsg,
              sentAt: sentAt ?? DateTime.now(),
              isVoiceNote: false,
            ),
          ));
        }
      } else if (type == 'message_persisted') {
        final threadId = json['threadId'] as String?;
        final messageId = json['messageId'] as String?;
        final tempId = json['tempId'] as String?;
        final senderId = json['senderId'] as String?;
        final textMsg = json['text'] as String?;
        final sentAt =
            json['sentAt'] != null ? parseApiDateTime(json['sentAt'] as String) : null;
        if (threadId != null && messageId != null && senderId != null && textMsg != null) {
          _incomingController.add(IncomingChatEvent(
            type: IncomingEventType.messagePersisted,
            threadId: threadId,
            tempId: tempId,
            message: IncomingMessage(
              id: messageId,
              senderId: senderId,
              text: textMsg,
              sentAt: sentAt ?? DateTime.now(),
              isVoiceNote: false,
            ),
          ));
        }
      } else if (type == 'thread_read') {
        final threadId = json['threadId'] as String?;
        final readerId = json['readerId'] as String?;
        final readAt =
            json['readAt'] != null ? parseApiDateTime(json['readAt'] as String) : null;
        if (threadId != null && readerId != null && readAt != null) {
          _incomingController.add(IncomingChatEvent(
            type: IncomingEventType.threadRead,
            threadId: threadId,
            readerId: readerId,
            readAt: readAt,
          ));
        }
      } else if (type == 'message_request_created' || type == 'message_request') {
        final threadId = json['threadId'] as String?;
        final messageRequestId = json['messageRequestId'] as String? ?? json['id'] as String?;
        final tempId = json['tempId'] as String?;
        final reqText = json['text'] as String?;
        _incomingController.add(IncomingChatEvent(
          type: IncomingEventType.messageRequestCreated,
          threadId: threadId,
          tempId: tempId,
          messageRequestId: messageRequestId,
          messageRequestText: reqText,
        ));
      } else if (type == 'error') {
        _incomingController.add(IncomingChatEvent(
          type: IncomingEventType.error,
          error: json['message'] as String? ?? json['code'] as String? ?? 'Unknown error',
          code: json['code'] as String?,
          threadId: json['threadId'] as String?,
          tempId: json['tempId'] as String?,
        ));
      }
    } catch (e) {
      debugPrint('[ChatWS] parse error: $e');
    }
  }

  /// Send message via WebSocket. Returns tempId if sent, null if fallback to HTTP needed.
  Future<String?> send(
    String threadId,
    String text, {
    String? adCompletionToken,
    String? outgoingTempId,
  }) async {
    if (_channel == null) return null;
    final ready = await waitUntilSessionReady(timeout: const Duration(seconds: 10));
    if (!ready) return null;
    try {
      final tempId =
          outgoingTempId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final payload = <String, dynamic>{
        'type': 'send',
        'threadId': threadId,
        'text': text,
        'tempId': tempId,
      };
      if (adCompletionToken != null && adCompletionToken.isNotEmpty) {
        payload['adCompletionToken'] = adCompletionToken;
      }
      _channel!.sink.add(jsonEncode(payload));
      return tempId;
    } catch (e) {
      debugPrint('[ChatWS] send error: $e');
      return null;
    }
  }

  void sendMarkRead(String threadId) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'mark_read', 'threadId': threadId}));
    } catch (e) {
      debugPrint('[ChatWS] mark_read error: $e');
    }
  }

  void sendPing() {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _tearDownConnection();
    if (!_incomingController.isClosed) _incomingController.close();
  }
}

enum IncomingEventType {
  connected,
  message,
  sent,
  messagePersisted,
  threadRead,
  messageRequestCreated,
  error,
}

class IncomingChatEvent {
  IncomingChatEvent({
    required this.type,
    this.threadId,
    this.message,
    this.error,
    this.code,
    this.tempId,
    this.messageRequestId,
    this.messageRequestText,
    this.readerId,
    this.readAt,
  });
  final IncomingEventType type;
  final String? threadId;
  final IncomingMessage? message;
  final String? error;
  final String? code;
  final String? tempId;
  final String? messageRequestId;
  /// Server echo for `message_request_created` (synthetic `pending-req:` row without refetch).
  final String? messageRequestText;
  final String? readerId;
  final DateTime? readAt;
}

class IncomingMessage {
  IncomingMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isVoiceNote = false,
  });
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isVoiceNote;
}
