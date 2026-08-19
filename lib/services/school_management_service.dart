import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/user_role.dart';
import 'admin_service.dart';
import 'teacher_service.dart';

/// Service managing class, section, subject, student class enrollment,
/// and teacher-subject assignment operations.
class SchoolManagementService {
  SchoolManagementService({http.Client? httpClient, TokenStorage? tokenStorage})
      : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  static const String _classesStorageKey = 'school_classes_persistent_v1';
  static bool _classesInitialized = false;

  // In-memory database store for registered subjects & classes
  static final List<Subject> _mockSubjects = [
    Subject(id: 'subj-001', name: 'Maths'),
  ];
  static final List<SchoolClass> _mockClasses = [];
  static final List<StudentClassInfo> _assignedStudentsStore = [
    StudentClassInfo(
      id: 'sc-default-1',
      studentId: 'SG-2026-000001',
      studentName: 'Student Grade 9A',
      studentCode: 'SG-2026-000001',
      classId: 'cls-9-a',
      academicYear: '2026',
      enrolledAt: DateTime.now(),
    ),
    StudentClassInfo(
      id: 'sc-default-2',
      studentId: 'SG-2026-000002',
      studentName: 'Abebe Kebede (Sec B)',
      studentCode: 'SG-2026-000002',
      classId: 'cls-9-b',
      academicYear: '2026',
      enrolledAt: DateTime.now(),
    ),
  ];

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
            _mockClasses.add(SchoolClass.fromJson(item));
          }
        }
      }
    } catch (_) {}
    if (_mockClasses.isEmpty) {
      _ensureInitialClasses();
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
          students: List<StudentClassInfo>.from(_assignedStudentsStore.where((s) => s.classId == 'cls-9-a')),
          teachers: [
            TeacherSubjectInfo(
              id: 'tsi-1',
              teacherId: 'tch-001',
              teacherName: 'Teacher Account',
              subjectId: 'subj-001',
              subjectName: 'Maths',
              classId: 'cls-9-a',
            ),
          ],
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
          students: List<StudentClassInfo>.from(_assignedStudentsStore.where((s) => s.classId == 'cls-9-b')),
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
          students: List<StudentClassInfo>.from(_assignedStudentsStore.where((s) => s.classId == 'cls-9-c')),
          teachers: [],
        ),
      ]);
    }
  }

  /// Fetch all registered classes/sections, filtered optionally by grade or search string.
  Future<List<SchoolClass>> getClasses({int? grade, String? query}) async {
    await _initClassesStorage();
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/admin/school/classes');
        final res = await _httpClient.get(uri, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }).timeout(ApiConfig.requestTimeout);

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          List<SchoolClass> fetched = [];
          if (body['data'] is List) {
            fetched = (body['data'] as List)
                .whereType<Map<String, dynamic>>()
                .map((json) => SchoolClass.fromJson(json))
                .toList();
          } else if (body is List) {
            fetched = body
                .whereType<Map<String, dynamic>>()
                .map((json) => SchoolClass.fromJson(json))
                .toList();
          }
          if (fetched.isNotEmpty) {
            final sections = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
            List<SchoolClass> processed = [];

            for (int i = 0; i < fetched.length; i++) {
              var f = fetched[i];
              String sec = f.section.trim();
              if (sec.isEmpty || processed.any((c) => c.grade == f.grade && c.section == sec)) {
                sec = sections[i % sections.length];
                if (processed.any((c) => c.grade == f.grade && c.section == sec)) {
                  sec = '${sections[i % sections.length]}${i + 1}';
                }
              }

              String room = (f.roomNumber != null && f.roomNumber!.trim().isNotEmpty)
                  ? f.roomNumber!.trim()
                  : 'Room 10${i + 1}';

              f = f.copyWith(
                section: sec,
                roomNumber: room,
              );
              processed.add(f);
            }

            for (final f in processed) {
              final idx = _mockClasses.indexWhere((c) => c.id == f.id);
              if (idx != -1) {
                _mockClasses[idx] = f;
              } else {
                _mockClasses.add(f);
              }
            }

            // Remove any old mock classes that were replaced or duplicated
            final seenIds = <String>{};
            _mockClasses.retainWhere((c) => seenIds.add(c.id));
          }
          return _applyClassFilters(_mockClasses, grade: grade, query: query);
        }
      }
    } catch (_) {
      // Offline / local fallback
    }

    return _applyClassFilters(_mockClasses, grade: grade, query: query);
  }

  List<SchoolClass> _applyClassFilters(List<SchoolClass> list, {int? grade, String? query}) {
    return list.where((cls) {
      if (grade != null && cls.grade != grade) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final g = '${cls.grade}';
        final s = cls.section.toLowerCase();
        final displayName = cls.displayName.toLowerCase();
        final shortLabel = cls.shortLabel.toLowerCase();
        final combined = '$g$s';
        final combinedWithSpace = '$g $s';
        final room = (cls.roomNumber ?? '').toLowerCase();
        final desc = (cls.description ?? '').toLowerCase();

        return g == q ||
            s.contains(q) ||
            displayName.contains(q) ||
            shortLabel.contains(q) ||
            combined.contains(q) ||
            combinedWithSpace.contains(q) ||
            room.contains(q) ||
            desc.contains(q);
      }
      return true;
    }).toList();
  }

  /// Register/Create a new class & section in the system.
  Future<SchoolClass> createClass({
    required int grade,
    required String section,
    String? academicYear,
    String? roomNumber,
    int? maxCapacity,
    String? description,
  }) async {
    final secUpper = section.trim().toUpperCase();
    final year = academicYear?.trim().isNotEmpty == true ? academicYear!.trim() : '2025/2026';

    final exists = _mockClasses.any((c) => c.grade == grade && c.section.toUpperCase() == secUpper);
    if (exists) {
      throw ApiException(
        statusCode: 400,
        code: 'CLASS_EXISTS',
        message: 'Class Grade $grade - Section $secUpper already exists.',
      );
    }

    SchoolClass newClass = SchoolClass(
      id: 'cls-${DateTime.now().millisecondsSinceEpoch}',
      grade: grade,
      section: secUpper,
      academicYear: year,
      roomNumber: roomNumber?.trim().isNotEmpty == true ? roomNumber!.trim() : 'Unassigned Room',
      maxCapacity: maxCapacity ?? 35,
      description: description?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      students: [],
      teachers: [],
    );

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/admin/school/classes');
        final res = await _httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'grade': grade,
            'section': secUpper,
          }),
        ).timeout(ApiConfig.requestTimeout);

        if (res.statusCode == 201 || res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['data'] is Map<String, dynamic>) {
            final data = body['data'] as Map<String, dynamic>;
            newClass = SchoolClass(
              id: data['id'] as String? ?? newClass.id,
              grade: (data['grade'] as num?)?.toInt() ?? grade,
              section: (data['section'] as String?) ?? secUpper,
              academicYear: year,
              roomNumber: roomNumber?.trim().isNotEmpty == true ? roomNumber!.trim() : 'Unassigned Room',
              maxCapacity: maxCapacity ?? 35,
              description: description?.trim(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              students: [],
              teachers: [],
            );
          }
        } else {
          final body = jsonDecode(res.body);
          final errMsg = (body['error'] is Map ? body['error']['message'] : null) ?? body['message'] ?? 'Failed to create class in database.';
          final errCode = (body['error'] is Map ? body['error']['code'] : null) ?? '';

          if (errMsg.toString().toLowerCase().contains('already exists') || errCode == 'CLASS_EXISTS') {
            final existingIdx = _mockClasses.indexWhere((c) => (c.grade == grade && c.section.toUpperCase() == secUpper));
            if (existingIdx != -1) {
              return _mockClasses[existingIdx];
            } else {
              _mockClasses.insert(0, newClass);
              return newClass;
            }
          }
          throw ApiException(statusCode: res.statusCode, code: 'SERVER_ERROR', message: '$errMsg');
        }
      }
    } on ApiException catch (e) {
      if (e.message.toLowerCase().contains('already exists')) {
        final existingIdx = _mockClasses.indexWhere((c) => (c.grade == grade && c.section.toUpperCase() == secUpper));
        if (existingIdx != -1) {
          return _mockClasses[existingIdx];
        } else {
          _mockClasses.insert(0, newClass);
          return newClass;
        }
      }
      rethrow;
    } catch (_) {
      // Local fallback if server unreachable
    }

    final existingIdx = _mockClasses.indexWhere((c) => c.id == newClass.id || (c.grade == newClass.grade && c.section == newClass.section));
    if (existingIdx != -1) {
      _mockClasses[existingIdx] = newClass;
    } else {
      _mockClasses.insert(0, newClass);
    }
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
    _mockClasses.removeWhere((c) => c.id == classId);
  }

  /// Fetch all available subjects.
  Future<List<Subject>> getSubjects() async {
    return List.unmodifiable(_mockSubjects);
  }

  /// Create a new subject.
  Future<Subject> createSubject({
    required String name,
    String? code,
    String? category,
    String? description,
  }) async {
    final sName = name.trim();
    if (_mockSubjects.any((s) => s.name.toLowerCase() == sName.toLowerCase())) {
      throw ApiException(
        statusCode: 400,
        code: 'SUBJECT_EXISTS',
        message: 'Subject "$sName" already exists.',
      );
    }

    Subject newSubject = Subject(
      id: 'subj-${DateTime.now().millisecondsSinceEpoch}',
      name: sName,
      code: code?.trim().isNotEmpty == true ? code!.trim().toUpperCase() : null,
      category: category?.trim().isNotEmpty == true ? category!.trim() : 'General',
      description: description?.trim(),
    );

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/admin/school/subjects');
        final res = await _httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': sName,
          }),
        ).timeout(ApiConfig.requestTimeout);

        if (res.statusCode == 201 || res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['data'] is Map<String, dynamic>) {
            final data = body['data'] as Map<String, dynamic>;
            newSubject = Subject(
              id: data['id'] as String? ?? newSubject.id,
              name: data['name'] as String? ?? sName,
              code: code?.trim().isNotEmpty == true ? code!.trim().toUpperCase() : null,
              category: category?.trim().isNotEmpty == true ? category!.trim() : 'General',
              description: description?.trim(),
            );
          }
        } else {
          final body = jsonDecode(res.body);
          final errMsg = (body['error'] is Map ? body['error']['message'] : null) ?? body['message'] ?? 'Failed to create subject in database.';
          throw ApiException(statusCode: res.statusCode, code: 'SERVER_ERROR', message: '$errMsg');
        }
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Local state fallback
    }

    _mockSubjects.add(newSubject);
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

  /// Delete a subject.
  Future<void> deleteSubject(String subjectId) async {
    _mockSubjects.removeWhere((s) => s.id == subjectId);
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
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/admin/school/assign-student');
        final res = await _httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'studentId': studentId,
            'classId': classId,
            if (academicYear != null) 'academicYear': academicYear,
          }),
        ).timeout(ApiConfig.requestTimeout);

        if (res.statusCode == 200 || res.statusCode == 201) {
          final body = jsonDecode(res.body);
          if (body['data'] is Map<String, dynamic>) {
            newEnrollment = StudentClassInfo.fromJson(body['data'] as Map<String, dynamic>);
          }
        }
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
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        String realClassId = classId;
        String realSubjectId = subjectId;
        String realTeacherId = teacherId;

        // Auto-create/ensure Class in Neon DB
        try {
          final cRes = await createClass(grade: targetClass.grade, section: targetClass.section);
          realClassId = cRes.id;
        } catch (_) {}

        // Auto-create/ensure Subject in Neon DB
        try {
          final sRes = await createSubject(name: subjectName);
          realSubjectId = sRes.id;
        } catch (_) {}

        // Auto-resolve Teacher UUID in Neon DB
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

        final uri = Uri.parse('${ApiConfig.baseUrl}/admin/school/assign-teacher');
        final res = await _httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'teacherId': realTeacherId,
            'classId': realClassId,
            'subjectId': realSubjectId,
            if (academicYear != null) 'academicYear': academicYear,
          }),
        ).timeout(ApiConfig.requestTimeout);

        if (res.statusCode == 200 || res.statusCode == 201) {
          final body = jsonDecode(res.body);
          if (body['data'] is Map<String, dynamic>) {
            newAssignment = TeacherSubjectInfo.fromJson(body['data'] as Map<String, dynamic>);
          }
        }
      }
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
  }
}
