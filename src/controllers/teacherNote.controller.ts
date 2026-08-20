import { Request, Response, NextFunction } from "express";
import { TeacherNoteService } from "../service/teacherNote.service";

export async function createTeacherNoteController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const note = await TeacherNoteService.createTeacherNote(req.user!.id, req.body);
    res.status(201).json({ message: "Teacher note created successfully.", note });
  } catch (error) {
    next(error);
  }
}

export async function getTeacherNoteByIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const note = await TeacherNoteService.getTeacherNoteById(req.params.id as string, {
      id: req.user!.id,
      role: req.user!.role,
    });
    res.status(200).json({ note });
  } catch (error) {
    next(error);
  }
}

export async function getTeacherNotesByStudentIdController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const notes = await TeacherNoteService.getTeacherNotesByStudentId(req.params.studentId as string, {
      id: req.user!.id,
      role: req.user!.role,
    });
    res.status(200).json({ notes });
  } catch (error) {
    next(error);
  }
}

export async function getTeacherNotesByTeacherController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const notes = await TeacherNoteService.getTeacherNotesByTeacher(req.user!.id);
    res.status(200).json({ notes });
  } catch (error) {
    next(error);
  }
}

export async function updateTeacherNoteController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const note = await TeacherNoteService.updateTeacherNote(req.params.id as string, req.user!.id, req.body);
    res.status(200).json({ message: "Teacher note updated successfully.", note });
  } catch (error) {
    next(error);
  }
}

export async function deleteTeacherNoteController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await TeacherNoteService.deleteTeacherNote(req.params.id as string, req.user!.id);
    res.status(200).json({ message: "Teacher note deleted successfully." });
  } catch (error) {
    next(error);
  }
}
