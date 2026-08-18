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

  bool get isGraded => gradeEntry != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'course': course.toJson(),
        'gradeEntry': gradeEntry?.toJson(),
        'registeredAt': registeredAt.toIso8601String(),
      };

  factory StudentCourseRegistration.fromJson(Map<String, dynamic> json) {
    return StudentCourseRegistration(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      course: CourseOffering.fromJson(json['course'] as Map<String, dynamic>),
      gradeEntry: json['gradeEntry'] != null
          ? GradeEntry.fromJson(json['gradeEntry'] as Map<String, dynamic>)
          : null,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }
}
