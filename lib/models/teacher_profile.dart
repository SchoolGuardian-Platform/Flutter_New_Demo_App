class TeacherProfile {
  const TeacherProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.majorField,
    required this.department,
    required this.employeeId,
    required this.assignedClasses,
    required this.assignedSubjects,
  });

  final String id;
  final String fullName;
  final String email;
  final String majorField; // e.g. "Computer Science & Mathematics"
  final String department; // e.g. "STEM & Advanced Analytics"
  final String employeeId; // e.g. "TCH-8802"
  final List<String> assignedClasses;
  final List<String> assignedSubjects;

  factory TeacherProfile.sample() {
    return const TeacherProfile(
      id: 'tch-001',
      fullName: 'Teacher Account',
      email: 'teacher@schoolguardian.app',
      majorField: 'Computer Science & Mathematics',
      department: 'STEM & Advanced Education',
      employeeId: 'TCH-9042',
      assignedClasses: [
        'Grade 9 - Section A',
      ],
      assignedSubjects: [
        'Maths',
      ],
    );
  }
}
