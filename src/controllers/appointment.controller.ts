import { Request, Response, NextFunction } from "express";
import { AppointmentService } from "../service/appointment.service";
import { 
  CreateSlotInput, 
  BookAppointmentInput, 
  UpdateAppointmentStatusInput 
} from "../validators/appointment.validator";


export const createSlotController = async (req: Request<{}, {}, CreateSlotInput>, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.user!.id;
    const slot = await AppointmentService.createSlot(teacherId, req.body);
    return res.status(201).json({ data: slot, message: "Appointment slot created successfully." });
  } catch (error) {
    next(error);
  }
};

export const closeSlotController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.user!.id;
    const slotId = req.params.slotId as string;
    const slot = await AppointmentService.closeSlot(slotId, teacherId);
    return res.status(200).json({ data: slot, message: "Appointment slot closed successfully." });
  } catch (error) {
    next(error);
  }
};

export const getTeacherAppointmentsController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.user!.id;
    const appointments = await AppointmentService.getTeacherAppointments(teacherId);
    return res.status(200).json({ data: appointments, message: "Appointments retrieved successfully." });
  } catch (error) {
    next(error);
  }
};

export const updateAppointmentStatusController = async (req: Request<{ appointmentId: string }, {}, UpdateAppointmentStatusInput>, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.user!.id;
    const appointmentId = req.params.appointmentId as string;
    const appointment = await AppointmentService.updateAppointmentStatus(appointmentId, teacherId, req.body.status);
    return res.status(200).json({ data: appointment, message: "Appointment status updated successfully." });
  } catch (error) {
    next(error);
  }
};


export const getAvailableSlotsController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.params.teacherId as string;
    const slots = await AppointmentService.getAvailableSlots(teacherId);
    return res.status(200).json({ data: slots, message: "Available slots retrieved successfully." });
  } catch (error) {
    next(error);
  }
};

export const bookAppointmentController = async (req: Request<{}, {}, BookAppointmentInput>, res: Response, next: NextFunction) => {
  try {
    const parentId = req.user!.id;
    const appointment = await AppointmentService.bookAppointment(parentId, req.body);
    return res.status(201).json({ data: appointment, message: "Appointment booked successfully." });
  } catch (error) {
    next(error);
  }
};

export const cancelAppointmentController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const parentId = req.user!.id;
    const appointmentId = req.params.appointmentId as string;
    const appointment = await AppointmentService.cancelAppointment(appointmentId, parentId);
    return res.status(200).json({ data: appointment, message: "Appointment cancelled successfully." });
  } catch (error) {
    next(error);
  }
};

export const getParentAppointmentsController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const parentId = req.user!.id;
    const appointments = await AppointmentService.getParentAppointments(parentId);
    return res.status(200).json({ data: appointments, message: "Appointments retrieved successfully." });
  } catch (error) {
    next(error);
  }
};
