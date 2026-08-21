import express, { Application } from "express";
import cors from "cors";
import authRoutes from "./routes/auth.routes";
import adminRoutes from "./routes/admin.routes";
import parentRoutes from "./routes/parent.routes";
import studentRoutes from "./routes/student.routes";
import attendanceRoutes from "./routes/attendance.routes";
import schoolManagementRoutes from "./routes/schoolManagement.routes";
import gradeRoutes from "./routes/grade.routes";
import homeworkRoutes from "./routes/homework.routes";
import teacherNoteRoutes from "./routes/teacherNote.routes";
import communicationRoutes from "./routes/communication.routes";
import appointmentRoutes from "./routes/appointment.routes";
import wellbeingRoutes from "./routes/wellbeing.routes";
import { errorHandler } from "./middleware/error.middleware";

const app: Application = express();

// Trust proxy for rate limiting if behind reverse proxy
app.set("trust proxy", 1);

// Standard security & parsing middleware
app.use(cors());
app.use(express.json());

// Mount Routers
app.use("/auth", authRoutes);
app.use("/api/auth", authRoutes);

app.use("/admin", adminRoutes);
app.use("/api/admin", adminRoutes);

app.use("/parents", parentRoutes);
app.use("/api/parents", parentRoutes);

app.use("/students", studentRoutes);
app.use("/api/students", studentRoutes);

app.use("/attendance", attendanceRoutes);
app.use("/api/attendance", attendanceRoutes);

app.use("/grades", gradeRoutes);
app.use("/api/grades", gradeRoutes);
app.use("/api/admin/school", schoolManagementRoutes);

app.use("/homework", homeworkRoutes);
app.use("/api/homework", homeworkRoutes);

app.use("/teacher-notes", teacherNoteRoutes);
app.use("/api/teacher-notes", teacherNoteRoutes);
app.use("/communication", communicationRoutes);
app.use("/api/communication", communicationRoutes);

app.use("/api/appointments", appointmentRoutes);

app.use("/wellbeing", wellbeingRoutes);
app.use("/api/wellbeing", wellbeingRoutes);

// Global Error Handler
app.use(errorHandler);

export default app;
