import '../models/grade_entry.dart';
import '../models/teacher_profile.dart';

class TeacherService {
  factory TeacherService() => _instance;
  TeacherService._internal();
  static final TeacherService _instance = TeacherService._internal();

  TeacherProfile _profile = TeacherProfile.sample();

  final List<GradeEntry> _entries = [
    GradeEntry(
      id: 'ge-1',
      studentId: 'STU-1001',
      studentName: 'Alexander Hayes',
      subject: 'Advanced Mathematics',
      assessmentType: AssessmentType.composite,
      score: 91.0,
      maxScore: 100.0,
      term: 'Fall 2026',
      attendanceScore: 7.0,   // out of 10
      midtermScore: 27.0,     // out of 30
      assignmentScore: 9.0,   // out of 10
      finalScore: 48.0,       // out of 50
      parentRecommendation:
          'Alexander demonstrates exceptional analytical thinking in calculus. Highly recommend enrolling him in the Advanced Placement Math Club.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    GradeEntry(
      id: 'ge-2',
      studentId: 'STU-1001',
      studentName: 'Alexander Hayes',
      subject: 'Computer Science 101',
      assessmentType: AssessmentType.composite,
      score: 88.0,
      maxScore: 100.0,
      term: 'Fall 2026',
      attendanceScore: 9.0,
      midtermScore: 25.0,
      assignmentScore: 10.0,
      finalScore: 44.0,
      parentRecommendation:
          'Alexander completed a great Python project. Please encourage him to review data structures before the upcoming final exam.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    GradeEntry(
      id: 'ge-3',
      studentId: 'STU-1002',
      studentName: 'Sophia Rodriguez',
      subject: 'Advanced Mathematics',
      assessmentType: AssessmentType.composite,
      score: 76.0,
      maxScore: 100.0,
      term: 'Fall 2026',
      attendanceScore: 8.0,
      midtermScore: 21.0,
      assignmentScore: 7.0,
      finalScore: 40.0,
      parentRecommendation:
          'Sophia understands algebraic concepts well but rushed through quadratic equations. 15 minutes of guided homework review daily would boost her confidence.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  Future<TeacherProfile> getTeacherProfile() async {
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
    );
  }

  Future<List<GradeEntry>> getGradeEntries() async {
    return List.unmodifiable(_entries);
  }

  Future<List<GradeEntry>> getGradesForStudent(String studentId) async {
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
    double? attendanceScore,
    double? midtermScore,
    double? assignmentScore,
    double? finalScore,
    String? parentRecommendation,
  }) async {
    final entry = GradeEntry(
      id: 'ge-${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      studentName: studentName.isNotEmpty ? studentName : 'Student $studentId',
      subject: subject,
      assessmentType: assessmentType,
      score: score,
      maxScore: maxScore,
      term: term,
      attendanceScore: attendanceScore,
      midtermScore: midtermScore,
      assignmentScore: assignmentScore,
      finalScore: finalScore,
      parentRecommendation: parentRecommendation,
      createdAt: DateTime.now(),
    );

    _entries.insert(0, entry);
    return entry;
  }
}
