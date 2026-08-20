import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/grade.dart';

/// Wraps the grade endpoints from `src/routes/grade.routes.ts`.
///
/// Teacher-only write operations:
///   POST   /grades                           createGrade
///   PATCH  /grades/:id                       updateGrade
///   DELETE /grades/:id                       deleteGrade
///
/// Read operations (teacher/student/parent/admin with access checks):
///   GET    /grades/teacher                   getGradesByTeacher
///   GET    /grades/student/:studentId        getGradesByStudent
///   GET    /grades/:id                       getGradeById
class GradeService {
  GradeService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /grades/teacher` — all grades created by the current teacher.
  Future<List<Grade>> getGradesByTeacher() async {
    final json =
        await _apiClient.get(ApiConfig.gradesByTeacher, requireAuth: true);
    final list = json['grades'] as List<dynamic>;
    return list
        .map((item) => Grade.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `GET /grades/student/:studentId` — all grades for a given student.
  /// Requires the caller to have access (teacher, student, parent, admin).
  Future<List<Grade>> getGradesByStudent(String studentId) async {
    final json = await _apiClient.get(
      ApiConfig.gradesByStudent(studentId),
      requireAuth: true,
    );
    final list = json['grades'] as List<dynamic>;
    return list
        .map((item) => Grade.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `POST /grades` — create a new grade record (TEACHER only).
  ///
  /// [assessmentType] must be one of the Prisma `AssessmentType` enum values
  /// (QUIZ, TEST, EXAM, ASSIGNMENT, PROJECT, OTHER) — use [AssessmentType.apiValue].
  Future<Grade> createGrade({
    required String studentId,
    required String subject,
    required AssessmentType assessmentType,
    required double score,
    required double maxScore,
    String? term,
    String? academicYear,
    String? comment,
  }) async {
    final json = await _apiClient.post(
      ApiConfig.grades,
      body: {
        'studentId': studentId,
        'subject': subject,
        'assessmentType': assessmentType.apiValue,
        'score': score,
        'maxScore': maxScore,
        if (term != null && term.isNotEmpty) 'term': term,
        if (academicYear != null && academicYear.isNotEmpty)
          'academicYear': academicYear,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      requireAuth: true,
    );
    return Grade.fromJson(json['grade'] as Map<String, dynamic>);
  }

  /// `PATCH /grades/:id` — update an existing grade (TEACHER only, own grades).
  Future<Grade> updateGrade(
    String id, {
    String? subject,
    AssessmentType? assessmentType,
    double? score,
    double? maxScore,
    String? term,
    String? academicYear,
    String? comment,
  }) async {
    final body = <String, dynamic>{};
    if (subject != null) body['subject'] = subject;
    if (assessmentType != null) {
      body['assessmentType'] = assessmentType.apiValue;
    }
    if (score != null) body['score'] = score;
    if (maxScore != null) body['maxScore'] = maxScore;
    if (term != null) body['term'] = term.isEmpty ? null : term;
    if (academicYear != null) {
      body['academicYear'] = academicYear.isEmpty ? null : academicYear;
    }
    if (comment != null) body['comment'] = comment.isEmpty ? null : comment;

    final json = await _apiClient.patch(
      ApiConfig.gradeById(id),
      body: body,
      requireAuth: true,
    );
    return Grade.fromJson(json['grade'] as Map<String, dynamic>);
  }

  /// `DELETE /grades/:id` — delete a grade (TEACHER only, own grades).
  Future<void> deleteGrade(String id) async {
    await _apiClient.delete(ApiConfig.gradeById(id), requireAuth: true);
  }
}
