import '../models/course_offering.dart';
import '../models/grade_entry.dart';
import '../models/student_course_registration.dart';

class CourseService {
  factory CourseService() => _instance;
  CourseService._internal();
  static final CourseService _instance = CourseService._internal();

  final List<CourseOffering> _offerings = [];
  final List<StudentCourseRegistration> _registrations = [];

  Future<List<CourseOffering>> getAvailableOfferings({String term = 'Fall 2026'}) async {
    final searchTerm = term.trim().toLowerCase();
    return _offerings
        .where((c) => searchTerm.isEmpty || c.term.trim().toLowerCase() == searchTerm)
        .toList();
  }

  Future<CourseOffering> createCourseOffering({
    required String code,
    required String title,
    required double credits,
    required String teacherName,
    required String department,
    required String term,
  }) async {
    final offering = CourseOffering(
      id: 'co-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      title: title,
      credits: credits,
      teacherId: 'TEA-${DateTime.now().millisecondsSinceEpoch % 1000}',
      teacherName: teacherName,
      department: department,
      term: term,
    );
    _offerings.insert(0, offering);
    return offering;
  }

  Future<List<StudentCourseRegistration>> getStudentRegistrations(
    String studentId, {
    String term = 'Fall 2026',
  }) async {
    final sId = studentId.trim().toUpperCase();
    final searchTerm = term.trim().toLowerCase();

    return _registrations
        .where((r) =>
            (sId.isEmpty || r.studentId.trim().toUpperCase() == sId) &&
            (searchTerm.isEmpty || r.course.term.trim().toLowerCase() == searchTerm))
        .toList();
  }

  Future<StudentCourseRegistration> registerStudentForCourse({
    required String studentId,
    required String studentName,
    required CourseOffering course,
  }) async {
    final sId = studentId.trim();

    final existing = _registrations.any(
        (r) => r.studentId == sId && r.course.id == course.id);
    if (existing) {
      throw Exception('Already registered for ${course.code}: ${course.title}');
    }

    final reg = StudentCourseRegistration(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      studentId: sId,
      studentName: studentName,
      course: course,
      registeredAt: DateTime.now(),
    );
    _registrations.add(reg);
    return reg;
  }

  Future<void> attachGradeToRegistration(
    String studentId,
    String courseCodeOrSubject,
    GradeEntry grade,
  ) async {
    final sSubject = courseCodeOrSubject.trim().toLowerCase();
    final index = _registrations.indexWhere((r) =>
        r.course.code.trim().toLowerCase() == sSubject ||
        r.course.title.trim().toLowerCase() == sSubject ||
        grade.subject.trim().toLowerCase().contains(r.course.code.trim().toLowerCase()) ||
        r.course.title.trim().toLowerCase().contains(grade.subject.trim().toLowerCase()));
    if (index != -1) {
      final old = _registrations[index];
      _registrations[index] = StudentCourseRegistration(
        id: old.id,
        studentId: old.studentId,
        studentName: old.studentName,
        course: old.course,
        gradeEntry: grade,
        registeredAt: old.registeredAt,
      );
    }
  }

  double calculateGPA(List<StudentCourseRegistration> registrations) {
    double totalWeightedPoints = 0;
    double totalCredits = 0;

    for (final reg in registrations) {
      if (reg.gradeEntry != null) {
        final points = reg.gradeEntry!.gpaPoints;
        final credits = reg.course.credits;
        totalWeightedPoints += (points * credits);
        totalCredits += credits;
      }
    }

    if (totalCredits == 0) return 0.0;
    return totalWeightedPoints / totalCredits;
  }

  double calculateTotalCredits(List<StudentCourseRegistration> registrations) {
    double total = 0;
    for (final reg in registrations) {
      total += reg.course.credits;
    }
    return total;
  }
}
