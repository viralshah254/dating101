import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  bool _connecting = false;
  bool _disposed = false;

  final _incomingController = StreamController<IncomingChatEvent>.broadcast();

  /// Stream of incoming messages and connection events.
  Stream<IncomingChatEvent> get incoming => _incomingController.stream;

  bool get isConnected => _channel != null;

  /// Connect to WebSocket. Call when user opens chat.
  Future<void> connect() async {
    if (_connecting || _disposed) return;
    final token = tokenStorage.accessToken;
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
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
      _incomingController.add(IncomingChatEvent(type: IncomingEventType.connected));

      _subscription = channel.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint('[ChatWS] stream error: $e');
          _channel = null;
          _subscription = null;
          _incomingController.add(IncomingChatEvent(type: IncomingEventType.error, error: e.toString()));
        },
        onDone: () {
          _channel = null;
          _subscription = null;
        },
      );
    } catch (e) {
      _connecting = false;
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

      if (type == 'message') {
        // Pushed to recipient from server
        final threadId = json['threadId'] as String?;
        final senderId = json['senderId'] as String?;
        final textMsg = json['text'] as String?;
        final sentAt = json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null;
        final id = json['id'] as String?;
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
        // Echo back to sender: carries real DB id and tempId for dedup
        final threadId = json['threadId'] as String?;
        final senderId = json['senderId'] as String?;
        final textMsg = json['text'] as String?;
        final sentAt = json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null;
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
      } else if (type == 'message_request_created') {
        // Free-tier ad-gated: message became a message request
        final threadId = json['threadId'] as String?;
        final messageRequestId = json['messageRequestId'] as String?;
        final tempId = json['tempId'] as String?;
        _incomingController.add(IncomingChatEvent(
          type: IncomingEventType.messageRequestCreated,
          threadId: threadId,
          tempId: tempId,
          messageRequestId: messageRequestId,
        ));
      } else if (type == 'error') {
        _incomingController.add(IncomingChatEvent(
          type: IncomingEventType.error,
          error: json['message'] as String? ?? json['code'] as String? ?? 'Unknown error',
          code: json['code'] as String?,
        ));
      }
    } catch (e) {
      debugPrint('[ChatWS] parse error: $e');
    }
  }

  /// Send message via WebSocket. Returns tempId if sent, null if fallback to HTTP needed.
  Future<String?> send(String threadId, String text, {String? adCompletionToken}) async {
    if (_channel == null) return null;
    try {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
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

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    if (!_incomingController.isClosed) _incomingController.close();
  }
}

enum IncomingEventType {
  connected,
  message,
  sent,
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
  });
  final IncomingEventType type;
  final String? threadId;
  final IncomingMessage? message;
  final String? error;
  final String? code;
  /// Client-side tempId for optimistic bubble resolution.
  final String? tempId;
  /// Present when type == messageRequestCreated.
  final String? messageRequestId;
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
