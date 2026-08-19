import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_entry.dart';
import '../models/teacher_profile.dart';
import 'course_service.dart';

class TeacherService {
  factory TeacherService() => _instance;
  TeacherService._internal() {
    _initStorage();
  }
  static final TeacherService _instance = TeacherService._internal();

  static const String _storageKey = 'teacher_grade_entries_persistent_v1';

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
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _persistToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<TeacherProfile> getTeacherProfile() async {
    await _initStorage();
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
    }
  }

  Future<void> removeAssignedSubject(String subject) async {
    final updatedList = List<String>.from(_profile.assignedSubjects)..remove(subject);
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
  }

  Future<List<GradeEntry>> getGradeEntries() async {
    await _initStorage();
    return List.unmodifiable(_entries);
  }

  Future<List<GradeEntry>> getGradesForStudent(String studentId) async {
    await _initStorage();
    return _entries
        .where((e) =>
            e.studentId.trim().toUpperCase() == studentId.trim().toUpperCase() ||
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
    final entry = GradeEntry(
      id: 'ge-${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
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

    _entries.insert(0, entry);
    await _persistToDisk();
    await CourseService().attachGradeToRegistration(studentId, subject, entry);
    return entry;
  }

  Future<GradeEntry> updateGradeEntry(GradeEntry updatedEntry) async {
    await _initStorage();
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
    _entries.removeWhere((e) => e.id == id);
    await _persistToDisk();
  }
}
