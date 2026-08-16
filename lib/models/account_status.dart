/// Mirrors `enum AccountStatus` in `prisma/schema.prisma`.
///
/// New registrations always start as [pending] (see
/// `registration.service.ts`). Login only succeeds for [active] accounts —
/// the backend intentionally returns the same generic "Invalid email or
/// password" error for pending/rejected/suspended accounts (see
/// `auth.service.ts` `loginUser`), so the app cannot distinguish those
/// cases from a login call alone.
enum AccountStatus { pending, active, rejected, suspended }

extension AccountStatusX on AccountStatus {
  String get apiValue {
    switch (this) {
      case AccountStatus.pending:
        return 'PENDING';
      case AccountStatus.active:
        return 'ACTIVE';
      case AccountStatus.rejected:
        return 'REJECTED';
      case AccountStatus.suspended:
        return 'SUSPENDED';
    }
  }

  static AccountStatus fromApiValue(String value) {
    switch (value) {
      case 'PENDING':
        return AccountStatus.pending;
      case 'ACTIVE':
        return AccountStatus.active;
      case 'REJECTED':
        return AccountStatus.rejected;
      case 'SUSPENDED':
        return AccountStatus.suspended;
      default:
        throw ArgumentError('Unknown account status value from API: $value');
    }
  }
}
