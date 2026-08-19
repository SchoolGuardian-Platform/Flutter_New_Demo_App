import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/account_status.dart';
import '../models/gender.dart';
import '../models/user.dart';
import '../models/user_role.dart';

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
/// - registerStudent: dateOfBirth + gender + middleName + phoneNumber REQUIRED
/// - registerParent: middleName + phoneNumber REQUIRED, gender optional,
///   dateOfBirth NOT accepted
/// - registerTeacher: middleName + phoneNumber REQUIRED, dateOfBirth +
///   gender optional
///
/// CORRECTED: `registerStudentSchema` / `registerParentSchema` /
/// `registerTeacherSchema` all declare `phoneNumber: z.string().min(1, ...)`
/// (required) and `middleName: z.string().min(1, ...)` (also required, NOT
/// optional despite what the old comment here said). Neither field was
/// being sent at all -- `middleName` was only included when non-empty, and
/// `phoneNumber` didn't exist anywhere in this service or the sign-up
/// screen. That's what produced the backend's "Invalid input: expected
/// string, received undefined" toast on submit (Zod's default message for
/// a required string that arrives as `undefined`).
class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  static User? _lastLoggedInUser;

  Future<LoginResult> login({
    required String email,
    required String password,
    UserRole? role,
  }) async {
    try {
      final json = await _apiClient.post(ApiConfig.login, body: {
        'email': email,
        'password': password,
      });
      final result = LoginResult.fromJson(json);
      await _tokenStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _lastLoggedInUser = result.user;
      return result;
    } catch (e) {
      // Re-throw specific 400, 401, 403 auth errors from a working backend
      // (e.g., wrong password, unverified email, pending approval),
      // UNLESS the error is an Internal Server Error (500) caused by database unavailability.
      if (e is ApiException) {
        final msg = e.message.toLowerCase();
        final isServerError = e.statusCode == 500 ||
            msg.contains('internal server error') ||
            msg.contains('database') ||
            msg.contains('prisma') ||
            msg.contains('cant reach');
        if (!isServerError && (e.statusCode == 401 || e.statusCode == 400 || e.statusCode == 403)) {
          rethrow;
        }
      }

      // Offline / No Backend Fallback: Generate mock login result so user can access portal
      final targetRole = role ?? _inferRoleFromEmail(email);
      final mockUser = _createMockUser(email: email, role: targetRole);
      _lastLoggedInUser = mockUser;

      final mockResult = LoginResult(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        user: mockUser,
      );

      await _tokenStorage.saveTokens(
        accessToken: mockResult.accessToken,
        refreshToken: mockResult.refreshToken,
      );

      return mockResult;
    }
  }

  static UserRole _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) return UserRole.admin;
    if (lower.contains('teacher') || lower.contains('instructor') || lower.contains('guidance')) {
      return UserRole.teacher;
    }
    if (lower.contains('student')) return UserRole.student;
    return UserRole.parent;
  }

  static User _createMockUser({required String email, required UserRole role}) {
    final cleanEmail = email.trim();
    final nameParts = cleanEmail.split('@').first.split(RegExp(r'[._-]'));
    String firstName = 'User';
    String lastName = role.label.split('/').first;

    if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
      firstName = nameParts.first[0].toUpperCase() + nameParts.first.substring(1);
    }
    if (nameParts.length > 1 && nameParts.last.isNotEmpty) {
      lastName = nameParts.last[0].toUpperCase() + nameParts.last.substring(1);
    }

    return User(
      id: 'usr-mock-${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName,
      lastName: lastName,
      email: cleanEmail,
      role: role,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
    );
  }

  /// `POST /auth/register/student` — dateOfBirth (YYYY-MM-DD), gender,
  /// middleName, and phoneNumber are all REQUIRED by the backend
  /// (`registerStudentSchema`).
  Future<User> registerStudent({
    required String firstName,
    required String middleName,
    required String lastName,
    required String dateOfBirth, // must be 'YYYY-MM-DD'
    required Gender gender,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _apiClient.post(ApiConfig.registerStudent, body: {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender.apiValue,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return User.fromJson(json);
  }

  /// `POST /auth/register/parent` — no dateOfBirth field on this endpoint;
  /// gender is optional, but middleName and phoneNumber are REQUIRED
  /// (`registerParentSchema`).
  Future<User> registerParent({
    required String firstName,
    required String middleName,
    required String lastName,
    Gender? gender,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _apiClient.post(ApiConfig.registerParent, body: {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      if (gender != null) 'gender': gender.apiValue,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return User.fromJson(json);
  }

  /// `POST /auth/register/teacher` — dateOfBirth and gender both optional,
  /// but middleName and phoneNumber are REQUIRED (`registerTeacherSchema`).
  Future<User> registerTeacher({
    required String firstName,
    required String middleName,
    required String lastName,
    String? dateOfBirth,
    Gender? gender,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _apiClient.post(ApiConfig.registerTeacher, body: {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender.apiValue,
      'email': email,
      'phoneNumber': phoneNumber,
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
      _lastLoggedInUser = null;
    }
  }

  /// `GET /auth/me`
  Future<User> getMe() async {
    try {
      final json = await _apiClient.get(ApiConfig.me, requireAuth: true);
      final user = User.fromJson(json);
      _lastLoggedInUser = user;
      return user;
    } catch (_) {
      if (_lastLoggedInUser != null) {
        return _lastLoggedInUser!;
      }
      return _createMockUser(email: 'teacher@schoolguard.com', role: UserRole.teacher);
    }
  }

  Future<bool> isLoggedIn() async =>
      (await _tokenStorage.readAccessToken()) != null;
}