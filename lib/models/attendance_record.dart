enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  String toDbString() {
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

  static AttendanceStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'LATE':
      case 'TARDY':
      case 'TARDY / LATE':
        return AttendanceStatus.late;
      case 'EXCUSED':
        return AttendanceStatus.excused;
      case 'PRESENT':
      default:
        return AttendanceStatus.present;
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String studentId;
  final String studentName;
  final String date; // YYYY-MM-DD
  final AttendanceStatus status;
  final String? note;
  final DateTime createdAt;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final studentObj = json['student'] as Map<String, dynamic>?;
    final nameFromObj = studentObj != null
        ? '${studentObj['firstName'] ?? ''} ${studentObj['lastName'] ?? ''}'.trim()
        : '';
    final studentIdVal = json['studentId'] as String? ?? '';

    return AttendanceRecord(
      id: json['id'] as String? ?? '',
      studentId: studentIdVal,
      studentName: nameFromObj.isNotEmpty ? nameFromObj : (json['studentName'] as String? ?? 'Student'),
      date: (json['date'] as String? ?? '').split('T').first,
      status: AttendanceStatus.fromString(json['status'] as String? ?? 'PRESENT'),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'date': date,
      'status': status.toDbString(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
