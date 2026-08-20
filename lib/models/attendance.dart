enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get apiValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.late:
        return 'LATE';
      case AttendanceStatus.excused:
        return 'EXCUSED';
    }
  }

  static AttendanceStatus fromApi(String value) {
    switch (value) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'LATE':
        return AttendanceStatus.late;
      case 'EXCUSED':
        return AttendanceStatus.excused;
      default:
        throw FormatException('Unknown attendance status: $value');
    }
  }
}

class Attendance {
  Attendance({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.date,
    required this.status,
    this.note,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      teacherId: json['teacherId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatusExtension.fromApi(
        json['status'] as String,
      ),
      note: json['note'] as String?,
    );
  }
}

class AttendanceSummary {
  AttendanceSummary({
    required this.totalDays,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.attendancePercentage,
  });

  final int totalDays;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final double attendancePercentage;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['totalDays'] as int,
      present: json['present'] as int,
      absent: json['absent'] as int,
      late: json['late'] as int,
      excused: json['excused'] as int,
      attendancePercentage:
          (json['attendancePercentage'] as num).toDouble(),
    );
  }
}