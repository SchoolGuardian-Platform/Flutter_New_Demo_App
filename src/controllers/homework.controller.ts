import { Request, Response, NextFunction } from "express";
import { HomeworkService } from "../service/homework.service";

export async function createHomeworkController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homework = await HomeworkService.createHomework(req.user!.id, req.body);
    res.status(201).json({ status: "success", data: homework, homework, message: "Homework created successfully." });
  } catch (error) {
    next(error);
  }
}

export async function getMyHomeworkController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homeworks = await HomeworkService.getMyHomework(req.user!.id);
    res.status(200).json({ status: "success", data: homeworks, homeworks });
  } catch (error) {
    next(error);
  }
}

export async function getHomeworkByIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homework = await HomeworkService.getHomeworkById(req.params.id as string, {
      id: req.user!.id,
      role: req.user!.role,
    });
    res.status(200).json({ status: "success", data: homework, homework });
  } catch (error) {
    next(error);
  }
}

export async function getHomeworksByStudentIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homeworks = await HomeworkService.getHomeworksByStudentId(req.params.studentId as string, {
      id: req.user!.id,
      role: req.user!.role,
    });
    res.status(200).json({ status: "success", data: homeworks, homeworks });
  } catch (error) {
    next(error);
  }
}

export async function getHomeworksByClassIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homeworks = await HomeworkService.getHomeworksByClassId(req.params.classId as string);
    res.status(200).json({ status: "success", data: homeworks, homeworks });
  } catch (error) {
    next(error);
  }
}

export async function getHomeworksByTeacherController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homeworks = await HomeworkService.getHomeworksByTeacher(req.user!.id);
    res.status(200).json({ status: "success", data: homeworks, homeworks });
  } catch (error) {
    next(error);
  }
}

export async function updateHomeworkController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const homework = await HomeworkService.updateHomework(req.params.id as string, req.user!.id, req.body);
    res.status(200).json({ status: "success", data: homework, homework, message: "Homework updated successfully." });
  } catch (error) {
    next(error);
  }
}

export async function deleteHomeworkController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await HomeworkService.deleteHomework(req.params.id as string, req.user!.id);
    res.status(200).json({ status: "success", message: "Homework deleted successfully." });
  } catch (error) {
    next(error);
  }
}
