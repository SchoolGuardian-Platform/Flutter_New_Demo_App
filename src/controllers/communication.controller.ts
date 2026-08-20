import { Request, Response, NextFunction } from "express";
import { CommunicationService } from "../service/communication.service";
import { MessageService } from "../service/message.service";
import { SendMessageInput } from "../validators/communication.validator";
import { NotFoundError } from "../utils/errors";

export const getTeacherStudentsController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.user!.id;
    const query = req.query.q as string | undefined;
    const students = await CommunicationService.getTeacherStudents(teacherId, query);
    return res.status(200).json({ data: students, message: "Teacher's students retrieved." });
  } catch (error) {
    next(error);
  }
};

export const lookupStudentBySchoolIdController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const schoolId = req.params.schoolId as string;
    const student = await CommunicationService.lookupStudentBySchoolId(schoolId);
    if (!student) {
      throw new NotFoundError(`No student found with school ID: ${schoolId}`);
    }
    return res.status(200).json({ data: student, message: "Student found." });
  } catch (error) {
    next(error);
  }
};

export const getStudentTeachersController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const studentId = req.params.studentId as string;
    const teachers = await CommunicationService.getStudentTeachers(studentId);
    return res.status(200).json({ data: teachers, message: "Teachers retrieved successfully." });
  } catch (error) {
    next(error);
  }
};

export const getStudentParentsController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const studentId = req.params.studentId as string;
    const parents = await CommunicationService.getStudentParents(studentId);
    return res.status(200).json({ data: parents, message: "Parents retrieved successfully." });
  } catch (error) {
    next(error);
  }
};

export const sendMessageController = async (req: Request<{}, {}, SendMessageInput>, res: Response, next: NextFunction) => {
  try {
    const senderId = req.user!.id;
    const { receiverId, content } = req.body;

    const message = await MessageService.sendMessage(senderId, receiverId, content);
    
    return res.status(201).json({ data: message, message: "Message sent successfully." });
  } catch (error) {
    next(error);
  }
};

export const getChatHistoryController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId1 = req.user!.id;
    const userId2 = req.params.userId as string;

    const messages = await MessageService.getChatHistory(userId1, userId2);
    
    return res.status(200).json({ data: messages, message: "Chat history retrieved successfully." });
  } catch (error) {
    next(error);
  }
};

export const markAsReadController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const receiverId = req.user!.id;
    const messageId = req.params.messageId as string;

    const message = await MessageService.markAsRead(messageId, receiverId);
    
    return res.status(200).json({ data: message, message: "Message marked as read." });
  } catch (error) {
    next(error);
  }
};

export const deleteMessageController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const messageId = req.params.messageId as string;

    await MessageService.deleteMessage(messageId, userId);
    
    return res.status(200).json({ message: "Message deleted successfully." });
  } catch (error) {
    next(error);
  }
};

export const getUnreadCountController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const count = await MessageService.getUnreadCount(userId);
    return res.status(200).json({ data: { unreadCount: count }, message: "Unread count retrieved." });
  } catch (error) {
    next(error);
  }
};
