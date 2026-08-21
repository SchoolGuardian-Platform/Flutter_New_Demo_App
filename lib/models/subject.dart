/// Model representing an academic subject in the school guardian system.
/// Matches Prisma `Subject` model (`id`, `name`) with optional display fields.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.code,
    this.category,
    this.description,
  });

  final String id;
  final String name;
  final String? code;
  final String? category;
  final String? description;

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? description,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
    };
  }
}
