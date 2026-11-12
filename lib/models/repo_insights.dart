/// Cantidad de archivos con una misma extensión (ej. ".dart": 42).
class ExtensionStat {
  const ExtensionStat({required this.extension, required this.count});

  final String extension;
  final int count;

  factory ExtensionStat.fromJson(Map<String, dynamic> json) => ExtensionStat(
        extension: json['extension'] as String,
        count: json['count'] as int,
      );

  Map<String, dynamic> toJson() => {'extension': extension, 'count': count};
}

/// Un archivo con su tamaño en bytes, para la lista de los más pesados.
class FileSize {
  const FileSize({required this.path, required this.size});

  final String path;
  final int size;

  factory FileSize.fromJson(Map<String, dynamic> json) =>
      FileSize(path: json['path'] as String, size: json['size'] as int);

  Map<String, dynamic> toJson() => {'path': path, 'size': size};
}

/// Una práctica detectada en el repositorio (ej. "Pruebas automatizadas").
class RepoSignal {
  const RepoSignal({required this.label, required this.present});

  final String label;
  final bool present;

  factory RepoSignal.fromJson(Map<String, dynamic> json) =>
      RepoSignal(label: json['label'] as String, present: json['present'] as bool);

  Map<String, dynamic> toJson() => {'label': label, 'present': present};
}

/// Análisis de la estructura completa del repositorio, calculado a partir del
/// árbol de Git (GET /git/trees/{rama}?recursive=1).
class RepoInsights {
  const RepoInsights({
    required this.totalFiles,
    required this.totalDirs,
    required this.totalBytes,
    required this.maxDepth,
    required this.extensions,
    required this.largestFiles,
    required this.signals,
    required this.recommendations,
    required this.truncated,
  });

  final int totalFiles;
  final int totalDirs;
  final int totalBytes;

  /// Nivel de carpetas más profundo (0 = todo en la raíz).
  final int maxDepth;

  /// Extensiones más frecuentes, de mayor a menor.
  final List<ExtensionStat> extensions;

  /// Archivos más pesados, de mayor a menor.
  final List<FileSize> largestFiles;
  final List<RepoSignal> signals;

  /// Sugerencias concretas para mejorar el repositorio.
  final List<String> recommendations;

  /// `true` si GitHub recortó el árbol por ser muy grande.
  final bool truncated;

  factory RepoInsights.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List?) ?? const [])
            .map((e) => parse(e as Map<String, dynamic>))
            .toList();
    return RepoInsights(
      totalFiles: json['total_files'] as int,
      totalDirs: json['total_dirs'] as int,
      totalBytes: json['total_bytes'] as int,
      maxDepth: json['max_depth'] as int,
      extensions: list('extensions', ExtensionStat.fromJson),
      largestFiles: list('largest_files', FileSize.fromJson),
      signals: list('signals', RepoSignal.fromJson),
      recommendations: ((json['recommendations'] as List?) ?? const []).cast<String>(),
      truncated: (json['truncated'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_files': totalFiles,
        'total_dirs': totalDirs,
        'total_bytes': totalBytes,
        'max_depth': maxDepth,
        'extensions': extensions.map((e) => e.toJson()).toList(),
        'largest_files': largestFiles.map((e) => e.toJson()).toList(),
        'signals': signals.map((e) => e.toJson()).toList(),
        'recommendations': recommendations,
        'truncated': truncated,
      };
}
