import 'account_status.dart';
import 'gender.dart';
import 'user_role.dart';

/// Represents the authenticated user. Field presence intentionally varies
/// by endpoint since the backend uses different Prisma `select`s:
///
/// - `POST /auth/login` -> id, studentId, firstName, middleName, lastName,
///   email, role  (see `loginUser` in `auth.service.ts` — no status/DOB/gender)
/// - `GET /auth/me` -> id, studentId, firstName, middleName, lastName,
///   dateOfBirth, gender, email, role, status (`getUserProfile`)
/// - `POST /auth/register/*` -> id, firstName, middleName, lastName,
///   dateOfBirth, gender, email, role, status, createdAt
///   (`registerUser` in `registration.service.ts`)
///
/// All of the above are handled by [User.fromJson] via nullable fields.
class User {
  const User({
    required this.id,
    this.studentId,
    this.schoolCode,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.dateOfBirth,
    this.gender,
    required this.role,
    this.status,
    this.createdAt,
  });

  final String id;
  final String? studentId;
  final String? schoolCode;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final UserRole role;
  final AccountStatus? status;
  final DateTime? createdAt;

  String get fullName =>
      [firstName, middleName, lastName].where((s) => (s ?? '').isNotEmpty).join(' ');

  /// Returns a copy with [status] swapped out (everything else unchanged).
  /// Used after an approve/reject decision so the row can be updated in
  /// place in a list instead of being removed from it.
  User copyWith({AccountStatus? status}) {
    return User(
      id: id,
      studentId: studentId,
      schoolCode: schoolCode,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender,
      role: role,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      studentId: json['studentId'] as String?,
      schoolCode: json['schoolCode'] as String?,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender:
          json['gender'] != null ? GenderX.fromApiValue(json['gender'] as String) : null,
      role: userRoleFromApiValue(json['role'] as String),
      status: json['status'] != null
          ? AccountStatusX.fromApiValue(json['status'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
