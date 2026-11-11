/// Análisis guardado en el historial (tabla `history`).
class HistoryEntry {
  const HistoryEntry({
    this.id,
    required this.userId,
    required this.fullName,
    required this.jsonSnapshot,
    required this.healthScore,
    required this.analyzedAt,
  });

  final int? id;
  final int userId;
  final String fullName;

  /// AnalysisResult serializado: permite reabrir el informe sin red.
  final String jsonSnapshot;
  final int healthScore;
  final DateTime analyzedAt;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as int?,
        userId: json['user_id'] as int,
        fullName: json['full_name'] as String,
        jsonSnapshot: json['json_snapshot'] as String,
        healthScore: json['health_score'] as int,
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'full_name': fullName,
        'json_snapshot': jsonSnapshot,
        'health_score': healthScore,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}
