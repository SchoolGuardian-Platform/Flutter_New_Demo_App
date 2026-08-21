import { Request, Response, NextFunction } from "express";
import { SchoolManagementService } from "../service/schoolManagement.service";

export const getClassesController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const classes = await SchoolManagementService.getClasses();
    res.status(200).json({
      status: "success",
      data: classes,
    });
  } catch (error) {
    next(error);
  }
};

export const getSubjectsController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const subjects = await SchoolManagementService.getSubjects();
    res.status(200).json({
      status: "success",
      data: subjects,
    });
  } catch (error) {
    next(error);
  }
};

export const createClassController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const cls = await SchoolManagementService.createClass(req.body);
    res.status(201).json({
      status: "success",
      message: "Class processed successfully.",
      data: cls,
    });
  } catch (error) {
    next(error);
  }
};

export const createSubjectController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const subject = await SchoolManagementService.createSubject(req.body);
    res.status(201).json({
      status: "success",
      message: "Subject processed successfully.",
      data: subject,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteClassController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const id = req.params.id as string;
    await SchoolManagementService.deleteClass(id);
    res.status(200).json({
      status: "success",
      message: "Class deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};

export const deleteSubjectController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const id = req.params.id as string;
    await SchoolManagementService.deleteSubject(id);
    res.status(200).json({
      status: "success",
      message: "Subject deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};

export const assignStudentController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const assignment = await SchoolManagementService.assignStudentToClass(req.body);
    res.status(200).json({
      status: "success",
      message: "Student assigned to class successfully.",
      data: assignment,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteStudentAssignmentController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const id = req.params.id as string;
    await SchoolManagementService.deleteStudentAssignment(id);
    res.status(200).json({
      status: "success",
      message: "Student assignment deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};

export const assignTeacherController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const assignment = await SchoolManagementService.assignTeacherToClass(req.body);
    res.status(200).json({
      status: "success",
      message: "Teacher assigned to class subject successfully.",
      data: assignment,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteTeacherAssignmentController = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const id = req.params.id as string;
    await SchoolManagementService.deleteTeacherAssignment(id);
    res.status(200).json({
      status: "success",
      message: "Teacher assignment deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};
