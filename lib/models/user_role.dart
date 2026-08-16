import 'package:flutter/material.dart';

enum UserRole { parent, student, teacher, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.parent:
        return 'Parent/Guardian';
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher/Guidance';
      case UserRole.admin:
        return 'School Admin';
    }
  }

  String get ctaLabel {
    switch (this) {
      case UserRole.parent:
        return 'Continue as Parent';
      case UserRole.student:
        return 'Continue as Student';
      case UserRole.teacher:
        return 'Continue as Teacher';
      case UserRole.admin:
        return 'Continue as Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.parent:
        return "Monitor, support, and stay connected with your child's educational journey and safety updates.";
      case UserRole.student:
        return 'Access your learning resources, track wellbeing, and connect securely with your teachers.';
      case UserRole.teacher:
        return 'Support students, communicate with parents, and manage classroom safety protocols.';
      case UserRole.admin:
        return 'Manage students, staff, security alerts, and oversee institution-wide operations.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.parent:
        return Icons.family_restroom;
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.teacher:
        return Icons.menu_book_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  /// Whether this role signs up through a self-serve form. Admin accounts
  /// are provisioned by the institution, so there is no admin sign-up page.
  bool get hasSignUp => this != UserRole.admin;

  /// Exact string the backend uses for `enum Role` (`prisma/schema.prisma`)
  /// and returns on `User.role` (login, /auth/me, registration responses).
  String get apiValue {
    switch (this) {
      case UserRole.parent:
        return 'PARENT';
      case UserRole.student:
        return 'STUDENT';
      case UserRole.teacher:
        return 'TEACHER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }
}

/// Parses the `role` string returned by the backend into a [UserRole].
/// Throws if the backend sends something this build doesn't recognize
/// (e.g. a role added on the backend that the app hasn't been updated
/// for) -- callers that read backend data (like `User.fromJson`) should
/// make sure this can't fail silently; see the `catch (e)` block in
/// `pending_approvals_page.dart` for why that matters.
UserRole userRoleFromApiValue(String value) {
  switch (value) {
    case 'PARENT':
      return UserRole.parent;
    case 'STUDENT':
      return UserRole.student;
    case 'TEACHER':
      return UserRole.teacher;
    case 'ADMIN':
      return UserRole.admin;
    default:
      throw ArgumentError('Unknown role value from API: "$value"');
  }
}
