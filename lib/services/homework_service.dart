import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/homework_entry.dart';

class HomeworkService {
  factory HomeworkService() => _instance;
  HomeworkService._internal();
  static final HomeworkService _instance = HomeworkService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _storageKey = 'homework_entries_cache_v1';
  final List<HomeworkEntry> _localCache = [];
  bool _initialized = false;

  Future<void> _initCache() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        _localCache.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _localCache.add(HomeworkEntry.fromJson(item));
          }
        }
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_localCache.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<HomeworkEntry> createHomework({
    required String classId,
    required String subject,
    required String title,
    required String description,
    required DateTime dueDate,
    String? className,
  }) async {
    await _initCache();
    HomeworkEntry entry;

    try {
      final payload = {
        'classId': classId,
        'subject': subject,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
      };

      final res = await _apiClient.post('/homework', body: payload, requireAuth: true);
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      entry = HomeworkEntry.fromJson(data);
    } catch (_) {
      entry = HomeworkEntry(
        id: 'hw-${DateTime.now().millisecondsSinceEpoch}',
        classId: classId,
        className: className,
        subject: subject,
        title: title,
        description: description,
        dueDate: dueDate,
      );
    }

    _localCache.insert(0, entry);
    await _persistCache();
    return entry;
  }

  Future<List<HomeworkEntry>> getTeacherHomeworks() async {
    await _initCache();
    try {
      final res = await _apiClient.get('/homework/teacher', requireAuth: true);
      final List<dynamic>? rawList = res['data'] is List ? (res['data'] as List<dynamic>) : null;
      if (rawList != null) {
        final fetched = <HomeworkEntry>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            fetched.add(HomeworkEntry.fromJson(item));
          }
        }
        _localCache.clear();
        _localCache.addAll(fetched);
        await _persistCache();
        return List.unmodifiable(_localCache);
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  Future<List<HomeworkEntry>> getStudentHomeworks(String studentId) async {
    await _initCache();
    try {
      final res = await _apiClient.get('/homework/student/$studentId', requireAuth: true);
      final rawList = res['data'] is List ? res['data'] as List : null;
      if (rawList != null) {
        final list = <HomeworkEntry>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            list.add(HomeworkEntry.fromJson(item));
          }
        }
        return list;
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  Future<void> deleteHomework(String id) async {
    await _initCache();
    try {
      await _apiClient.delete('/homework/$id', requireAuth: true);
    } catch (_) {}
    _localCache.removeWhere((h) => h.id == id);
    await _persistCache();
  }
}
