/// Model representing student enrollment in a class (`StudentClass` in Prisma schema).
class StudentClassInfo {
  const StudentClassInfo({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentCode,
    required this.classId,
    this.academicYear,
    this.enrolledAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String? studentCode;
  final String classId;
  final String? academicYear;
  final DateTime? enrolledAt;

  factory StudentClassInfo.fromJson(Map<String, dynamic> json) {
    String name = 'Unknown Student';
    if (json['student'] != null && json['student'] is Map<String, dynamic>) {
      final s = json['student'] as Map<String, dynamic>;
      final first = s['firstName'] as String? ?? '';
      final last = s['lastName'] as String? ?? '';
      name = '$first $last'.trim();
    } else if (json['studentName'] != null) {
      name = json['studentName'] as String;
    }

    final rawCode = json['studentCode'] as String? ??
        (json['student'] is Map ? json['student']['studentId'] as String? : null);
    final rawId = json['studentId'] as String? ??
        (json['student'] is Map ? json['student']['id'] as String? : '');

    return StudentClassInfo(
      id: json['id'] as String? ?? '',
      studentId: (rawId != null && rawId.isNotEmpty) ? rawId : (json['id'] as String? ?? ''),
      studentName: name.isNotEmpty ? name : 'Student',
      studentCode: rawCode ?? rawId,
      classId: json['classId'] as String? ?? '',
      academicYear: json['academicYear'] as String?,
      enrolledAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : (json['enrolledAt'] != null
              ? DateTime.tryParse(json['enrolledAt'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      'classId': classId,
      'academicYear': academicYear,
      if (enrolledAt != null) 'enrolledAt': enrolledAt!.toIso8601String(),
    };
  }
}

/// Model representing teacher & subject assignment in a class (`TeacherClassSubject` in Prisma schema).
class TeacherSubjectInfo {
  const TeacherSubjectInfo({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    this.academicYear,
    this.assignedAt,
  });

  final String id;
  final String teacherId;
  final String teacherName;
  final String subjectId;
  final String subjectName;
  final String classId;
  final String? academicYear;
  final DateTime? assignedAt;

  factory TeacherSubjectInfo.fromJson(Map<String, dynamic> json) {
    String tName = 'Unknown Teacher';
    if (json['teacher'] != null && json['teacher'] is Map<String, dynamic>) {
      final t = json['teacher'] as Map<String, dynamic>;
      final first = t['firstName'] as String? ?? '';
      final last = t['lastName'] as String? ?? '';
      tName = '$first $last'.trim();
    } else if (json['teacherName'] != null) {
      tName = json['teacherName'] as String;
    }

    String sName = 'Subject';
    if (json['subject'] != null && json['subject'] is Map<String, dynamic>) {
      sName = (json['subject'] as Map<String, dynamic>)['name'] as String? ?? 'Subject';
    } else if (json['subjectName'] != null) {
      sName = json['subjectName'] as String;
    }

    return TeacherSubjectInfo(
      id: json['id'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      teacherName: tName.isNotEmpty ? tName : 'Teacher',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: sName,
      classId: json['classId'] as String? ?? '',
      academicYear: json['academicYear'] as String?,
      assignedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : (json['assignedAt'] != null
              ? DateTime.tryParse(json['assignedAt'] as String)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'classId': classId,
      'academicYear': academicYear,
      if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
    };
  }
}

/// Model representing a Class and Section in the school system (`Class` in Prisma schema).
class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.grade,
    required this.section,
    this.academicYear = '2025/2026',
    this.roomNumber,
    this.maxCapacity = 35,
    this.description,
    this.students = const [],
    this.teachers = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int grade;
  final String section;
  final String academicYear;
  final String? roomNumber;
  final int maxCapacity;
  final String? description;
  final List<StudentClassInfo> students;
  final List<TeacherSubjectInfo> teachers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => 'Grade $grade - Section $section';
  String get shortLabel => '$grade-$section';

  int get studentCount => students.length;
  int get teacherCount => teachers.length;

  SchoolClass copyWith({
    String? id,
    int? grade,
    String? section,
    String? academicYear,
    String? roomNumber,
    int? maxCapacity,
    String? description,
    List<StudentClassInfo>? students,
    List<TeacherSubjectInfo>? teachers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      academicYear: academicYear ?? this.academicYear,
      roomNumber: roomNumber ?? this.roomNumber,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      description: description ?? this.description,
      students: students ?? this.students,
      teachers: teachers ?? this.teachers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    List<StudentClassInfo> studentList = [];
    if (json['students'] is List) {
      studentList = (json['students'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => StudentClassInfo.fromJson(item))
          .toList();
    }

    List<TeacherSubjectInfo> teacherList = [];
    if (json['teachers'] is List) {
      teacherList = (json['teachers'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => TeacherSubjectInfo.fromJson(item))
          .toList();
    }

    final rawGrade = json['grade'];
    int parsedGrade = 9;
    if (rawGrade is num) {
      parsedGrade = rawGrade.toInt();
    } else if (rawGrade != null) {
      parsedGrade = int.tryParse(rawGrade.toString()) ?? 9;
    }

    final rawCapacity = json['maxCapacity'];
    int parsedCapacity = 35;
    if (rawCapacity is num) {
      parsedCapacity = rawCapacity.toInt();
    } else if (rawCapacity != null) {
      parsedCapacity = int.tryParse(rawCapacity.toString()) ?? 35;
    }

    return SchoolClass(
      id: json['id'] as String? ?? 'cls-${DateTime.now().millisecondsSinceEpoch}',
      grade: parsedGrade,
      section: json['section'] as String? ?? 'A',
      academicYear: json['academicYear'] as String? ?? '2025/2026',
      roomNumber: json['roomNumber'] as String? ?? json['room_number'] as String?,
      maxCapacity: parsedCapacity,
      description: json['description'] as String?,
      students: studentList,
      teachers: teacherList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'section': section,
      'academicYear': academicYear,
      if (roomNumber != null) 'roomNumber': roomNumber,
      'maxCapacity': maxCapacity,
      if (description != null) 'description': description,
      'students': students.map((s) => s.toJson()).toList(),
      'teachers': teachers.map((t) => t.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolClass && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

