class TeacherProfile {
  const TeacherProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.majorField,
    required this.department,
    required this.employeeId,
    required this.assignedClasses,
  });

  final String id;
  final String fullName;
  final String email;
  final String majorField; // e.g. "Computer Science & Mathematics"
  final String department; // e.g. "STEM & Advanced Analytics"
  final String employeeId; // e.g. "TCH-8802"
  final List<String> assignedClasses;

  factory TeacherProfile.sample() {
    return const TeacherProfile(
      id: 'tch-001',
      fullName: 'Dr. Elizabeth Vance',
      email: 'teacher@schoolguardian.app',
      majorField: 'Computer Science & Applied Mathematics',
      department: 'Department of STEM Education',
      employeeId: 'TCH-9042',
      assignedClasses: [
        'CS-101: Intro to Computer Science',
        'MATH-202: Advanced Algebra & Calculus',
        'STEM-305: Robotics & Problem Solving',
      ],
    );
  }
}
