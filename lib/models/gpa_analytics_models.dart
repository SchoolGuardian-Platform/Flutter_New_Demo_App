/// Data Point for Semester GPA Progression
class SemesterGpaPoint {
  const SemesterGpaPoint({
    required this.semesterLabel, // e.g. 'Sem 1', 'Sem 2'
    required this.termName, // e.g. 'Fall 2023'
    required this.gpa, // e.g. 3.75
    required this.creditsEarned, // e.g. 16.0
    required this.gradeDistribution, // e.g. "4 A's, 1 B+"
    required this.deltaVsPrevious, // e.g. "+0.07"
  });

  final String semesterLabel;
  final String termName;
  final double gpa;
  final double creditsEarned;
  final String gradeDistribution;
  final String deltaVsPrevious;
}

/// Overall Cumulative Academic Summary Data Model
class CumulativeAcademicSummary {
  const CumulativeAcademicSummary({
    required this.cumulativeGpa,
    required this.maxGpa,
    required this.trendText,
    required this.honorsBadgeText,
    required this.totalCreditsEarned,
    required this.majorRankText,
    required this.currentSemesterText,
    required this.targetGpa,
  });

  final double cumulativeGpa;
  final double maxGpa;
  final String trendText;
  final String honorsBadgeText;
  final double totalCreditsEarned;
  final String majorRankText;
  final String currentSemesterText;
  final double targetGpa;
}
