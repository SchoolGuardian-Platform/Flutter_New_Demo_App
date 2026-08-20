import { PrismaClient, Role, AccountStatus, RelationshipType, RelationshipStatus } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding test users and relationships for SchoolGuardian...");

  const passwordHash = await bcrypt.hash("Password123!", 10);

  // 1. Create Admin
  const admin = await prisma.user.upsert({
    where: { email: "admin@schoolguardian.com" },
    update: {},
    create: {
      firstName: "Admin",
      lastName: "User",
      email: "admin@schoolguardian.com",
      passwordHash,
      role: Role.ADMIN,
      status: AccountStatus.ACTIVE,
    },
  });

  // 2. Create Active Student (Sara)
  const studentSara = await prisma.user.upsert({
    where: { email: "sara@student.com" },
    update: {},
    create: {
      firstName: "Sara",
      lastName: "Student",
      dateOfBirth: new Date("2012-05-18"),
      gender: "FEMALE",
      studentId: "SG-2026-000001",
      email: "sara@student.com",
      passwordHash,
      role: Role.STUDENT,
      status: AccountStatus.ACTIVE,
    },
  });

  // 3. Create Pending Student (Daniel)
  await prisma.user.upsert({
    where: { email: "daniel@student.com" },
    update: {},
    create: {
      firstName: "Daniel",
      lastName: "Pending",
      dateOfBirth: new Date("2013-09-10"),
      gender: "MALE",
      email: "daniel@student.com",
      passwordHash,
      role: Role.STUDENT,
      status: AccountStatus.PENDING,
    },
  });

  // 4. Create Guardian 1 (Mother)
  const mother = await prisma.user.upsert({
    where: { email: "mother@parent.com" },
    update: {},
    create: {
      firstName: "Mother",
      lastName: "Parent",
      email: "mother@parent.com",
      passwordHash,
      role: Role.PARENT,
      status: AccountStatus.ACTIVE,
    },
  });

  // 5. Create Guardian 2 (Father)
  const father = await prisma.user.upsert({
    where: { email: "father@parent.com" },
    update: {},
    create: {
      firstName: "Father",
      lastName: "Parent",
      email: "father@parent.com",
      passwordHash,
      role: Role.PARENT,
      status: AccountStatus.ACTIVE,
    },
  });

  // 6. Seed Guardian 1 Relationship (Mother -> Sara, APPROVED)
  await prisma.parentStudentRelationship.upsert({
    where: {
      parentId_studentId_relationshipType: {
        parentId: mother.id,
        studentId: studentSara.id,
        relationshipType: RelationshipType.MOTHER,
      },
    },
    update: { status: RelationshipStatus.APPROVED },
    create: {
      parentId: mother.id,
      studentId: studentSara.id,
      relationshipType: RelationshipType.MOTHER,
      status: RelationshipStatus.APPROVED,
      verifiedBy: admin.id,
      verifiedAt: new Date(),
    },
  });

  // 7. Seed Guardian 2 Relationship (Father -> Sara, PENDING approval)
  await prisma.parentStudentRelationship.upsert({
    where: {
      parentId_studentId_relationshipType: {
        parentId: father.id,
        studentId: studentSara.id,
        relationshipType: RelationshipType.FATHER,
      },
    },
    update: {},
    create: {
      parentId: father.id,
      studentId: studentSara.id,
      relationshipType: RelationshipType.FATHER,
      status: RelationshipStatus.PENDING,
    },
  });

  console.log("Database seed completed successfully.");
}

main()
  .catch((e) => {
    console.error("Seeding error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
