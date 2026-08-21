import { Request, Response, NextFunction } from "express";
import { GradeService } from "../service/grade.service";

export async function createGradeController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const grade = await GradeService.createGrade(req.user!.id, req.body);
    res.status(201).json({ message: "Grade recorded successfully.", grade });
  } catch (error) {
    next(error);
  }
}

export async function getGradeByIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const grade = await GradeService.getGradeById(req.params.id as string, { id: req.user!.id, role: req.user!.role });
    res.json({ grade });
  } catch (error) {
    next(error);
  }
}

export async function getGradesByStudentIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const grades = await GradeService.getGradesByStudentId(req.params.studentId as string);
    res.json({ grades });
  } catch (error) {
    next(error);
  }
}

export async function getGradeSummaryController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const summary = await GradeService.getGradeSummary(req.params.studentId as string);
    res.json({ summary });
  } catch (error) {
    next(error);
  }
}

export async function getGradesByTeacherController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const grades = await GradeService.getGradesByTeacher(req.user!.id);
    res.json({ grades });
  } catch (error) {
    next(error);
  }
}

export async function updateGradeController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const grade = await GradeService.updateGrade(req.params.id as string, req.user!.id, req.body);
    res.json({ message: "Grade updated successfully.", grade });
  } catch (error) {
    next(error);
  }
}

export async function deleteGradeController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await GradeService.deleteGrade(req.params.id as string, req.user!.id);
    res.json({ message: "Grade deleted successfully." });
  } catch (error) {
    next(error);
  }
}

export async function getGlobalGradeReportController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { term, academicYear, subject } = req.query;
    const report = await GradeService.getGlobalGradeReport(
      term as string | undefined,
      academicYear as string | undefined,
      subject as string | undefined
    );
    res.json({ report });
  } catch (error) {
    next(error);
  }
}
