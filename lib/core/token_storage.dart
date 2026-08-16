import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the access/refresh token pair issued by `POST /auth/login`,
/// `/auth/register/*` (indirectly, after approval) and `/auth/refresh`.
///
/// REQUIRES a dependency that isn't in this `lib/`-only export — add to
/// `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   flutter_secure_storage: ^9.2.2
/// ```
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'sg_access_token';
  static const _refreshTokenKey = 'sg_refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
