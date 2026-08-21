import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/attendance.dart';
import '../models/user_role.dart';
import 'admin_service.dart';

/// Wraps the attendance endpoints from `src/routes/attendance.routes.ts`
/// with local SharedPreferences caching support for offline resilience.
class AttendanceService {
  factory AttendanceService({ApiClient? apiClient}) {
    if (apiClient != null) {
      _instance._apiClient = apiClient;
    }
    return _instance;
  }

  AttendanceService._internal() : _apiClient = ApiClient();
  static final AttendanceService _instance = AttendanceService._internal();

  ApiClient _apiClient;
  static const String _storageKey = 'attendance_records_cache_v1';
  final List<Attendance> _localCache = [];
  bool _initialized = false;

  Future<void> _initCache() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        _localCache.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _localCache.add(Attendance.fromJson(item));
          }
        }
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_localCache.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  // ---- Read endpoints ----

  /// `GET /attendance/student/:studentId`
  /// Access: teacher (own students), student (own), parent (linked), admin.
  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    await _initCache();
    try {
      final json = await _apiClient.get(
        ApiConfig.attendanceByStudent(studentId),
        requireAuth: true,
      );
      final rawList = json['attendance'] is List
          ? json['attendance'] as List<dynamic>
          : (json['data'] is List ? json['data'] as List<dynamic> : null);

      if (rawList != null) {
        final records = rawList
            .map((item) => Attendance.fromJson(item as Map<String, dynamic>))
            .toList();
        return records;
      }
    } catch (_) {}
    return _localCache.where((r) => r.studentId == studentId).toList();
  }

  /// `GET /attendance/student/:studentId/summary`
  /// Access: same as getStudentAttendance.
  Future<AttendanceSummary> getStudentAttendanceSummary(
      String studentId) async {
    final json = await _apiClient.get(
      ApiConfig.attendanceSummary(studentId),
      requireAuth: true,
    );
    final summaryData = (json['summary'] ?? json['data'] ?? json) as Map<String, dynamic>;
    return AttendanceSummary.fromJson(summaryData);
  }

  /// `GET /attendance/teacher`
  /// Access: TEACHER only — returns all attendance records created by the current teacher.
  Future<List<Attendance>> getTeacherAttendance() async {
    await _initCache();
    try {
      final json = await _apiClient.get(
        ApiConfig.attendanceTeacher,
        requireAuth: true,
      );
      final rawList = json['attendance'] is List
          ? json['attendance'] as List<dynamic>
          : (json['data'] is List ? json['data'] as List<dynamic> : null);

      if (rawList != null) {
        final fetched = rawList
            .map((item) => Attendance.fromJson(item as Map<String, dynamic>))
            .toList();
        _localCache.clear();
        _localCache.addAll(fetched);
        await _persistCache();
        return List.unmodifiable(_localCache);
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  // ---- Write endpoints (TEACHER only) ----

  /// `POST /attendance`
  ///
  /// [date] must be 'YYYY-MM-DD'.
  /// Resolves display ID/custom string to student UUID if necessary.
  Future<Attendance> markAttendance({
    required String studentId,
    required String date, // 'YYYY-MM-DD'
    required AttendanceStatus status,
    String? note,
    String? studentName,
  }) async {
    await _initCache();
    Attendance record;

    String realStudentUuid = studentId;
    if (!RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(studentId)) {
      try {
        final activeStudents = await AdminService().getActive(UserRole.student);
        for (final s in activeStudents) {
          if (s.id.toLowerCase() == studentId.toLowerCase() ||
              (s.studentId != null &&
                  s.studentId!.toLowerCase() == studentId.toLowerCase()) ||
              '${s.firstName} ${s.lastName}'.toLowerCase() ==
                  (studentName ?? '').toLowerCase()) {
            realStudentUuid = s.id;
            break;
          }
        }
      } catch (_) {}
    }

    try {
      final payload = {
        'studentId': realStudentUuid,
        'date': date,
        'status': status.apiValue,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final res = await _apiClient.post(
        ApiConfig.attendance,
        body: payload,
        requireAuth: true,
      );
      final data = res['attendance'] is Map<String, dynamic>
          ? res['attendance'] as Map<String, dynamic>
          : (res['data'] is Map<String, dynamic>
              ? res['data'] as Map<String, dynamic>
              : res);
      record = Attendance.fromJson(data);
    } catch (_) {
      record = Attendance(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        studentId: realStudentUuid,
        studentName: studentName ?? 'Student',
        date: date,
        status: status,
        note: note,
      );
    }

    _localCache.removeWhere(
        (r) => r.studentId == realStudentUuid && r.date == date);
    _localCache.insert(0, record);
    await _persistCache();
    return record;
  }

  /// Alias for [markAttendance] for backward compatibility.
  Future<Attendance> createAttendance({
    required String studentId,
    required String date,
    required AttendanceStatus status,
    String? note,
  }) =>
      markAttendance(
        studentId: studentId,
        date: date,
        status: status,
        note: note,
      );

  /// `PATCH /attendance/:id`
  ///
  /// Only the status and note can be updated.
  Future<Attendance> updateAttendance(
    String id, {
    AttendanceStatus? status,
    String? note,
  }) async {
    await _initCache();
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.apiValue;
    if (note != null) body['note'] = note.isEmpty ? null : note;

    final json = await _apiClient.patch(
      ApiConfig.attendanceById(id),
      body: body,
      requireAuth: true,
    );
    final data = json['attendance'] is Map<String, dynamic>
        ? json['attendance'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json);
    final updated = Attendance.fromJson(data);

    final idx = _localCache.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _localCache[idx] = updated;
      await _persistCache();
    }
    return updated;
  }

  /// `DELETE /attendance/:id` — TEACHER only.
  Future<void> deleteAttendance(String id) async {
    await _initCache();
    try {
      await _apiClient.delete(ApiConfig.attendanceById(id), requireAuth: true);
    } catch (_) {}
    _localCache.removeWhere((r) => r.id == id);
    await _persistCache();
  }
}