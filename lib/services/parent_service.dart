import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/parent_student_link.dart';
import '../models/relationship.dart';

/// Wraps the parent-facing endpoints from `src/routes/parent.routes.ts`.
///
///   GET   /parents/my-students      — list verified linked students
///   POST  /parents/link-student     — request a new guardian link
class ParentService {
  ParentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /parents/my-students`
  ///
  /// Returns approved guardian links for the authenticated parent.
  /// Backend response envelope: `{ "data": [ { relationshipId, relationshipType,
  /// student: {...}, verifiedAt } ] }` (see `getParentVerifiedStudents` in
  /// `relationship.service.ts`).
  ///
  /// [ApiClient] returns the full decoded body when `data` is a List (not a
  /// Map), so we read `json['data']` directly from the decoded response.
  Future<List<ParentStudentLink>> getMyStudents() async {
    final json = await _apiClient.get(
      ApiConfig.parentMyStudents,
      requireAuth: true,
    );
    // ApiClient._send returns decoded (full body) when data is a List.
    final raw = json['data'];
    if (raw is! List) return [];
    return raw
        .map((item) =>
            ParentStudentLink.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `POST /parents/link-student`
  ///
  /// Requests a guardian relationship. Requires admin approval before it
  /// shows up in [getMyStudents].
  ///
  /// [studentId] or [studentEmail] must be provided (backend picks one).
  /// [relationshipType] must be one of: MOTHER, FATHER, GUARDIAN, OTHER.
  Future<void> linkStudent({
    String? studentId,
    String? studentEmail,
    required RelationshipType relationshipType,
  }) async {
    final body = <String, dynamic>{
      'relationshipType': relationshipType.name.toUpperCase(),
    };
    if (studentId != null && studentId.isNotEmpty) {
      body['studentId'] = studentId;
    }
    if (studentEmail != null && studentEmail.isNotEmpty) {
      body['studentEmail'] = studentEmail;
    }
    await _apiClient.post(
      ApiConfig.parentLinkStudent,
      body: body,
      requireAuth: true,
    );
  }
}
