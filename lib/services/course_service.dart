import '../models/course_offering.dart';
import '../models/grade_entry.dart';
import '../models/student_course_registration.dart';

class CourseService {
  factory CourseService() => _instance;
  CourseService._internal();
  static final CourseService _instance = CourseService._internal();

  final List<CourseOffering> _offerings = [
    const CourseOffering(
      id: 'co-101',
      code: 'CS-101',
      title: 'Intro to Computer Science',
      credits: 3.0,
      teacherId: 'TEA-801',
      teacherName: 'Dr. Elizabeth Vance',
      department: 'Computer Science & Software',
      term: 'Fall 2026',
    ),
    const CourseOffering(
      id: 'co-202',
      code: 'MATH-202',
      title: 'Advanced Algebra & Calculus',
      credits: 4.0,
      teacherId: 'TEA-802',
      teacherName: 'Prof. Marcus Miller',
      department: 'Mathematics & Statistics',
      term: 'Fall 2026',
    ),
    const CourseOffering(
      id: 'co-305',
      code: 'STEM-305',
      title: 'Robotics & Embedded Systems',
      credits: 3.0,
      teacherId: 'TEA-803',
      teacherName: 'Dr. Aris Thorne',
      department: 'Engineering & Technology',
      term: 'Fall 2026',
    ),
    const CourseOffering(
      id: 'co-401',
      code: 'ENG-105',
      title: 'Technical Communication & Logic',
      credits: 2.0,
      teacherId: 'TEA-804',
      teacherName: 'Prof. Clara Oswald',
      department: 'Humanities & Arts',
      term: 'Fall 2026',
    ),
  ];

  final List<StudentCourseRegistration> _registrations = [
    StudentCourseRegistration(
      id: 'reg-1',
      studentId: 'STU-1001',
      studentName: 'Alexander Hayes',
      course: const CourseOffering(
        id: 'co-101',
        code: 'CS-101',
        title: 'Intro to Computer Science',
        credits: 3.0,
        teacherId: 'TEA-801',
        teacherName: 'Dr. Elizabeth Vance',
        department: 'Computer Science & Software',
        term: 'Fall 2026',
      ),
      gradeEntry: GradeEntry(
        id: 'ge-101',
        studentId: 'STU-1001',
        studentName: 'Alexander Hayes',
        subject: 'Intro to Computer Science',
        assessmentType: AssessmentType.composite,
        score: 91.0,
        maxScore: 100.0,
        term: 'Fall 2026',
        components: const [
          AssessmentComponent(name: 'Attendance', score: 9.0, maxScore: 10.0),
          AssessmentComponent(name: 'Python Project', score: 18.0, maxScore: 20.0),
          AssessmentComponent(name: 'Midterm Exam', score: 26.0, maxScore: 30.0),
          AssessmentComponent(name: 'Final Exam', score: 38.0, maxScore: 40.0),
        ],
        parentRecommendation:
            'Alexander completed an outstanding Python project. Strongly encourage him to join the Robotics & Coding Club.',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    StudentCourseRegistration(
      id: 'reg-2',
      studentId: 'STU-1001',
      studentName: 'Alexander Hayes',
      course: const CourseOffering(
        id: 'co-202',
        code: 'MATH-202',
        title: 'Advanced Algebra & Calculus',
        credits: 4.0,
        teacherId: 'TEA-802',
        teacherName: 'Prof. Marcus Miller',
        department: 'Mathematics & Statistics',
        term: 'Fall 2026',
      ),
      gradeEntry: GradeEntry(
        id: 'ge-202',
        studentId: 'STU-1001',
        studentName: 'Alexander Hayes',
        subject: 'Advanced Algebra & Calculus',
        assessmentType: AssessmentType.composite,
        score: 78.0,
        maxScore: 100.0,
        term: 'Fall 2026',
        components: const [
          AssessmentComponent(name: 'Attendance', score: 7.0, maxScore: 10.0),
          AssessmentComponent(name: 'Midterm Exam', score: 24.0, maxScore: 30.0),
          AssessmentComponent(name: 'Assignments', score: 8.0, maxScore: 10.0),
          AssessmentComponent(name: 'Final Exam', score: 39.0, maxScore: 50.0),
        ],
        parentRecommendation:
            'Alexander demonstrates solid calculus fundamentals but rushed through integration formulas. Daily 15-min guided review is recommended.',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    StudentCourseRegistration(
      id: 'reg-3',
      studentId: 'STU-1001',
      studentName: 'Alexander Hayes',
      course: const CourseOffering(
        id: 'co-305',
        code: 'STEM-305',
        title: 'Robotics & Embedded Systems',
        credits: 3.0,
        teacherId: 'TEA-803',
        teacherName: 'Dr. Aris Thorne',
        department: 'Engineering & Technology',
        term: 'Fall 2026',
      ),
      gradeEntry: GradeEntry(
        id: 'ge-305',
        studentId: 'STU-1001',
        studentName: 'Alexander Hayes',
        subject: 'Robotics & Embedded Systems',
        assessmentType: AssessmentType.composite,
        score: 82.0,
        maxScore: 100.0,
        term: 'Fall 2026',
        components: const [
          AssessmentComponent(name: 'Attendance', score: 9.0, maxScore: 10.0),
          AssessmentComponent(name: 'Hardware Lab', score: 25.0, maxScore: 30.0),
          AssessmentComponent(name: 'Final Demo', score: 48.0, maxScore: 60.0),
        ],
        parentRecommendation:
            'Great effort on the autonomous robot lab demo. Has strong technical intuition.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    StudentCourseRegistration(
      id: 'reg-4',
      studentId: 'STU-1001',
      studentName: 'Alexander Hayes',
      course: const CourseOffering(
        id: 'co-401',
        code: 'ENG-105',
        title: 'Technical Communication & Logic',
        credits: 2.0,
        teacherId: 'TEA-804',
        teacherName: 'Prof. Clara Oswald',
        department: 'Humanities & Arts',
        term: 'Fall 2026',
      ),
      gradeEntry: GradeEntry(
        id: 'ge-401',
        studentId: 'STU-1001',
        studentName: 'Alexander Hayes',
        subject: 'Technical Communication & Logic',
        assessmentType: AssessmentType.composite,
        score: 62.0,
        maxScore: 100.0,
        term: 'Fall 2026',
        components: const [
          AssessmentComponent(name: 'Attendance', score: 6.0, maxScore: 10.0),
          AssessmentComponent(name: 'Essays', score: 18.0, maxScore: 30.0),
          AssessmentComponent(name: 'Final Presentation', score: 38.0, maxScore: 60.0),
        ],
        parentRecommendation:
            'Alexander needs to spend more time drafting technical documentation. Extra writing lab sessions are suggested.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  Future<List<CourseOffering>> getAvailableOfferings({String term = 'Fall 2026'}) async {
    return _offerings.where((c) => c.term == term || term.isEmpty).toList();
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
    return _registrations
        .where((r) =>
            (r.studentId.trim().toUpperCase() == studentId.trim().toUpperCase() ||
                studentId.trim().isEmpty) &&
            (r.course.term == term || term.isEmpty))
        .toList();
  }

  Future<StudentCourseRegistration> registerStudentForCourse({
    required String studentId,
    required String studentName,
    required CourseOffering course,
  }) async {
    final existing = _registrations.any(
        (r) => r.studentId == studentId && r.course.id == course.id);
    if (existing) {
      throw Exception('Already registered for ${course.code}: ${course.title}');
    }

    final reg = StudentCourseRegistration(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      studentName: studentName,
      course: course,
      registeredAt: DateTime.now(),
    );
    _registrations.add(reg);
    return reg;
  }

  Future<void> attachGradeToRegistration(
    String studentId,
    String courseCode,
    GradeEntry grade,
  ) async {
    final index = _registrations.indexWhere((r) =>
        r.studentId == studentId &&
        r.course.code.trim().toUpperCase() == courseCode.trim().toUpperCase());
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

  /// Automated GPA calculation formula:
  /// GPA = sum(gpaPoints * credits) / sum(credits)
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
