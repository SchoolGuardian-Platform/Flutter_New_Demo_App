import { prisma } from "../utils/prisma";
import { Role, RelationshipStatus } from "@prisma/client";
import { UnauthorizedError, NotFoundError } from "../utils/errors";

export class MessageService {
  /**
   * Checks if two users have a valid legal connection to message each other.
   */
  static async canMessage(userAId: string, userBId: string): Promise<boolean> {
    const userA = await prisma.user.findUnique({ where: { id: userAId } });
    const userB = await prisma.user.findUnique({ where: { id: userBId } });

    if (!userA || !userB) return false;

    // Admins can message anyone
    if (userA.role === Role.ADMIN || userB.role === Role.ADMIN) return true;

    // Teacher <-> Parent communication
    if (
      (userA.role === Role.TEACHER && userB.role === Role.PARENT) ||
      (userA.role === Role.PARENT && userB.role === Role.TEACHER)
    ) {
      return true;
    }

    return true;
  }

  static async sendMessage(senderId: string, receiverId: string, content: string) {
    const isAllowed = await this.canMessage(senderId, receiverId);
    if (!isAllowed) {
      throw new UnauthorizedError("You do not have permission to message this user.");
    }

    return await prisma.message.create({
      data: {
        senderId,
        receiverId,
        content,
      },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true, role: true } },
      },
    });
  }

  static async getChatHistory(userId1: string, userId2: string) {
    const isAllowed = await this.canMessage(userId1, userId2);
    if (!isAllowed) {
      throw new UnauthorizedError("You do not have permission to view this chat.");
    }

    // Auto mark unread messages from userId2 to userId1 as read
    await prisma.message.updateMany({
      where: {
        senderId: userId2,
        receiverId: userId1,
        isRead: false,
      },
      data: { isRead: true },
    });

    return await prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId1, receiverId: userId2 },
          { senderId: userId2, receiverId: userId1 },
        ],
      },
      orderBy: {
        createdAt: "asc",
      },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true, role: true } },
      },
    });
  }

  static async markAsRead(messageId: string, receiverId: string) {
    const message = await prisma.message.findUnique({ where: { id: messageId } });

    if (!message) {
      throw new NotFoundError("Message not found.");
    }

    if (message.receiverId !== receiverId) {
      throw new UnauthorizedError("You can only mark your own received messages as read.");
    }

    return await prisma.message.update({
      where: { id: messageId },
      data: { isRead: true },
    });
  }

  static async deleteMessage(messageId: string, userId: string) {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) {
      throw new NotFoundError("Message not found.");
    }
    if (message.senderId !== userId && message.receiverId !== userId) {
      throw new UnauthorizedError("You can only delete messages from your conversations.");
    }
    return await prisma.message.delete({ where: { id: messageId } });
  }

  /**
   * Returns the total count of unread messages received by the current user.
   * Used for notification badges in the UI.
   */
  static async getUnreadCount(userId: string): Promise<number> {
    return await prisma.message.count({
      where: {
        receiverId: userId,
        isRead: false,
      },
    });
  }
}
