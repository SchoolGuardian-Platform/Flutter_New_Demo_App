class CourseOffering {
  const CourseOffering({
    required this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.teacherId,
    required this.teacherName,
    required this.department,
    required this.term,
  });

  final String id;
  final String code;
  final String title;
  final double credits;
  final String teacherId;
  final String teacherName;
  final String department;
  final String term;
}
