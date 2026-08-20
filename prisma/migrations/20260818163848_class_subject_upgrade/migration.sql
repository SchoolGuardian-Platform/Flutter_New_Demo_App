/*
  Warnings:

  - You are about to drop the `TeacherStudent` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "TeacherStudent" DROP CONSTRAINT "TeacherStudent_studentId_fkey";

-- DropForeignKey
ALTER TABLE "TeacherStudent" DROP CONSTRAINT "TeacherStudent_teacherId_fkey";

-- DropTable
DROP TABLE "TeacherStudent";

-- CreateTable
CREATE TABLE "Class" (
    "id" TEXT NOT NULL,
    "grade" INTEGER NOT NULL,
    "section" TEXT NOT NULL,

    CONSTRAINT "Class_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subject" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "Subject_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StudentClass" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "classId" TEXT NOT NULL,
    "academicYear" TEXT,

    CONSTRAINT "StudentClass_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TeacherClassSubject" (
    "id" TEXT NOT NULL,
    "teacherId" TEXT NOT NULL,
    "classId" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "academicYear" TEXT,

    CONSTRAINT "TeacherClassSubject_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Class_grade_section_key" ON "Class"("grade", "section");

-- CreateIndex
CREATE UNIQUE INDEX "Subject_name_key" ON "Subject"("name");

-- CreateIndex
CREATE INDEX "StudentClass_studentId_idx" ON "StudentClass"("studentId");

-- CreateIndex
CREATE INDEX "StudentClass_classId_idx" ON "StudentClass"("classId");

-- CreateIndex
CREATE UNIQUE INDEX "StudentClass_studentId_classId_key" ON "StudentClass"("studentId", "classId");

-- CreateIndex
CREATE INDEX "TeacherClassSubject_teacherId_idx" ON "TeacherClassSubject"("teacherId");

-- CreateIndex
CREATE INDEX "TeacherClassSubject_classId_idx" ON "TeacherClassSubject"("classId");

-- CreateIndex
CREATE INDEX "TeacherClassSubject_subjectId_idx" ON "TeacherClassSubject"("subjectId");

-- CreateIndex
CREATE UNIQUE INDEX "TeacherClassSubject_teacherId_classId_subjectId_key" ON "TeacherClassSubject"("teacherId", "classId", "subjectId");

-- AddForeignKey
ALTER TABLE "StudentClass" ADD CONSTRAINT "StudentClass_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StudentClass" ADD CONSTRAINT "StudentClass_classId_fkey" FOREIGN KEY ("classId") REFERENCES "Class"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeacherClassSubject" ADD CONSTRAINT "TeacherClassSubject_teacherId_fkey" FOREIGN KEY ("teacherId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeacherClassSubject" ADD CONSTRAINT "TeacherClassSubject_classId_fkey" FOREIGN KEY ("classId") REFERENCES "Class"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeacherClassSubject" ADD CONSTRAINT "TeacherClassSubject_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject"("id") ON DELETE CASCADE ON UPDATE CASCADE;
