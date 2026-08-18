import 'account_status.dart';
import 'relationship.dart';

/// One verified (APPROVED) parent-student link, as returned by
/// `GET /parents/my-students`.
///
/// SHAPE NOTE: the OpenAPI spec's `UserListResponse` ref for this
/// endpoint doesn't match what `getParentVerifiedStudents` in
/// `relationship.service.ts` actually returns -- it's not a bare list of
/// students, it's a list of `{ relationshipId, relationshipType, student,
/// verifiedAt }`. This model follows the real service code rather than
/// the spec.
class StudentLink {
  const StudentLink({
    required this.relationshipId,
    required this.relationshipType,
    required this.studentId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.status,
    this.verifiedAt,
  });

  final String relationshipId;
  final RelationshipType relationshipType;
  final String studentId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final AccountStatus? status;
  final DateTime? verifiedAt;

  String get fullName =>
      [firstName, middleName, lastName].where((s) => (s ?? '').isNotEmpty).join(' ');

  factory StudentLink.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>? ?? const {};
    return StudentLink(
      relationshipId: json['relationshipId'] as String,
      relationshipType: relationshipTypeFromApiValue(
          json['relationshipType'] as String? ?? 'OTHER'),
      studentId: student['id'] as String? ?? '',
      firstName: student['firstName'] as String? ?? '',
      middleName: student['middleName'] as String?,
      lastName: student['lastName'] as String? ?? '',
      email: student['email'] as String? ?? '',
      status: student['status'] != null
          ? AccountStatusX.fromApiValue(student['status'] as String)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
    );
  }
}
