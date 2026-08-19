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

  factory HomeworkEntry.fromJson(Map<String, dynamic> json) {
    final classObj = json['class'] as Map<String, dynamic>?;
    String? cName;
    if (classObj != null) {
      cName = 'Grade ${classObj['grade'] ?? ''} - Section ${classObj['section'] ?? ''}';
    }

    return HomeworkEntry(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: cName ?? json['className'] as String?,
      subject: json['subject'] as String? ?? 'General',
      title: json['title'] as String? ?? 'Homework',
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : DateTime.now().add(const Duration(days: 1)),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
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
