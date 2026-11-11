/// Lenguaje de un repositorio con sus bytes y su porcentaje.
class LanguageStat {
  const LanguageStat({required this.name, required this.bytes, required this.percent});

  final String name;
  final int bytes;

  /// Porcentaje (0-100) respecto al total de bytes del repo.
  final double percent;

  factory LanguageStat.fromJson(Map<String, dynamic> json) => LanguageStat(
        name: json['name'] as String,
        bytes: json['bytes'] as int,
        percent: (json['percent'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'name': name, 'bytes': bytes, 'percent': percent};

  /// Convierte la respuesta de GET /languages (`{"Dart": 1200, "Kotlin": 300}`)
  /// en una lista ordenada de mayor a menor con porcentajes calculados.
  static List<LanguageStat> listFromApi(Map<String, dynamic> json) {
    final total = json.values.fold<int>(0, (sum, v) => sum + (v as int));
    if (total == 0) return [];
    final list = json.entries
        .map((e) => LanguageStat(
              name: e.key,
              bytes: e.value as int,
              percent: (e.value as int) * 100 / total,
            ))
        .toList()
      ..sort((a, b) => b.bytes.compareTo(a.bytes));
    return list;
  }
}
