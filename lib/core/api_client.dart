import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper around `package:http` that:
/// - prefixes every request with [ApiConfig.baseUrl]
/// - attaches `Authorization: Bearer <token>` when [requireAuth] is true
/// - decodes JSON bodies
/// - converts the backend's `{ error: { code, message } }` shape into
///   an [ApiException]
///
/// REQUIRES a dependency that isn't in this `lib/`-only export — add to
/// `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   http: ^1.2.2
/// ```
class ApiClient {
  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
      : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> get(
    String path, {
    bool requireAuth = false,
    Duration? timeout,
  }) =>
      _send('GET', path, requireAuth: requireAuth, timeout: timeout);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
    Duration? timeout,
  }) =>
      _send('POST', path, body: body, requireAuth: requireAuth, timeout: timeout);

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
    Duration? timeout,
  }) =>
      _send('DELETE', path, body: body, requireAuth: requireAuth, timeout: timeout);

  /// Guards against a stampede of parallel 401s each kicking off their own
  /// `/auth/refresh` call — every caller that arrives while a refresh is
  /// already in flight awaits the same future instead.
  Future<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
    bool isRetryAfterRefresh = false,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _httpClient
          .send(request)
          .timeout(timeout ?? ApiConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw ApiException.network(
          'Could not reach the server. Check your connection.');
    } on HttpException {
      throw ApiException.network('The server could not be reached.');
    } catch (_) {
      throw ApiException.network('The request timed out or failed.');
    }

    // Access tokens are short-lived (see generateAccessToken /
    // jwt.ts). On a 401 for an authenticated call, try
    // `POST /auth/refresh` once and replay the original request with the
    // new token before giving up. Never do this for the login/refresh
    // calls themselves, or more than once per request.
    if (response.statusCode == 401 &&
        requireAuth &&
        !isRetryAfterRefresh &&
        path != ApiConfig.refresh &&
        path != ApiConfig.login) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _send(
          method,
          path,
          body: body,
          requireAuth: requireAuth,
          isRetryAfterRefresh: true,
          timeout: timeout,
        );
      }
      // Refresh failed too (refresh token expired/revoked) — clear
      // whatever we had and fall through to report the original 401.
      await _tokenStorage.clear();
    }

    // 204 No Content (e.g. POST /auth/logout)
    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const {};
      }
      throw ApiException.malformed(response.statusCode);
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException.malformed(response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Every success response wraps its payload in `{ data: ... }`
      // (see the controllers, e.g. auth.controller.ts).
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      // Some endpoints could return a bare object; fall back gracefully.
      return decoded;
    }

    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        statusCode: response.statusCode,
        code: (error['code'] as String?) ?? 'UNKNOWN_ERROR',
        message: (error['message'] as String?) ?? 'Something went wrong.',
      );
    }

    throw ApiException.malformed(response.statusCode);
  }

  /// Calls `POST /auth/refresh` directly (bypassing [_send]'s own 401
  /// handling, to avoid recursion) and stores the rotated token pair.
  /// Returns whether it succeeded.
  Future<bool> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}');
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        })
        ..body = jsonEncode({'refreshToken': refreshToken});
      final streamed =
          await _httpClient.send(request).timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      await _tokenStorage.saveTokens(
        accessToken: data['token'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}