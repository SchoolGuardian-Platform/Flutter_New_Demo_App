import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../models/relationship.dart';

/// Snapshot of everything currently awaiting admin action, across every
/// category. This is what powers the admin notification bell / badge --
/// see `screens/admin/admin_notifications_page.dart`. There is no single
/// backend endpoint for this (the `/notifications` endpoint in the OpenAPI
/// spec is marked `x-implementation-status: planned`, i.e. not live yet),
/// so it is assembled client-side from the four `GET .../pending` endpoints
/// that ARE implemented today.
class PendingSummary {
  const PendingSummary({
    required this.students,
    required this.parents,
    required this.teachers,
    required this.relationships,
  });

  final List<User> students;
  final List<User> parents;
  final List<User> teachers;
  final List<Relationship> relationships;

  int get total =>
      students.length + parents.length + teachers.length + relationships.length;

  static const empty = PendingSummary(
    students: [],
    parents: [],
    teachers: [],
    relationships: [],
  );

  /// Returns a copy with the given user removed from its role's list.
  /// Used after approving/rejecting a single item straight from the
  /// notification feed so the tile disappears immediately, without a
  /// full re-fetch of all four queues.
  PendingSummary withoutUser({required UserRole role, required String userId}) {
    switch (role) {
      case UserRole.student:
        return PendingSummary(
          students: students.where((u) => u.id != userId).toList(),
          parents: parents,
          teachers: teachers,
          relationships: relationships,
        );
      case UserRole.parent:
        return PendingSummary(
          students: students,
          parents: parents.where((u) => u.id != userId).toList(),
          teachers: teachers,
          relationships: relationships,
        );
      case UserRole.teacher:
        return PendingSummary(
          students: students,
          parents: parents,
          teachers: teachers.where((u) => u.id != userId).toList(),
          relationships: relationships,
        );
      case UserRole.admin:
        return this;
    }
  }

  /// Same idea as [withoutUser], for a resolved guardian-link request.
  PendingSummary withoutRelationship(String id) => PendingSummary(
        students: students,
        parents: parents,
        teachers: teachers,
        relationships: relationships.where((r) => r.id != id).toList(),
      );
}

/// Covers the `/admin/*` endpoints (`src/routes/admin.routes.ts`) for the
/// "Pending Approvals" screen: list pending accounts by role, and
/// approve/reject a given account.
///
/// INTENTIONALLY SEPARATE FROM `core/api_client.dart`: that shared client
/// only exposes GET/POST today, and these endpoints use PATCH and DELETE.
/// Rather than
/// touch the shared API layer (risk of merge conflicts with whatever else
/// is in flight on it), this makes its own `package:http` calls, reusing
/// `ApiConfig.baseUrl` and `TokenStorage` read-only. It mirrors the same
/// response envelope handling as `ApiClient` — `{ data: ... }` on success,
/// `{ error: { code, message } }` on failure — but does NOT get
/// `ApiClient`'s automatic 401-refresh-and-retry. If a request comes back
/// 401 here, it surfaces as a normal `ApiException` instead of silently
/// refreshing; the caller can prompt a re-login.
///
/// Once `ApiClient` grows a `patch()` method, this can be folded into it.
class AdminService {
  AdminService({http.Client? httpClient, TokenStorage? tokenStorage})
      : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  /// How many accounts this admin has approved since the app was opened.
  /// NOTE: this is intentionally a session-local counter, not a true
  /// historical total -- the backend doesn't expose a "count of all-time
  /// approvals" endpoint yet, only the live pending queues. It resets to
  /// 0 on app restart. Powers the "Approved this session" stat on the
  /// dashboard Overview tab (see `screens/admin/admin_overview_tab.dart`).
  static int sessionApprovals = 0;

  static const Map<UserRole, String> _pendingPaths = {
    UserRole.student: '/admin/students/pending',
    UserRole.parent: '/admin/parents/pending',
    UserRole.teacher: '/admin/teachers/pending',
  };

  static const Map<UserRole, String> _resourceSegments = {
    UserRole.student: 'students',
    UserRole.parent: 'parents',
    UserRole.teacher: 'teachers',
  };

  /// `GET /admin/{students|parents|teachers}/pending`
  Future<List<User>> getPending(UserRole role) async {
    final path = _pendingPaths[role];
    if (path == null) {
      throw ArgumentError('No pending-approvals endpoint for role: $role');
    }
    final decoded = await _get(path);
    final list = decoded['data'];
    if (list is! List) {
      throw ApiException.malformed(200);
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => User.fromJson(json))
        .toList();
  }

  /// `GET /admin/users/verified?role={ROLE}` -- verified/approved accounts
  /// (`AccountStatus.ACTIVE`) for the "Users" directory tab, rather than
  /// the approvals queue.
  ///
  /// CORRECTED: this used to call `/admin/{role}/active`, which does not
  /// exist anywhere in `admin.routes.ts` (every request 404'd, so the
  /// "Users" tab always rendered empty). The route that's actually
  /// implemented is a single `GET /admin/users/verified` that takes the
  /// role as a query parameter -- see `getVerifiedUsersController` /
  /// `getVerifiedUsersByRole` in `admin.controller.ts` / `admin.service.ts`.
  /// `UserRole.admin` has no verified-users listing (admins aren't shown
  /// in this directory), so it throws same as before.
  Future<List<User>> getActive(UserRole role) async {
    if (role == UserRole.admin) {
      throw ArgumentError('No verified-users listing for role: $role');
    }
    final decoded = await _get('/admin/users/verified?role=${role.apiValue}');
    final list = decoded['data'];
    if (list is! List) {
      throw ApiException.malformed(200);
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => User.fromJson(json))
        .toList();
  }

  /// `DELETE /admin/users/:id` -- permanently removes a user account.
  /// The backend refuses to delete an ADMIN account (`deleteUser` in
  /// `admin.service.ts` throws `BadRequestError`), which surfaces here as
  /// a normal `ApiException` for the caller to show.
  Future<void> deleteUser(String userId) async {
    await _delete('/admin/users/$userId');
  }

  /// `PATCH /admin/{students|parents|teachers}/:id/approve`
  Future<User> approve(UserRole role, String userId) async {
    final segment = _resourceSegments[role]!;
    final decoded = await _patch('/admin/$segment/$userId/approve');
    sessionApprovals++;
    return User.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// `PATCH /admin/{students|parents|teachers}/:id/reject`
  /// [reason] is optional (see `rejectionSchema` in `admin.validator.ts`).
  Future<User> reject(UserRole role, String userId, {String? reason}) async {
    final segment = _resourceSegments[role]!;
    final decoded = await _patch(
      '/admin/$segment/$userId/reject',
      body: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
    return User.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// `GET /admin/relationships/pending` -- guardian-link requests, the
  /// fourth category of "thing waiting on an admin" alongside the three
  /// account types above. Previously missing from this service entirely,
  /// which meant approved/rejected parent-student links never showed up
  /// anywhere in the admin UI.
  Future<List<Relationship>> getPendingRelationships() async {
    final decoded = await _get('/admin/relationships/pending');
    final list = decoded['data'];
    if (list is! List) {
      throw ApiException.malformed(200);
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Relationship.fromJson(json))
        .toList();
  }

  /// `PATCH /admin/relationships/:id/approve`
  Future<void> approveRelationship(String id) async {
    await _patch('/admin/relationships/$id/approve');
    sessionApprovals++;
  }

  /// `PATCH /admin/relationships/:id/reject`
  Future<void> rejectRelationship(String id, {String? reason}) async {
    await _patch(
      '/admin/relationships/$id/reject',
      body: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
  }

  /// Fetches all four pending queues in parallel and folds them into one
  /// [PendingSummary]. This is the single source of truth for "how many
  /// things need my attention" -- used by the notification bell badge on
  /// the dashboard and by `AdminNotificationsPage`. A single failed
  /// category doesn't take down the rest: it's simply reported as empty
  /// for this fetch, so one flaky endpoint can't blank out the whole
  /// notification feed.
  Future<PendingSummary> getPendingSummary() async {
    final results = await Future.wait([
      getPending(UserRole.student).catchError((_) => <User>[]),
      getPending(UserRole.parent).catchError((_) => <User>[]),
      getPending(UserRole.teacher).catchError((_) => <User>[]),
      getPendingRelationships().catchError((_) => <Relationship>[]),
    ]);
    return PendingSummary(
      students: results[0] as List<User>,
      parents: results[1] as List<User>,
      teachers: results[2] as List<User>,
      relationships: results[3] as List<Relationship>,
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _tokenStorage.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    http.Response response;
    try {
      response = await _httpClient
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw ApiException.network(
          'Could not reach the server. Check your connection.');
    } on HttpException {
      throw ApiException.network('The server could not be reached.');
    } catch (_) {
      throw ApiException.network('The request timed out or failed.');
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.Request('PATCH', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    if (body != null) {
      request.body = jsonEncode(body);
    }
    http.Response response;
    try {
      final streamed =
          await _httpClient.send(request).timeout(ApiConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw ApiException.network(
          'Could not reach the server. Check your connection.');
    } on HttpException {
      throw ApiException.network('The server could not be reached.');
    } catch (_) {
      throw ApiException.network('The request timed out or failed.');
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final token = await _tokenStorage.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    http.Response response;
    try {
      response = await _httpClient
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.requestTimeout);
    } on SocketException {
      throw ApiException.network(
          'Could not reach the server. Check your connection.');
    } on HttpException {
      throw ApiException.network('The server could not be reached.');
    } catch (_) {
      throw ApiException.network('The request timed out or failed.');
    }
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException.malformed(response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
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
}