enum AssessmentType {
  assignment,
  quiz,
  midterm,
  finalExam,
  project,
  composite,
}

extension AssessmentTypeX on AssessmentType {
  String get label {
    switch (this) {
      case AssessmentType.assignment:
        return 'Assignment';
      case AssessmentType.quiz:
        return 'Quiz';
      case AssessmentType.midterm:
        return 'Midterm Exam';
      case AssessmentType.finalExam:
        return 'Final Exam';
      case AssessmentType.project:
        return 'Project';
      case AssessmentType.composite:
        return 'Composite Evaluation (100)';
    }
  }

  String get apiValue {
    switch (this) {
      case AssessmentType.assignment:
        return 'ASSIGNMENT';
      case AssessmentType.quiz:
        return 'QUIZ';
      case AssessmentType.midterm:
        return 'MIDTERM';
      case AssessmentType.finalExam:
        return 'FINAL';
      case AssessmentType.project:
        return 'PROJECT';
      case AssessmentType.composite:
        return 'COMPOSITE';
    }
  }

  static AssessmentType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ASSIGNMENT':
        return AssessmentType.assignment;
      case 'QUIZ':
        return AssessmentType.quiz;
      case 'MIDTERM':
        return AssessmentType.midterm;
      case 'FINAL':
      case 'FINAL_EXAM':
        return AssessmentType.finalExam;
      case 'PROJECT':
        return AssessmentType.project;
      case 'COMPOSITE':
        return AssessmentType.composite;
      default:
        return AssessmentType.assignment;
    }
  }
}

class GradeEntry {
  const GradeEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.assessmentType,
    required this.score,
    required this.maxScore,
    required this.term,
    this.attendanceScore,
    this.midtermScore,
    this.assignmentScore,
    this.finalScore,
    this.parentRecommendation,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final AssessmentType assessmentType;
  final double score;
  final double maxScore;
  final String term;

  // Breakdown Component Marks out of 100 total:
  // Attendance (max 10), Midterm (max 30), Assignment (max 10), Final (max 50)
  final double? attendanceScore;
  final double? midtermScore;
  final double? assignmentScore;
  final double? finalScore;

  /// Private text recommendation written by the teacher.
  /// PRIVACY RULE: Visible ONLY to Parents, strictly hidden from Students.
  final String? parentRecommendation;
  final DateTime createdAt;

  bool get hasBreakdown =>
      attendanceScore != null ||
      midtermScore != null ||
      assignmentScore != null ||
      finalScore != null;

  double get calculatedTotal =>
      (attendanceScore ?? 0) +
      (midtermScore ?? 0) +
      (assignmentScore ?? 0) +
      (finalScore ?? 0);

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get letterGrade {
    final p = percentage;
    if (p >= 90) return 'A';
    if (p >= 80) return 'B';
    if (p >= 70) return 'C';
    if (p >= 60) return 'D';
    return 'F';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'subject': subject,
        'assessmentType': assessmentType.apiValue,
        'score': score,
        'maxScore': maxScore,
        'term': term,
        'attendanceScore': attendanceScore,
        'midtermScore': midtermScore,
        'assignmentScore': assignmentScore,
        'finalScore': finalScore,
        'parentRecommendation': parentRecommendation,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GradeEntry.fromJson(Map<String, dynamic> json) {
    return GradeEntry(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      subject: json['subject'] as String,
      assessmentType: AssessmentTypeX.fromString(json['assessmentType'] as String),
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      term: json['term'] as String,
      attendanceScore: json['attendanceScore'] != null
          ? (json['attendanceScore'] as num).toDouble()
          : null,
      midtermScore: json['midtermScore'] != null
          ? (json['midtermScore'] as num).toDouble()
          : null,
      assignmentScore: json['assignmentScore'] != null
          ? (json['assignmentScore'] as num).toDouble()
          : null,
      finalScore: json['finalScore'] != null
          ? (json['finalScore'] as num).toDouble()
          : null,
      parentRecommendation: json['parentRecommendation'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
