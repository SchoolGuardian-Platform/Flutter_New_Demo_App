import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/relationship.dart';
import '../models/student_link.dart';

/// Covers `/parents/*` (`src/routes/parent.routes.ts`) for the parent
/// dashboard's "Linked Students" tab and the "Link a Student" form.
///
/// SCOPE NOTE: the guardian-link relationship can only be *initiated*
/// from the parent side -- `POST /parents/relationships` (aliased as
/// `POST /parents/link-student`, same controller) is the only endpoint
/// that creates a `ParentStudentRelationship` row. There is no matching
/// student-side endpoint; `GET /students/my-guardians`
/// (`StudentService`) is read-only. See `relationship.controller.ts`.
class ParentService {
  ParentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String myStudentsPath = '/parents/my-students';
  static const String relationshipsPath = '/parents/relationships';

  /// `GET /parents/my-students` -- verified (APPROVED) students linked to
  /// the signed-in parent's account.
  Future<List<StudentLink>> getMyStudents() async {
    final decoded = await _apiClient.get(myStudentsPath, requireAuth: true);
    final list = decoded['data'];
    if (list is! List) {
      throw ApiException.malformed(200);
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => StudentLink.fromJson(json))
        .toList();
  }

  /// `POST /parents/relationships` -- requests a guardian link to a
  /// student, identified by EITHER [studentId] OR [studentEmail] (exactly
  /// one must be non-null/non-empty, matching `createRelationshipSchema`'s
  /// `.refine` in `relationship.validator.ts`). Creates the relationship
  /// with status PENDING; an admin must approve it before it shows up in
  /// [getMyStudents] or the student's `GET /students/my-guardians`.
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
    final decoded = await _apiClient.post(
      relationshipsPath,
      requireAuth: true,
      body: {
        if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
        if (studentEmail != null && studentEmail.isNotEmpty)
          'studentEmail': studentEmail,
        'relationshipType': relationshipType.apiValue,
      },
    );
    return Relationship.fromJson(decoded);
  }
}
