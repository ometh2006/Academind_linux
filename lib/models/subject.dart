class Subject {
  final int? id;
  final String name;
  final String? description;
  final String colorHex;
  final DateTime createdAt;

  Subject({
    this.id,
    required this.name,
    this.description,
    this.colorHex = '#6750A4',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        colorHex: map['colorHex'] ?? '#6750A4',
        createdAt: DateTime.parse(map['createdAt']),
      );

  Subject copyWith({int? id, String? name, String? description, String? colorHex}) =>
      Subject(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt,
      );
}
