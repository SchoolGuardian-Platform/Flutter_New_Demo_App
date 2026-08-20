import { PrismaClient, Role, AccountStatus } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash("admin123", 10); //[cite: 2]

  const admin = await prisma.user.upsert({
    where: { email: "admin@gmail.com" }, //[cite: 2]
    update: {
      passwordHash, //[cite: 2]
      role: Role.ADMIN, //[cite: 2]
      status: AccountStatus.ACTIVE, //[cite: 2]
      middleName: "Admin",
      gender: "MALE",
      phoneNumber: "+0000000000",
    },
    create: {
      firstName: "Admin", //[cite: 2]
      middleName: "Admin",
      lastName: "User", //[cite: 2]
      gender: "MALE",
      phoneNumber: "+0000000000",
      email: "admin@gmail.com", //[cite: 2]
      passwordHash, //[cite: 2]
      role: Role.ADMIN, //[cite: 2]
      status: AccountStatus.ACTIVE, //[cite: 2]
    },
  });

  console.log("Admin ready:", admin.email); //[cite: 2]
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });