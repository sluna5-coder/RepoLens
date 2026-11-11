import 'commit_info.dart';
import 'contributor.dart';
import 'language_stat.dart';
import 'repo_file.dart';
import 'repo_info.dart';

/// Un criterio de la puntuación de salud (ej. "Tiene README").
class HealthCheck {
  const HealthCheck({required this.label, required this.passed, required this.points});

  final String label;
  final bool passed;

  /// Puntos que aporta el criterio cuando se cumple.
  final int points;

  factory HealthCheck.fromJson(Map<String, dynamic> json) => HealthCheck(
        label: json['label'] as String,
        passed: json['passed'] as bool,
        points: json['points'] as int,
      );

  Map<String, dynamic> toJson() => {'label': label, 'passed': passed, 'points': points};
}

/// Informe completo de un repositorio: datos de la API más el análisis propio
/// (stack detectado, salud y alertas). Es lo que se muestra en la pantalla de
/// resultado y lo que se guarda como snapshot JSON en caché e historial.
class AnalysisResult {
  const AnalysisResult({
    required this.repo,
    required this.languages,
    required this.commits,
    required this.contributors,
    required this.files,
    required this.readme,
    required this.stacks,
    required this.healthScore,
    required this.healthChecks,
    required this.alerts,
    required this.analyzedAt,
    this.fromCache = false,
  });

  final RepoInfo repo;
  final List<LanguageStat> languages;
  final List<CommitInfo> commits;
  final List<Contributor> contributors;
  final List<RepoFile> files;

  /// README en Markdown ya decodificado, o `null` si no hay.
  final String? readme;

  /// Tecnologías detectadas por los archivos de la raíz.
  final List<String> stacks;

  /// Puntuación de salud de 0 a 100.
  final int healthScore;
  final List<HealthCheck> healthChecks;

  /// Nombres de archivos sensibles encontrados en la raíz.
  final List<String> alerts;
  final DateTime analyzedAt;

  /// `true` si el informe salió de la caché local y no de la red.
  final bool fromCache;

  AnalysisResult copyWith({bool? fromCache}) => AnalysisResult(
        repo: repo,
        languages: languages,
        commits: commits,
        contributors: contributors,
        files: files,
        readme: readme,
        stacks: stacks,
        healthScore: healthScore,
        healthChecks: healthChecks,
        alerts: alerts,
        analyzedAt: analyzedAt,
        fromCache: fromCache ?? this.fromCache,
      );

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List?) ?? const [])
            .map((e) => parse(e as Map<String, dynamic>))
            .toList();
    return AnalysisResult(
      repo: RepoInfo.fromJson(json['repo'] as Map<String, dynamic>),
      languages: list('languages', LanguageStat.fromJson),
      commits: list('commits', CommitInfo.fromJson),
      contributors: list('contributors', Contributor.fromJson),
      files: list('files', RepoFile.fromJson),
      readme: json['readme'] as String?,
      stacks: ((json['stacks'] as List?) ?? const []).cast<String>(),
      healthScore: json['health_score'] as int,
      healthChecks: list('health_checks', HealthCheck.fromJson),
      alerts: ((json['alerts'] as List?) ?? const []).cast<String>(),
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'repo': repo.toJson(),
        'languages': languages.map((e) => e.toJson()).toList(),
        'commits': commits.map((e) => e.toJson()).toList(),
        'contributors': contributors.map((e) => e.toJson()).toList(),
        'files': files.map((e) => e.toJson()).toList(),
        'readme': readme,
        'stacks': stacks,
        'health_score': healthScore,
        'health_checks': healthChecks.map((e) => e.toJson()).toList(),
        'alerts': alerts,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}
