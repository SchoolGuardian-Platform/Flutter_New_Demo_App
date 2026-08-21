import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../models/parent_student_link.dart';
import '../models/relationship.dart';

/// Wraps the parent-facing endpoints from `src/routes/parent.routes.ts`.
///
/// Covers `/parents/*` for the parent dashboard's "Linked Students" tab
/// and the "Link a Student" request form.
class ParentService {
  ParentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /parents/my-students`
  ///
  /// Returns verified (APPROVED) students linked to the authenticated parent.
  /// Handles backend envelope shape `{ "data": [ ... ] }`.
  Future<List<ParentStudentLink>> getMyStudents() async {
    final decoded = await _apiClient.get(
      ApiConfig.parentMyStudents,
      requireAuth: true,
    );
    final raw = decoded['data'];
    if (raw is! List) {
      throw ApiException.malformed(200);
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => ParentStudentLink.fromJson(item))
        .toList();
  }

  /// `POST /parents/link-student` (or `POST /parents/relationships`)
  ///
  /// Requests a guardian relationship. Requires admin approval before it
  /// shows up in [getMyStudents] or the student's guardian list.
  ///
  /// Exactly one of [studentId] or [studentEmail] must be non-null/non-empty.
  Future<Relationship> requestRelationship({
    String? studentId,
    String? studentEmail,
    required RelationshipType relationshipType,
  }) async {
    assert(
      (studentId != null && studentId.isNotEmpty) ||
          (studentEmail != null && studentEmail.isNotEmpty),
      'Either studentId or studentEmail must be provided',
    );

    final body = <String, dynamic>{
      'relationshipType': relationshipType.name.toUpperCase(),
      if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
      if (studentEmail != null && studentEmail.isNotEmpty)
        'studentEmail': studentEmail,
    };

    final decoded = await _apiClient.post(
      ApiConfig.parentLinkStudent,
      body: body,
      requireAuth: true,
    );

    final data = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;

    return Relationship.fromJson(data);
  }

  /// Alias for [requestRelationship] supporting `void` returns.
  Future<void> linkStudent({
    String? studentId,
    String? studentEmail,
    required RelationshipType relationshipType,
  }) async {
    await requestRelationship(
      studentId: studentId,
      studentEmail: studentEmail,
      relationshipType: relationshipType,
    );
  }
}