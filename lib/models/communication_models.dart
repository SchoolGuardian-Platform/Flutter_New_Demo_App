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

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestampText,
    required this.isMe,
  });

  final String id;
  final String senderName;
  final String senderRole;
  final String content;
  final String timestampText;
  final bool isMe;
}
