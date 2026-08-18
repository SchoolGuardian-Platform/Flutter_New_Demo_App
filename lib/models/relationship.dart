/// A parent↔student guardian-link request awaiting admin verification.
/// Mirrors the `Relationship` schema in `SchoolGuardian_Final_OpenAPI.yaml`
/// and the `/admin/relationships/*` endpoints (`admin.routes.ts`).
///
/// Unlike student/parent/teacher pending accounts, this only carries IDs
/// (no names) — the backend doesn't join in parent/student profile data
/// on this endpoint. [parentId]/[studentId] are shown as-is; a future
/// backend change could enrich this response with names.
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

class Relationship {
  const Relationship({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.relationshipType,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String parentId;
  final String studentId;
  final RelationshipType relationshipType;
  final RelationshipStatus status;
  final DateTime? createdAt;

  /// Returns a copy with [status] swapped out (everything else unchanged).
  /// Used after an approve/reject decision so the row can be updated in
  /// place in a list instead of being removed from it.
  Relationship copyWith({RelationshipStatus? status}) {
    return Relationship(
      id: id,
      parentId: parentId,
      studentId: studentId,
      relationshipType: relationshipType,
      status: status ?? this.status,
      createdAt: createdAt,
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
      );
}
