import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/communication_models.dart';

/// CommunicationService bridges Flutter's Messages portal directly to the Prisma `Message` backend table.
class CommunicationService {
  CommunicationService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  // ──────────────────────────── Contact Discovery ────────────────────────────

  /// Resolve a student's internal UUID (and profile) from their human-readable
  /// school ID like "SG-2026-000001". Returns null if not found.
  Future<Map<String, dynamic>?> lookupStudentBySchoolId(String schoolStudentId) async {
    try {
      final res = await _apiClient.get(
        '/communication/students/by-school-id/$schoolStudentId',
        requireAuth: true,
      );
      final data = res['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('lookupStudentBySchoolId error: $e');
      return null;
    }
  }

  /// Fetch all students in classes the authenticated teacher teaches.
  /// Optionally pass [query] for server-side filtering (name or school ID).
  Future<List<Map<String, dynamic>>> getTeacherStudents({String? query}) async {
    try {
      final path = query != null && query.isNotEmpty
          ? '/communication/my-students?q=${Uri.encodeComponent(query)}'
          : '/communication/my-students';
      final res = await _apiClient.get(path, requireAuth: true);
      final rawList = res['data'] as List<dynamic>? ?? [];
      return rawList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('getTeacherStudents error: $e');
      return [];
    }
  }

  /// Get all teachers assigned to a student (by their internal UUID).
  Future<List<Map<String, dynamic>>> getStudentTeachers(String studentId) async {
    try {
      final res = await _apiClient.get(
        '/communication/students/$studentId/teachers',
        requireAuth: true,
      );
      final rawList = res['data'] as List<dynamic>? ?? [];
      return rawList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to fetch student teachers: $e');
      return [];
    }
  }

  /// Get all approved parents linked to a student (by their internal UUID).
  Future<List<Map<String, dynamic>>> getStudentParents(String studentId) async {
    try {
      final res = await _apiClient.get(
        '/communication/students/$studentId/parents',
        requireAuth: true,
      );
      final rawList = res['data'] as List<dynamic>? ?? [];
      return rawList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Failed to fetch student parents: $e');
      return [];
    }
  }

  // ──────────────────────────── Direct Messaging ─────────────────────────────

  /// Send a direct message, persisted in the Neon DB `Message` table.
  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String content,
    required String currentUserId,
  }) async {
    try {
      final res = await _apiClient.post(
        '/communication/messages',
        body: {'receiverId': receiverId, 'content': content},
        requireAuth: true,
      );
      final data = res['data'] as Map<String, dynamic>? ?? res;
      return ChatMessage.fromJson(data, currentUserId);
    } catch (e) {
      debugPrint('Local message dispatch fallback: $e');
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId,
        receiverId: receiverId,
        senderName: 'You',
        senderRole: 'User',
        content: content,
        timestampText: 'Just now',
        isMe: true,
        isRead: false,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Retrieve the full chat history between the current user and another user.
  Future<List<ChatMessage>> getChatHistory({
    required String otherUserId,
    required String currentUserId,
  }) async {
    try {
      final res = await _apiClient.get(
        '/communication/messages/$otherUserId',
        requireAuth: true,
      );
      final rawList = res['data'] as List<dynamic>? ?? [];
      return rawList
          .map((item) =>
              ChatMessage.fromJson(item as Map<String, dynamic>, currentUserId))
          .toList();
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
      return [];
    }
  }

  /// Get the total count of unread messages for the current user.
  /// Used to display notification badges.
  Future<int> getUnreadCount() async {
    try {
      final res = await _apiClient.get(
        '/communication/messages/unread-count',
        requireAuth: true,
      );
      final data = res['data'] as Map<String, dynamic>? ?? {};
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Failed to fetch unread count: $e');
      return 0;
    }
  }

  /// Mark a message as read in the DB.
  Future<void> markAsRead(String messageId) async {
    try {
      await _apiClient.patch(
        '/communication/messages/$messageId/read',
        body: {},
        requireAuth: true,
      );
    } catch (e) {
      debugPrint('Failed to mark message as read: $e');
    }
  }

  /// Delete a message from the DB.
  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiClient.delete(
        '/communication/messages/$messageId',
        requireAuth: true,
      );
    } catch (e) {
      debugPrint('Failed to delete message: $e');
    }
  }
}
