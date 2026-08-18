import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:schoolguardian_app/screens/verify_eamil_page.dart';
import 'models/user.dart';
import 'models/user_role.dart';
import 'screens/account_rejected_page.dart';
import 'screens/admin/admin_notifications_page.dart';
import 'screens/admin/admin_profile_page.dart';
import 'screens/admin/manage_courses_page.dart';
import 'screens/admin/manage_users_page.dart';
import 'screens/admin/pending_approvals_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/grades/parent_grades_page.dart';
import 'screens/grades/student_grades_page.dart';
import 'screens/landing_page.dart';
import 'screens/login_page.dart';
import 'screens/onboarding/onboarding_page.dart';
import 'screens/pending_approval_page.dart';
import 'screens/reports/academic_report_page.dart';
import 'screens/reports/attendance_report_page.dart';
import 'screens/reports/reports_page.dart';
import 'screens/reports/wellbeing_report_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/session_check_page.dart';
import 'screens/signup/signup_page.dart';
import 'screens/student/course_registration_page.dart';
import 'screens/teacher/add_grade_page.dart';
import 'screens/teacher/my_classes_page.dart';
import 'screens/teacher/teacher_portal_page.dart';
import 'screens/unauthorized_page.dart';
import 'theme/app_theme.dart';

void main() {
  // On web, this strips the leading "#" from URLs so links look like
  // http://localhost:3000/reset-password?token=... instead of
  // http://localhost:3000/#/reset-password?token=... — this is what lets
  // the backend's plain http://localhost:3000/reset-password link (see
  // RESET_PASSWORD_URL) open straight to this app's reset-password route.
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // THIS IS THE FIX for screens going completely blank with no message
  // (e.g. a pending-approvals tab showing nothing at all): Flutter's
  // default behaviour when a widget throws mid-build is to swap in a
  // small blank/gray box, especially outside debug mode -- so a real bug
  // looks identical to "there's just nothing here". This makes any such
  // crash visible with the actual error, so it can be diagnosed from a
  // screenshot instead of guessed at.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: AppColors.errorContainer,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        'Something went wrong displaying this.\n${details.exceptionAsString()}',
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: AppColors.onErrorContainer, fontSize: 12),
      ),
    );
  };
  runApp(const SchoolGuardianApp());
}

class SchoolGuardianApp extends StatefulWidget {
  const SchoolGuardianApp({super.key});

  @override
  State<SchoolGuardianApp> createState() => _SchoolGuardianAppState();
}

class _SchoolGuardianAppState extends State<SchoolGuardianApp> {
  // A global navigator key lets the deep-link listener below push routes
  // from outside the widget tree (it has no BuildContext of its own).
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Handles the password-reset link sent by the backend:
  /// `schoolguardian://reset-password?token=...` (see `RESET_PASSWORD_URL`
  /// in the backend's .env).
  ///
  /// Two cases to cover:
  /// 1. App is closed and the link launches it fresh -> [getInitialLink].
  /// 2. App is already running in the background -> [uriLinkStream].
  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleIncomingLink(initialUri);
    } catch (_) {
      // Malformed or missing initial link -- fall through to normal
      // SessionCheckPage startup flow instead of crashing the app.
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (_) {
        // Ignore malformed links rather than crashing a running session.
      },
    );
  }

  void _handleIncomingLink(Uri uri) {
    // Matches schoolguardian://reset-password?token=... — "reset-password"
    // parses as the URI's host for a custom scheme, not its path.
    final isResetPasswordLink = uri.host == 'reset-password';
    // Matches schoolguardian://verify-email?token=..., same shape as the
    // reset-password link above (see VERIFY_EMAIL_URL, mirroring
    // RESET_PASSWORD_URL, on the backend .env).
    final isVerifyEmailLink = uri.host == 'verify-email';
    if (!isResetPasswordLink && !isVerifyEmailLink) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    if (isResetPasswordLink) {
      _navigatorKey.currentState?.pushNamed(
        ResetPasswordPage.routeName,
        arguments: token,
      );
    } else {
      _navigatorKey.currentState?.pushNamed(
        VerifyEmailPage.routeName,
        arguments: {'token': token},
      );
    }
  }

  /// On web the browser's real starting URL (e.g.
  /// `http://localhost:3000/reset-password?token=abc`, from the backend's
  /// emailed link) is what should decide the first screen — not always
  /// [SessionCheckPage]. Elsewhere (mobile, or web with no special path)
  /// we keep the normal startup flow.
  String get _initialRoute {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.path == ResetPasswordPage.routeName ||
          uri.path == VerifyEmailPage.routeName) {
        return Uri(path: uri.path, queryParameters: uri.queryParametersAll)
            .toString();
      }
    }
    return SessionCheckPage.routeName;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SchoolGuardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Every launch starts at SessionCheckPage, which decides between
      // OnboardingPage (first-ever launch), LandingPage (returning, no/
      // invalid session), or DashboardPage (valid session) — see
      // session_check_page.dart. The exception is web loading straight
      // into a /reset-password?token=... link, handled by _initialRoute.
      initialRoute: _initialRoute,
      onGenerateRoute: (settings) {
        // On web, settings.name may carry a query string (e.g.
        // "/reset-password?token=abc") when it comes straight from the
        // browser's URL via _initialRoute above. Route matching below
        // always switches on the bare path; the token itself is read
        // from either the pushed arguments (mobile deep-link flow) or
        // the URL's query parameters (web link-click flow).
        final uri = Uri.parse(settings.name ?? SessionCheckPage.routeName);
        switch (uri.path) {
          case SessionCheckPage.routeName:
            return MaterialPageRoute(builder: (_) => const SessionCheckPage());

          case OnboardingPage.routeName:
            return MaterialPageRoute(builder: (_) => const OnboardingPage());

          case LandingPage.routeName:
            return MaterialPageRoute(builder: (_) => const LandingPage());

          case DashboardPage.routeName:
            final user = settings.arguments as User;
            return MaterialPageRoute(builder: (_) => DashboardPage(user: user));

          case LoginPage.routeName:
            final role = settings.arguments as UserRole?;
            return MaterialPageRoute(builder: (_) => LoginPage(role: role));

          case '/signup/parent':
            return MaterialPageRoute(
                builder: (_) => const SignUpPage(role: UserRole.parent));
          case '/signup/student':
            return MaterialPageRoute(
                builder: (_) => const SignUpPage(role: UserRole.student));
          case '/signup/teacher':
            return MaterialPageRoute(
                builder: (_) => const SignUpPage(role: UserRole.teacher));

          case ForgotPasswordPage.routeName:
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

          case ResetPasswordPage.routeName:
            final token =
                settings.arguments as String? ?? uri.queryParameters['token'];
            return MaterialPageRoute(
                builder: (_) => ResetPasswordPage(token: token));

          case PendingApprovalPage.routeName:
            return MaterialPageRoute(builder: (_) => const PendingApprovalPage());

          case VerifyEmailPage.routeName:
            // Two ways in, same as ResetPasswordPage above:
            // - Straight from SignUpPage: arguments = {'email': ...}.
            // - From the emailed link (deep link or web click-through):
            //   arguments = {'token': ...} (mobile) or the URL's own
            //   query parameters (web).
            final args = settings.arguments;
            final argsMap = args is Map ? args : const {};
            final email = argsMap['email'] as String? ??
                uri.queryParameters['email'];
            final token = argsMap['token'] as String? ??
                uri.queryParameters['token'];
            return MaterialPageRoute(
                builder: (_) => VerifyEmailPage(email: email, token: token));

          // --- Admin screens (previously unreachable: no routes were
          // registered for them, which was the root cause of pending
          // requests never surfacing in the admin portal) ---
          case PendingApprovalsPage.routeName:
            return MaterialPageRoute(
                builder: (_) => const PendingApprovalsPage());

          case AdminNotificationsPage.routeName:
            return MaterialPageRoute(
                builder: (_) => const AdminNotificationsPage());

          case ManageUsersPage.routeName:
            return MaterialPageRoute(builder: (_) => const ManageUsersPage());

          case AdminProfilePage.routeName:
            final user = settings.arguments as User?;
            return MaterialPageRoute(
                builder: (_) => AdminProfilePage(initialUser: user));

          case ReportsPage.routeName:
            return MaterialPageRoute(builder: (_) => const ReportsPage());

          case AcademicReportPage.routeName:
            return MaterialPageRoute(builder: (_) => const AcademicReportPage());

          case AttendanceReportPage.routeName:
            return MaterialPageRoute(builder: (_) => const AttendanceReportPage());

          case WellbeingReportPage.routeName:
            return MaterialPageRoute(builder: (_) => const WellbeingReportPage());

          case ManageCoursesPage.routeName:
            return MaterialPageRoute(builder: (_) => const ManageCoursesPage());

          case CourseRegistrationPage.routeName:
            return MaterialPageRoute(builder: (_) => const CourseRegistrationPage());

          case TeacherPortalPage.routeName:
            return MaterialPageRoute(builder: (_) => const TeacherPortalPage());

          case MyClassesPage.routeName:
            return MaterialPageRoute(builder: (_) => const MyClassesPage());

          case AddGradePage.routeName:
            return MaterialPageRoute(builder: (_) => const AddGradePage());

          case ParentGradesPage.routeName:
            final studentId = settings.arguments as String? ?? 'STU-1001';
            return MaterialPageRoute(
                builder: (_) => ParentGradesPage(studentId: studentId));

          case StudentGradesPage.routeName:
            final studentId = settings.arguments as String? ?? 'STU-1001';
            return MaterialPageRoute(
                builder: (_) => StudentGradesPage(studentId: studentId));

          case AccountRejectedPage.routeName:
            final reason = settings.arguments as String?;
            return MaterialPageRoute(
                builder: (_) => AccountRejectedPage(reason: reason));

          case UnauthorizedPage.routeName:
            return MaterialPageRoute(builder: (_) => const UnauthorizedPage());

          default:
            return MaterialPageRoute(builder: (_) => const LandingPage());
        }
      },
    );
  }
}