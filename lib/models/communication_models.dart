import 'package:flutter/material.dart';
import 'user_role.dart';

/// Communication Channel Specification with Strict Role-Based Visibility
class PrivateChannel {
  PrivateChannel({
    required this.id,
    required this.channelTitle,
    required this.subtitle,
    required this.icon,
    required this.participantName,
    required this.participantRole,
    required this.allowedRoles,
    required this.messages,
    this.unreadCount = 0,
  });

  final String id;
  final String channelTitle;
  final String subtitle;
  final IconData icon;
  final String participantName;
  final String participantRole;
  final List<UserRole> allowedRoles;
  final List<ChatMessage> messages;
  int unreadCount;
}

/// Matches Prisma `Message` Schema:
/// model Message {
///   id         String   @id @default(uuid())
///   senderId   String
///   receiverId String
///   content    String   @db.Text
///   isRead     Boolean  @default(false)
///   createdAt  DateTime @default(now())
/// }
class ChatMessage {
  ChatMessage({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestampText,
    required this.isMe,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String? senderId;
  final String? receiverId;
  final String senderName;
  final String senderRole;
  final String content;
  final String timestampText;
  final bool isMe;
  final bool isRead;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderObj = json['sender'] is Map ? json['sender'] as Map<String, dynamic> : null;
    final senderName = senderObj != null
        ? '${senderObj['firstName'] ?? ''} ${senderObj['lastName'] ?? ''}'.trim()
        : (json['senderName'] ?? 'User');
    final senderRole = senderObj != null ? (senderObj['role'] ?? '') : (json['senderRole'] ?? '');
    final senderId = json['senderId']?.toString() ?? '';
    final createdAtRaw = json['createdAt']?.toString();
    final createdAt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: senderId,
      receiverId: json['receiverId']?.toString(),
      senderName: senderName.isEmpty ? 'User' : senderName,
      senderRole: senderRole,
      content: json['content']?.toString() ?? '',
      timestampText: createdAt != null ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}' : 'Just now',
      isMe: senderId == currentUserId,
      isRead: json['isRead'] == true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'senderName': senderName,
        'senderRole': senderRole,
        'content': content,
        'timestampText': timestampText,
        'isMe': isMe,
        'isRead': isRead,
        'createdAt': createdAt?.toIso8601String(),
      };
}
