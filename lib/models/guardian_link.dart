import 'account_status.dart';
import 'relationship.dart';

/// One verified (APPROVED) parent-student link, as returned by
/// `GET /students/my-guardians`.
///
/// SHAPE NOTE: mirrors [StudentLink] on the parent side, for the same
/// reason -- `getStudentVerifiedGuardians` in `relationship.service.ts`
/// does NOT return a bare list of guardian users. It returns a list of
/// `{ relationshipId, relationshipType, guardian, verifiedAt }`, where
/// `guardian` is the nested profile (`id, firstName, middleName,
/// lastName, email, status` -- notably no `role`). Parsing each item
/// directly as a top-level `User` (as this previously did) throws,
/// because `User.fromJson` requires a `role` field that simply isn't
/// present at any level of this response -- that was the cause of the
/// "Something went wrong loading your guardians" error on the student
/// dashboard. This model reads the real shape instead.
class GuardianLink {
  const GuardianLink({
    required this.relationshipId,
    required this.relationshipType,
    required this.guardianId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.status,
    this.verifiedAt,
  });

  final String relationshipId;
  final RelationshipType relationshipType;
  final String guardianId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final AccountStatus? status;
  final DateTime? verifiedAt;

  String get fullName =>
      [firstName, middleName, lastName].where((s) => (s ?? '').isNotEmpty).join(' ');

  factory GuardianLink.fromJson(Map<String, dynamic> json) {
    final guardian = json['guardian'] as Map<String, dynamic>? ?? const {};
    return GuardianLink(
      relationshipId: json['relationshipId'] as String,
      relationshipType: relationshipTypeFromApiValue(
          json['relationshipType'] as String? ?? 'OTHER'),
      guardianId: guardian['id'] as String? ?? '',
      firstName: guardian['firstName'] as String? ?? '',
      middleName: guardian['middleName'] as String?,
      lastName: guardian['lastName'] as String? ?? '',
      email: guardian['email'] as String? ?? '',
      status: guardian['status'] != null
          ? AccountStatusX.fromApiValue(guardian['status'] as String)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
    );
  }
}
