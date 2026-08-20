import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/homework.dart';

/// Wraps the homework endpoints from `src/routes/homework.routes.ts`.
///
/// Teacher-only write operations:
///   POST   /homework           createHomework
///   PATCH  /homework/:id       updateHomework
///   DELETE /homework/:id       deleteHomework
///
/// Read operations:
///   GET    /homework/teacher                   getHomeworkByTeacher
///   GET    /homework/student/:studentId        getHomeworkByStudent
///   GET    /homework/class/:classId            getHomeworkByClass
class HomeworkService {
  HomeworkService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// `GET /homework/teacher` — all homework posted by the current teacher.
  Future<List<Homework>> getHomeworkByTeacher() async {
    final json = await _apiClient.get(
      ApiConfig.homeworkByTeacher,
      requireAuth: true,
    );
    final list = json['homeworks'] as List<dynamic>;
    return list
        .map((item) => Homework.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `GET /homework/student/:studentId` — homework for a specific student.
  Future<List<Homework>> getHomeworkByStudent(String studentId) async {
    final json = await _apiClient.get(
      ApiConfig.homeworkByStudent(studentId),
      requireAuth: true,
    );
    final list = json['homeworks'] as List<dynamic>;
    return list
        .map((item) => Homework.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `POST /homework` — create a new homework assignment (TEACHER only).
  ///
  /// [classId] must be a valid UUID for a class the teacher is assigned to.
  Future<Homework> createHomework({
    required String classId,
    required String subject,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    final json = await _apiClient.post(
      ApiConfig.homework,
      body: {
        'classId': classId,
        'subject': subject,
        'title': title,
        'description': description,
        // Backend validator accepts string or Date, transforms to Date.
        'dueDate': dueDate.toIso8601String(),
      },
      requireAuth: true,
    );
    return Homework.fromJson(json['homework'] as Map<String, dynamic>);
  }

  /// `PATCH /homework/:id` — update an existing homework (TEACHER only, own).
  Future<Homework> updateHomework(
    String id, {
    String? subject,
    String? title,
    String? description,
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{};
    if (subject != null) body['subject'] = subject;
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

    final json = await _apiClient.patch(
      ApiConfig.homeworkById(id),
      body: body,
      requireAuth: true,
    );
    return Homework.fromJson(json['homework'] as Map<String, dynamic>);
  }

  /// `DELETE /homework/:id` — delete a homework record (TEACHER only, own).
  Future<void> deleteHomework(String id) async {
    await _apiClient.delete(ApiConfig.homeworkById(id), requireAuth: true);
  }
}
