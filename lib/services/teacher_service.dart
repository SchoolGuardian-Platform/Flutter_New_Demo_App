import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/grade_entry.dart';
import '../models/teacher_profile.dart';
import '../models/user_role.dart';
import 'admin_service.dart';
import 'auth_service.dart';
import 'course_service.dart';
import 'school_management_service.dart';

class TeacherService {
  factory TeacherService() => _instance;
  TeacherService._internal() {
    _initStorage();
  }
  static final TeacherService _instance = TeacherService._internal();

  static const String _storageKey = 'teacher_grade_entries_persistent_v2';
  static const String _subjectsStorageKey = 'teacher_assigned_subjects_v4';
  static const String _classesStorageKey = 'teacher_assigned_classes_v4';

  TeacherProfile _profile = TeacherProfile.sample();
  final List<GradeEntry> _entries = [];
  bool _initialized = false;

  Future<void> _initStorage() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        _entries.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _entries.add(GradeEntry.fromJson(item));
          }
        }
      }

      final savedSubs = prefs.getStringList(_subjectsStorageKey);
      if (savedSubs != null && savedSubs.isNotEmpty) {
        final existing = List<String>.from(_profile.assignedSubjects);
        for (final s in savedSubs) {
          final clean = s.trim();
          if (clean.isNotEmpty && !existing.contains(clean)) {
            existing.add(clean);
          }
        }
        _profile = TeacherProfile(
          id: _profile.id,
          fullName: _profile.fullName,
          email: _profile.email,
          majorField: _profile.majorField,
          department: _profile.department,
          employeeId: _profile.employeeId,
          assignedClasses: _profile.assignedClasses,
          assignedSubjects: existing,
        );
      }

      final savedCls = prefs.getStringList(_classesStorageKey);
      if (savedCls != null && savedCls.isNotEmpty) {
        final existing = List<String>.from(_profile.assignedClasses);
        for (final c in savedCls) {
          if (c.trim().isNotEmpty && !existing.contains(c.trim())) {
            existing.add(c.trim());
          }
        }
        _profile = TeacherProfile(
          id: _profile.id,
          fullName: _profile.fullName,
          email: _profile.email,
          majorField: _profile.majorField,
          department: _profile.department,
          employeeId: _profile.employeeId,
          assignedClasses: existing,
          assignedSubjects: _profile.assignedSubjects,
        );
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _persistToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      await prefs.setStringList(_subjectsStorageKey, _profile.assignedSubjects);
      await prefs.setStringList(_classesStorageKey, _profile.assignedClasses);
    } catch (_) {}
  }

  Future<String?> _resolveStudentUuid(String queryIdOrName) async {
    final clean = queryIdOrName.trim();
    if (clean.isEmpty) return null;

    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(clean)) {
      return clean;
    }

    try {
      final activeStudents = await AdminService().getActive(UserRole.student);
      for (final s in activeStudents) {
        if (s.id.toLowerCase() == clean.toLowerCase() ||
            (s.studentId != null && s.studentId!.toLowerCase() == clean.toLowerCase()) ||
            '${s.firstName} ${s.lastName}'.toLowerCase() == clean.toLowerCase()) {
          return s.id;
        }
      }
    } catch (_) {}

    try {
      final classes = await SchoolManagementService().getClasses();
      for (final c in classes) {
        for (final st in c.students) {
          if (st.studentId.toLowerCase() == clean.toLowerCase() ||
              (st.studentCode != null && st.studentCode!.toLowerCase() == clean.toLowerCase()) ||
              st.studentName.toLowerCase() == clean.toLowerCase()) {
            if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(st.studentId)) {
              return st.studentId;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<TeacherProfile> getTeacherProfile() async {
    await _initStorage();
    try {
      final me = await AuthService().getMe();
      if (me.role == UserRole.teacher) {
        final classes = await SchoolManagementService().getClasses();
        final teacherClasses = <String>[];
        final adminSubjects = <String>[];

        for (final sc in classes) {
          final isAssigned = sc.teachers.any((t) =>
            t.teacherId == me.id || t.teacherName.toLowerCase() == '${me.firstName} ${me.lastName}'.toLowerCase()
          );
          if (isAssigned) {
            teacherClasses.add(sc.displayName);
            for (final t in sc.teachers) {
              if ((t.teacherId == me.id || t.teacherName.toLowerCase() == '${me.firstName} ${me.lastName}'.toLowerCase()) && t.subjectName.isNotEmpty) {
                adminSubjects.add(t.subjectName);
              }
            }
          }
        }

        final dbGrades = await getGradeEntries();
        final gradeSubjects = dbGrades.map((g) => g.subject.trim()).where((s) => s.isNotEmpty).toList();

        final mergedClasses = <String>{..._profile.assignedClasses, ...teacherClasses}.toList();
        final mergedSubjects = <String>{..._profile.assignedSubjects, ...adminSubjects, ...gradeSubjects}
            .where((s) => s.trim().isNotEmpty)
            .toList();

        _profile = TeacherProfile(
          id: me.id,
          fullName: '${me.firstName} ${me.lastName}',
          email: me.email,
          majorField: _profile.majorField.isNotEmpty ? _profile.majorField : 'Educational Pedagogy',
          department: 'Academic Faculty',
          employeeId: me.studentId ?? 'TEA-${me.id.length >= 6 ? me.id.substring(0, 6) : me.id}',
          assignedClasses: mergedClasses,
          assignedSubjects: mergedSubjects,
        );
        await _persistToDisk();
      }
    } catch (_) {}
    return _profile;
  }

  Future<void> updateMajorField(String newMajorField) async {
    _profile = TeacherProfile(
      id: _profile.id,
      fullName: _profile.fullName,
      email: _profile.email,
      majorField: newMajorField,
      department: _profile.department,
      employeeId: _profile.employeeId,
      assignedClasses: _profile.assignedClasses,
      assignedSubjects: _profile.assignedSubjects,
    );
  }

  Future<void> addAssignedSubject(String subject) async {
    final clean = subject.trim();
    if (clean.isEmpty) return;
    try {
      await SchoolManagementService().createSubject(name: clean);
    } catch (_) {}
    if (!_profile.assignedSubjects.contains(clean)) {
      final updatedList = List<String>.from(_profile.assignedSubjects)..add(clean);
      _profile = TeacherProfile(
        id: _profile.id,
        fullName: _profile.fullName,
        email: _profile.email,
        majorField: _profile.majorField,
        department: _profile.department,
        employeeId: _profile.employeeId,
        assignedClasses: _profile.assignedClasses,
        assignedSubjects: updatedList,
      );
      await _persistToDisk();
    }
  }

  Future<void> addAssignedClass(String className) async {
    final clean = className.trim();
    if (clean.isEmpty) return;
    if (!_profile.assignedClasses.contains(clean)) {
      final updatedList = List<String>.from(_profile.assignedClasses)..add(clean);
      _profile = TeacherProfile(
        id: _profile.id,
        fullName: _profile.fullName,
        email: _profile.email,
        majorField: _profile.majorField,
        department: _profile.department,
        employeeId: _profile.employeeId,
        assignedClasses: updatedList,
        assignedSubjects: _profile.assignedSubjects,
      );
      await _persistToDisk();
    }
  }

  Future<void> removeAssignedSubject(String subject) async {
    final clean = subject.trim().toLowerCase();
    final updatedList = List<String>.from(_profile.assignedSubjects)
      ..removeWhere((s) => s.trim().toLowerCase() == clean);
    _profile = TeacherProfile(
      id: _profile.id,
      fullName: _profile.fullName,
      email: _profile.email,
      majorField: _profile.majorField,
      department: _profile.department,
      employeeId: _profile.employeeId,
      assignedClasses: _profile.assignedClasses,
      assignedSubjects: updatedList,
    );
    await _persistToDisk();
  }

  Future<List<GradeEntry>> getGradeEntries() async {
    await _initStorage();
    try {
      final token = await TokenStorage().readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/grades/teacher');
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(ApiConfig.requestTimeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] is List ? body['data'] : (body is List ? body : []);
          final fetched = <GradeEntry>[];
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final studentInfo = item['student'] as Map<String, dynamic>?;
              final studentName = studentInfo != null
                  ? '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}'.trim()
                  : (item['studentId'] as String? ?? 'Student');

              final assessmentStr = item['assessmentType'] as String? ?? 'ASSIGNMENT';
              final assessmentEnum = AssessmentTypeX.fromString(assessmentStr == 'OTHER' ? 'COMPOSITE' : assessmentStr);
              final comment = item['comment'] as String?;

              fetched.add(GradeEntry(
                id: item['id'] as String? ?? 'ge-${DateTime.now().millisecondsSinceEpoch}',
                studentId: item['studentId'] as String? ?? '',
                studentName: studentName.isNotEmpty ? studentName : 'Student',
                subject: item['subject'] as String? ?? 'General',
                assessmentType: assessmentEnum,
                score: (item['score'] as num?)?.toDouble() ?? 0.0,
                maxScore: (item['maxScore'] as num?)?.toDouble() ?? 100.0,
                term: item['term'] as String? ?? item['academicYear'] as String? ?? '2025/2026',
                components: const [],
                parentRecommendation: comment,
                createdAt: item['createdAt'] != null ? DateTime.parse(item['createdAt'] as String) : DateTime.now(),
              ));
            }
          }

          if (fetched.isNotEmpty) {
            for (final f in fetched) {
              final idx = _entries.indexWhere((e) => e.id == f.id);
              if (idx != -1) {
                _entries[idx] = f;
              } else {
                _entries.add(f);
              }
            }
            await _persistToDisk();
          }
        }
      }
    } catch (_) {}

    return List.unmodifiable(_entries);
  }

  Future<List<GradeEntry>> getGradesForStudent(String studentId) async {
    await _initStorage();
    if (studentId.trim().isEmpty) return [];

    try {
      final token = await TokenStorage().readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/grades/student/$studentId');
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(ApiConfig.requestTimeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] is List ? body['data'] : (body is List ? body : []);
          final fetched = <GradeEntry>[];
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final studentInfo = item['student'] as Map<String, dynamic>?;
              final studentName = studentInfo != null
                  ? '${studentInfo['firstName'] ?? ''} ${studentInfo['lastName'] ?? ''}'.trim()
                  : (item['studentId'] as String? ?? 'Student');

              final assessmentStr = item['assessmentType'] as String? ?? 'ASSIGNMENT';
              final assessmentEnum = AssessmentTypeX.fromString(assessmentStr == 'OTHER' ? 'COMPOSITE' : assessmentStr);
              final comment = item['comment'] as String?;

              fetched.add(GradeEntry(
                id: item['id'] as String? ?? 'ge-${DateTime.now().millisecondsSinceEpoch}',
                studentId: item['studentId'] as String? ?? studentId,
                studentName: studentName.isNotEmpty ? studentName : 'Student',
                subject: item['subject'] as String? ?? 'General',
                assessmentType: assessmentEnum,
                score: (item['score'] as num?)?.toDouble() ?? 0.0,
                maxScore: (item['maxScore'] as num?)?.toDouble() ?? 100.0,
                term: item['term'] as String? ?? item['academicYear'] as String? ?? '2025/2026',
                components: const [],
                parentRecommendation: comment,
                createdAt: item['createdAt'] != null ? DateTime.parse(item['createdAt'] as String) : DateTime.now(),
              ));
            }
          }
          if (fetched.isNotEmpty) return fetched;
        }
      }
    } catch (_) {}

    final all = await getGradeEntries();
    return all
        .where((e) =>
            e.studentId.trim().toLowerCase() == studentId.trim().toLowerCase() ||
            studentId.trim().isEmpty)
        .toList();
  }

  Future<GradeEntry> addGradeEntry({
    required String studentId,
    required String studentName,
    required String subject,
    required AssessmentType assessmentType,
    required double score,
    required double maxScore,
    required String term,
    List<AssessmentComponent> components = const [],
    double? attendanceScore,
    double? midtermScore,
    double? assignmentScore,
    double? finalScore,
    String? parentRecommendation,
  }) async {
    await _initStorage();
    final realStudentUuid = await _resolveStudentUuid(studentId) ?? studentId;

    GradeEntry entry = GradeEntry(
      id: 'ge-${DateTime.now().millisecondsSinceEpoch}',
      studentId: realStudentUuid,
      studentName: studentName.isNotEmpty ? studentName : 'Student $studentId',
      subject: subject,
      assessmentType: assessmentType,
      score: score,
      maxScore: maxScore,
      term: term,
      components: components,
      attendanceScore: attendanceScore,
      midtermScore: midtermScore,
      assignmentScore: assignmentScore,
      finalScore: finalScore,
      parentRecommendation: parentRecommendation,
      createdAt: DateTime.now(),
    );

    try {
      final token = await TokenStorage().readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/grades');
        final apiType = (assessmentType == AssessmentType.composite)
            ? 'OTHER'
            : assessmentType.apiValue;

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'studentId': realStudentUuid,
            'subject': subject,
            'assessmentType': apiType,
            'score': score,
            'maxScore': maxScore,
            'term': term,
            'academicYear': '2025/2026',
            if (parentRecommendation != null && parentRecommendation.isNotEmpty)
              'comment': parentRecommendation,
          }),
        ).timeout(ApiConfig.requestTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = jsonDecode(response.body);
          if (body['data'] is Map<String, dynamic>) {
            final data = body['data'] as Map<String, dynamic>;
            entry = GradeEntry(
              id: data['id'] as String? ?? entry.id,
              studentId: data['studentId'] as String? ?? realStudentUuid,
              studentName: entry.studentName,
              subject: data['subject'] as String? ?? subject,
              assessmentType: entry.assessmentType,
              score: (data['score'] as num?)?.toDouble() ?? score,
              maxScore: (data['maxScore'] as num?)?.toDouble() ?? maxScore,
              term: data['term'] as String? ?? term,
              components: components,
              attendanceScore: attendanceScore,
              midtermScore: midtermScore,
              assignmentScore: assignmentScore,
              finalScore: finalScore,
              parentRecommendation: parentRecommendation,
              createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : DateTime.now(),
            );
          }
        } else {
          Map<String, dynamic>? decoded;
          try {
            decoded = jsonDecode(response.body) as Map<String, dynamic>;
          } catch (_) {}
          final errorMsg = decoded?['error']?['message'] ?? decoded?['message'] ?? 'Failed to record grade in database';
          throw ApiException(
            statusCode: response.statusCode,
            code: decoded?['error']?['code'] ?? 'GRADE_CREATE_ERROR',
            message: errorMsg,
          );
        }
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Local fallback
    }

    _entries.removeWhere((e) => e.id == entry.id);
    _entries.insert(0, entry);
    await _persistToDisk();
    await CourseService().attachGradeToRegistration(realStudentUuid, subject, entry);
    return entry;
  }

  Future<GradeEntry> updateGradeEntry(GradeEntry updatedEntry) async {
    await _initStorage();

    final token = await TokenStorage().readAccessToken();
    if (token != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(updatedEntry.id)) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grades/${updatedEntry.id}');
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subject': updatedEntry.subject,
          'assessmentType': updatedEntry.assessmentType == AssessmentType.composite
              ? 'OTHER'
              : updatedEntry.assessmentType.apiValue,
          'score': updatedEntry.score,
          'maxScore': updatedEntry.maxScore,
          'term': updatedEntry.term,
          'academicYear': '2025/2026',
          if (updatedEntry.parentRecommendation != null)
            'comment': updatedEntry.parentRecommendation,
        }),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        Map<String, dynamic>? decoded;
        try {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        final errorMsg = decoded?['error']?['message'] ?? decoded?['message'] ?? 'Failed to update grade in database';
        throw ApiException(
          statusCode: response.statusCode,
          code: decoded?['error']?['code'] ?? 'GRADE_UPDATE_ERROR',
          message: errorMsg,
        );
      }
    }

    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;
    } else {
      _entries.insert(0, updatedEntry);
    }
    await _persistToDisk();
    await CourseService().attachGradeToRegistration(
        updatedEntry.studentId, updatedEntry.subject, updatedEntry);
    return updatedEntry;
  }

  Future<void> deleteGradeEntry(String id) async {
    await _initStorage();

    final token = await TokenStorage().readAccessToken();
    if (token != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grades/$id');
      final response = await http.delete(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        Map<String, dynamic>? decoded;
        try {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        final errorMsg = decoded?['error']?['message'] ?? decoded?['message'] ?? 'Failed to delete grade from database';
        throw ApiException(
          statusCode: response.statusCode,
          code: decoded?['error']?['code'] ?? 'GRADE_DELETE_ERROR',
          message: errorMsg,
        );
      }
    }

    _entries.removeWhere((e) => e.id == id);
    await _persistToDisk();
  }
}
