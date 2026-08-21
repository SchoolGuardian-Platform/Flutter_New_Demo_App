import { Request, Response, NextFunction } from "express";
import { AttendanceService } from "../service/attendance.service";

export async function createAttendanceController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const attendance = await AttendanceService.createAttendance(req.user!.id, req.body);
    res.status(201).json({ message: "Attendance recorded successfully.", attendance });
  } catch (error) {
    next(error);
  }
}

export async function getAttendanceByIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const attendance = await AttendanceService.getAttendanceById(req.params.id as string, { id: req.user!.id, role: req.user!.role });
    res.json({ attendance });
  } catch (error) {
    next(error);
  }
}

export async function getAttendanceByStudentIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const attendance = await AttendanceService.getAttendanceByStudentId(req.params.studentId as string);
    res.json({ attendance });
  } catch (error) {
    next(error);
  }
}

export async function getAttendanceSummaryController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const summary = await AttendanceService.getAttendanceSummary(req.params.studentId as string);
    res.json({ summary });
  } catch (error) {
    next(error);
  }
}

export async function getAttendanceByTeacherController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const attendance = await AttendanceService.getAttendanceByTeacher(req.user!.id);
    res.json({ attendance });
  } catch (error) {
    next(error);
  }
}

export async function updateAttendanceController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const attendance = await AttendanceService.updateAttendance(req.params.id as string, req.user!.id, req.body);
    res.json({ message: "Attendance updated successfully.", attendance });
  } catch (error) {
    next(error);
  }
}

export async function deleteAttendanceController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await AttendanceService.deleteAttendance(req.params.id as string, req.user!.id);
    res.json({ message: "Attendance deleted successfully." });
  } catch (error) {
    next(error);
  }
}

export async function getGlobalAttendanceReportController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { startDate, endDate } = req.query;
    const report = await AttendanceService.getGlobalAttendanceReport(
      startDate as string | undefined, 
      endDate as string | undefined
    );
    res.json({ report });
  } catch (error) {
    next(error);
  }
}
