import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/user_role.dart';
import 'admin_service.dart';
import 'teacher_service.dart';

/// Service managing class, section, subject, student class enrollment,
/// and teacher-subject assignment operations.
class SchoolManagementService {
  SchoolManagementService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _classesStorageKey = 'school_classes_persistent_v5';
  static bool _classesInitialized = false;

  static const String _subjectsStorageKey = 'school_subjects_persistent_v5';
  static bool _subjectsInitialized = false;

  // In-memory database store for registered subjects & classes
  static final List<Subject> _mockSubjects = [];
  static final List<SchoolClass> _mockClasses = [];

  static Future<void> _initSubjectsStorage() async {
    if (_subjectsInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_subjectsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _mockSubjects.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final s = Subject.fromJson(item);
            if (s.name.toLowerCase() != 'maths' && s.code != 'MATH101' && s.id != 'subj-001') {
              _mockSubjects.add(s);
            }
          }
        }
      }
    } catch (_) {}
    _mockSubjects.removeWhere((s) => s.name.toLowerCase() == 'maths' || s.code == 'MATH101' || s.id == 'subj-001');
    _subjectsInitialized = true;
  }

  static Future<void> _persistSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_mockSubjects.map((s) => s.toJson()).toList());
      await prefs.setString(_subjectsStorageKey, encoded);
    } catch (_) {}
  }
  static final List<StudentClassInfo> _assignedStudentsStore = [];

  static Future<void> _initClassesStorage() async {
    if (_classesInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_classesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _mockClasses.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final cls = SchoolClass.fromJson(item);
            final cleanStudents = cls.students.where((s) =>
              !s.studentName.toLowerCase().contains('abebe') &&
              !s.studentName.toLowerCase().contains('student grade') &&
              s.studentId != 'SG-2026-000001' &&
              s.studentId != 'SG-2026-000002'
            ).toList();
            _mockClasses.add(cls.copyWith(students: cleanStudents));
          }
        }
      }
    } catch (_) {}
    if (_mockClasses.isEmpty) {
      _ensureInitialClasses();
    } else {
      for (int i = 0; i < _mockClasses.length; i++) {
        final cls = _mockClasses[i];
        final cleanStudents = cls.students.where((s) =>
          !s.studentName.toLowerCase().contains('abebe') &&
          !s.studentName.toLowerCase().contains('student grade') &&
          s.studentId != 'SG-2026-000001' &&
          s.studentId != 'SG-2026-000002'
        ).toList();
        _mockClasses[i] = cls.copyWith(students: cleanStudents);
      }
    }
    _classesInitialized = true;
  }

  static Future<void> _persistClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_mockClasses.map((c) => c.toJson()).toList());
      await prefs.setString(_classesStorageKey, encoded);
    } catch (_) {}
  }

  static void _ensureInitialClasses() {
    if (_mockClasses.isEmpty) {
      _mockClasses.addAll([
        SchoolClass(
          id: 'cls-9-a',
          grade: 9,
          section: 'A',
          academicYear: '2025/2026',
          roomNumber: 'Room 101',
          maxCapacity: 35,
          description: 'Main Grade 9 Section A',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          students: [],
          teachers: [],
        ),
        SchoolClass(
          id: 'cls-9-b',
          grade: 9,
          section: 'B',
          academicYear: '2025/2026',
          roomNumber: 'Room 102',
          maxCapacity: 35,
          description: 'Grade 9 Section B',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          students: [],
          teachers: [],
        ),
        SchoolClass(
          id: 'cls-9-c',
          grade: 9,
          section: 'C',
          academicYear: '2025/2026',
          roomNumber: 'Room 103',
          maxCapacity: 35,
          description: 'Grade 9 Section C',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          students: [],
          teachers: [],
        ),
      ]);
    }
  }

  /// Fetch all registered classes/sections, filtered optionally by grade or search string.
  Future<List<SchoolClass>> getClasses({int? grade, String? query}) async {
    await _initClassesStorage();

    try {
      final res = await _apiClient.get('/admin/school/classes', requireAuth: true);
      final rawList = res['data'] is List ? res['data'] as List : null;
      if (rawList != null) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            final cls = SchoolClass.fromJson(item);
            final idx = _mockClasses.indexWhere((c) => c.id == cls.id || (c.grade == cls.grade && c.section.toUpperCase() == cls.section.toUpperCase()));
            if (idx != -1) {
              _mockClasses[idx] = cls;
            } else {
              _mockClasses.add(cls);
            }
          }
        }
      }
    } catch (_) {}

    List<SchoolClass> results = List.from(_mockClasses);
    if (grade != null) {
      results = results.where((c) => c.grade == grade).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((c) =>
        c.displayName.toLowerCase().contains(q) ||
        (c.roomNumber ?? '').toLowerCase().contains(q) ||
        (c.section ?? '').toLowerCase().contains(q)
      ).toList();
    }

    return List.unmodifiable(results);
  }

  /// Fetch a single class detail by ID.
  Future<SchoolClass> getClassById(String classId) async {
    final classes = await getClasses();
    return classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => throw ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Class not found.'),
    );
  }

  /// Create a new class/section.
  Future<SchoolClass> createClass({
    required int grade,
    required String section,
    String? roomNumber,
    int? maxCapacity,
    String? description,
    String? academicYear,
  }) async {
    await _initClassesStorage();
    final secUpper = section.trim().toUpperCase();
    final year = academicYear?.trim().isNotEmpty == true ? academicYear!.trim() : '2025/2026';

    SchoolClass newClass = SchoolClass(
      id: 'cls-$grade-${secUpper.toLowerCase()}',
      grade: grade,
      section: secUpper,
      academicYear: year,
      roomNumber: roomNumber?.trim().isNotEmpty == true ? roomNumber!.trim() : 'Room 101',
      maxCapacity: maxCapacity ?? 35,
      description: description?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      students: [],
      teachers: [],
    );

    try {
      final res = await _apiClient.post(
        '/admin/school/classes',
        body: {
          'grade': grade,
          'section': secUpper,
        },
        requireAuth: true,
      );

      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;

      if (data['id'] is String) {
        newClass = SchoolClass(
          id: data['id'] as String,
          grade: (data['grade'] as num?)?.toInt() ?? grade,
          section: (data['section'] as String?) ?? secUpper,
          academicYear: year,
          roomNumber: roomNumber?.trim().isNotEmpty == true ? roomNumber!.trim() : 'Room 101',
          maxCapacity: maxCapacity ?? 35,
          description: description?.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          students: [],
          teachers: [],
        );
      }
    } on ApiException {
      rethrow;
    } catch (_) {}

    final existingIdx = _mockClasses.indexWhere((c) => c.id == newClass.id || (c.grade == newClass.grade && c.section == newClass.section));
    if (existingIdx != -1) {
      _mockClasses[existingIdx] = newClass;
    } else {
      _mockClasses.insert(0, newClass);
    }
    await _persistClasses();
    return newClass;
  }

  /// Update details of an existing class/section.
  Future<SchoolClass> updateClass(SchoolClass updated) async {
    final index = _mockClasses.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _mockClasses[index] = updated.copyWith(updatedAt: DateTime.now());
      return _mockClasses[index];
    }
    throw ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Class not found.');
  }

  /// Delete a class/section from the database.
  Future<void> deleteClass(String classId) async {
    await _initClassesStorage();
    _mockClasses.removeWhere((c) => c.id == classId);
    await _persistClasses();

    try {
      if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(classId)) {
        await _apiClient.delete('/admin/school/classes/$classId', requireAuth: true);
      }
    } catch (_) {}
  }

  /// Fetch all available subjects.
  Future<List<Subject>> getSubjects() async {
    await _initSubjectsStorage();

    try {
      final res = await _apiClient.get('/admin/school/subjects', requireAuth: true);
      final rawList = res['data'] is List ? res['data'] as List : null;
      if (rawList != null) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            final dbSubj = Subject.fromJson(item);

            final idx = _mockSubjects.indexWhere(
              (m) => m.id == dbSubj.id || m.name.toLowerCase() == dbSubj.name.toLowerCase(),
            );
            if (idx != -1) {
              final existing = _mockSubjects[idx];
              _mockSubjects[idx] = existing.copyWith(
                id: dbSubj.id,
                name: dbSubj.name,
              );
            } else {
              _mockSubjects.add(dbSubj);
            }
          }
        }
        await _persistSubjects();
      }
    } catch (_) {}

    return List.unmodifiable(_mockSubjects);
  }

  /// Create a new subject.
  Future<Subject> createSubject({
    required String name,
    String? code,
    String? category,
    String? description,
  }) async {
    await _initSubjectsStorage();
    final sName = name.trim();

    final existingIdx = _mockSubjects.indexWhere((s) => s.name.toLowerCase() == sName.toLowerCase());

    Subject newSubject = Subject(
      id: existingIdx != -1 ? _mockSubjects[existingIdx].id : 'subj-${DateTime.now().millisecondsSinceEpoch}',
      name: sName,
      code: code?.trim().isNotEmpty == true ? code!.trim().toUpperCase() : null,
      category: category?.trim().isNotEmpty == true ? category!.trim() : 'General',
      description: description?.trim(),
    );

    try {
      final res = await _apiClient.post(
        '/admin/school/subjects',
        body: {'name': sName},
        requireAuth: true,
      );

      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;

      if (data['id'] is String) {
        newSubject = Subject(
          id: data['id'] as String,
          name: data['name'] as String? ?? sName,
          code: code?.trim().isNotEmpty == true ? code!.trim().toUpperCase() : null,
          category: category?.trim().isNotEmpty == true ? category!.trim() : 'General',
          description: description?.trim(),
        );
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Local state fallback
    }

    if (existingIdx != -1) {
      _mockSubjects[existingIdx] = newSubject;
    } else {
      _mockSubjects.add(newSubject);
    }
    await _persistSubjects();
    return newSubject;
  }

  /// Find assigned class for a student ID or student code.
  Future<SchoolClass?> getStudentClass(String studentId, {String? studentCode}) async {
    final classes = await getClasses();
    for (final cls in classes) {
      if (cls.students.any((s) =>
          s.studentId == studentId ||
          (studentCode != null && studentCode.isNotEmpty && s.studentCode == studentCode))) {
        return cls;
      }
    }
    return null;
  }

  /// Delete a subject from app state and persistence, and sync with TeacherService.
  Future<void> deleteSubject(String subjectId) async {
    await _initSubjectsStorage();
    final targetIndex = _mockSubjects.indexWhere(
      (s) => s.id == subjectId || s.name.toLowerCase() == subjectId.toLowerCase(),
    );

    String targetName = subjectId;
    if (targetIndex != -1) {
      targetName = _mockSubjects[targetIndex].name;
      _mockSubjects.removeAt(targetIndex);
    } else {
      _mockSubjects.removeWhere((s) => s.id == subjectId);
    }

    await _persistSubjects();

    try {
      if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(subjectId)) {
        await _apiClient.delete('/admin/school/subjects/$subjectId', requireAuth: true);
      }
    } catch (_) {}

    // 1. Remove subject from Teacher profiles / My Teaching Subjects
    try {
      await TeacherService().removeAssignedSubject(targetName);
    } catch (_) {}

    // 2. Remove subject assignment from all classes
    await _initClassesStorage();
    for (int i = 0; i < _mockClasses.length; i++) {
      final cls = _mockClasses[i];
      final updatedTeachers = cls.teachers.where((t) =>
        t.subjectId != subjectId && t.subjectName.toLowerCase() != targetName.toLowerCase()
      ).toList();
      if (updatedTeachers.length != cls.teachers.length) {
        _mockClasses[i] = cls.copyWith(teachers: updatedTeachers, updatedAt: DateTime.now());
      }
    }
    await _persistClasses();
  }

  /// Assign/enroll a student into a class & section.
  Future<StudentClassInfo> assignStudentToClass({
    required String studentId,
    required String classId,
    required String studentName,
    String? studentCode,
    String? academicYear,
  }) async {
    final classIndex = _mockClasses.indexWhere((c) => c.id == classId);
    if (classIndex == -1) {
      throw ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Class not found.');
    }

    final realStudentCode = (studentCode != null && studentCode.trim().isNotEmpty)
        ? studentCode.trim()
        : ((studentId.startsWith('SG-') || studentId.startsWith('STU-'))
            ? studentId
            : 'SG-${DateTime.now().year}-${studentId.hashCode.abs().toString().padLeft(6, '0')}');

    final targetClass = _mockClasses[classIndex];
    if (targetClass.students.any((s) => s.studentId == realStudentCode || s.studentId == studentId || s.studentCode == realStudentCode)) {
      throw ApiException(
        statusCode: 400,
        code: 'ALREADY_ASSIGNED',
        message: '$studentName is already enrolled in ${targetClass.displayName}.',
      );
    }

    StudentClassInfo newEnrollment = StudentClassInfo(
      id: 'sc-${DateTime.now().millisecondsSinceEpoch}',
      studentId: realStudentCode,
      studentName: studentName,
      studentCode: realStudentCode,
      classId: classId,
      academicYear: academicYear ?? targetClass.academicYear,
      enrolledAt: DateTime.now(),
    );

    try {
      final res = await _apiClient.post(
        '/admin/school/assign-student',
        body: {
          'studentId': studentId,
          'classId': classId,
          if (academicYear != null) 'academicYear': academicYear,
        },
        requireAuth: true,
      );

      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      if (data is Map<String, dynamic>) {
        newEnrollment = StudentClassInfo.fromJson(data);
      }
    } catch (_) {
      // Local fallback
    }

    _assignedStudentsStore.add(newEnrollment);
    final updatedStudents = List<StudentClassInfo>.from(targetClass.students)..add(newEnrollment);
    _mockClasses[classIndex] = targetClass.copyWith(
      students: updatedStudents,
      updatedAt: DateTime.now(),
    );

    await _persistClasses();
    return newEnrollment;
  }

  /// Remove a student enrollment from a class.
  Future<void> removeStudentFromClass({
    required String classId,
    required String enrollmentId,
  }) async {
    final classIndex = _mockClasses.indexWhere((c) => c.id == classId);
    if (classIndex != -1) {
      final targetClass = _mockClasses[classIndex];
      final updatedStudents = targetClass.students.where((s) => s.id != enrollmentId).toList();
      _mockClasses[classIndex] = targetClass.copyWith(
        students: updatedStudents,
        updatedAt: DateTime.now(),
      );
      await _persistClasses();
    }

    try {
      if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(enrollmentId)) {
        await _apiClient.delete('/admin/school/assign-student/$enrollmentId', requireAuth: true);
      }
    } catch (_) {}
  }

  /// Assign a teacher and subject to a class.
  Future<TeacherSubjectInfo> assignTeacherToClass({
    required String teacherId,
    required String teacherName,
    required String classId,
    required String subjectId,
    required String subjectName,
    String? academicYear,
  }) async {
    final classIndex = _mockClasses.indexWhere((c) => c.id == classId);
    if (classIndex == -1) {
      throw ApiException(statusCode: 404, code: 'NOT_FOUND', message: 'Class not found.');
    }

    final targetClass = _mockClasses[classIndex];
    final alreadyAssigned = targetClass.teachers.any(
      (t) => t.teacherId == teacherId && t.subjectId == subjectId,
    );

    if (alreadyAssigned) {
      throw ApiException(
        statusCode: 400,
        code: 'ALREADY_ASSIGNED',
        message: '$teacherName is already assigned to teach $subjectName in ${targetClass.displayName}.',
      );
    }

    TeacherSubjectInfo newAssignment = TeacherSubjectInfo(
      id: 'tc-${DateTime.now().millisecondsSinceEpoch}',
      teacherId: teacherId,
      teacherName: teacherName,
      subjectId: subjectId,
      subjectName: subjectName,
      classId: classId,
      academicYear: academicYear ?? targetClass.academicYear,
      assignedAt: DateTime.now(),
    );

    try {
      String realClassId = classId;
      String realSubjectId = subjectId;
      String realTeacherId = teacherId;

      try {
        final cRes = await createClass(grade: targetClass.grade, section: targetClass.section);
        if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(cRes.id)) {
          realClassId = cRes.id;
        }
      } catch (_) {}

      try {
        final sRes = await createSubject(name: subjectName);
        if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(sRes.id)) {
          realSubjectId = sRes.id;
        }
      } catch (_) {}

      if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(realTeacherId)) {
        try {
          final activeTeachers = await AdminService().getActive(UserRole.teacher);
          if (activeTeachers.isNotEmpty) {
            final match = activeTeachers.firstWhere(
              (t) => t.fullName.toLowerCase() == teacherName.toLowerCase() || t.id == teacherId,
              orElse: () => activeTeachers.first,
            );
            realTeacherId = match.id;
          }
        } catch (_) {}
      }

      if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(realClassId) &&
          RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(realSubjectId) &&
          RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(realTeacherId)) {
        final res = await _apiClient.post(
          '/admin/school/assign-teacher',
          body: {
            'teacherId': realTeacherId,
            'classId': realClassId,
            'subjectId': realSubjectId,
            if (academicYear != null) 'academicYear': academicYear,
          },
          requireAuth: true,
        );

        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        if (data is Map<String, dynamic>) {
          newAssignment = TeacherSubjectInfo.fromJson(data);
        }
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Local fallback
    }

    final updatedTeachers = List<TeacherSubjectInfo>.from(targetClass.teachers)..add(newAssignment);
    _mockClasses[classIndex] = targetClass.copyWith(
      teachers: updatedTeachers,
      updatedAt: DateTime.now(),
    );

    await _persistClasses();

    try {
      final ts = TeacherService();
      await ts.addAssignedSubject(subjectName);
      await ts.addAssignedClass(targetClass.displayName);
      await ts.addAssignedClass(targetClass.shortLabel);
    } catch (_) {}

    return newAssignment;
  }

  /// Remove a teacher & subject assignment from a class.
  Future<void> removeTeacherFromClass({
    required String classId,
    required String assignmentId,
  }) async {
    final classIndex = _mockClasses.indexWhere((c) => c.id == classId);
    if (classIndex != -1) {
      final targetClass = _mockClasses[classIndex];
      final updatedTeachers = targetClass.teachers.where((t) => t.id != assignmentId).toList();
      _mockClasses[classIndex] = targetClass.copyWith(
        teachers: updatedTeachers,
        updatedAt: DateTime.now(),
      );
      await _persistClasses();
    }

    try {
      if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(assignmentId)) {
        await _apiClient.delete('/admin/school/assign-teacher/$assignmentId', requireAuth: true);
      }
    } catch (_) {}
  }
}
