import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/attendance.dart';

/// Wraps the attendance endpoints from `src/routes/attendance.routes.ts`.
///
/// Teacher write operations:
///   POST   /attendance          createAttendance
///   PATCH  /attendance/:id      updateAttendance
///   DELETE /attendance/:id      deleteAttendance
///
/// Read operations:
///   GET    /attendance/teacher                  getTeacherAttendance
///   GET    /attendance/student/:studentId       getStudentAttendance
///   GET    /attendance/student/:studentId/summary  getStudentAttendanceSummary
class AttendanceService {
  AttendanceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  // ---- Read endpoints ----

  /// `GET /attendance/student/:studentId`
  /// Access: teacher (own students), student (own), parent (linked), admin.
  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    final json = await _apiClient.get(
      ApiConfig.attendanceByStudent(studentId),
      requireAuth: true,
    );
    final records = json['attendance'] as List<dynamic>;
    return records
        .map((item) => Attendance.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// `GET /attendance/student/:studentId/summary`
  /// Access: same as getStudentAttendance.
  Future<AttendanceSummary> getStudentAttendanceSummary(
      String studentId) async {
    final json = await _apiClient.get(
      ApiConfig.attendanceSummary(studentId),
      requireAuth: true,
    );
    return AttendanceSummary.fromJson(
        json['summary'] as Map<String, dynamic>);
  }

  /// `GET /attendance/teacher`
  /// Access: TEACHER only — returns all attendance records created by the
  /// current teacher.
  Future<List<Attendance>> getTeacherAttendance() async {
    final json = await _apiClient.get(
      ApiConfig.attendanceTeacher,
      requireAuth: true,
    );
    final records = json['attendance'] as List<dynamic>;
    return records
        .map((item) => Attendance.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ---- Write endpoints (TEACHER only) ----

  /// `POST /attendance`
  ///
  /// [date] must be 'YYYY-MM-DD' (the backend validator enforces this regex).
  /// [status] must be one of PRESENT, ABSENT, LATE, EXCUSED.
  Future<Attendance> createAttendance({
    required String studentId,
    required String date, // 'YYYY-MM-DD'
    required AttendanceStatus status,
    String? note,
  }) async {
    final json = await _apiClient.post(
      ApiConfig.attendance,
      body: {
        'studentId': studentId,
        'date': date,
        'status': status.apiValue,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      requireAuth: true,
    );
    return Attendance.fromJson(
        json['attendance'] as Map<String, dynamic>);
  }

  /// `PATCH /attendance/:id`
  ///
  /// Only the status and note can be updated. The student, teacher, and
  /// date are immutable after creation.
  Future<Attendance> updateAttendance(
    String id, {
    AttendanceStatus? status,
    String? note,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.apiValue;
    if (note != null) body['note'] = note.isEmpty ? null : note;

    final json = await _apiClient.patch(
      ApiConfig.attendanceById(id),
      body: body,
      requireAuth: true,
    );
    return Attendance.fromJson(
        json['attendance'] as Map<String, dynamic>);
  }

  /// `DELETE /attendance/:id` — TEACHER only.
  Future<void> deleteAttendance(String id) async {
    await _apiClient.delete(ApiConfig.attendanceById(id), requireAuth: true);
  }
}
