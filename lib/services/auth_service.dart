import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/token_storage.dart';
import '../models/gender.dart';
import '../models/user.dart';

/// Result of a successful `POST /auth/login` call.
/// Shape matches `loginUser`'s return value in `auth.service.ts`.
class LoginResult {
  LoginResult({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final User user;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        accessToken: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Wraps every `/auth/*` endpoint described in
/// `src/routes/auth.routes.ts` + `src/validators/auth.validator.ts`.
///
/// Payload keys and requiredness intentionally mirror the Zod schemas
/// exactly so the backend's 400 validation errors are avoided:
/// - registerStudent: dateOfBirth + gender REQUIRED
/// - registerParent: dateOfBirth NOT accepted, gender optional
/// - registerTeacher: dateOfBirth + gender optional
///
/// NOTE: the current sign-up screen (`screens/signup/signup_page.dart`)
/// does not yet collect date of birth or gender, and it collects
/// studentId/schoolCode/phone fields the backend register endpoints do not
/// accept at all. That screen still needs to be reworked to match — see
/// PROGRESS.md.
class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final json = await _apiClient.post(ApiConfig.login, body: {
      'email': email,
      'password': password,
    });
    final result = LoginResult.fromJson(json);
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    return result;
  }

  /// `POST /auth/register/student` — dateOfBirth (YYYY-MM-DD) and gender
  /// are REQUIRED by the backend (`registerStudentSchema`).
  Future<User> registerStudent({
    required String firstName,
    String? middleName,
    required String lastName,
    required String dateOfBirth, // must be 'YYYY-MM-DD'
    required Gender gender,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _apiClient.post(ApiConfig.registerStudent, body: {
      'firstName': firstName,
      if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender.apiValue,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return User.fromJson(json);
  }

  /// `POST /auth/register/parent` — no dateOfBirth field on this endpoint;
  /// gender is optional (`registerParentSchema`).
  Future<User> registerParent({
    required String firstName,
    String? middleName,
    required String lastName,
    Gender? gender,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _apiClient.post(ApiConfig.registerParent, body: {
      'firstName': firstName,
      if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
      'lastName': lastName,
      if (gender != null) 'gender': gender.apiValue,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return User.fromJson(json);
  }

  /// `POST /auth/register/teacher` — dateOfBirth and gender both optional
  /// (`registerTeacherSchema`).
  Future<User> registerTeacher({
    required String firstName,
    String? middleName,
    required String lastName,
    String? dateOfBirth,
    Gender? gender,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _apiClient.post(ApiConfig.registerTeacher, body: {
      'firstName': firstName,
      if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': ?dateOfBirth,
      if (gender != null) 'gender': gender.apiValue,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return User.fromJson(json);
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiConfig.forgotPassword,
      body: {'email': email},
      timeout: ApiConfig.emailRequestTimeout,
    );
  }

  Future<void> resetPasswordConfirm({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post(ApiConfig.resetPasswordConfirm, body: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  /// `POST /auth/verify-email/resend` — same shape as [forgotPassword]:
  /// email only, and given the same generous [ApiConfig.emailRequestTimeout]
  /// since it does a DB lookup + SMTP send synchronously before responding.
  Future<void> resendVerificationEmail(String email) async {
    await _apiClient.post(
      ApiConfig.verifyEmailResend,
      body: {'email': email},
      timeout: ApiConfig.emailRequestTimeout,
    );
  }

  /// `POST /auth/verify-email/confirm` — same shape as
  /// [resetPasswordConfirm]: redeems the token from the emailed link.
  Future<void> verifyEmailConfirm(String token) async {
    await _apiClient.post(ApiConfig.verifyEmailConfirm, body: {
      'token': token,
    });
  }

  /// `POST /auth/refresh` — rotates the refresh token; returns a fresh pair.
  Future<void> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return;
    final json = await _apiClient.post(ApiConfig.refresh, body: {
      'refreshToken': refreshToken,
    });
    await _tokenStorage.saveTokens(
      accessToken: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  /// `POST /auth/logout` — requires the access token; body carries the
  /// refresh token to revoke (optional server-side).
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      await _apiClient.post(
        ApiConfig.logout,
        body: refreshToken != null ? {'refreshToken': refreshToken} : null,
        requireAuth: true,
      );
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// `GET /auth/me`
  Future<User> getMe() async {
    final json = await _apiClient.get(ApiConfig.me, requireAuth: true);
    return User.fromJson(json);
  }

  Future<bool> isLoggedIn() async =>
      (await _tokenStorage.readAccessToken()) != null;
}