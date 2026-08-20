import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/homework_entry.dart';

class HomeworkService {
  factory HomeworkService() => _instance;
  HomeworkService._internal();
  static final HomeworkService _instance = HomeworkService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _storageKey = 'homework_entries_cache_v2';
  static const String _seenIdsKey = 'homework_seen_ids_v1';

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

  List<dynamic> _extractList(Map<String, dynamic> res) {
    if (res['data'] is List) return res['data'] as List;
    if (res['homeworks'] is List) return res['homeworks'] as List;
    return [];
  }

  /// Creates homework (teacher only). Throws on API failure so the UI can show
  /// the actual error message instead of silently falling back to local.
  Future<HomeworkEntry> createHomework({
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

    final res = await _apiClient.post('/homework', body: payload, requireAuth: true);
    final rawData = res['data'] ?? res['homework'] ?? res;
    final Map<String, dynamic> data = rawData is Map<String, dynamic> ? rawData : res;
    final entry = HomeworkEntry.fromJson(data);

    _localCache.insert(0, entry);
    await _persistCache();
    return entry;
  }

  /// Fetches all homework posted by the authenticated teacher.
  Future<List<HomeworkEntry>> getTeacherHomeworks() async {
    await _initCache();
    try {
      final res = await _apiClient.get('/homework/teacher', requireAuth: true);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
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

  /// Fetches homework for the currently authenticated student from the
  /// secure `/homework/student/me` endpoint which resolves class enrollment
  /// server-side. Falls back to the by-studentId endpoint if needed.
  Future<List<HomeworkEntry>> getMyHomework() async {
    await _initCache();
    try {
      final res = await _apiClient.get('/homework/student/me', requireAuth: true);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        final list = <HomeworkEntry>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            list.add(HomeworkEntry.fromJson(item));
          }
        }
        // Update local cache with fresh data
        _localCache.clear();
        _localCache.addAll(list);
        await _persistCache();
        return list;
      }
    } catch (_) {}
    return List.unmodifiable(_localCache);
  }

  /// Legacy: fetch homework by student ID. Now calls getMyHomework() first,
  /// then falls back to the by-id endpoint for compatibility.
  Future<List<HomeworkEntry>> getStudentHomeworks(String studentId) async {
    // First try the authenticated /me endpoint
    final myHomework = await getMyHomework();
    if (myHomework.isNotEmpty) return myHomework;

    // Fallback: try by student ID
    await _initCache();
    try {
      final res = await _apiClient.get('/homework/student/$studentId', requireAuth: true);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
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

  /// Returns homework entries that were posted within the last 48 hours AND
  /// have not been "seen" by the user yet. Used to drive the notification banner.
  Future<List<HomeworkEntry>> getNewHomeworks() async {
    final all = await getMyHomework();
    final seenIds = await _getSeenIds();
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return all
        .where((hw) => hw.createdAt.isAfter(cutoff) && !seenIds.contains(hw.id))
        .toList();
  }

  /// Marks all current homework IDs as seen so the notification banner hides.
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

  /// Deletes a homework entry (teacher only).
  Future<void> deleteHomework(String id) async {
    await _initCache();
    try {
      await _apiClient.delete('/homework/$id', requireAuth: true);
    } catch (_) {}
    _localCache.removeWhere((h) => h.id == id);
    await _persistCache();
  }
}
