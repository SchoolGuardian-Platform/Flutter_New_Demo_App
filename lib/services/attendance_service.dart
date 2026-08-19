import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/attendance_record.dart';
import '../models/user_role.dart';
import 'admin_service.dart';

class AttendanceService {
  factory AttendanceService() => _instance;
  AttendanceService._internal();
  static final AttendanceService _instance = AttendanceService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _storageKey = 'attendance_records_cache_v1';
  final List<AttendanceRecord> _localCache = [];
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
            _localCache.add(AttendanceRecord.fromJson(item));
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

  Future<AttendanceRecord> markAttendance({
    required String studentId,
    required String date, // YYYY-MM-DD
    required AttendanceStatus status,
    String? note,
    String? studentName,
  }) async {
    await _initCache();
    AttendanceRecord record;

    String realStudentUuid = studentId;
    if (!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(studentId)) {
      try {
        final activeStudents = await AdminService().getActive(UserRole.student);
        for (final s in activeStudents) {
          if (s.id.toLowerCase() == studentId.toLowerCase() ||
              (s.studentId != null && s.studentId!.toLowerCase() == studentId.toLowerCase()) ||
              '${s.firstName} ${s.lastName}'.toLowerCase() == (studentName ?? '').toLowerCase()) {
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
        'status': status.toDbString(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final res = await _apiClient.post('/attendance', body: payload, requireAuth: true);
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      record = AttendanceRecord.fromJson(data);
    } catch (_) {
      record = AttendanceRecord(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        studentId: realStudentUuid,
        studentName: studentName ?? 'Student',
        date: date,
        status: status,
        note: note,
      );
    }

    _localCache.removeWhere((r) => r.studentId == realStudentUuid && r.date == date);
    _localCache.insert(0, record);
    await _persistCache();
    return record;
  }

  Future<List<AttendanceRecord>> getTeacherAttendance() async {
    await _initCache();
    try {
      final res = await _apiClient.get('/attendance/teacher', requireAuth: true);
      final List<dynamic>? rawList = res['data'] is List ? (res['data'] as List<dynamic>) : null;
      if (rawList != null) {
        final fetched = <AttendanceRecord>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            fetched.add(AttendanceRecord.fromJson(item));
          }
        }
        _localCache.clear();
        _localCache.addAll(fetched);
        await _persistCache();
        return List.unmodifiable(_localCache);
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  Future<List<AttendanceRecord>> getStudentAttendance(String studentId) async {
    await _initCache();
    try {
      final res = await _apiClient.get('/attendance/student/$studentId', requireAuth: true);
      final rawList = res['data'] is List
          ? res['data'] as List
          : (res is List ? res as List : null);
      if (rawList != null) {
        final list = <AttendanceRecord>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            list.add(AttendanceRecord.fromJson(item));
          }
        }
        return list;
      }
    } catch (_) {}
    return _localCache.where((r) => r.studentId == studentId).toList();
  }

  Future<void> deleteAttendance(String id) async {
    await _initCache();
    try {
      await _apiClient.delete('/attendance/$id', requireAuth: true);
    } catch (_) {}
    _localCache.removeWhere((r) => r.id == id);
    await _persistCache();
  }
}
