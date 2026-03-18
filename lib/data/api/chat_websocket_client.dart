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
      if (type == 'message' || type == 'sent') {
        final threadId = json['threadId'] as String?;
        final senderId = json['senderId'] as String?;
        final textMsg = json['text'] as String?;
        final sentAt = json['sentAt'] != null ? DateTime.tryParse(json['sentAt'] as String) : null;
        final tempId = json['tempId'] as String?;
        if (threadId != null && senderId != null && textMsg != null) {
          _incomingController.add(IncomingChatEvent(
            type: IncomingEventType.message,
            threadId: threadId,
            message: IncomingMessage(
              id: tempId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
              senderId: senderId,
              text: textMsg,
              sentAt: sentAt ?? DateTime.now(),
              isVoiceNote: json['isVoiceNote'] as bool? ?? false,
            ),
          ));
        }
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

  /// Send message via WebSocket. Returns true if sent, false if fallback to HTTP needed.
  Future<bool> send(String threadId, String text, {String? adCompletionToken}) async {
    if (_channel == null) return false;
    try {
      final payload = <String, dynamic>{
        'type': 'send',
        'threadId': threadId,
        'text': text,
        'tempId': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      };
      if (adCompletionToken != null && adCompletionToken.isNotEmpty) {
        payload['adCompletionToken'] = adCompletionToken;
      }
      _channel!.sink.add(jsonEncode(payload));
      return true;
    } catch (e) {
      debugPrint('[ChatWS] send error: $e');
      return false;
    }
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _incomingController.close();
  }
}

enum IncomingEventType { connected, message, error }

class IncomingChatEvent {
  IncomingChatEvent({
    required this.type,
    this.threadId,
    this.message,
    this.error,
    this.code,
  });
  final IncomingEventType type;
  final String? threadId;
  final IncomingMessage? message;
  final String? error;
  final String? code;
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
