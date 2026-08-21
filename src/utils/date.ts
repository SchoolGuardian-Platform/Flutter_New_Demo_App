/**
 * Calculates current age from date of birth dynamically.
 * Do not permanently store age in DB.
 */
export function calculateAge(dateOfBirth: Date): number {
  const today = new Date();
  let age = today.getFullYear() - dateOfBirth.getFullYear();
  const monthDiff = today.getMonth() - dateOfBirth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dateOfBirth.getDate())) {
    age--;
  }
  return age;
}

/**
 * Generates a unique Student ID during Admin approval workflow.
 * Example format: SG-2026-000123
 */
export function generateStudentId(sequenceNumber: number): string {
  const year = new Date().getFullYear();
  const paddedSeq = String(sequenceNumber).padStart(6, "0");
  return `SG-${year}-${paddedSeq}`;
}
