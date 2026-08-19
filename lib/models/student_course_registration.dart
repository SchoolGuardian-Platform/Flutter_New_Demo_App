import 'course_offering.dart';
import 'grade_entry.dart';

class StudentCourseRegistration {
  const StudentCourseRegistration({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.course,
    this.gradeEntry,
    required this.registeredAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final CourseOffering course;
  final GradeEntry? gradeEntry;
  final DateTime registeredAt;
}
