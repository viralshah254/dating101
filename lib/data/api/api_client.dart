import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

/// HTTP error with status code and parsed body.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message, [this.details]);
  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Centralized HTTP client with auth token injection and automatic refresh.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _http;
  bool _isRefreshing = false;

  Map<String, String> get _headers => {
        HttpHeaders.contentTypeHeader: 'application/json',
        if (tokenStorage.accessToken != null)
          HttpHeaders.authorizationHeader: 'Bearer ${tokenStorage.accessToken}',
      };

  // ── Public HTTP methods ──────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    _log('GET', uri);
    return _sendWithRetry(() => _http.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('POST', uri, body);
    return _sendWithRetry(
      () => _http.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null),
    );
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('PATCH', uri, body);
    return _sendWithRetry(
      () => _http.patch(uri, headers: _headers, body: body != null ? jsonEncode(body) : null),
    );
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('PUT', uri, body);
    return _sendWithRetry(
      () => _http.put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null),
    );
  }

  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    _log('DELETE', uri);
    final resp = await _http.delete(uri, headers: _headers);
    _logResponse('DELETE', uri, resp);
    if (resp.statusCode == 204 || resp.statusCode == 200) return;
    if (resp.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final retryResp = await _http.delete(uri, headers: _headers);
        _logResponse('DELETE (retry)', uri, retryResp);
        if (retryResp.statusCode == 204 || retryResp.statusCode == 200) return;
        _throwFromResponse(retryResp);
      }
    }
    _throwFromResponse(resp);
  }

  /// POST without auth (for auth endpoints).
  Future<Map<String, dynamic>> postNoAuth(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('POST (no-auth)', uri, body);
    final resp = await _http.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _logResponse('POST (no-auth)', uri, resp);
    return _parseResponse(resp);
  }

  // ── Internals ────────────────────────────────────────────────────────

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final fullPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$fullPath').replace(queryParameters: query?.isNotEmpty == true ? query : null);
  }

  Future<Map<String, dynamic>> _sendWithRetry(
    Future<http.Response> Function() request,
  ) async {
    try {
      var resp = await request();
      _logResponse(resp.request?.method ?? '?', resp.request?.url, resp);
      if (resp.statusCode == 401 && !_isRefreshing) {
        debugPrint('[API] 401 → attempting token refresh...');
        final refreshed = await _tryRefresh();
        if (refreshed) {
          debugPrint('[API] Token refreshed, retrying request...');
          resp = await request();
          _logResponse('${resp.request?.method ?? '?'} (retry)', resp.request?.url, resp);
        }
      }
      return _parseResponse(resp);
    } catch (e) {
      debugPrint('[API] ERROR: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseResponse(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {};
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    _throwFromResponse(resp);
  }

  Never _throwFromResponse(http.Response resp) {
    String code = 'UNKNOWN';
    String message = 'Request failed with status ${resp.statusCode}';
    Map<String, dynamic>? details;
    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      code = body['code'] as String? ?? code;
      message = body['message'] as String? ?? message;
      details = body['details'] as Map<String, dynamic>?;
    } catch (_) {}
    debugPrint('[API] THROW: $code — $message (${resp.statusCode})');
    throw ApiException(resp.statusCode, code, message, details);
  }

  Future<bool> _tryRefresh() async {
    if (tokenStorage.refreshToken == null) {
      debugPrint('[API] No refresh token, cannot refresh');
      return false;
    }
    _isRefreshing = true;
    try {
      final uri = _buildUri('/auth/refresh');
      debugPrint('[API] POST $uri (token refresh)');
      final resp = await _http.post(
        uri,
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'refreshToken': tokenStorage.refreshToken}),
      );
      debugPrint('[API] Refresh response: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        await tokenStorage.updateAccessToken(body['accessToken'] as String);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[API] Refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Debug logging ───────────────────────────────────────────────────

  void _log(String method, Uri uri, [Object? body]) {
    debugPrint('[API] ──────────────────────────────────');
    debugPrint('[API] $method $uri');
    if (body != null) {
      debugPrint('[API] Body: ${const JsonEncoder.withIndent('  ').convert(body)}');
    }
    debugPrint('[API] Auth: ${tokenStorage.accessToken != null ? "Bearer ***${tokenStorage.accessToken!.length > 10 ? tokenStorage.accessToken!.substring(tokenStorage.accessToken!.length - 6) : ''}" : "NONE"}');
  }

  void _logResponse(String method, Object? uri, http.Response resp) {
    final preview = resp.body.length > 500 ? '${resp.body.substring(0, 500)}...' : resp.body;
    debugPrint('[API] ← $method ${resp.statusCode} (${resp.body.length} bytes)');
    debugPrint('[API] Response: $preview');
  }
}
