import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/models/commit_info.dart';
import 'package:repolens/models/contributor.dart';
import 'package:repolens/models/repo_file.dart';
import 'package:repolens/models/repo_info.dart';
import 'package:repolens/services/analyzer.dart';
import 'package:repolens/services/github_service.dart';

import '../mocks/mock_responses.dart';

RepoFile _file(String name, {String type = 'file'}) =>
    RepoFile(name: name, path: name, type: type, size: 1);

/// Arma datos de repo a medida para cada prueba.
RepoData _data({
  bool license = true,
  String? description = 'Algo',
  List<String> topics = const ['flutter'],
  List<String> files = const ['README.md', '.gitignore'],
  String? readme = '# Hola',
  int contributors = 2,
  DateTime? lastCommit,
}) {
  final json = jsonDecode(repoJson) as Map<String, dynamic>
    ..['license'] = license ? {'name': 'MIT License'} : null
    ..['description'] = description
    ..['topics'] = topics
    ..['pushed_at'] = null;
  return RepoData(
    repo: RepoInfo.fromJson(json),
    languages: const [],
    commits: [
      if (lastCommit != null)
        CommitInfo(sha: 'abc', message: 'm', authorName: 'a', date: lastCommit),
    ],
    contributors: [
      for (var i = 0; i < contributors; i++)
        Contributor(login: 'u$i', avatarUrl: '', contributions: 1),
    ],
    files: files.map(_file).toList(),
    readme: readme,
  );
}

void main() {
  final now = DateTime.utc(2026, 11, 11);

  group('Detección de stack', () {
    test('reconoce cada tecnología por su archivo de la raíz', () {
      expect(Analyzer.detectStack([_file('pubspec.yaml')]), ['Flutter/Dart']);
      expect(Analyzer.detectStack([_file('package.json')]), ['Node/JS']);
      expect(Analyzer.detectStack([_file('pyproject.toml')]), ['Python']);
      expect(Analyzer.detectStack([_file('build.gradle.kts')]), ['Android/Kotlin/Java']);
      expect(Analyzer.detectStack([_file('pom.xml')]), ['Maven']);
      expect(Analyzer.detectStack([_file('Cargo.toml')]), ['Rust']);
      expect(Analyzer.detectStack([_file('go.mod')]), ['Go']);
      expect(Analyzer.detectStack([_file('composer.json')]), ['PHP']);
      expect(Analyzer.detectStack([_file('MiApp.csproj')]), ['.NET']);
      expect(Analyzer.detectStack([_file('Dockerfile')]), ['Docker']);
    });

    test('combina varias tecnologías sin duplicar e ignora carpetas', () {
      final stacks = Analyzer.detectStack([
        _file('requirements.txt'),
        _file('pyproject.toml'),
        _file('Dockerfile'),
        _file('package.json', type: 'dir'),
        _file('main.c'),
      ]);
      expect(stacks, ['Python', 'Docker']);
    });
  });

  group('Alertas de seguridad', () {
    test('detecta archivos sensibles por nombre y por extensión', () {
      final alerts = Analyzer.securityAlerts([
        _file('.env'),
        _file('google-services.json'),
        _file('GoogleService-Info.plist'),
        _file('key.properties'),
        _file('release.jks'),
        _file('debug.keystore'),
        _file('server.pem'),
        _file('id_rsa'),
        _file('credentials.json'),
        _file('README.md'),
        _file('.env.example'),
      ]);
      expect(alerts, hasLength(9));
      expect(alerts, isNot(contains('README.md')));
      expect(alerts, isNot(contains('.env.example')));
    });

    test('un repo limpio no genera alertas', () {
      expect(Analyzer.securityAlerts([_file('lib', type: 'dir'), _file('pubspec.yaml')]), isEmpty);
    });
  });

  group('Puntuación de salud', () {
    test('repo completo obtiene 100', () {
      final data = _data(lastCommit: now.subtract(const Duration(days: 5)));
      final checks = Analyzer.healthChecks(data, now: now);
      expect(checks, hasLength(7));
      expect(checks.every((c) => c.passed), isTrue);
      expect(Analyzer.healthScore(checks), 100);
    });

    test('repo descuidado obtiene 0', () {
      final data = _data(
        license: false,
        description: '  ',
        topics: const [],
        files: const ['main.c'],
        readme: null,
        contributors: 1,
        lastCommit: now.subtract(const Duration(days: 400)),
      );
      expect(Analyzer.healthScore(Analyzer.healthChecks(data, now: now)), 0);
    });

    test('cada criterio resta sus puntos: sin licencia y commit viejo = 65', () {
      final data = _data(license: false, lastCommit: now.subtract(const Duration(days: 91)));
      final checks = Analyzer.healthChecks(data, now: now);
      expect(Analyzer.healthScore(checks), 65);
      expect(checks.firstWhere((c) => c.label == 'Tiene licencia').passed, isFalse);
      expect(checks.firstWhere((c) => c.label.startsWith('Commit')).passed, isFalse);
    });

    test('build arma el informe con stack, salud y alertas', () {
      final data = _data(
        files: const ['README.md', '.gitignore', 'pubspec.yaml', '.env'],
        lastCommit: now,
      );
      final result = Analyzer.build(data, now: now);
      expect(result.stacks, ['Flutter/Dart']);
      expect(result.alerts, ['.env']);
      expect(result.healthScore, 100);
      expect(result.analyzedAt, now);
    });
  });

  group('Árbol completo', () {
    RepoFile node(String path, {int size = 10}) => RepoFile(
        name: path.split('/').last, path: path, type: 'file', size: size);

    test('detecta el stack en subcarpetas y por herramientas', () {
      final stack = Analyzer.detectStack(
          [node('web/package.json'), node('web/vite.config.ts'), node('.github/workflows/ci.yml')]);
      expect(stack, containsAll(['Node/JS', 'Vite', 'GitHub Actions']));
    });

    test('en Flutter no repite las plataformas de la plantilla', () {
      expect(
          Analyzer.detectStack([
            node('app/pubspec.yaml'),
            node('app/android/build.gradle.kts'),
            node('app/android/app/src/main/AndroidManifest.xml'),
            node('app/windows/CMakeLists.txt'),
          ]),
          ['Flutter/Dart']);
    });

    test('sin archivos de configuración usa las extensiones', () {
      expect(Analyzer.detectStack([node('index.html'), node('css/style.css'), node('js/app.js')]),
          ['HTML', 'CSS', 'JavaScript']);
    });

    test('reporta archivos sensibles en subcarpetas con su ruta', () {
      expect(Analyzer.securityAlerts([node('config/.env'), node('src/app.js')]), ['config/.env']);
    });

    test('calcula estructura, prácticas y recomendaciones', () {
      final base = _data(license: false, topics: const []);
      final data = RepoData(
        repo: base.repo,
        languages: base.languages,
        commits: base.commits,
        contributors: base.contributors,
        files: base.files,
        readme: base.readme,
        tree: [
          const RepoFile(name: 'src', path: 'src', type: 'dir', size: 0),
          node('src/app.js', size: 2000),
          node('src/util.js', size: 500),
          node('index.html', size: 100),
        ],
      );
      final result = Analyzer.build(data, now: now);
      final insights = result.insights!;
      expect(insights.totalFiles, 3);
      expect(insights.totalDirs, 1);
      expect(insights.totalBytes, 2600);
      expect(insights.maxDepth, 1);
      expect(insights.extensions.first.extension, '.js');
      expect(insights.extensions.first.count, 2);
      expect(insights.largestFiles.first.path, 'src/app.js');
      expect(insights.signals.firstWhere((s) => s.label.startsWith('Pruebas')).present, isFalse);
      expect(insights.recommendations, isNotEmpty);
      expect(insights.recommendations.any((r) => r.contains('licencia')), isTrue);
    });

    test('README y .gitignore dentro de la carpeta del proyecto', () {
      final base = _data(files: const ['app']);
      final data = RepoData(
        repo: base.repo,
        languages: base.languages,
        commits: base.commits,
        contributors: base.contributors,
        files: [_file('app', type: 'dir')],
        readme: null,
        tree: [
          const RepoFile(name: 'app', path: 'app', type: 'dir', size: 0),
          node('app/README.md'),
          node('app/.gitignore'),
        ],
      );
      final result = Analyzer.build(data, now: now);
      expect(result.healthChecks.firstWhere((c) => c.label == 'Tiene .gitignore').passed, isTrue);
      expect(result.healthChecks.firstWhere((c) => c.label == 'Tiene README').passed, isFalse);
      expect(result.insights!.recommendations.first, contains('app/README.md'));
    });

    test('sin árbol no hay análisis de estructura', () {
      expect(Analyzer.build(_data(), now: now).insights, isNull);
    });
  });
}
