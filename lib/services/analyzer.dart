import '../models/analysis_result.dart';
import '../models/repo_file.dart';
import 'github_service.dart';

/// Lógica de negocio propia de RepoLens: no hace peticiones, solo analiza los
/// datos ya descargados. Por eso todos sus métodos son estáticos y puros,
/// fáciles de probar.
class Analyzer {
  /// Archivo de la raíz -> tecnología que delata.
  static const Map<String, String> _stackByFile = {
    'pubspec.yaml': 'Flutter/Dart',
    'package.json': 'Node/JS',
    'requirements.txt': 'Python',
    'pyproject.toml': 'Python',
    'build.gradle': 'Android/Kotlin/Java',
    'build.gradle.kts': 'Android/Kotlin/Java',
    'pom.xml': 'Maven',
    'cargo.toml': 'Rust',
    'go.mod': 'Go',
    'composer.json': 'PHP',
    'dockerfile': 'Docker',
  };

  /// Nombres exactos de archivos sensibles.
  static const Set<String> _sensitiveNames = {
    '.env',
    'google-services.json',
    'googleservice-info.plist',
    'key.properties',
    'id_rsa',
    'credentials.json',
  };

  /// Extensiones de archivos sensibles (llaves y almacenes de claves).
  static const List<String> _sensitiveExtensions = ['.jks', '.keystore', '.pem'];

  /// Detecta el stack por los archivos de la raíz (sin repetir tecnologías).
  static List<String> detectStack(List<RepoFile> files) {
    final found = <String>{};
    for (final file in files.where((f) => !f.isDir)) {
      final name = file.name.toLowerCase();
      final stack = _stackByFile[name];
      if (stack != null) found.add(stack);
      if (name.endsWith('.csproj')) found.add('.NET');
    }
    return found.toList();
  }

  /// Lista los archivos sensibles que no deberían estar en un repo público.
  static List<String> securityAlerts(List<RepoFile> files) {
    return files.where((f) => !f.isDir).map((f) => f.name).where((name) {
      final lower = name.toLowerCase();
      return _sensitiveNames.contains(lower) ||
          _sensitiveExtensions.any(lower.endsWith);
    }).toList();
  }

  /// Calcula los 7 criterios de salud. Los puntos suman 100.
  /// [now] se puede inyectar para que las pruebas sean deterministas.
  static List<HealthCheck> healthChecks(RepoData data, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final names = data.files.map((f) => f.name.toLowerCase()).toSet();
    final lastCommit = data.commits.isNotEmpty
        ? (data.commits.first.date ?? data.repo.pushedAt)
        : data.repo.pushedAt;
    final recent =
        lastCommit != null && today.difference(lastCommit).inDays <= 90;
    final description = data.repo.description?.trim() ?? '';

    return [
      HealthCheck(
        label: 'Tiene README',
        passed: data.readme != null || names.any((n) => n.startsWith('readme')),
        points: 20,
      ),
      HealthCheck(label: 'Tiene licencia', passed: data.repo.license != null, points: 15),
      HealthCheck(label: 'Tiene .gitignore', passed: names.contains('.gitignore'), points: 10),
      HealthCheck(label: 'Tiene descripción', passed: description.isNotEmpty, points: 15),
      HealthCheck(label: 'Commit en los últimos 90 días', passed: recent, points: 20),
      HealthCheck(
        label: 'Más de un contribuidor',
        passed: data.contributors.length > 1,
        points: 10,
      ),
      HealthCheck(label: 'Temas definidos', passed: data.repo.topics.isNotEmpty, points: 10),
    ];
  }

  /// Suma los puntos de los criterios cumplidos (0 a 100).
  static int healthScore(List<HealthCheck> checks) =>
      checks.where((c) => c.passed).fold(0, (sum, c) => sum + c.points);

  /// Une los datos de la API con el análisis propio en un informe completo.
  static AnalysisResult build(RepoData data, {DateTime? now}) {
    final checks = healthChecks(data, now: now);
    return AnalysisResult(
      repo: data.repo,
      languages: data.languages,
      commits: data.commits,
      contributors: data.contributors,
      files: data.files,
      readme: data.readme,
      stacks: detectStack(data.files),
      healthScore: healthScore(checks),
      healthChecks: checks,
      alerts: securityAlerts(data.files),
      analyzedAt: now ?? DateTime.now(),
    );
  }
}
