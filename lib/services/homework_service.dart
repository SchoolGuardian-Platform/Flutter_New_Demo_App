import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/homework.dart';

/// Wraps the homework endpoints from `src/routes/homework.routes.ts`
/// with local SharedPreferences caching and notification tracking.
class HomeworkService {
  factory HomeworkService({ApiClient? apiClient}) {
    if (apiClient != null) {
      _instance._apiClient = apiClient;
    }
    return _instance;
  }

  HomeworkService._internal() : _apiClient = ApiClient();
  static final HomeworkService _instance = HomeworkService._internal();

  ApiClient _apiClient;
  static const String _storageKey = 'homework_entries_cache_v2';
  static const String _seenIdsKey = 'homework_seen_ids_v1';

  final List<Homework> _localCache = [];
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
            _localCache.add(Homework.fromJson(item));
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

  List<dynamic> _extractList(Map<String, dynamic> res) {
    if (res['data'] is List) return res['data'] as List<dynamic>;
    if (res['homeworks'] is List) return res['homeworks'] as List<dynamic>;
    return [];
  }

  // ---- Read endpoints ----

  /// `GET /homework/teacher` — all homework posted by the current teacher.
  Future<List<Homework>> getHomeworkByTeacher() async {
    await _initCache();
    try {
      final json = await _apiClient.get(
        ApiConfig.homeworkByTeacher,
        requireAuth: true,
      );
      final rawList = _extractList(json);
      if (rawList.isNotEmpty) {
        final list = rawList
            .map((item) => Homework.fromJson(item as Map<String, dynamic>))
            .toList();
        _localCache.clear();
        _localCache.addAll(list);
        await _persistCache();
        return List.unmodifiable(_localCache);
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  /// Alias for [getHomeworkByTeacher].
  Future<List<Homework>> getTeacherHomeworks() => getHomeworkByTeacher();

  /// Fetches homework for the authenticated student using `/homework/student/me`
  /// or falls back to local cache.
  Future<List<Homework>> getMyHomework() async {
    await _initCache();
    try {
      final res = await _apiClient.get(
        '/homework/student/me',
        requireAuth: true,
      );
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        final list = rawList
            .map((item) => Homework.fromJson(item as Map<String, dynamic>))
            .toList();
        _localCache.clear();
        _localCache.addAll(list);
        await _persistCache();
        return list;
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  /// `GET /homework/student/:studentId` — homework for a specific student.
  Future<List<Homework>> getHomeworkByStudent(String studentId) async {
    await _initCache();
    try {
      final json = await _apiClient.get(
        ApiConfig.homeworkByStudent(studentId),
        requireAuth: true,
      );
      final rawList = _extractList(json);
      if (rawList.isNotEmpty) {
        final list = rawList
            .map((item) => Homework.fromJson(item as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {}
    return _localCache.where((hw) => hw.studentId == studentId).toList();
  }

  /// Alias for [getHomeworkByStudent].
  Future<List<Homework>> getStudentHomeworks(String studentId) async {
    final myHw = await getMyHomework();
    if (myHw.isNotEmpty) return myHw;
    return getHomeworkByStudent(studentId);
  }

  /// `GET /homework/class/:classId` — homework for a specific class.
  Future<List<Homework>> getHomeworkByClass(String classId) async {
    await _initCache();
    try {
      final json = await _apiClient.get(
        ApiConfig.homeworkByClass(classId),
        requireAuth: true,
      );
      final rawList = _extractList(json);
      if (rawList.isNotEmpty) {
        return rawList
            .map((item) => Homework.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _localCache.where((hw) => hw.classId == classId).toList();
  }

  /// Returns homework entries posted within the last 48 hours and not marked seen.
  Future<List<Homework>> getNewHomeworks() async {
    final all = await getMyHomework();
    final seenIds = await _getSeenIds();
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return all
        .where((hw) => hw.createdAt.isAfter(cutoff) && !seenIds.contains(hw.id))
        .toList();
  }

  /// Marks all current homework IDs as seen.
  Future<void> markAllSeen() async {
    await _initCache();
    final allIds = _localCache.map((hw) => hw.id).toSet();
    final prefs = await SharedPreferences.getInstance();
    final existing = await _getSeenIds();
    final merged = {...existing, ...allIds};
    await prefs.setStringList(_seenIdsKey, merged.toList());
  }

  Future<Set<String>> _getSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_seenIdsKey)?.toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  // ---- Write endpoints (TEACHER only) ----

  /// `POST /homework` — create a new homework assignment (TEACHER only).
  Future<Homework> createHomework({
    required String classId,
    required String subject,
    required String title,
    required String description,
    required DateTime dueDate,
    String? className,
  }) async {
    await _initCache();

    final payload = {
      'classId': classId,
      'subject': subject,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
    };

    final res = await _apiClient.post(
      ApiConfig.homework,
      body: payload,
      requireAuth: true,
    );

    final rawData = res['data'] ?? res['homework'] ?? res;
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : res;
    final entry = Homework.fromJson(data);

    _localCache.insert(0, entry);
    await _persistCache();
    return entry;
  }

  /// `PATCH /homework/:id` — update an existing homework assignment (TEACHER only).
  Future<Homework> updateHomework(
    String id, {
    String? subject,
    String? title,
    String? description,
    DateTime? dueDate,
  }) async {
    await _initCache();
    final body = <String, dynamic>{};
    if (subject != null) body['subject'] = subject;
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

    final json = await _apiClient.patch(
      ApiConfig.homeworkById(id),
      body: body,
      requireAuth: true,
    );

    final rawData = json['data'] ?? json['homework'] ?? json;
    final Map<String, dynamic> data =
        rawData is Map<String, dynamic> ? rawData : json;
    final updated = Homework.fromJson(data);

    final idx = _localCache.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _localCache[idx] = updated;
      await _persistCache();
    }
    return updated;
  }

  /// `DELETE /homework/:id` — delete a homework record (TEACHER only).
  Future<void> deleteHomework(String id) async {
    await _initCache();
    try {
      await _apiClient.delete(ApiConfig.homeworkById(id), requireAuth: true);
    } catch (_) {}
    _localCache.removeWhere((h) => h.id == id);
    await _persistCache();
  }
}