/// Central configuration for talking to the SchoolGuardian backend.
///
/// The backend (see `src/app.ts`) mounts every router twice — once bare
/// and once under `/api` — so either `baseUrl` works. We standardize on
/// the `/api` prefix here.
///
/// [baseUrl] is read from `--dart-define=API_BASE_URL=...` so it can vary
/// per environment (local dev vs staging vs prod) without touching code.
/// Run/build with e.g.:
/// ```
/// flutter run --dart-define=API_BASE_URL=[http://10.0.2.2:3000/api](http://10.0.2.2:3000/api)
/// flutter build apk --dart-define=API_BASE_URL=[https://api.schoolguardian.app/api](https://api.schoolguardian.app/api)
/// ```
/// If nothing is passed, it falls back to the local-dev Android-emulator
/// address below (10.0.2.2 maps to the host machine's localhost — use your
/// machine's LAN IP for a physical device).
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static String get _fallbackBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  static final String baseUrl =
      const String.fromEnvironment('API_BASE_URL').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : _fallbackBaseUrl;

  static const Duration requestTimeout = Duration(seconds: 15);

  /// `POST /auth/forgot-password` sends an email synchronously before
  /// responding (DB lookup + SMTP handshake + send) -- the default
  /// [requestTimeout] is tuned for plain DB-backed calls and is too
  /// tight for that, especially on a cold Neon connection or a slow
  /// first TLS handshake to the mail provider. Give this one call more
  /// room so the app doesn't show "timed out or failed" for a request
  /// the backend actually completed successfully.
  static const Duration emailRequestTimeout = Duration(seconds: 30);

  // ---- Auth (src/routes/auth.routes.ts) ----
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String registerStudent = '/auth/register/student';
  static const String registerParent = '/auth/register/parent';
  static const String registerTeacher = '/auth/register/teacher';

  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPasswordConfirm = '/auth/reset-password/confirm';

  // Mirrors the forgot-password/reset-password pair above, one step
  // earlier in the flow. NOTE: unlike reset-password, these two don't
  // share a path prefix -- confirm is POST /auth/verify-email (not
  // .../verify-email/confirm) and resend is POST /auth/resend-verification
  // (not .../verify-email/resend). Matches auth.routes.ts exactly.
  static const String verifyEmailConfirm = '/auth/verify-email';
  static const String verifyEmailResend = '/auth/resend-verification';

  // ---- Attendance (src/routes/attendance.routes.ts) ----
  static const String attendance = '/attendance';
  static const String attendanceTeacher = '/attendance/teacher';

  static String attendanceByStudent(String studentId) =>
      '/attendance/student/$studentId';

  static String attendanceSummary(String studentId) =>
      '/attendance/student/$studentId/summary';

  static String attendanceById(String id) => '/attendance/$id';

  // ---- Grades (src/routes/grade.routes.ts) ----
  static const String grades = '/grades';
  static const String gradesByTeacher = '/grades/teacher';

  static String gradesByStudent(String studentId) =>
      '/grades/student/$studentId';

  static String gradeSummary(String studentId) =>
      '/grades/student/$studentId/summary';

  static String gradeById(String id) => '/grades/$id';

  // ---- Homework (src/routes/homework.routes.ts) ----
  static const String homework = '/homework';
  static const String homeworkByTeacher = '/homework/teacher';

  static String homeworkByStudent(String studentId) =>
      '/homework/student/$studentId';

  static String homeworkByClass(String classId) => '/homework/class/$classId';

  static String homeworkById(String id) => '/homework/$id';

  // ---- Parent (src/routes/parent.routes.ts) ----
  static const String parentMyStudents = '/parents/my-students';
  static const String parentLinkStudent = '/parents/link-student';

  // ---- Gemini AI (Google AI Studio free tier) ----
  // Get your free API key at: https://aistudio.google.com/app/apikey
  // Pass via: flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static final String geminiApiKey =
      const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
          ? const String.fromEnvironment('GEMINI_API_KEY')
          : '';

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent';
}