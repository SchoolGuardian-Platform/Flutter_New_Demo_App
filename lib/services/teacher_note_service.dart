import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../core/token_storage.dart';

class TeacherNoteItem {
  final String id;
  final String studentId;
  final String? studentName;
  final String? teacherName;
  final String title;
  final String content;
  final DateTime createdAt;

  TeacherNoteItem({
    required this.id,
    required this.studentId,
    this.studentName,
    this.teacherName,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory TeacherNoteItem.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['student'] != null && json['student'] is Map<String, dynamic>) {
      final s = json['student'] as Map<String, dynamic>;
      name = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
    } else if (json['studentName'] != null) {
      name = json['studentName'] as String;
    }

    String? tName;
    if (json['teacher'] != null && json['teacher'] is Map<String, dynamic>) {
      final t = json['teacher'] as Map<String, dynamic>;
      tName = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
    } else if (json['teacherName'] != null) {
      tName = json['teacherName'] as String;
    }

    return TeacherNoteItem(
      id: json['id'] as String? ?? 'tn-${DateTime.now().millisecondsSinceEpoch}',
      studentId: json['studentId'] as String? ?? '',
      studentName: name != null && name.isNotEmpty ? name : null,
      teacherName: tName != null && tName.isNotEmpty ? tName : null,
      title: json['title'] as String? ?? 'Observation Note',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class TeacherNoteService {
  Future<List<TeacherNoteItem>> getStudentNotes(String studentId) async {
    try {
      final token = await TokenStorage().readAccessToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/teacher-notes/student/$studentId'), headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body['notes'] as List<dynamic>?) ?? [];
        return list.map((e) => TeacherNoteItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<TeacherNoteItem>> getTeacherNotes() async {
    try {
      final token = await TokenStorage().readAccessToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/teacher-notes/teacher'), headers: headers)
          .timeout(ApiConfig.requestTimeout);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body['notes'] as List<dynamic>?) ?? [];
        return list.map((e) => TeacherNoteItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> createNote({
    required String studentId,
    required String title,
    required String content,
  }) async {
    try {
      final token = await TokenStorage().readAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final body = json.encode({
        'studentId': studentId,
        'title': title,
        'content': content,
      });

      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/teacher-notes'),
            headers: headers,
            body: body,
          )
          .timeout(ApiConfig.requestTimeout);

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateNote(String id, {required String title, required String content}) async {
    try {
      final token = await TokenStorage().readAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final body = json.encode({'title': title, 'content': content});

      final res = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/teacher-notes/$id'),
            headers: headers,
            body: body,
          )
          .timeout(ApiConfig.requestTimeout);

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      final token = await TokenStorage().readAccessToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http
          .delete(Uri.parse('${ApiConfig.baseUrl}/teacher-notes/$id'), headers: headers)
          .timeout(ApiConfig.requestTimeout);

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
