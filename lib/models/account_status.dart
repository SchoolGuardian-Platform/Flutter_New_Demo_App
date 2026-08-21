/// Mirrors `enum AccountStatus` in `prisma/schema.prisma`.
///
/// New registrations start as [unverified] and move to [pending] once the
/// email is confirmed (see `registration.service.ts` /
/// `emailVerification.service.ts`). Login only succeeds for [active]
/// accounts — the backend returns a specific message for each non-active
/// state (`auth.service.ts` `loginUser`): a distinct "not verified" message
/// for [unverified], "pending Admin approval" for [pending], and a generic
/// "inactive" message for [rejected]/[suspended] (those two are not
/// distinguished from each other in the login response).
enum AccountStatus { unverified, pending, active, rejected, suspended }

extension AccountStatusX on AccountStatus {
  String get apiValue {
    switch (this) {
      case AccountStatus.unverified:
        return 'UNVERIFIED';
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
      case 'UNVERIFIED':
        return AccountStatus.unverified;
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