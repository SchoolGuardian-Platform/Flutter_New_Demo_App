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

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'credits': credits,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'department': department,
        'term': term,
      };

  factory CourseOffering.fromJson(Map<String, dynamic> json) {
    return CourseOffering(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      credits: (json['credits'] as num).toDouble(),
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String,
      department: json['department'] as String,
      term: json['term'] as String,
    );
  }
}
