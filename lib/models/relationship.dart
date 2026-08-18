import 'account_status.dart';

/// A parent↔student guardian-link request awaiting (or already given)
/// admin verification. Mirrors the `Relationship` schema in
/// `SchoolGuardian_Final_OpenAPI.yaml` and the `/admin/relationships/*`
/// endpoints (`admin.routes.ts`).
///
/// `GET /admin/relationships/pending` and `GET /admin/relationships/:id`
/// both join in lightweight parent/student profile data (see
/// `getPendingRelationships`/`getRelationshipById` in
/// `relationship.service.ts`), exposed here as [parent]/[student]. Those
/// are null only if a future/older endpoint didn't include them, in which
/// case callers fall back to the raw [parentId]/[studentId].
enum RelationshipType { mother, father, guardian, other }

enum RelationshipStatus { pending, verified, rejected }

RelationshipType relationshipTypeFromApiValue(String value) {
  switch (value.toUpperCase()) {
    case 'MOTHER':
      return RelationshipType.mother;
    case 'FATHER':
      return RelationshipType.father;
    case 'GUARDIAN':
      return RelationshipType.guardian;
    default:
      return RelationshipType.other;
  }
}

RelationshipStatus relationshipStatusFromApiValue(String value) {
  switch (value.toUpperCase()) {
    case 'PENDING':
      return RelationshipStatus.pending;
    // Backend (`prisma/schema.prisma`) uses APPROVED. 'VERIFIED' is kept
    // as a defensive alias only -- the real API value is APPROVED, and
    // treating it as an unrecognized value (falling through to the old
    // default of `pending`) was the bug: an approved relationship coming
    // back from the server was silently displayed as still pending.
    case 'APPROVED':
    case 'VERIFIED':
      return RelationshipStatus.verified;
    case 'REJECTED':
      return RelationshipStatus.rejected;
    default:
      return RelationshipStatus.pending;
  }
}

extension RelationshipTypeLabel on RelationshipType {
  String get label {
    switch (this) {
      case RelationshipType.mother:
        return 'Mother';
      case RelationshipType.father:
        return 'Father';
      case RelationshipType.guardian:
        return 'Guardian';
      case RelationshipType.other:
        return 'Other';
    }
  }

  /// Exact string the backend uses for `enum RelationshipType`
  /// (`prisma/schema.prisma`) -- the reverse of
  /// [relationshipTypeFromApiValue]. Needed when a parent submits
  /// `POST /parents/relationships` (see `CreateRelationshipRequest` in
  /// `SchoolGuardian_Final_OpenAPI.yaml`), which is the only place this
  /// app sends a relationship type rather than just reading one back.
  String get apiValue {
    switch (this) {
      case RelationshipType.mother:
        return 'MOTHER';
      case RelationshipType.father:
        return 'FATHER';
      case RelationshipType.guardian:
        return 'GUARDIAN';
      case RelationshipType.other:
        return 'OTHER';
    }
  }
}

/// Lightweight parent/student profile as joined into a [Relationship] by
/// `GET /admin/relationships*` -- id, name, email, and account status
/// only (not the full `User` shape, e.g. no human-readable Student ID).
class RelationshipParty {
  const RelationshipParty({
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
  final AccountStatus? status;

  String get fullName => [firstName, middleName, lastName]
      .where((s) => (s ?? '').isNotEmpty)
      .join(' ');

  factory RelationshipParty.fromJson(Map<String, dynamic> json) =>
      RelationshipParty(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        middleName: json['middleName'] as String?,
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        status: json['status'] != null
            ? AccountStatusX.fromApiValue(json['status'] as String)
            : null,
      );
}

class Relationship {
  const Relationship({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.relationshipType,
    required this.status,
    this.createdAt,
    this.verifiedAt,
    this.parent,
    this.student,
  });

  final String id;
  final String parentId;
  final String studentId;
  final RelationshipType relationshipType;
  final RelationshipStatus status;
  final DateTime? createdAt;

  /// When an admin approved or rejected this link (`verifiedAt` on
  /// `ParentStudentRelationship`). Null while still PENDING.
  final DateTime? verifiedAt;

  /// Joined parent/student profile data, present on both
  /// `GET /admin/relationships` and `.../relationships/pending`.
  final RelationshipParty? parent;
  final RelationshipParty? student;

  /// Returns a copy with [status] swapped out (everything else unchanged).
  /// Used after an approve/reject decision so the row can be updated in
  /// place in a list instead of being removed from it.
  Relationship copyWith({RelationshipStatus? status, DateTime? verifiedAt}) {
    return Relationship(
      id: id,
      parentId: parentId,
      studentId: studentId,
      relationshipType: relationshipType,
      status: status ?? this.status,
      createdAt: createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      parent: parent,
      student: student,
    );
  }

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
        id: json['id'] as String,
        parentId: json['parentId'] as String,
        studentId: json['studentId'] as String,
        relationshipType:
            relationshipTypeFromApiValue(json['relationshipType'] as String? ?? 'OTHER'),
        status: relationshipStatusFromApiValue(json['status'] as String? ?? 'PENDING'),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.tryParse(json['verifiedAt'] as String)
            : null,
        parent: json['parent'] is Map<String, dynamic>
            ? RelationshipParty.fromJson(json['parent'] as Map<String, dynamic>)
            : null,
        student: json['student'] is Map<String, dynamic>
            ? RelationshipParty.fromJson(json['student'] as Map<String, dynamic>)
            : null,
      );
}