/// Repositorio favorito con nota editable (tabla `favorites`).
class Favorite {
  const Favorite({
    this.id,
    required this.userId,
    required this.fullName,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int userId;
  final String fullName;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Favorite copyWith({int? id, String? note, DateTime? updatedAt}) => Favorite(
        id: id ?? this.id,
        userId: userId,
        fullName: fullName,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        id: json['id'] as int?,
        userId: json['user_id'] as int,
        fullName: json['full_name'] as String,
        note: (json['note'] as String?) ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'full_name': fullName,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
