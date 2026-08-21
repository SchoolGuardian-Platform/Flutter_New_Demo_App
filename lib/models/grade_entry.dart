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
        return 'Composite Evaluation';
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

class AssessmentComponent {
  const AssessmentComponent({
    required this.name,
    required this.score,
    required this.maxScore,
  });

  final String name;
  final double score;
  final double maxScore;

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'maxScore': maxScore,
      };

  factory AssessmentComponent.fromJson(Map<String, dynamic> json) {
    return AssessmentComponent(
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
    );
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
    this.components = const [],
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

  /// Dynamic list of chosen assessment sections (Midterm, Attendance, Project, etc.)
  final List<AssessmentComponent> components;

  // Legacy Breakdown Component Marks out of 100 total
  final double? attendanceScore;
  final double? midtermScore;
  final double? assignmentScore;
  final double? finalScore;

  /// Private text recommendation written by the teacher.
  /// PRIVACY RULE: Visible ONLY to Parents, strictly hidden from Students.
  final String? parentRecommendation;
  final DateTime createdAt;

  List<AssessmentComponent> get activeComponents {
    if (components.isNotEmpty) return components;
    final list = <AssessmentComponent>[];
    if (attendanceScore != null) {
      list.add(AssessmentComponent(
          name: 'Attendance', score: attendanceScore!, maxScore: 10));
    }
    if (midtermScore != null) {
      list.add(AssessmentComponent(
          name: 'Midterm Exam', score: midtermScore!, maxScore: 30));
    }
    if (assignmentScore != null) {
      list.add(AssessmentComponent(
          name: 'Assignments', score: assignmentScore!, maxScore: 10));
    }
    if (finalScore != null) {
      list.add(AssessmentComponent(
          name: 'Final Exam', score: finalScore!, maxScore: 50));
    }
    return list;
  }

  bool get hasBreakdown => activeComponents.isNotEmpty;

  double get calculatedTotalEarned {
    if (components.isNotEmpty) {
      return components.fold(0.0, (sum, c) => sum + c.score);
    }
    return (attendanceScore ?? 0) +
        (midtermScore ?? 0) +
        (assignmentScore ?? 0) +
        (finalScore ?? 0);
  }

  double get calculatedTotalMax {
    if (components.isNotEmpty) {
      return components.fold(0.0, (sum, c) => sum + c.maxScore);
    }
    return maxScore > 0 ? maxScore : 100.0;
  }

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get letterGrade {
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 85) return 'A';
    if (p >= 80) return 'A-';
    if (p >= 75) return 'B+';
    if (p >= 70) return 'B';
    if (p >= 65) return 'B-';
    if (p >= 60) return 'C+';
    if (p >= 50) return 'C';
    if (p >= 45) return 'C-';
    if (p >= 40) return 'D';
    return 'F';
  }

  double get gpaPoints {
    final p = percentage;
    if (p >= 90) return 4.0;
    if (p >= 85) return 4.0;
    if (p >= 80) return 3.75;
    if (p >= 75) return 3.5;
    if (p >= 70) return 3.0;
    if (p >= 65) return 2.75;
    if (p >= 60) return 2.5;
    if (p >= 50) return 2.0;
    if (p >= 45) return 1.75;
    if (p >= 40) return 1.0;
    return 0.0;
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
        'components': components.map((c) => c.toJson()).toList(),
        'attendanceScore': attendanceScore,
        'midtermScore': midtermScore,
        'assignmentScore': assignmentScore,
        'finalScore': finalScore,
        'parentRecommendation': parentRecommendation,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GradeEntry.fromJson(Map<String, dynamic> json) {
    final rawComponents = json['components'] as List<dynamic>?;
    final parsedComponents = rawComponents != null
        ? rawComponents
            .map((c) => AssessmentComponent.fromJson(c as Map<String, dynamic>))
            .toList()
        : <AssessmentComponent>[];

    return GradeEntry(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      subject: json['subject'] as String,
      assessmentType: AssessmentTypeX.fromString(json['assessmentType'] as String),
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      term: json['term'] as String,
      components: parsedComponents,
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
