/// Mirrors the error shape produced by `src/middleware/error.middleware.ts`:
///
/// ```json
/// { "error": { "code": "BAD_REQUEST", "message": "..." } }
/// ```
///
/// [code] is one of the backend's error codes (e.g. `UNAUTHORIZED`,
/// `DUPLICATE_EMAIL`, `WEAK_PASSWORD`, `VALIDATION_ERROR`, `NOT_FOUND`,
/// `RATE_LIMITED`, `INTERNAL_ERROR`) — see `src/utils/errors.ts` and the
/// registration service for the full list. [statusCode] is the HTTP status.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  /// Thrown when the device has no connectivity or the request timed out,
  /// i.e. we never got a response from the server to parse.
  factory ApiException.network(String message) => ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: message,
      );

  /// Thrown when the response body isn't the JSON shape we expect.
  factory ApiException.malformed(int statusCode) => ApiException(
        statusCode: statusCode,
        code: 'MALFORMED_RESPONSE',
        message: 'Received an unexpected response from the server.',
      );

  final int statusCode;
  final String code;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isNetworkError => code == 'NETWORK_ERROR';

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
