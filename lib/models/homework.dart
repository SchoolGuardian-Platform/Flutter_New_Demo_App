/// Mirrors the `Homework` record returned by the backend's homework endpoints
/// (`src/routes/homework.routes.ts`, `src/service/homework.service.ts`).
///
/// Response shapes:
///   POST   /homework            -> { message, homework }   (homework object)
///   GET    /homework/teacher    -> { homeworks }           (array)
///   GET    /homework/student/:id -> { homeworks }          (array)
///   GET    /homework/class/:id  -> { homeworks }           (array)
///   GET    /homework/:id        -> { homework }            (single)
///   PATCH  /homework/:id        -> { message, homework }   (homework object)
class Homework {
  const Homework({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    this.createdAt,
  });

  final String id;
  final String teacherId;
  final String classId;
  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? createdAt;

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'] as String,
        teacherId: json['teacherId'] as String,
        classId: json['classId'] as String,
        subject: json['subject'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        dueDate: DateTime.parse(json['dueDate'] as String),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
