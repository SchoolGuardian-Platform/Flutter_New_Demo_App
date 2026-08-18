import { prisma } from "../utils/prisma";
import { CreateSlotInput, BookAppointmentInput, UpdateAppointmentStatusInput } from "../validators/appointment.validator";
import { BadRequestError, NotFoundError, UnauthorizedError } from "../utils/errors";
import { AppointmentStatus, RelationshipStatus } from "@prisma/client";

export class AppointmentService {
  // ==========================================
  // TEACHER METHODS
  // ==========================================

  static async createSlot(teacherId: string, data: CreateSlotInput) {
    const dateObj = new Date(data.date);
    if (isNaN(dateObj.getTime())) {
      throw new BadRequestError("Invalid date.");
    }

    return prisma.appointmentSlot.create({
      data: {
        teacherId,
        date: dateObj,
        startTime: data.startTime,
        endTime: data.endTime,
      },
    });
  }

  static async closeSlot(slotId: string, teacherId: string) {
    const slot = await prisma.appointmentSlot.findUnique({ where: { id: slotId } });
    if (!slot) throw new NotFoundError("Appointment slot not found.");
    if (slot.teacherId !== teacherId) throw new UnauthorizedError("You do not own this slot.");

    return prisma.appointmentSlot.update({
      where: { id: slotId },
      data: { isClosed: true },
    });
  }

  static async getTeacherAppointments(teacherId: string) {
    return prisma.appointment.findMany({
      where: {
        slot: {
          teacherId,
        },
      },
      include: {
        slot: true,
        parent: { select: { id: true, firstName: true, lastName: true, email: true, phoneNumber: true } },
        student: { select: { id: true, firstName: true, lastName: true } },
      },
      orderBy: {
        slot: { date: "asc" },
      },
    });
  }

  static async updateAppointmentStatus(appointmentId: string, teacherId: string, status: AppointmentStatus) {
    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: { slot: true },
    });

    if (!appointment) throw new NotFoundError("Appointment not found.");
    if (appointment.slot.teacherId !== teacherId) throw new UnauthorizedError("You do not own this appointment.");

    return prisma.appointment.update({
      where: { id: appointmentId },
      data: { status },
    });
  }

  // ==========================================
  // PARENT METHODS
  // ==========================================

  static async getAvailableSlots(teacherId: string) {
    // A slot is available if it is not closed and has less than 2 active appointments
    const slots = await prisma.appointmentSlot.findMany({
      where: {
        teacherId,
        isClosed: false,
        date: { gte: new Date() }, // Only future or today slots
      },
      include: {
        appointments: {
          where: {
            status: { in: [AppointmentStatus.PENDING, AppointmentStatus.ACCEPTED] },
          },
        },
      },
      orderBy: [
        { date: "asc" },
        { startTime: "asc" }
      ]
    });

    // Filter slots by capacity (max 2)
    return slots.filter((slot) => slot.appointments.length < 2).map(slot => {
      const { appointments, ...slotData } = slot;
      return {
        ...slotData,
        availableCapacity: 2 - appointments.length
      };
    });
  }

  static async bookAppointment(parentId: string, data: BookAppointmentInput) {
    const slot = await prisma.appointmentSlot.findUnique({
      where: { id: data.slotId },
      include: {
        appointments: {
          where: {
            status: { in: [AppointmentStatus.PENDING, AppointmentStatus.ACCEPTED] },
          },
        },
      },
    });

    if (!slot) throw new NotFoundError("Appointment slot not found.");
    if (slot.isClosed) throw new BadRequestError("This slot is closed.");
    if (slot.appointments.length >= 2) throw new BadRequestError("This slot is fully booked.");

    // Verify parent-student relationship
    const relationship = await prisma.parentStudentRelationship.findFirst({
      where: {
        parentId,
        studentId: data.studentId,
        status: RelationshipStatus.APPROVED,
      },
    });

    if (!relationship) {
      throw new UnauthorizedError("You do not have an approved relationship with this student.");
    }

    // Verify teacher-student relationship
    const assignment = await prisma.teacherClassSubject.findFirst({
      where: {
        teacherId: slot.teacherId,
        class: {
          students: {
            some: { studentId: data.studentId }
          }
        }
      },
    });

    if (!assignment) {
      throw new UnauthorizedError("This teacher does not teach this student.");
    }

    // Check if this specific parent already booked this slot for this student
    const existingBooking = slot.appointments.find(
      (appt) => appt.parentId === parentId && appt.studentId === data.studentId
    );
    if (existingBooking) {
      throw new BadRequestError("You have already booked this slot for this student.");
    }

    return prisma.appointment.create({
      data: {
        slotId: data.slotId,
        parentId,
        studentId: data.studentId,
        reason: data.reason,
      },
      include: {
        slot: true,
      }
    });
  }

  static async cancelAppointment(appointmentId: string, parentId: string) {
    const appointment = await prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment) throw new NotFoundError("Appointment not found.");
    if (appointment.parentId !== parentId) throw new UnauthorizedError("You do not own this appointment.");
    if (appointment.status === AppointmentStatus.CANCELLED_BY_PARENT) {
       throw new BadRequestError("Appointment is already cancelled.");
    }

    return prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.CANCELLED_BY_PARENT },
    });
  }

  static async getParentAppointments(parentId: string) {
    return prisma.appointment.findMany({
      where: { parentId },
      include: {
        slot: {
          include: {
            teacher: { select: { id: true, firstName: true, lastName: true } }
          }
        },
        student: { select: { id: true, firstName: true, lastName: true } },
      },
      orderBy: {
        createdAt: "desc",
      },
    });
  }
}
