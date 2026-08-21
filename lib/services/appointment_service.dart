import '../core/api_client.dart';

class AppointmentSlotItem {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final bool isClosed;
  final int availableCapacity;

  AppointmentSlotItem({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isClosed = false,
    this.availableCapacity = 2,
  });

  factory AppointmentSlotItem.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotItem(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isClosed: json['isClosed'] as bool? ?? false,
      availableCapacity: (json['availableCapacity'] as num?)?.toInt() ?? 2,
    );
  }
}

class AppointmentItem {
  final String id;
  final String parentName;
  final String parentEmail;
  final String studentName;
  final String teacherName;
  final String date;
  final String startTime;
  final String endTime;
  final String reason;
  final String status;

  AppointmentItem({
    required this.id,
    required this.parentName,
    required this.parentEmail,
    required this.studentName,
    required this.teacherName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    String pName = 'Parent';
    String pEmail = '';
    if (json['parent'] != null && json['parent'] is Map<String, dynamic>) {
      final p = json['parent'] as Map<String, dynamic>;
      pName = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
      pEmail = p['email'] as String? ?? '';
    }

    String sName = 'Student';
    if (json['student'] != null && json['student'] is Map<String, dynamic>) {
      final s = json['student'] as Map<String, dynamic>;
      sName = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
    }

    String tName = 'Teacher';
    String dt = '';
    String st = '';
    String et = '';
    if (json['slot'] != null && json['slot'] is Map<String, dynamic>) {
      final sl = json['slot'] as Map<String, dynamic>;
      dt = sl['date'] as String? ?? '';
      st = sl['startTime'] as String? ?? '';
      et = sl['endTime'] as String? ?? '';
      if (sl['teacher'] != null && sl['teacher'] is Map<String, dynamic>) {
        final t = sl['teacher'] as Map<String, dynamic>;
        tName = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
      }
    }

    return AppointmentItem(
      id: json['id'] as String? ?? 'apt-${DateTime.now().millisecondsSinceEpoch}',
      parentName: pName.isNotEmpty ? pName : 'Parent',
      parentEmail: pEmail,
      studentName: sName.isNotEmpty ? sName : 'Student',
      teacherName: tName.isNotEmpty ? tName : 'Teacher',
      date: dt.isNotEmpty ? dt : (json['date'] as String? ?? ''),
      startTime: st.isNotEmpty ? st : (json['startTime'] as String? ?? ''),
      endTime: et.isNotEmpty ? et : (json['endTime'] as String? ?? ''),
      reason: json['reason'] as String? ?? 'General Conference Request',
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

class AppointmentService {
  AppointmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AppointmentItem>> getTeacherAppointments() async {
    try {
      final res = await _apiClient.get('/appointments/teacher', requireAuth: true);
      final list = (res['data'] as List<dynamic>?) ?? [];
      return list.map((e) => AppointmentItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AppointmentItem>> getParentAppointments() async {
    try {
      final res = await _apiClient.get('/appointments/parent', requireAuth: true);
      final list = (res['data'] as List<dynamic>?) ?? [];
      return list.map((e) => AppointmentItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AppointmentSlotItem>> getAvailableSlots(String teacherId) async {
    try {
      final res = await _apiClient.get('/appointments/teachers/$teacherId/slots', requireAuth: true);
      final list = (res['data'] as List<dynamic>?) ?? [];
      return list.map((e) => AppointmentSlotItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createSlot({
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      await _apiClient.post(
        '/appointments/slots',
        body: {'date': date, 'startTime': startTime, 'endTime': endTime},
        requireAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> bookAppointment({
    required String slotId,
    required String studentId,
    String? reason,
  }) async {
    try {
      await _apiClient.post(
        '/appointments/book',
        body: {
          'slotId': slotId,
          'studentId': studentId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
        requireAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _apiClient.patch(
        '/appointments/$appointmentId/cancel',
        body: {},
        requireAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _apiClient.patch(
        '/appointments/$appointmentId/status',
        body: {'status': status},
        requireAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
