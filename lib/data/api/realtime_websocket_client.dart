import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'token_storage.dart';

/// Lightweight WebSocket for realtime RPC (e.g. Likes tab snapshot). Separate from [ChatWebSocketClient].
class RealtimeWebSocketClient {
  RealtimeWebSocketClient({
    required this.wsBaseUrl,
    required this.tokenStorage,
  });

  final String wsBaseUrl;
  final TokenStorage tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connecting = false;
  bool _disposed = false;

  final Map<String, Completer<Map<String, dynamic>>> _pendingLikesSnapshot = {};

  void _tearDownConnection() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> connect() async {
    if (_connecting || _disposed) return;
    final token = tokenStorage.accessToken;
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
      if (_channel != null) {
        _tearDownConnection();
      }

      final wsUrl = wsBaseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final base = wsUrl.endsWith('/') ? wsUrl.substring(0, wsUrl.length - 1) : wsUrl;
      final uri = Uri.parse('$base/realtime/ws').replace(
        queryParameters: {'token': token},
      );

      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _connecting = false;

      _subscription = channel.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint('[RealtimeWS] stream error: $e');
          _failAllPending(e.toString());
          _channel = null;
          _subscription = null;
        },
        onDone: () {
          _failAllPending('Connection closed');
          _channel = null;
          _subscription = null;
        },
      );
    } catch (e) {
      _connecting = false;
      debugPrint('[RealtimeWS] connect error: $e');
      _failAllPending(e.toString());
    }
  }

  void _failAllPending(String message) {
    for (final c in _pendingLikesSnapshot.values) {
      if (!c.isCompleted) {
        c.completeError(message);
      }
    }
    _pendingLikesSnapshot.clear();
  }

  void _onMessage(dynamic data) {
    try {
      final text = data is String ? data : String.fromCharCodes(data as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>?;
      if (json == null) return;
      final type = json['type'] as String?;
      if (type == 'likes_snapshot') {
        final requestId = json['requestId'] as String?;
        if (requestId != null) {
          final c = _pendingLikesSnapshot.remove(requestId);
          if (c != null && !c.isCompleted) {
            c.complete(json);
          }
        }
      } else if (type == 'error') {
        final code = json['code'] as String? ?? '';
        final msg = json['message'] as String? ?? 'error';
        _failAllPending('$code: $msg');
      }
    } catch (e) {
      debugPrint('[RealtimeWS] parse error: $e');
    }
  }

  /// Request full Likes-tab snapshot (counts + three lists). Returns null if WS unavailable or timed out.
  Future<Map<String, dynamic>?> requestLikesSnapshot(String mode, {Duration timeout = const Duration(seconds: 12)}) async {
    if (_disposed) return null;
    if (_channel == null) {
      await connect();
    }
    if (_channel == null) return null;

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<Map<String, dynamic>>();
    _pendingLikesSnapshot[requestId] = completer;

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'likes_snapshot',
        'mode': mode,
        'requestId': requestId,
      }));
      final result = await completer.future.timeout(timeout);
      return result;
    } on TimeoutException {
      _pendingLikesSnapshot.remove(requestId);
      return null;
    } catch (e) {
      _pendingLikesSnapshot.remove(requestId);
      debugPrint('[RealtimeWS] likes_snapshot failed: $e');
      return null;
    }
  }

  void dispose() {
    _disposed = true;
    _tearDownConnection();
    _failAllPending('Disposed');
  }
}
