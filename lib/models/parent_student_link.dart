/// Represents one entry in the `GET /parents/my-students` response.
///
/// The backend returns an array of:
/// ```json
/// {
///   "relationshipId": "...",
///   "relationshipType": "MOTHER|FATHER|GUARDIAN|OTHER",
///   "student": {
///     "id": "...",
///     "firstName": "...",
///     "middleName": "...",
///     "lastName": "...",
///     "email": "...",
///     "status": "..."
///   },
///   "verifiedAt": "..."
/// }
/// ```
/// (see `getParentVerifiedStudents` in `relationship.service.ts`)
class LinkedStudent {
  const LinkedStudent({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.status,
  });

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? status;

  String get fullName =>
      [firstName, middleName, lastName].where((s) => (s ?? '').isNotEmpty).join(' ');

  factory LinkedStudent.fromJson(Map<String, dynamic> json) => LinkedStudent(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        middleName: json['middleName'] as String?,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        status: json['status'] as String?,
      );
}

class ParentStudentLink {
  const ParentStudentLink({
    required this.relationshipId,
    required this.relationshipType,
    required this.student,
    this.verifiedAt,
  });

  final String relationshipId;
  final String relationshipType;
  final LinkedStudent student;
  final DateTime? verifiedAt;

  factory ParentStudentLink.fromJson(Map<String, dynamic> json) =>
      ParentStudentLink(
        relationshipId: json['relationshipId'] as String,
        relationshipType: json['relationshipType'] as String,
        student: LinkedStudent.fromJson(
            json['student'] as Map<String, dynamic>),
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.tryParse(json['verifiedAt'] as String)
            : null,
      );
}
