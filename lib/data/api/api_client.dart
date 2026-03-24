import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'token_storage.dart';

const _uuid = Uuid();

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
    /// When set, adds Accept-Language header so backend can return translated profile content (bio, marital status, etc.).
    String? Function()? localeGetter,
  })  : _http = httpClient ?? http.Client(),
        _localeGetter = localeGetter;

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _http;
  final String? Function()? _localeGetter;

  /// One shared refresh; concurrent 401s must await this instead of skipping refresh
  /// while `_isRefreshing` was true (that caused spurious 401 → logout).
  Future<bool>? _refreshInFlight;

  Map<String, String> _buildHeaders({String? requestId}) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': requestId ?? _uuid.v4(),
      if (tokenStorage.accessToken != null)
        HttpHeaders.authorizationHeader: 'Bearer ${tokenStorage.accessToken}',
    };
    final locale = _localeGetter?.call();
    if (locale != null && locale.isNotEmpty) {
      headers['Accept-Language'] = locale;
    }
    return headers;
  }

  /// Backward-compatible getter used by no-auth calls.
  Map<String, String> get _headers => _buildHeaders();

  // ── Public HTTP methods ──────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _buildUri(path, query);
    final reqId = _uuid.v4();
    _log('GET', uri);
    return _sendWithRetry(() => _http.get(uri, headers: _buildHeaders(requestId: reqId)), requestId: reqId);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final uri = _buildUri(path);
    final reqId = _uuid.v4();
    _log('POST', uri, body);
    return _sendWithRetry(
      () => _http.post(
        uri,
        headers: _buildHeaders(requestId: reqId),
        body: body != null ? jsonEncode(body) : null,
      ),
      requestId: reqId,
    );
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final uri = _buildUri(path);
    final reqId = _uuid.v4();
    _log('PATCH', uri, body);
    return _sendWithRetry(
      () => _http.patch(
        uri,
        headers: _buildHeaders(requestId: reqId),
        body: body != null ? jsonEncode(body) : null,
      ),
      requestId: reqId,
    );
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final uri = _buildUri(path);
    final reqId = _uuid.v4();
    _log('PUT', uri, body);
    return _sendWithRetry(
      () => _http.put(
        uri,
        headers: _buildHeaders(requestId: reqId),
        body: body != null ? jsonEncode(body) : null,
      ),
      requestId: reqId,
    );
  }

  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    _log('DELETE', uri);
    final resp = await _http.delete(uri, headers: _headers);
    _logResponse('DELETE', uri, resp);
    if (resp.statusCode == 204 || resp.statusCode == 200) return;
    if (resp.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final retryResp = await _http.delete(uri, headers: _headers);
        _logResponse('DELETE (retry)', uri, retryResp);
        if (retryResp.statusCode == 204 || retryResp.statusCode == 200) return;
        _throwFromResponse(retryResp);
      } else if (tokenStorage.isLoggedIn) {
        final retryResp = await _http.delete(uri, headers: _headers);
        _logResponse('DELETE (retry after session change)', uri, retryResp);
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
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final fullPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$base$fullPath',
    ).replace(queryParameters: query?.isNotEmpty == true ? query : null);
  }

  Future<Map<String, dynamic>> _sendWithRetry(
    Future<http.Response> Function() request, {
    String? requestId,
  }) async {
    try {
      var resp = await request();
      _logResponse(resp.request?.method ?? '?', resp.request?.url, resp);
      if (resp.statusCode == 401) {
        debugPrint('[API] 401 → attempting token refresh... (req-id: $requestId)');
        final refreshed = await _tryRefresh();
        if (refreshed) {
          debugPrint('[API] Token refreshed, retrying request...');
          resp = await request();
          _logResponse(
            '${resp.request?.method ?? '?'} (retry)',
            resp.request?.url,
            resp,
          );
        } else if (tokenStorage.isLoggedIn) {
          // e.g. new login while a stale shared refresh finished without applying
          debugPrint('[API] Retrying once with current session (req-id: $requestId)');
          resp = await request();
          _logResponse(
            '${resp.request?.method ?? '?'} (retry after session change)',
            resp.request?.url,
            resp,
          );
        }
      }
      return _parseResponse(resp);
    } catch (e) {
      debugPrint('[API] ERROR (req-id: $requestId): $e');
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
      // Include full body as details so consumers can read count, lockedPreview, etc.
      details = body;
    } catch (_) {}
    debugPrint('[API] THROW: $code — $message (${resp.statusCode})');
    throw ApiException(resp.statusCode, code, message, details);
  }

  /// All callers awaiting 401 recovery share one refresh; avoids parallel requests
  /// seeing `401` while another refresh is in progress and incorrectly failing.
  Future<bool> _tryRefresh() {
    _refreshInFlight ??= _executeRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<bool> _executeRefresh() async {
    final startedGen = tokenStorage.sessionGeneration;
    if (tokenStorage.refreshToken == null) {
      debugPrint('[API] No refresh token, cannot refresh');
      if (tokenStorage.sessionGeneration == startedGen && tokenStorage.isLoggedIn) {
        await tokenStorage.clear();
      }
      return false;
    }
    try {
      final uri = _buildUri('/auth/refresh');
      const maxAttempts = 2;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (tokenStorage.sessionGeneration != startedGen) {
          debugPrint('[API] Refresh aborted (session changed)');
          return false;
        }
        debugPrint('[API] POST $uri (token refresh, attempt ${attempt + 1}/$maxAttempts)');
        final refreshToken = tokenStorage.refreshToken;
        if (refreshToken == null) {
          return false;
        }
        final resp = await _http.post(
          uri,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        debugPrint('[API] Refresh response: ${resp.statusCode}');
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          final access = body['accessToken'] as String?;
          if (access == null || access.isEmpty) {
            debugPrint('[API] Refresh 200 but missing accessToken, clearing session');
            if (tokenStorage.sessionGeneration == startedGen) {
              await tokenStorage.clear();
            }
            return false;
          }
          if (tokenStorage.sessionGeneration != startedGen) {
            debugPrint('[API] Ignoring refresh success (session changed)');
            return false;
          }
          await tokenStorage.updateAccessToken(access);
          return true;
        }
        final isInvalid = resp.statusCode == 401 || resp.statusCode == 403;
        if (isInvalid) {
          debugPrint('[API] Refresh rejected (${resp.statusCode}), clearing session');
          if (tokenStorage.sessionGeneration == startedGen) {
            await tokenStorage.clear();
          }
          return false;
        }
        final maybeTransient = resp.statusCode >= 500 && resp.statusCode < 600;
        if (maybeTransient && attempt < maxAttempts - 1) {
          debugPrint('[API] Refresh server error, will retry...');
          continue;
        }
        debugPrint('[API] Refresh failed, clearing session');
        if (tokenStorage.sessionGeneration == startedGen) {
          await tokenStorage.clear();
        }
        return false;
      }
      if (tokenStorage.sessionGeneration == startedGen) {
        await tokenStorage.clear();
      }
      return false;
    } catch (e) {
      debugPrint('[API] Refresh error: $e');
      if (e is SocketException ||
          e is HttpException ||
          e is HandshakeException ||
          e is http.ClientException ||
          e is TimeoutException) {
        debugPrint('[API] Refresh network/transient error — keeping tokens; retry later');
        return false;
      }
      if (tokenStorage.sessionGeneration == startedGen) {
        await tokenStorage.clear();
      }
      return false;
    }
  }

  // ── Debug logging ───────────────────────────────────────────────────

  void _log(String method, Uri uri, [Object? body]) {
    debugPrint('[API] ──────────────────────────────────');
    debugPrint('[API] $method $uri');
    if (body != null) {
      debugPrint(
        '[API] Body: ${const JsonEncoder.withIndent('  ').convert(body)}',
      );
    }
    debugPrint(
      '[API] Auth: ${tokenStorage.accessToken != null ? "Bearer ***${tokenStorage.accessToken!.length > 10 ? tokenStorage.accessToken!.substring(tokenStorage.accessToken!.length - 6) : ''}" : "NONE"}',
    );
  }

  void _logResponse(String method, Object? uri, http.Response resp) {
    final preview = resp.body.length > 500
        ? '${resp.body.substring(0, 500)}...'
        : resp.body;
    debugPrint(
      '[API] ← $method ${resp.statusCode} (${resp.body.length} bytes)',
    );
    debugPrint('[API] Response: $preview');
  }
}
