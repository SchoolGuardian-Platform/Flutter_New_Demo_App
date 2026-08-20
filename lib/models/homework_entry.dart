class HomeworkEntry {
  HomeworkEntry({
    required this.id,
    required this.classId,
    this.className,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String classId;
  final String? className;
  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;

  factory HomeworkEntry.fromJson(Map<String, dynamic> rawJson) {
    Map<String, dynamic> json = rawJson;
    if (rawJson['homework'] is Map<String, dynamic>) {
      json = rawJson['homework'] as Map<String, dynamic>;
    } else if (rawJson['data'] is Map<String, dynamic> && !(rawJson['data'] as Map<String, dynamic>).containsKey('homework')) {
      json = rawJson['data'] as Map<String, dynamic>;
    }

    final classObj = json['class'] as Map<String, dynamic>?;
    String? cName;
    if (classObj != null) {
      final grade = classObj['grade'];
      final section = classObj['section'];
      if (grade != null && section != null) {
        cName = 'Grade $grade - Section $section';
      } else if (grade != null) {
        cName = 'Grade $grade';
      }
    }

    DateTime parsedDueDate = DateTime.now().add(const Duration(days: 1));
    if (json['dueDate'] != null) {
      parsedDueDate = DateTime.tryParse(json['dueDate'].toString()) ?? parsedDueDate;
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString()) ?? parsedCreatedAt;
    }

    return HomeworkEntry(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: cName ?? json['className'] as String?,
      subject: json['subject'] as String? ?? 'General',
      title: json['title'] as String? ?? 'Homework',
      description: json['description'] as String? ?? '',
      dueDate: parsedDueDate,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'className': className,
      'subject': subject,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
