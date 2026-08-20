/// Mirrors the `Grade` record returned by the backend's grade endpoints
/// (`src/routes/grade.routes.ts`, `src/service/grade.service.ts`).
///
/// Response shapes:
///   POST /grades          -> { message, grade }        (grade object)
///   GET  /grades/teacher  -> { grades }                (array)
///   GET  /grades/student/:id -> { grades }             (array)
///   GET  /grades/:id      -> { grade }                 (single)
///   PATCH /grades/:id     -> { message, grade }        (grade object)
///
/// Assessment types come from the Prisma enum `AssessmentType`.
enum AssessmentType {
  quiz,
  test,
  exam,
  assignment,
  project,
  other,
}

extension AssessmentTypeX on AssessmentType {
  String get apiValue {
    switch (this) {
      case AssessmentType.quiz:
        return 'QUIZ';
      case AssessmentType.test:
        return 'TEST';
      case AssessmentType.exam:
        return 'EXAM';
      case AssessmentType.assignment:
        return 'ASSIGNMENT';
      case AssessmentType.project:
        return 'PROJECT';
      case AssessmentType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case AssessmentType.quiz:
        return 'Quiz';
      case AssessmentType.test:
        return 'Test';
      case AssessmentType.exam:
        return 'Exam';
      case AssessmentType.assignment:
        return 'Assignment';
      case AssessmentType.project:
        return 'Project';
      case AssessmentType.other:
        return 'Other';
    }
  }

  static AssessmentType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'QUIZ':
        return AssessmentType.quiz;
      case 'TEST':
        return AssessmentType.test;
      case 'EXAM':
        return AssessmentType.exam;
      case 'ASSIGNMENT':
        return AssessmentType.assignment;
      case 'PROJECT':
        return AssessmentType.project;
      default:
        return AssessmentType.other;
    }
  }
}

class Grade {
  const Grade({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.subject,
    required this.assessmentType,
    required this.score,
    required this.maxScore,
    this.term,
    this.academicYear,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String subject;
  final AssessmentType assessmentType;
  final double score;
  final double maxScore;
  final String? term;
  final String? academicYear;
  final String? comment;
  final DateTime? createdAt;

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        teacherId: json['teacherId'] as String,
        subject: json['subject'] as String,
        assessmentType:
            AssessmentTypeX.fromApi(json['assessmentType'] as String),
        score: (json['score'] as num).toDouble(),
        maxScore: (json['maxScore'] as num).toDouble(),
        term: json['term'] as String?,
        academicYear: json['academicYear'] as String?,
        comment: json['comment'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
