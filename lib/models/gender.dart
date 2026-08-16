/// Mirrors `enum Gender` in `prisma/schema.prisma`.
enum Gender { male, female, other, preferNotToSay }

extension GenderX on Gender {
  /// Exact string the backend expects/returns (Zod `GenderEnum` in
  /// `auth.validator.ts`, Prisma enum in `schema.prisma`).
  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
      case Gender.other:
        return 'OTHER';
      case Gender.preferNotToSay:
        return 'PREFER_NOT_TO_SAY';
    }
  }

  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  static Gender fromApiValue(String value) {
    switch (value) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      case 'OTHER':
        return Gender.other;
      case 'PREFER_NOT_TO_SAY':
        return Gender.preferNotToSay;
      default:
        throw ArgumentError('Unknown gender value from API: $value');
    }
  }
}
